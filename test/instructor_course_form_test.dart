import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lms/models/course.dart';
import 'package:flutter_lms/models/course_category.dart';
import 'package:flutter_lms/models/instructor_summary.dart';
import 'package:flutter_lms/models/paged_result.dart';
import 'package:flutter_lms/models/user_model.dart';
import 'package:flutter_lms/providers/auth_provider.dart';
import 'package:flutter_lms/providers/instructor_courses_provider.dart';
import 'package:flutter_lms/providers/instructor_dashboard_provider.dart';
import 'package:flutter_lms/screens/instructor_course_screens.dart';
import 'package:flutter_lms/services/api_client.dart';
import 'package:flutter_lms/services/auth_service.dart';
import 'package:flutter_lms/services/course_service.dart';
import 'package:flutter_lms/services/instructor_course_service.dart';
import 'package:flutter_lms/services/token_storage.dart';
import 'package:flutter_lms/utils/api_exception.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('course form sends documented data and backend errors', (
    tester,
  ) async {
    final client = ApiClient(TokenStorage.memory());
    final tokenStorage = TokenStorage.memory();
    final courseService = _CourseService(client);
    final instructorService = _InstructorCourseService(client);
    final courses = InstructorCoursesProvider(instructorService);
    final dashboard = InstructorDashboardProvider(instructorService);
    final auth = AuthProvider(AuthService(client, tokenStorage))
      ..setUser(
        const UserModel(
          id: 'instructor-id',
          firstName: 'Instructor',
          lastName: 'User',
          email: 'instructor@example.test',
          role: 'INSTRUCTOR',
        ),
      );
    addTearDown(client.dio.close);
    addTearDown(courses.dispose);
    addTearDown(dashboard.dispose);
    addTearDown(auth.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<CourseService>.value(value: courseService),
          ChangeNotifierProvider<InstructorCoursesProvider>.value(
            value: courses,
          ),
          ChangeNotifierProvider<InstructorDashboardProvider>.value(
            value: dashboard,
          ),
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ],
        child: const MaterialApp(home: InstructorCourseFormScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final shortDescriptionField = tester.widget<TextFormField>(
      find.byType(TextFormField).at(1),
    );
    expect(find.text('Short description *'), findsOneWidget);
    expect(
      shortDescriptionField.validator?.call(''),
      'This field is required.',
    );

    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    expect(find.text('Inactive category'), findsNothing);
    await tester.tap(find.text('Development').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'OOP with Java');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'Learn object-oriented programming',
    );
    await tester.enterText(find.byType(TextFormField).at(2), 'Course details');
    await tester.enterText(find.byType(TextFormField).at(3), 'Java');
    await tester.ensureVisible(find.text('Requirements'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.ancestor(
        of: find.text('Requirements'),
        matching: find.byType(TextFormField),
      ),
      'Basic Java',
    );
    await tester.ensureVisible(find.text('Learning outcomes'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.ancestor(
        of: find.text('Learning outcomes'),
        matching: find.byType(TextFormField),
      ),
      'Use OOP',
    );
    await tester.ensureVisible(find.text('Target audience'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.ancestor(
        of: find.text('Target audience'),
        matching: find.byType(TextFormField),
      ),
      'Undergraduates',
    );
    await tester.drag(find.byType(ListView), const Offset(0, -900));
    await tester.pumpAndSettle();

    final request = RequestOptions(path: '/api/v1/courses');
    instructorService.createError = ApiException.fromDioException(
      DioException(
        requestOptions: request,
        response: Response<dynamic>(
          requestOptions: request,
          statusCode: 500,
          data: {
            'message': 'Request validation failed',
            'errors': {
              'requirements': ['Please provide at least one requirement.'],
            },
          },
        ),
        type: DioExceptionType.badResponse,
      ),
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Create course'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Request validation failed: requirements: Please provide at least one requirement.',
      ),
      findsOneWidget,
    );

    expect(instructorService.createCalls, 1);
    expect(instructorService.createBody, {
      'categoryId': 'category-id',
      'title': 'OOP with Java',
      'shortDescription': 'Learn object-oriented programming',
      'description': 'Course details',
      'level': 'BEGINNER',
      'language': 'Java',
      'requirements': ['Basic Java'],
      'learningOutcomes': ['Use OOP'],
      'targetAudience': ['Undergraduates'],
    });
  });
}

class _CourseService extends CourseService {
  _CourseService(super.client);

  @override
  Future<PagedResult<CourseCategory>> getCategories({
    int page = 1,
    int limit = 20,
  }) async => const PagedResult(
    items: [
      CourseCategory(
        id: 'inactive-category-id',
        name: 'Inactive category',
        isActive: false,
      ),
      CourseCategory(id: 'category-id', name: 'Development'),
    ],
    page: 1,
    limit: 20,
    total: 2,
    totalPages: 1,
  );
}

class _InstructorCourseService extends InstructorCourseService {
  _InstructorCourseService(super.client);

  Map<String, dynamic>? createBody;
  ApiException? createError;
  var createCalls = 0;

  @override
  Future<PagedResult<Course>> getMyCourses({
    int page = 1,
    int limit = 10,
    String? status,
    String? search,
  }) async =>
      const PagedResult(items: [], page: 1, limit: 10, total: 0, totalPages: 1);

  @override
  Future<Course> createCourse(Map<String, dynamic> body) async {
    createCalls++;
    createBody = Map.of(body);
    if (createError != null) throw createError!;
    return const Course(
      id: 'course-id',
      title: 'OOP with Java',
      shortDescription: 'Learn object-oriented programming',
      description: 'Course details',
      level: 'BEGINNER',
      language: 'Java',
      price: 0,
      averageRating: 0,
      reviewCount: 0,
      enrollmentCount: 0,
      status: 'DRAFT',
    );
  }

  @override
  Future<InstructorSummary> getDashboard() async => const InstructorSummary(
    totalCourses: 1,
    publishedCourses: 0,
    draftCourses: 1,
    archivedCourses: 0,
    totalEnrollments: 0,
    pendingSubmissions: 0,
    averageRating: 0,
  );
}
