import 'package:flutter_lms/core/constants/api_endpoints.dart';
import 'package:flutter_lms/features/admin/core/admin_api.dart';
import 'package:flutter_lms/features/admin/core/admin_paged_data.dart';
import 'package:flutter_lms/features/admin/models/admin_models.dart';
import 'package:flutter_lms/services/api_client.dart';
import 'package:flutter_lms/utils/api_response.dart';

class AdminEnrollmentsService {
  AdminEnrollmentsService(this._client);
  final ApiClient _client;

  Future<AdminPagedData<AdminEnrollment>> list({
    int page = 1,
    int limit = 20,
    String status = '',
    String courseId = '',
    String studentId = '',
  }) => adminApi(() async {
    final response = await _client.dio.get<dynamic>(
      ApiEndpoints.adminEnrollments,
      queryParameters: adminListQuery(
        page: page,
        limit: limit,
        filters: {
          'status': status,
          'courseId': courseId,
          'studentId': studentId,
        },
      ),
    );
    return AdminPagedData.fromResponse(
      ApiResponse.data(response),
      AdminEnrollment.fromJson,
      fallbackPage: page,
      fallbackLimit: limit,
    );
  });
}
