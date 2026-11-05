import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lms/providers/assignment_provider.dart';
import 'package:flutter_lms/providers/learning_provider.dart';
import 'package:flutter_lms/providers/quiz_provider.dart';
import 'package:flutter_lms/screens/student_learning_screens.dart';
import 'package:flutter_lms/services/api_client.dart';
import 'package:flutter_lms/services/assignment_service.dart';
import 'package:flutter_lms/services/course_service.dart';
import 'package:flutter_lms/services/enrollment_service.dart';
import 'package:flutter_lms/services/learning_service.dart';
import 'package:flutter_lms/services/quiz_service.dart';
import 'package:flutter_lms/services/token_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets(
    'course page loads and refreshes quizzes and assignments for its course ID',
    (tester) async {
      final adapter = _CourseWorkAdapter();
      final api = ApiClient(TokenStorage.memory())
        ..dio.httpClientAdapter = adapter;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<LearningProvider>(
              create: (_) => _LearningProvider(api),
            ),
            ChangeNotifierProvider(
              create: (_) => QuizProvider(QuizService(api)),
            ),
            ChangeNotifierProvider(
              create: (_) => AssignmentProvider(
                AssignmentService(api),
                EnrollmentService(api),
              ),
            ),
          ],
          child: const MaterialApp(
            home: CurriculumScreen(
              courseId: 'course-from-enrollment',
              title: 'Published course',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('No assignments yet'),
        350,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('No quizzes yet'), findsOneWidget);
      expect(find.text('No assignments yet'), findsOneWidget);
      expect(
        adapter.paths,
        containsAll([
          '/api/v1/courses/course-from-enrollment/quizzes',
          '/api/v1/courses/course-from-enrollment/assignments',
        ]),
      );

      adapter.hasPublishedWork = true;
      await tester.drag(find.byType(ListView).first, const Offset(0, 1200));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView).first, const Offset(0, 420));
      await tester.pumpAndSettle();

      expect(find.text('Published quiz'), findsOneWidget);
      expect(find.text('Published assignment'), findsOneWidget);
      expect(
        adapter.paths.where((path) => path.endsWith('/quizzes')).length,
        2,
      );
      expect(
        adapter.paths.where((path) => path.endsWith('/assignments')).length,
        2,
      );
    },
  );
}

class _LearningProvider extends LearningProvider {
  _LearningProvider(ApiClient api)
    : super(CourseService(api), LearningService(api));

  @override
  Future<void> load(
    String id, {
    String title = '',
    String? enrollmentId,
  }) async {
    courseId = id;
    courseTitle = title;
    sections = const [];
    isLoading = false;
  }
}

class _CourseWorkAdapter implements HttpClientAdapter {
  final paths = <String>[];
  bool hasPublishedWork = false;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    paths.add(options.path);
    final dynamic data;
    if (options.path.endsWith('/quizzes')) {
      data = {
        'quizzes': hasPublishedWork
            ? [
                {'_id': 'quiz-1', 'title': 'Published quiz'},
              ]
            : <dynamic>[],
      };
    } else if (options.path.endsWith('/assignments')) {
      data = {
        'assignments': hasPublishedWork
            ? [
                {
                  '_id': 'assignment-1',
                  'title': 'Published assignment',
                  'status': 'PUBLISHED',
                },
              ]
            : <dynamic>[],
      };
    } else {
      data = {'sections': <dynamic>[]};
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
