import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_lms/providers/instructor_lesson_provider.dart';
import 'package:flutter_lms/services/api_client.dart';
import 'package:flutter_lms/services/instructor_lesson_service.dart';
import 'package:flutter_lms/services/token_storage.dart';
import 'package:flutter_lms/utils/upload_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'uses the section management endpoints and refreshes after mutations',
    () async {
      final adapter = _LessonAdapter();
      final client = ApiClient(TokenStorage.memory())
        ..dio.httpClientAdapter = adapter;
      final provider = InstructorLessonProvider(
        InstructorLessonService(client),
      );

      await provider.loadSections('course-response-id');
      expect(
        await provider.createSection({
          'title': 'New section',
          'description': 'Section description',
          'isPublished': false,
        }),
        isNull,
      );
      expect(
        await provider.updateSection('section-response-id', {
          'title': 'Updated section',
        }),
        isNull,
      );
      expect(await provider.reorderSection('section-response-id', 2), isNull);
      expect(await provider.deleteSection('section-response-id'), isNull);

      expect(
        adapter.requests
            .map((request) => '${request.method} ${request.path}')
            .where(
              (request) =>
                  request != 'GET /api/v1/courses/course-response-id/sections',
            )
            .toList(),
        [
          'POST /api/v1/courses/course-response-id/sections',
          'PATCH /api/v1/sections/section-response-id',
          'PATCH /api/v1/sections/section-response-id/reorder',
          'DELETE /api/v1/sections/section-response-id',
        ],
      );
      expect(
        adapter.requests
            .where(
              (request) =>
                  request.method == 'GET' &&
                  request.path == '/api/v1/courses/course-response-id/sections',
            )
            .length,
        5,
      );
      expect(
        adapter.requests
            .singleWhere((request) => request.method == 'POST')
            .body,
        {
          'title': 'New section',
          'description': 'Section description',
          'isPublished': false,
        },
      );
      expect(
        adapter.requests
            .singleWhere(
              (request) =>
                  request.method == 'PATCH' &&
                  request.path == '/api/v1/sections/section-response-id',
            )
            .body,
        {'title': 'Updated section'},
      );
      expect(
        adapter.requests
            .singleWhere((request) => request.path.endsWith('/reorder'))
            .body,
        {'order': 2},
      );
      provider.dispose();
    },
  );

  test('uses the lesson endpoints and multipart field names', () async {
    final adapter = _LessonAdapter();
    final client = ApiClient(TokenStorage.memory())
      ..dio.httpClientAdapter = adapter;
    final service = InstructorLessonService(client);
    final videoFile = File(
      '${Directory.systemTemp.path}\\instructor_lesson_test.mp4',
    );
    final documentFile = File(
      '${Directory.systemTemp.path}\\instructor_lesson_test.pdf',
    );
    await videoFile.writeAsBytes([0, 0, 0, 0]);
    await documentFile.writeAsBytes([0, 0, 0, 0]);

    addTearDown(() async {
      if (await videoFile.exists()) await videoFile.delete();
      if (await documentFile.exists()) await documentFile.delete();
    });
    await service.getCourseSections('course-response-id');
    await service.getSectionLessons('section-response-id');
    await service.createLesson('section-response-id', {
      'title': 'Text lesson',
      'description': '',
      'lessonType': 'TEXT',
      'textContent': 'Lesson body',
      'durationMinutes': 5,
      'isPreview': false,
      'isPublished': false,
    });
    await service.updateLesson('lesson-response-id', {'isPublished': true});
    await service.reorderLesson('lesson-response-id', 2);
    await service.getLesson('lesson-response-id');
    await service.uploadVideo(
      'lesson-response-id',
      videoFile.path,
      'test.mp4',
      onSendProgress: (_, _) {},
      cancelToken: CancelToken(),
    );
    await service.uploadDocument(
      'lesson-response-id',
      documentFile.path,
      'test.pdf',
      onSendProgress: (_, _) {},
      cancelToken: CancelToken(),
    );
    await service.deleteVideo('lesson-response-id');
    await service.deleteDocument('lesson-response-id');
    await service.deleteLesson('lesson-response-id');

    expect(
      adapter.requests.map((request) => '${request.method} ${request.path}'),
      [
        'GET /api/v1/courses/course-response-id/sections',
        'GET /api/v1/sections/section-response-id/lessons',
        'POST /api/v1/sections/section-response-id/lessons',
        'PATCH /api/v1/lessons/lesson-response-id',
        'PATCH /api/v1/lessons/lesson-response-id/reorder',
        'GET /api/v1/lessons/lesson-response-id',
        'POST /api/v1/lessons/lesson-response-id/video',
        'POST /api/v1/lessons/lesson-response-id/document',
        'DELETE /api/v1/lessons/lesson-response-id/video',
        'DELETE /api/v1/lessons/lesson-response-id/document',
        'DELETE /api/v1/lessons/lesson-response-id',
      ],
    );
    expect(adapter.requests[2].body, {
      'title': 'Text lesson',
      'description': '',
      'lessonType': 'TEXT',
      'textContent': 'Lesson body',
      'durationMinutes': 5,
      'isPreview': false,
      'isPublished': false,
    });
    expect(adapter.requests[3].body, {'isPublished': true});
    expect(adapter.requests[4].body, {'order': 2});
    expect(adapter.requests[6].multipartFieldNames, contains('video'));
    expect(adapter.requests[7].multipartFieldNames, contains('document'));
    expect(
      adapter.requests[6].contentType,
      matches(RegExp(r'multipart/form-data; boundary=.+')),
    );
    expect(adapter.requests[6].sendTimeout, const Duration(minutes: 10));
  });

  test('accepts supported upload types at the size boundary', () {
    expect(
      UploadHelper.validateLessonFile(
        fileName: 'lesson.MP4',
        sizeBytes: UploadHelper.maxLessonVideoBytes,
        isVideo: true,
      ),
      isNull,
    );
    expect(
      UploadHelper.validateLessonFile(
        fileName: 'notes.docx',
        sizeBytes: UploadHelper.maxLessonDocumentBytes,
        isVideo: false,
      ),
      isNull,
    );
  });

  test('rejects unsupported types and files above the size boundary', () {
    expect(
      UploadHelper.validateLessonFile(
        fileName: 'lesson.avi',
        sizeBytes: 1,
        isVideo: true,
      ),
      isNotNull,
    );
    expect(
      UploadHelper.validateLessonFile(
        fileName: 'lesson.mp4',
        sizeBytes: UploadHelper.maxLessonVideoBytes + 1,
        isVideo: true,
      ),
      isNotNull,
    );
    expect(
      UploadHelper.validateLessonFile(
        fileName: 'notes.pdf',
        sizeBytes: UploadHelper.maxLessonDocumentBytes + 1,
        isVideo: false,
      ),
      isNotNull,
    );
  });

  test('refreshes lesson list after a successful mutation', () async {
    final adapter = _LessonAdapter();
    final client = ApiClient(TokenStorage.memory())
      ..dio.httpClientAdapter = adapter;
    final provider = InstructorLessonProvider(InstructorLessonService(client));

    await provider.loadLessons('section-response-id');
    final error = await provider.updateLesson('lesson-response-id', {
      'title': 'Updated title',
    });

    expect(error, isNull);
    expect(provider.lessons.single.title, 'Latest title');
    expect(
      adapter.requests
          .where((request) => request.path.endsWith('/lessons'))
          .length,
      2,
    );
    provider.dispose();
  });
}

