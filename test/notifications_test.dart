import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_lms/models/student_notification.dart';
import 'package:flutter_lms/services/api_client.dart';
import 'package:flutter_lms/services/notification_service.dart';
import 'package:flutter_lms/services/token_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses nullable notification fields defensively', () {
    final notification = StudentNotification.fromJson({
      'id': 'notification-from-response',
      'title': 'Course update',
      'message': 'A new lesson is available.',
      'isRead': false,
      'createdAt': '2026-10-27T09:00:00.000Z',
    });

    expect(notification.id, 'notification-from-response');
    expect(notification.isRead, isFalse);
    expect(notification.createdAt, isNotNull);
    expect(StudentNotification.fromJson({}).id, isNull);
    expect(StudentNotification.fromJson({}).isRead, isNull);
  });

  test('uses notification endpoints and query parameters', () async {
    final adapter = _NotificationAdapter();
    final apiClient = ApiClient(TokenStorage.memory())
      ..dio.httpClientAdapter = adapter;
    final service = NotificationService(apiClient);

    final page = await service.getNotifications(page: 2, unreadOnly: true);
    final count = await service.getUnreadCount();
    await service.markRead('response-id');
    await service.markAllRead();
    await service.delete('response-id');

    expect(page.items.single.id, 'response-id');
    expect(count, 3);
    expect(adapter.requests[0].path, '/api/v1/notifications/me');
    expect(adapter.requests[0].queryParameters, {
      'page': 2,
      'limit': 20,
      'unreadOnly': true,
    });
    expect(adapter.requests.map((request) => request.path), [
      '/api/v1/notifications/me',
      '/api/v1/notifications/me/unread-count',
      '/api/v1/notifications/response-id/read',
      '/api/v1/notifications/me/read-all',
      '/api/v1/notifications/response-id',
    ]);
    expect(adapter.requests.map((request) => request.method), [
      'GET',
      'GET',
      'PATCH',
      'PATCH',
      'DELETE',
    ]);
  });
}

class _NotificationAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final payload = switch (options.path) {
      '/api/v1/notifications/me' => {
        'data': {
          'notifications': [
            {
              'id': 'response-id',
              'title': 'Update',
              'message': 'New lesson',
              'isRead': false,
            },
          ],
          'pagination': {'page': 2, 'limit': 20, 'total': 21, 'totalPages': 2},
        },
      },
      '/api/v1/notifications/me/unread-count' => {
        'data': {'unreadCount': 3},
      },
      _ => {'data': <String, Object?>{}},
    };
    return ResponseBody.fromString(
      jsonEncode(payload),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
