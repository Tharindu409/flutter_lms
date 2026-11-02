import 'package:flutter_lms/core/constants/api_endpoints.dart';
import 'package:flutter_lms/features/admin/core/admin_api.dart';
import 'package:flutter_lms/features/admin/core/admin_paged_data.dart';
import 'package:flutter_lms/features/admin/models/admin_models.dart';
import 'package:flutter_lms/services/api_client.dart';
import 'package:flutter_lms/utils/api_response.dart';

class AdminUsersService {
  AdminUsersService(this._client);
  final ApiClient _client;

  Future<AdminPagedData<AdminUser>> list({
    int page = 1,
    int limit = 20,
    String search = '',
    String role = '',
    String status = '',
  }) => adminApi(() async {
    final response = await _client.dio.get<dynamic>(
      ApiEndpoints.users,
      queryParameters: adminListQuery(
        page: page,
        limit: limit,
        filters: {'search': search, 'role': role, 'status': status},
      ),
    );
    return AdminPagedData.fromResponse(
      ApiResponse.data(response),
      AdminUser.fromJson,
      fallbackPage: page,
      fallbackLimit: limit,
    );
  });

  Future<AdminUser> details(String userId) => adminApi(() async {
    final response = await _client.dio.get<dynamic>(ApiEndpoints.user(userId));
    final payload = adminPayload(ApiResponse.data(response), const ['user']);
    if (payload == null) throw adminUnexpectedResponse();
    return AdminUser.fromJson(payload);
  });

  Future<AdminUser> setStatus(String userId, String status) => adminApi(
    () async {
      final response = await _client.dio.patch<dynamic>(
        ApiEndpoints.userStatus(userId),
        data: {'status': status},
      );
      final payload = adminPayload(ApiResponse.data(response), const ['user']);
      if (payload == null) throw adminUnexpectedResponse();
      return AdminUser.fromJson(payload);
    },
  );
}
