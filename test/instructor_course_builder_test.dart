import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_lms/services/api_client.dart';
import 'package:flutter_lms/services/instructor_course_service.dart';
import 'package:flutter_lms/services/instructor_lesson_service.dart';
import 'package:flutter_lms/services/token_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  test('uses the course and section builder endpoint contracts', () async {
    final adapter = _BuilderAdapter();
    final client = ApiClient(TokenStorage.memory())
      ..dio.httpClientAdapter = adapter;
    final courseService = InstructorCourseService(client);
    final sectionService = InstructorLessonService(client);

    await courseService.getDashboard();
    await courseService.getMyCourses(
      page: 2,
      limit: 20,
      status: 'DRAFT',
      search: 'Flutter',
    );
    await courseService.getMyCourse('course-response-id');
    await courseService.createCourse({
      'categoryId': 'category-response-id',
      'title': 'Course',
      'shortDescription': 'Short',
      'description': 'Description',
      'level': 'BEGINNER',
      'language': 'English',
      'requirements': ['Basics'],
      'learningOutcomes': ['Build apps'],
      'targetAudience': ['Developers'],
    });
    await courseService.updateCourse('course-response-id', {
      'shortDescription': 'Changed only',
    });
    final image = File(
      '${Directory.systemTemp.path}\\instructor_course_test.png',
    );
    await image.writeAsBytes([1, 2, 3, 4]);
    addTearDown(() async {
      if (await image.exists()) await image.delete();
    });
    await courseService.uploadThumbnail(
      'course-response-id',
      XFile(image.path),
      onSendProgress: (_, _) {},
    );
    await courseService.removeThumbnail('course-response-id');
    await courseService.publishCourse('course-response-id');
    await courseService.archiveCourse('course-response-id');

    await sectionService.getCourseSections('course-response-id');
    await sectionService.createSection('course-response-id', {
      'title': 'Section',
      'description': 'Intro',
      'isPublished': false,
    });
    await sectionService.updateSection('section-response-id', {
      'title': 'Changed',
    });
    await sectionService.reorderSection('section-response-id', 3);
    await sectionService.deleteSection('section-response-id');

    expect(
      adapter.requests.map((request) => '${request.method} ${request.path}'),
      [
        'GET /api/v1/dashboard/instructor',
        'GET /api/v1/courses/instructor/me',
        'GET /api/v1/courses/instructor/me/course-response-id',
        'POST /api/v1/courses',
        'PATCH /api/v1/courses/course-response-id',
        'POST /api/v1/courses/course-response-id/thumbnail',
        'DELETE /api/v1/courses/course-response-id/thumbnail',
        'PATCH /api/v1/courses/course-response-id/publish',
        'PATCH /api/v1/courses/course-response-id/archive',
        'GET /api/v1/courses/course-response-id/sections',
        'POST /api/v1/courses/course-response-id/sections',
        'PATCH /api/v1/sections/section-response-id',
        'PATCH /api/v1/sections/section-response-id/reorder',
        'DELETE /api/v1/sections/section-response-id',
      ],
    );
    expect(adapter.requests[1].query, {
      'page': 2,
      'limit': 20,
      'status': 'DRAFT',
      'search': 'Flutter',
    });
    expect(adapter.requests[4].body, {'shortDescription': 'Changed only'});
    expect(adapter.requests[5].multipartFieldNames, contains('thumbnail'));
    expect(
      adapter.requests[5].contentType,
      matches(RegExp(r'multipart/form-data; boundary=.+')),
    );
    expect(adapter.requests[11].body, {'title': 'Changed'});
    expect(adapter.requests[12].body, {'order': 3});
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
  });

  final String method;
  final String path;
  final dynamic body;
  final Map<String, dynamic> query;
  final List<String> multipartFieldNames;
  final String? contentType;
}

class _BuilderAdapter implements HttpClientAdapter {
  final requests = <_CapturedRequest>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final data = options.data;
    final form = data is FormData ? data : null;
    dynamic response = {};
    if (options.path == '/api/v1/courses/instructor/me/course-response-id' ||
        options.path == '/api/v1/courses') {
      response = {
        'course': {
          'id': 'course-response-id',
          'title': 'Course',
          'status': 'DRAFT',
        },
      };
    } else if (options.path.endsWith('/courses/instructor/me')) {
      response = {
        'courses': [
          {'id': 'course-response-id', 'title': 'Course', 'status': 'DRAFT'},
        ],
        'pagination': {'page': 2, 'limit': 20, 'totalPages': 3},
      };
    } else if (options.path.endsWith('/sections')) {
      response = {
        'sections': [
          {'id': 'section-response-id', 'title': 'Section', 'order': 1},
        ],
      };
    }

    requests.add(
      _CapturedRequest(
        method: options.method,
        path: options.path,
        body: data is Map<String, dynamic> ? data : null,
        query: Map<String, dynamic>.from(options.queryParameters),
        multipartFieldNames:
            form?.files.map((entry) => entry.key).toList() ?? const [],
        contentType: options.headers[Headers.contentTypeHeader]?.toString(),
      ),
    );
    return ResponseBody.fromString(
      jsonEncode({'data': response}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
