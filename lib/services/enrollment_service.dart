import 'package:dio/dio.dart';
import 'package:flutter_lms/models/enrollment.dart';
import 'package:flutter_lms/models/course_progress.dart';
import 'package:flutter_lms/models/paged_result.dart';
import 'package:flutter_lms/services/api_client.dart';
import 'package:flutter_lms/utils/api_guard.dart';
import 'package:flutter_lms/utils/api_response.dart';
import 'package:flutter_lms/utils/api_exception.dart';
import 'package:flutter_lms/utils/json_utils.dart';
import 'package:flutter_lms/utils/app_config.dart';

class EnrollmentService {
  EnrollmentService(this._apiClient);

  final ApiClient _apiClient;

  Dio get _dio => _apiClient.dio;

  /// The backend rejects duplicate enrollments and unpublished courses.
  Future<void> enroll(String courseId) {
    return guardApi<void>(() async {
      await _dio.post<dynamic>('/api/v1/courses/$courseId/enroll');
    });
  }

  /// [status] can be ACTIVE, COMPLETED or CANCELLED. Null returns all.
  Future<PagedResult<Enrollment>> getMyEnrollments({
    int page = 1,
    int limit = AppConfig.defaultPageSize,
    String? status,
  }) {
    return guardApi(() async {
      final response = await _dio.get<dynamic>(
        '/api/v1/enrollments/me',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (status != null && status.isNotEmpty) 'status': status,
        },
      );
      return PagedResult.fromData(
        ApiResponse.data(response),
        Enrollment.fromJson,
        fallbackPage: page,
        fallbackLimit: limit,
      );
    });
  }

  Future<Enrollment> getEnrollment(String enrollmentId) {
    return guardApi(() async {
      final response = await _dio.get<dynamic>(
        '/api/v1/enrollments/$enrollmentId',
      );
      final json = JsonUtils.unwrap(ApiResponse.data(response), ['enrollment']);
      if (json == null) {
        throw const ApiException(
          message: 'Unexpected response from the server.',
        );
      }
      return Enrollment.fromJson(json);
    });
  }

  Future<CourseProgress> getEnrollmentProgress(String enrollmentId) {
    return guardApi(() async {
      final response = await _dio.get<dynamic>(
        '/api/v1/enrollments/$enrollmentId/progress',
      );
      final json = JsonUtils.unwrap(ApiResponse.data(response), ['progress']);
      if (json == null) {
        throw const ApiException(
          message: 'Unexpected response from the server.',
        );
      }
      return CourseProgress.fromJson(json);
    });
  }
}
