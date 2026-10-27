import 'package:dio/dio.dart';
import 'package:flutter_lms/models/course_progress.dart';
import 'package:flutter_lms/services/api_client.dart';
import 'package:flutter_lms/utils/api_exception.dart';
import 'package:flutter_lms/utils/api_guard.dart';
import 'package:flutter_lms/utils/api_response.dart';
import 'package:flutter_lms/utils/json_utils.dart';

class LearningService {
  LearningService(this._apiClient);

  final ApiClient _apiClient;

  Dio get _dio => _apiClient.dio;

  /// Marks the lesson IN_PROGRESS. Needs an active enrollment.
  Future<void> startLesson(String lessonId) {
    return guardApi<void>(() async {
      await _dio.patch<dynamic>('/api/v1/lessons/$lessonId/start');
    });
  }

  /// Marks the lesson COMPLETED. The backend recalculates the course progress.
  Future<void> completeLesson(String lessonId) {
    return guardApi<void>(() async {
      await _dio.patch<dynamic>('/api/v1/lessons/$lessonId/complete');
    });
  }

  /// Backend-calculated progress for every published lesson of the course.
  Future<CourseProgress> getCourseProgress(String courseId) {
    return guardApi(() async {
      final response = await _dio.get<dynamic>(
        '/api/v1/courses/$courseId/progress/me',
      );
      final json = JsonUtils.asMap(ApiResponse.data(response));
      if (json == null) {
        throw const ApiException(
          message: 'Unexpected response from the server.',
        );
      }
      return CourseProgress.fromJson(json);
    });
  }
}
