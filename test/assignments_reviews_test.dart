import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_lms/services/api_client.dart';
import 'package:flutter_lms/services/assignment_service.dart';
import 'package:flutter_lms/services/token_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loads published course assignments with backend fields', () async {
    final adapter = _AssignmentAdapter();
    final client = ApiClient(TokenStorage.memory())
      ..dio.httpClientAdapter = adapter;

    final assignments = await AssignmentService(client)
        .getCourseAssignments('course-from-enrollment');

    expect(
      adapter.paths.single,
      '/api/v1/courses/course-from-enrollment/assignments',
    );
    expect(assignments, hasLength(1));
    expect(assignments.single.id, 'assignment-from-response');
    expect(assignments.single.title, 'Build an app');
    expect(assignments.single.dueDate, DateTime.utc(2026, 11, 1));
    expect(assignments.single.maximumMarks, 50);
    expect(assignments.single.status, 'SUBMITTED');
  });

  test('loads assignment details by the response assignment id', () async {
    final adapter = _AssignmentAdapter();
    final client = ApiClient(TokenStorage.memory())
      ..dio.httpClientAdapter = adapter;

    final assignment = await AssignmentService(client)
        .getAssignment('assignment-from-response');

    expect(
      adapter.paths.single,
      '/api/v1/assignments/assignment-from-response',
    );
    expect(assignment.title, 'Build an app');
    expect(assignment.attachmentName, 'brief.pdf');
  });
}

class _AssignmentAdapter implements HttpClientAdapter {
  final paths = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    paths.add(options.path);
    final assignment = {
      'id': 'assignment-from-response',
      'title': 'Build an app',
      'dueDate': '2026-11-01T00:00:00.000Z',
      'maximumMarks': 50,
      'status': 'SUBMITTED',
      'attachment': {
        'originalName': 'brief.pdf',
        'url': 'https://test.local/brief.pdf',
      },
    };
    final data = options.path.endsWith('/assignments')
        ? {
            'assignments': [assignment],
          }
        : {'assignment': assignment};
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
