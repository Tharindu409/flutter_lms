import 'package:dio/dio.dart';
import 'package:flutter_lms/models/paged_result.dart';
import 'package:flutter_lms/models/student_notification.dart';
import 'package:flutter_lms/services/api_client.dart';
import 'package:flutter_lms/utils/api_exception.dart';
import 'package:flutter_lms/utils/api_guard.dart';
import 'package:flutter_lms/utils/api_response.dart';
import 'package:flutter_lms/utils/app_config.dart';

class NotificationService {
  NotificationService(this._apiClient);

  final ApiClient _apiClient;
  Dio get _dio => _apiClient.dio;

  Future<PagedResult<StudentNotification>> getNotifications({
    required int page,
    bool unreadOnly = false,
  }) {
    return guardApi(() async {
      final response = await _dio.get<dynamic>(
        '/api/v1/notifications/me',
        queryParameters: {
          'page': page,
          'limit': AppConfig.defaultPageSize,
          'unreadOnly': unreadOnly,
        },
      );
      return PagedResult.fromData(
        ApiResponse.data(response),
        StudentNotification.fromJson,
        fallbackPage: page,
        fallbackLimit: AppConfig.defaultPageSize,
      );
    });
  }

  Future<int> getUnreadCount() {
    return guardApi(() async {
      final response = await _dio.get<dynamic>(
        '/api/v1/notifications/me/unread-count',
      );
      final data = ApiResponse.data(response);
      final count = _readCount(data);
      if (count == null || count < 0) {
        throw const ApiException(
          message: 'Unable to load your unread notification count.',
        );
      }
      return count;
    });
  }

  Future<void> markRead(String notificationId) {
    return guardApi<void>(() async {
      await _dio.patch<dynamic>('/api/v1/notifications/$notificationId/read');
    });
  }

  Future<void> markAllRead() {
    return guardApi<void>(() async {
      await _dio.patch<dynamic>('/api/v1/notifications/me/read-all');
    });
  }

  Future<void> delete(String notificationId) {
    return guardApi<void>(() async {
      await _dio.delete<dynamic>('/api/v1/notifications/$notificationId');
    });
  }

  static int? _readCount(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    if (value is! Map) return null;
    for (final key in const ['unreadCount', 'count', 'total', 'unread']) {
      final raw = value[key];
      if (raw is num) return raw.toInt();
      if (raw is String) {
        final parsed = int.tryParse(raw);
        if (parsed != null) return parsed;
      }
    }
    return _readCount(value['data']);
  }
}
