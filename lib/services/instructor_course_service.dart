import 'package:dio/dio.dart';
import 'package:flutter_lms/models/course.dart';
import 'package:flutter_lms/models/instructor_summary.dart';
import 'package:flutter_lms/models/paged_result.dart';
import 'package:flutter_lms/services/api_client.dart';
import 'package:flutter_lms/utils/api_exception.dart';
import 'package:flutter_lms/utils/api_guard.dart';
import 'package:flutter_lms/utils/api_response.dart';
import 'package:flutter_lms/utils/json_utils.dart';
import 'package:flutter_lms/utils/upload_helper.dart';
import 'package:image_picker/image_picker.dart';

/// Course management for the logged-in INSTRUCTOR. The backend checks
/// ownership on every call, so a 403 means the course belongs to someone else.
class InstructorCourseService {
  InstructorCourseService(this._apiClient);

  final ApiClient _apiClient;

  Dio get _dio => _apiClient.dio;

  static const _unexpected = ApiException(
    message: 'Unexpected response from the server.',
  );

  Future<InstructorSummary> getDashboard() {
    return guardApi(() async {
      final response = await _dio.get<dynamic>('/api/v1/dashboard/instructor');
      final json = JsonUtils.asMap(ApiResponse.data(response));
      if (json == null) throw _unexpected;
      return InstructorSummary.fromJson(json);
    });
  }

  /// [status] can be DRAFT, PUBLISHED or ARCHIVED. Null returns all.
  Future<PagedResult<Course>> getMyCourses({
    int page = 1,
    int limit = 10,
    String? status,
    String? search,
  }) {
    return guardApi(() async {
      final response = await _dio.get<dynamic>(
        '/api/v1/courses/instructor/me',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (status != null && status.isNotEmpty) 'status': status,
          if (search != null && search.trim().isNotEmpty)
            'search': search.trim(),
        },
      );
      return PagedResult.fromData(
        ApiResponse.data(response),
        Course.fromJson,
        fallbackPage: page,
        fallbackLimit: limit,
      );
    });
  }

  Future<Course> getMyCourse(String courseId) {
    return guardApi(() async {
      final response = await _dio.get<dynamic>(
        '/api/v1/courses/instructor/me/$courseId',
      );
      final json = JsonUtils.unwrap(ApiResponse.data(response), ['course']);
      if (json == null) throw _unexpected;
      return Course.fromJson(json);
    });
  }

  /// Body: categoryId, title, shortDescription, description, level, language,
  /// requirements[], learningOutcomes[], targetAudience[].
  /// The new course starts as DRAFT.
  Future<Course> createCourse(Map<String, dynamic> body) {
    return guardApi(() async {
      final response = await _dio.post<dynamic>('/api/v1/courses', data: body);
      final json = JsonUtils.unwrap(ApiResponse.data(response), ['course']);
      if (json == null) throw _unexpected;
      return Course.fromJson(json);
    });
  }

  /// Partial update. Archived courses cannot be edited.
  Future<void> updateCourse(String courseId, Map<String, dynamic> body) {
    return guardApi<void>(() async {
      await _dio.patch<dynamic>('/api/v1/courses/$courseId', data: body);
    });
  }

  /// Multipart field name must be exactly "thumbnail".
  Future<void> uploadThumbnail(
    String courseId,
    XFile file, {
    ProgressCallback? onSendProgress,
  }) {
    return guardApi<void>(() async {
      final form = FormData.fromMap({
        'thumbnail': await UploadHelper.imagePart(file),
      });
      await _dio.post<dynamic>(
        '/api/v1/courses/$courseId/thumbnail',
        data: form,
        onSendProgress: onSendProgress,
      );
    });
  }

  Future<void> removeThumbnail(String courseId) {
    return guardApi<void>(() async {
      await _dio.delete<dynamic>('/api/v1/courses/$courseId/thumbnail');
    });
  }

  /// A DRAFT course needs at least one published section with a published
  /// lesson. If not, the backend message explains what is missing.
  Future<void> publishCourse(String courseId) {
    return guardApi<void>(() async {
      await _dio.patch<dynamic>('/api/v1/courses/$courseId/publish');
    });
  }

  /// Keeps content and enrollments but stops new enrollments.
  Future<void> archiveCourse(String courseId) {
    return guardApi<void>(() async {
      await _dio.patch<dynamic>('/api/v1/courses/$courseId/archive');
    });
  }
}