class _CapturedRequest {
  const _CapturedRequest({
    required this.method,
    required this.path,
    required this.body,
    required this.multipartFieldNames,
    required this.sendTimeout,
    required this.contentType,
  });

  final String method;
  final String path;
  final dynamic body;
  final List<String> multipartFieldNames;
  final Duration? sendTimeout;
  final String? contentType;
}

class _LessonAdapter implements HttpClientAdapter {
  final requests = <_CapturedRequest>[];
  int _listCalls = 0;

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
      final text = utf8.decode(bytes);
      if (options.contentType?.startsWith('multipart/form-data') == true) {
        final boundary = RegExp(r'boundary="?([^";]+)')
            .firstMatch(options.contentType!)
            ?.group(1);
        if (boundary != null) {
          multipartFieldNames.addAll(
            RegExp(r'name="([^"]+)"')
                .allMatches(text)
                .map((match) => match.group(1)!),
          );
        }
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
        multipartFieldNames: multipartFieldNames,
        sendTimeout: options.sendTimeout,
        contentType: options.contentType,
      ),
    );

    if (options.method == 'GET' && options.path.endsWith('/lessons')) {
      _listCalls++;
      return _jsonResponse({
        'lessons': [
          {
            'id': 'lesson-response-id',
            'sectionId': 'section-response-id',
            'title': _listCalls > 1 ? 'Latest title' : 'Original title',
            'lessonType': 'TEXT',
            'isPublished': false,
          },
        ],
      });
    }
    if (options.method == 'GET' && options.path.endsWith('/sections')) {
      return _jsonResponse({
        'sections': [
          {'id': 'section-response-id', 'title': 'Section 1', 'order': 1},
        ],
      });
    }
    if (options.path.endsWith('/lesson-response-id') &&
        options.method == 'GET') {
      return _jsonResponse({
        'lesson': {
          'id': 'lesson-response-id',
          'sectionId': 'section-response-id',
          'title': 'Text lesson',
          'lessonType': 'TEXT',
        },
      });
    }
    return _jsonResponse({});
  }

  ResponseBody _jsonResponse(dynamic data) => ResponseBody.fromString(
    jsonEncode({'data': data}),
    200,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  @override
  void close({bool force = false}) {}
}
