import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_lms/providers/instructor_assignment_provider.dart';
import 'package:flutter_lms/services/api_client.dart';
import 'package:flutter_lms/services/instructor_assignment_service.dart';
import 'package:flutter_lms/services/instructor_lesson_service.dart';
import 'package:flutter_lms/services/token_storage.dart';
import 'package:flutter_lms/utils/api_exception.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'uses instructor assignment, submissions, enrollment and grade APIs',
    () async {
      final adapter = _AssignmentAdapter();
      final client = ApiClient(TokenStorage.memory())
        ..dio.httpClientAdapter = adapter;
      final service = InstructorAssignmentService(client);

      await service.getCourseAssignments('course-response-id');
      await service.createAssignment('course-response-id', {
        'sectionId': 'section-response-id',
        'title': 'Essay',
        'description': 'Description',
        'instructions': 'Write an essay',
        'dueDate': '2026-11-01T10:00:00.000',
        'maximumMarks': 20,
      });
      await service.updateAssignment('assignment-response-id', {
        'instructions': 'Updated instructions',
        'maximumMarks': 25,
      });
      final file = File(
        '${Directory.systemTemp.path}\\instructor_assignment_test.pdf',
      );
      await file.writeAsBytes([0, 0, 0, 0]);
      addTearDown(() async {
        if (await file.exists()) await file.delete();
      });
      await service.uploadAttachment(
        'assignment-response-id',
        file.path,
        'instructions.pdf',
        onSendProgress: (_, _) {},
        cancelToken: CancelToken(),
      );
      await service.deleteAttachment('assignment-response-id');
      await service.publishAssignment('assignment-response-id');
      await service.deleteAssignment('assignment-response-id');
      final submissions = await service.getSubmissions(
        'assignment-response-id',
        page: 2,
        limit: 20,
        status: 'GRADED',
      );
      final enrollments = await service.getCourseEnrollments(
        'course-response-id',
        status: 'ACTIVE',
      );
      await service.gradeSubmission('submission-response-id', {
        'marksAwarded': 18,
        'feedback': 'Good work',
        'status': 'GRADED',
      });

      expect(
        adapter.requests.map((request) => '${request.method} ${request.path}'),
        [
          'GET /api/v1/courses/course-response-id/assignments/instructor',
          'POST /api/v1/courses/course-response-id/assignments',
          'PATCH /api/v1/assignments/assignment-response-id',
          'POST /api/v1/assignments/assignment-response-id/attachment',
          'DELETE /api/v1/assignments/assignment-response-id/attachment',
          'PATCH /api/v1/assignments/assignment-response-id/publish',
          'DELETE /api/v1/assignments/assignment-response-id',
          'GET /api/v1/assignments/assignment-response-id/submissions',
          'GET /api/v1/courses/course-response-id/enrollments',
          'PATCH /api/v1/submissions/submission-response-id/grade',
        ],
      );
      expect(adapter.requests[1].body['sectionId'], 'section-response-id');
      expect(adapter.requests[2].body, {
        'instructions': 'Updated instructions',
        'maximumMarks': 25,
      });
      expect(adapter.requests[3].multipartFieldNames, contains('attachment'));
      expect(
        adapter.requests[3].contentType,
        matches(RegExp(r'multipart/form-data; boundary=.+')),
      );
      expect(adapter.requests[3].sendTimeout, const Duration(minutes: 10));
      expect(adapter.requests[5].body, isEmpty);
      expect(adapter.requests[7].query, {
        'page': 2,
        'limit': 20,
        'status': 'GRADED',
      });
      expect(adapter.requests[8].query, {
        'page': 1,
        'limit': 20,
        'status': 'ACTIVE',
      });
      expect(submissions.items.single.studentName, 'Sam Student');
      expect(submissions.items.single.status, 'SUBMITTED');
      expect(submissions.items.single.textAnswer, 'My answer');
      expect(enrollments.items.single.progressPercentage, '63.5');
    },
  );

  test('refreshes assignment list after a successful update', () async {
    final adapter = _AssignmentAdapter();
    final client = ApiClient(TokenStorage.memory())
      ..dio.httpClientAdapter = adapter;
    final provider = InstructorAssignmentProvider(
      InstructorAssignmentService(client),
      InstructorLessonService(client),
    );
    await provider.loadCourse('course-response-id', title: 'Course');
    final error = await provider.updateAssignment('assignment-response-id', {
      'maximumMarks': 30,
    });

    expect(error, isNull);
    expect(provider.assignments.single.id, 'assignment-response-id');
    expect(
      adapter.requests
          .where((request) => request.path.endsWith('/assignments/instructor'))
          .length,
      2,
    );
    provider.dispose();
  });

  test('maps ownership errors and preserves backend grading errors', () async {
    final forbiddenClient = ApiClient(TokenStorage.memory())
      ..dio.httpClientAdapter = _AssignmentAdapter(
        failureStatus: 403,
        failureMessage: 'ownership denied',
      );
    await expectLater(
      InstructorAssignmentService(forbiddenClient)
          .getCourseAssignments('course-response-id'),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          'You do not have access to this course',
        ),
      ),
    );

    final invalidClient = ApiClient(TokenStorage.memory())
      ..dio.httpClientAdapter = _AssignmentAdapter(
        failureStatus: 422,
        failureMessage:
            'Maximum marks cannot be less than marks already awarded.',
      );
    await expectLater(
      InstructorAssignmentService(invalidClient)
          .updateAssignment('assignment-response-id', {'maximumMarks': 2}),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          'Maximum marks cannot be less than marks already awarded.',
        ),
      ),
    );
  });
}

