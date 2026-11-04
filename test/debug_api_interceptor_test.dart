import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_lms/services/api_client.dart';
import 'package:flutter_lms/services/debug_api_interceptor.dart';
import 'package:flutter_lms/services/token_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ApiClient installs scoped logging only in debug mode', () {
    final client = ApiClient(TokenStorage.memory());

    expect(
      client.dio.interceptors.whereType<DebugApiInterceptor>(),
      kDebugMode ? hasLength(1) : isEmpty,
    );
  });

  test(
    'logs matching requests and redacts sensitive response values',
    () async {
      final logs = <String>[];
      final dio = Dio(BaseOptions(baseUrl: 'https://lms.example'));
      dio.interceptors.add(DebugApiInterceptor(log: logs.add));
      dio.httpClientAdapter = _LoggingAdapter();

      await dio.get<dynamic>(
        '/api/v1/courses/course-42/quizzes',
        queryParameters: {'access_token': 'query-secret'},
      );

      final output = logs.join('\n');
      expect(
        output,
        contains('GET https://lms.example/api/v1/courses/course-42/quizzes'),
      );
      expect(output, contains('-> 200'));
      expect(output, contains('[REDACTED]'));
      expect(output, contains('[REDACTED_EMAIL]'));
      expect(output, isNot(contains('query-secret')));
      expect(output, isNot(contains('body-secret')));
      expect(output, isNot(contains('mail@example.com')));
    },
  );

  test('does not log unrelated API requests', () async {
    final logs = <String>[];
    final dio = Dio(BaseOptions(baseUrl: 'https://lms.example'));
    dio.interceptors.add(DebugApiInterceptor(log: logs.add));
    dio.httpClientAdapter = _LoggingAdapter();

    await dio.get<dynamic>('/api/v1/courses');

    expect(logs, isEmpty);
  });
}

class _LoggingAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode({
        'data': {
          'items': [
            {
              'accessToken': 'body-secret',
              'email': 'mail@example.com',
              'title': 'Safe field',
              'note': 'Contact mail@example.com',
              'metadata': {'password': 'another-secret'},
            },
          ],
        },
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
