import 'package:flutter_lms/core/constants/api_endpoints.dart';
import 'package:flutter_lms/features/admin/core/admin_api.dart';
import 'package:flutter_lms/features/admin/core/admin_paged_data.dart';
import 'package:flutter_lms/features/admin/models/admin_models.dart';
import 'package:flutter_lms/services/api_client.dart';
import 'package:flutter_lms/utils/api_response.dart';

class AdminCategoriesService {
  AdminCategoriesService(this._client);
  final ApiClient _client;

  Future<AdminPagedData<AdminCategory>> list({
    int page = 1,
    int limit = 20,
    String search = '',
  }) => adminApi(() async {
    final response = await _client.dio.get<dynamic>(
      ApiEndpoints.categories,
      queryParameters: {
        ...adminListQuery(
          page: page,
          limit: limit,
          filters: {'search': search},
        ),
        'activeOnly': false,
      },
    );
    return AdminPagedData.fromResponse(
      ApiResponse.data(response),
      AdminCategory.fromJson,
      fallbackPage: page,
      fallbackLimit: limit,
    );
  });

  Future<AdminCategory> create(Map<String, dynamic> body) => adminApi(() async {
    final response = await _client.dio.post<dynamic>(
      ApiEndpoints.categories,
      data: body,
    );
    final payload = adminPayload(ApiResponse.data(response), const [
      'category',
    ]);
    if (payload == null) throw adminUnexpectedResponse();
    return AdminCategory.fromJson(payload);
  });

  Future<AdminCategory> update(String categoryId, Map<String, dynamic> body) =>
      adminApi(() async {
        final response = await _client.dio.patch<dynamic>(
          ApiEndpoints.category(categoryId),
          data: body,
        );
        final payload = adminPayload(ApiResponse.data(response), const [
          'category',
        ]);
        if (payload == null) throw adminUnexpectedResponse();
        return AdminCategory.fromJson(payload);
      });

  Future<AdminCategory> setActive(String categoryId, bool isActive) =>
      adminApi(() async {
        final response = await _client.dio.patch<dynamic>(
          ApiEndpoints.categoryStatus(categoryId),
          data: {'isActive': isActive},
        );
        final payload = adminPayload(ApiResponse.data(response), const [
          'category',
        ]);
        if (payload == null) throw adminUnexpectedResponse();
        return AdminCategory.fromJson(payload);
      });
}