class _CapturedRequest {
  const _CapturedRequest({
    required this.method,
    required this.path,
    required this.body,
    required this.query,
    required this.multipartFieldNames,
    required this.contentType,
    required this.sendTimeout,
  });

  final String method;
  final String path;
  final Map<String, dynamic> body;
  final Map<String, dynamic> query;
  final List<String> multipartFieldNames;
  final String? contentType;
  final Duration? sendTimeout;
}

class _AssignmentAdapter implements HttpClientAdapter {
  _AssignmentAdapter({this.failureStatus, this.failureMessage});

  final int? failureStatus;
  final String? failureMessage;
  final requests = <_CapturedRequest>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final data = options.data;
    final body = data is Map<String, dynamic>
        ? data
        : const <String, dynamic>{};
    final form = data is FormData ? data : null;
    requests.add(
      _CapturedRequest(
        method: options.method,
        path: options.path,
        body: body,
        query: Map<String, dynamic>.from(options.queryParameters),
        multipartFieldNames:
            form?.files.map((entry) => entry.key).toList() ?? const [],
        contentType: options.headers[Headers.contentTypeHeader]?.toString(),
        sendTimeout: options.sendTimeout,
      ),
    );
    if (failureStatus != null) {
      return ResponseBody.fromString(
        jsonEncode({'message': failureMessage}),
        failureStatus!,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    dynamic dataResponse = {};
    if (options.path.endsWith('/assignments/instructor')) {
      dataResponse = {
        'assignments': [
          {
            'id': 'assignment-response-id',
            'title': 'Essay',
            'maximumMarks': 25,
            'status': 'PUBLISHED',
          },
        ],
      };
    } else if (options.path.endsWith('/submissions')) {
      dataResponse = {
        'submissions': [
          {
            'id': 'submission-response-id',
            'assignmentId': 'assignment-response-id',
            'student': {'firstName': 'Sam', 'lastName': 'Student'},
            'textAnswer': 'My answer',
            'status': 'SUBMITTED',
            'submittedAt': '2026-10-28T07:00:00Z',
          },
        ],
        'pagination': {'page': 2, 'limit': 20, 'totalPages': 3},
      };
    } else if (options.path.endsWith('/enrollments')) {
      dataResponse = {
        'enrollments': [
          {
            'id': 'enrollment-response-id',
            'student': {'firstName': 'Sam', 'lastName': 'Student'},
            'status': 'ACTIVE',
            'progressPercentage': 63.5,
          },
        ],
        'pagination': {'page': 1, 'limit': 20, 'totalPages': 1},
      };
    }

    return ResponseBody.fromString(
      jsonEncode({'data': dataResponse}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
