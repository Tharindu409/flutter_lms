import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lms/models/user_model.dart';
import 'package:flutter_lms/providers/auth_provider.dart';
import 'package:flutter_lms/providers/instructor_dashboard_provider.dart';
import 'package:flutter_lms/providers/instructor_quiz_provider.dart';
import 'package:flutter_lms/screens/instructor_quiz_screens.dart';
import 'package:flutter_lms/services/api_client.dart';
import 'package:flutter_lms/services/auth_service.dart';
import 'package:flutter_lms/services/instructor_course_service.dart';
import 'package:flutter_lms/services/instructor_lesson_service.dart';
import 'package:flutter_lms/services/instructor_quiz_service.dart';
import 'package:flutter_lms/services/token_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('publishes a draft quiz from its course list card', (
    tester,
  ) async {
    final adapter = _QuizPublishAdapter();
    final storage = TokenStorage.memory();
    final api = ApiClient(storage)..dio.httpClientAdapter = adapter;
    final auth = AuthProvider(AuthService(api, storage))
      ..setUser(
        const UserModel(
          id: 'instructor-id',
          firstName: 'Taylor',
          lastName: 'Teacher',
          email: 'teacher@example.test',
          role: 'INSTRUCTOR',
        ),
      );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
          ChangeNotifierProvider(
            create: (_) => InstructorQuizProvider(
              InstructorQuizService(api),
              InstructorLessonService(api),
            ),
          ),
          ChangeNotifierProvider(
            create: (_) =>
                InstructorDashboardProvider(InstructorCourseService(api)),
          ),
        ],
        child: const MaterialApp(
          home: InstructorCourseQuizzesScreen(
            courseId: 'course-id',
            courseTitle: 'Course',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Draft'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Publish'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Publish').last);
    await tester.pumpAndSettle();

    expect(adapter.published, isTrue);
    expect(adapter.paths, contains('PATCH /api/v1/quizzes/quiz-id/publish'));
    expect(find.text('Published'), findsOneWidget);
  });
}

class _QuizPublishAdapter implements HttpClientAdapter {
  final paths = <String>[];
  bool published = false;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    paths.add('${options.method} ${options.path}');

    if (options.path == '/api/v1/quizzes/quiz-id/publish') {
      published = true;
    }

    dynamic data = {};
    if (options.path == '/api/v1/courses/course-id/quizzes/instructor') {
      data = {
        'quizzes': [
          {
            'id': 'quiz-id',
            'title': 'First quiz',
            'isPublished': published,
            'questionCount': 1,
          },
        ],
      };
    } else if (options.path == '/api/v1/courses/course-id/sections') {
      data = {'sections': <dynamic>[]};
    } else if (options.path == '/api/v1/dashboard/instructor') {
      data = {'dashboard': <String, dynamic>{}};
    }

    return ResponseBody.fromString(
      jsonEncode({'data': data}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
