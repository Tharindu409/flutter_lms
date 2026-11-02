import 'package:flutter_lms/core/constants/api_endpoints.dart';
import 'package:flutter_lms/features/admin/core/admin_api.dart';
import 'package:flutter_lms/features/admin/models/admin_models.dart';
import 'package:flutter_lms/services/api_client.dart';
import 'package:flutter_lms/utils/api_response.dart';

class AdminDashboardService {
  AdminDashboardService(this._client);
  final ApiClient _client;

  Future<AdminDashboardSummary> load() => adminApi(() async {
    final response = await _client.dio.get<dynamic>(
      ApiEndpoints.adminDashboard,
    );
    final payload = adminPayload(ApiResponse.data(response), const [
      'dashboard',
      'summary',
    ]);
    return AdminDashboardSummary.fromJson(payload ?? const {});
  });
}
