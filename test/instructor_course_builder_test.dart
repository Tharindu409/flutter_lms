import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_lms/services/api_client.dart';
import 'package:flutter_lms/services/course_service.dart';
import 'package:flutter_lms/services/instructor_course_service.dart';
import 'package:flutter_lms/services/token_storage.dart';
import 'package:flutter_lms/providers/instructor_courses_provider.dart';
import 'package:flutter_lms/screens/instructor_course_screens.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  test('course update payload includes only changed fields', () {
    expect(
      courseUpdatePayload(
        originalShortDescription: 'Original',
        originalLevel: 'BEGINNER',
        originalLearningOutcomes: const ['A'],
        shortDescription: 'Changed',
        level: 'BEGINNER',
        learningOutcomes: const ['A'],
      ),
      {'shortDescription': 'Changed'},
    );
  });

  test('refreshes the course list after a successful mutation', () async {
    final adapter = _CourseAdapter();
    final client = ApiClient(TokenStorage.memory())
      ..dio.httpClientAdapter = adapter;
    final provider = InstructorCoursesProvider(InstructorCourseService(client));

    await provider.refresh();
    expect(await provider.publishCourse('course-response-id'), isNull);

    expect(
      adapter.requests
          .where(
            (request) =>
                request.method == 'GET' &&
                request.path == '/api/v1/courses/instructor/me',
          )
          .length,
      2,
    );
    provider.dispose();
  });

  test('uses the instructor course endpoints and thumbnail field', () async {
    final adapter = _CourseAdapter();
    final client = ApiClient(TokenStorage.memory())
      ..dio.httpClientAdapter = adapter;
    final service = InstructorCourseService(client);
    final thumbnail = File(
      '${Directory.systemTemp.path}\\course_builder_test.png',
    );
    await thumbnail.writeAsBytes([137, 80, 78, 71, 13, 10, 26, 10]);
    addTearDown(() async {
      if (await thumbnail.exists()) await thumbnail.delete();
    });

    await service.getMyCourses(page: 1, limit: 20, status: 'DRAFT');
    await service.getMyCourse('course-response-id');
    await service.createCourse({
      'categoryId': 'category-response-id',
      'title': 'Course',
      'shortDescription': 'Short description',
      'description': 'Description',
      'level': 'BEGINNER',
      'language': 'en',
      'requirements': <String>[],
      'learningOutcomes': <String>[],
      'targetAudience': <String>[],
    });
    await service.updateCourse('course-response-id', {
      'shortDescription': 'Changed summary',
      'learningOutcomes': ['Outcome'],
    });
    await service.uploadThumbnail('course-response-id', XFile(thumbnail.path));
    await service.removeThumbnail('course-response-id');
    await service.publishCourse('course-response-id');
    await service.archiveCourse('course-response-id');
    await CourseService(client).getCategories(page: 1, limit: 20);

    expect(
      adapter.requests.map((request) => '${request.method} ${request.path}'),
      [
        'GET /api/v1/courses/instructor/me',
        'GET /api/v1/courses/instructor/me/course-response-id',
        'POST /api/v1/courses',
        'PATCH /api/v1/courses/course-response-id',
        'POST /api/v1/courses/course-response-id/thumbnail',
        'DELETE /api/v1/courses/course-response-id/thumbnail',
        'PATCH /api/v1/courses/course-response-id/publish',
        'PATCH /api/v1/courses/course-response-id/archive',
        'GET /api/v1/categories',
      ],
    );
    expect(adapter.requests[3].body, {
      'shortDescription': 'Changed summary',
      'learningOutcomes': ['Outcome'],
    });
    expect(adapter.requests[4].multipartFieldNames, contains('thumbnail'));
    expect(adapter.requests[0].queryParameters, {
      'page': 1,
      'limit': 20,
      'status': 'DRAFT',
    });
    expect(adapter.requests[8].queryParameters, {
      'page': 1,
      'limit': 20,
      'activeOnly': true,
    });
  });
}

class _CapturedRequest {
  const _CapturedRequest({
    required this.method,
    required this.path,
    required this.body,
    required this.queryParameters,
    required this.multipartFieldNames,
  });

  final String method;
  final String path;
  final dynamic body;
  final Map<String, dynamic> queryParameters;
  final List<String> multipartFieldNames;
}

class _CourseAdapter implements HttpClientAdapter {
  final requests = <_CapturedRequest>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final bytes = <int>[];
    if (requestStream != null) {
      await for (final chunk in requestStream) {
        bytes.addAll(chunk);
      }
    }

    dynamic body;
    final multipartFieldNames = <String>[];
    if (options.data is Map<String, dynamic>) {
      body = options.data;
    } else if (bytes.isNotEmpty) {
      final text = utf8.decode(bytes, allowMalformed: true);
      if (options.contentType?.startsWith('multipart/form-data') == true) {
        multipartFieldNames.addAll(
          RegExp(r'name="([^"]+)"')
              .allMatches(text)
              .map((match) => match.group(1)!),
        );
      } else {
        try {
          body = jsonDecode(text);
        } on FormatException {
          body = text;
        }
      }
    }

    requests.add(
      _CapturedRequest(
        method: options.method,
        path: options.path,
        body: body,
        queryParameters: options.queryParameters,
        multipartFieldNames: multipartFieldNames,
      ),
    );
    return ResponseBody.fromString(
      jsonEncode({'data': {}}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
