import 'package:flutter_lms/core/constants/api_endpoints.dart';
import 'package:flutter_lms/features/admin/core/admin_api.dart';
import 'package:flutter_lms/features/admin/core/admin_paged_data.dart';
import 'package:flutter_lms/features/admin/models/admin_models.dart';
import 'package:flutter_lms/services/api_client.dart';
import 'package:flutter_lms/utils/api_response.dart';

class AdminCoursesService {
  AdminCoursesService(this._client);
  final ApiClient _client;

  Future<AdminPagedData<AdminCourse>> list({
    int page = 1,
    int limit = 20,
    String search = '',
    String status = '',
    String instructorId = '',
    String categoryId = '',
  }) => adminApi(() async {
    final response = await _client.dio.get<dynamic>(
      ApiEndpoints.adminCourses,
      queryParameters: adminListQuery(
        page: page,
        limit: limit,
        filters: {
          'search': search,
          'status': status,
          'instructorId': instructorId,
          'categoryId': categoryId,
        },
      ),
    );
    return AdminPagedData.fromResponse(
      ApiResponse.data(response),
      AdminCourse.fromJson,
      fallbackPage: page,
      fallbackLimit: limit,
    );
  });

  Future<AdminCourse> publishedDetails(String courseId) => adminApi(() async {
    final response = await _client.dio.get<dynamic>(
      ApiEndpoints.course(courseId),
    );
    final payload = adminPayload(ApiResponse.data(response), const ['course']);
    if (payload == null) throw adminUnexpectedResponse();
    return AdminCourse.fromJson(payload);
  });

  Future<AdminCourse> archive(String courseId) => adminApi(() async {
    final response = await _client.dio.patch<dynamic>(
      ApiEndpoints.archiveCourse(courseId),
    );
    final payload = adminPayload(ApiResponse.data(response), const ['course']);
    if (payload == null) throw adminUnexpectedResponse();
    return AdminCourse.fromJson(payload);
  });
}
