import 'package:dio/dio.dart';
import 'package:flutter_lms/models/course.dart';
import 'package:flutter_lms/models/course_category.dart';
import 'package:flutter_lms/models/course_section.dart';
import 'package:flutter_lms/models/lesson.dart';
import 'package:flutter_lms/models/paged_result.dart';
import 'package:flutter_lms/services/api_client.dart';
import 'package:flutter_lms/utils/api_exception.dart';
import 'package:flutter_lms/utils/api_guard.dart';
import 'package:flutter_lms/utils/api_response.dart';
import 'package:flutter_lms/utils/app_config.dart';
import 'package:flutter_lms/utils/json_utils.dart';

class CourseService {
  CourseService(this._apiClient);

  final ApiClient _apiClient;

  Dio get _dio => _apiClient.dio;

  static const _unexpected = ApiException(
    message: 'Unexpected response from the server.',
  );

  Future<PagedResult<CourseCategory>> getCategories({
    int page = 1,
    int limit = AppConfig.defaultPageSize,
  }) {
    return guardApi(() async {
      final response = await _dio.get<dynamic>(
        '/api/v1/categories',
        queryParameters: {'page': page, 'limit': limit, 'activeOnly': true},
      );
      return PagedResult.fromData(
        ApiResponse.data(response),
        CourseCategory.fromJson,
        fallbackPage: page,
        fallbackLimit: limit,
      );
    });
  }

  /// Published courses only. Empty filters are not sent.
  Future<PagedResult<Course>> browseCourses({
    int page = 1,
    int limit = AppConfig.defaultPageSize,
    String? search,
    String? categoryId,
    String? level,
    String? language,
  }) {
    return guardApi(() async {
      final response = await _dio.get<dynamic>(
        '/api/v1/courses',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (search != null && search.trim().isNotEmpty)
            'search': search.trim(),
          if (categoryId != null && categoryId.isNotEmpty)
            'categoryId': categoryId,
          if (level != null && level.isNotEmpty) 'level': level,
          if (language != null && language.isNotEmpty) 'language': language,
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

  Future<Course> getCourse(String courseId) {
    return guardApi(() async {
      final response = await _dio.get<dynamic>('/api/v1/courses/$courseId');
      final json = JsonUtils.unwrap(ApiResponse.data(response), ['course']);
      if (json == null) throw _unexpected;
      return Course.fromJson(json);
    });
  }

  /// Students receive only published sections of courses they can access.
  Future<List<CourseSection>> getSections(String courseId) {
    return guardApi(() async {
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

  Future<List<Lesson>> getLessons(String sectionId) {
    return guardApi(() async {
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
    return guardApi(() async {
      final response = await _dio.get<dynamic>('/api/v1/lessons/$lessonId');
      final json = JsonUtils.unwrap(ApiResponse.data(response), ['lesson']);
      if (json == null) throw _unexpected;
      return Lesson.fromJson(json);
    });
  }
}
