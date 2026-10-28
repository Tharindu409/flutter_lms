import 'package:dio/dio.dart';
import 'package:flutter_lms/models/course_section.dart';
import 'package:flutter_lms/models/lesson.dart';
import 'package:flutter_lms/models/paged_result.dart';
import 'package:flutter_lms/services/api_client.dart';
import 'package:flutter_lms/utils/api_exception.dart';
import 'package:flutter_lms/utils/api_guard.dart';
import 'package:flutter_lms/utils/api_response.dart';
import 'package:flutter_lms/utils/json_utils.dart';
import 'package:flutter_lms/utils/upload_helper.dart';

class InstructorLessonService {
  InstructorLessonService(this._apiClient);

  final ApiClient _apiClient;

  Dio get _dio => _apiClient.dio;

  Future<List<CourseSection>> getCourseSections(String courseId) {
    return _run(() async {
      final response = await _dio.get<dynamic>(
        '/api/v1/courses/$courseId/sections',
      );
      final sections = PagedResult.fromData(
        ApiResponse.data(response),
        CourseSection.fromJson,
      ).items;
      sections.sort((a, b) => a.order.compareTo(b.order));
      return sections;
    });
  }

  Future<List<Lesson>> getSectionLessons(String sectionId) {
    return _run(() async {
      final response = await _dio.get<dynamic>(
        '/api/v1/sections/$sectionId/lessons',
      );
      final lessons = PagedResult.fromData(
        ApiResponse.data(response),
        Lesson.fromJson,
      ).items;
      lessons.sort((a, b) => a.order.compareTo(b.order));
      return lessons;
    });
  }

  Future<Lesson> getLesson(String lessonId) {
    return _run(() async {
      final response = await _dio.get<dynamic>('/api/v1/lessons/$lessonId');
      final json = JsonUtils.unwrap(ApiResponse.data(response), ['lesson']);
      if (json == null) {
        throw const ApiException(
          message: 'Unexpected response from the server.',
        );
      }
      return Lesson.fromJson(json);
    });
  }

  Future<void> createLesson(String sectionId, Map<String, dynamic> body) {
    return _run(() async {
      await _dio.post<dynamic>(
        '/api/v1/sections/$sectionId/lessons',
        data: body,
      );
    });
  }

  Future<void> updateLesson(String lessonId, Map<String, dynamic> body) {
    return _run(() async {
      await _dio.patch<dynamic>('/api/v1/lessons/$lessonId', data: body);
    });
  }

  Future<void> reorderLesson(String lessonId, int order) {
    return _run(() async {
      await _dio.patch<dynamic>(
        '/api/v1/lessons/$lessonId/reorder',
        data: {'order': order},
      );
    });
  }

  Future<void> uploadVideo(
    String lessonId,
    String path,
    String fileName, {
    required ProgressCallback onSendProgress,
    required CancelToken cancelToken,
  }) {
    return _upload(
      lessonId: lessonId,
      path: path,
      fileName: fileName,
      fieldName: 'video',
      isVideo: true,
      onSendProgress: onSendProgress,
      cancelToken: cancelToken,
    );
  }

  Future<void> uploadDocument(
    String lessonId,
    String path,
    String fileName, {
    required ProgressCallback onSendProgress,
    required CancelToken cancelToken,
  }) {
    return _upload(
      lessonId: lessonId,
      path: path,
      fileName: fileName,
      fieldName: 'document',
      isVideo: false,
      onSendProgress: onSendProgress,
      cancelToken: cancelToken,
    );
  }

  Future<void> _upload({
    required String lessonId,
    required String path,
    required String fileName,
    required String fieldName,
    required bool isVideo,
    required ProgressCallback onSendProgress,
    required CancelToken cancelToken,
  }) {
    return _run(() async {
      final part = await UploadHelper.lessonPart(
        path: path,
        name: fileName,
        isVideo: isVideo,
      );
      final form = FormData.fromMap({fieldName: part});
      await _dio.post<dynamic>(
        '/api/v1/lessons/$lessonId/$fieldName',
        data: form,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        options: Options(sendTimeout: const Duration(minutes: 10)),
      );
    });
  }

  Future<void> deleteVideo(String lessonId) {
    return _run(() async {
      await _dio.delete<dynamic>('/api/v1/lessons/$lessonId/video');
    });
  }

  Future<void> deleteDocument(String lessonId) {
    return _run(() async {
      await _dio.delete<dynamic>('/api/v1/lessons/$lessonId/document');
    });
  }

  Future<void> deleteLesson(String lessonId) {
    return _run(() async {
      await _dio.delete<dynamic>('/api/v1/lessons/$lessonId');
    });
  }

  Future<T> _run<T>(Future<T> Function() action) async {
    try {
      return await guardApi<T>(action);
    } on ApiException catch (error) {
      throw _friendlyError(error);
    }
  }

  ApiException _friendlyError(ApiException error) {
    if (error.statusCode == 403) {
      return ApiException(
        statusCode: error.statusCode,
        message: 'You do not have access to this course.',
      );
    }

    if (const [400, 413, 415, 422].contains(error.statusCode)) {
      final backendMessage = error.backendMessage?.trim();
      if (backendMessage != null && backendMessage.isNotEmpty) {
        return ApiException(
          statusCode: error.statusCode,
          message: backendMessage,
        );
      }
    }

    return error;
  }
}
