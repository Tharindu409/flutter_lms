import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class DebugApiInterceptor extends Interceptor {
  DebugApiInterceptor({void Function(String)? log}) : _log = log ?? _debugLog;

  final void Function(String) _log;

  static final _emailPattern = RegExp(
    r'\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b',
    caseSensitive: false,
  );

  static void _debugLog(String message) => debugPrint(message);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_isTarget(options.uri.path)) {
      _log('${options.method} ${_safeUri(options.uri)}');
    }
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final request = response.requestOptions;
    if (_isTarget(request.uri.path)) {
      _log(
        '${request.method} ${_safeUri(request.uri)} '
        '-> ${response.statusCode}\n${_safeBody(response.data)}',
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final request = err.requestOptions;
    if (_isTarget(request.uri.path)) {
      _log(
        '${request.method} ${_safeUri(request.uri)} '
        '-> ${err.response?.statusCode}\n'
        '${_safeBody(err.response?.data)}',
      );
    }
    handler.next(err);
  }

  bool _isTarget(String path) {
    final segments = Uri.parse(path).pathSegments;
    return segments.any(
      (segment) =>
          segment == 'quizzes' ||
          segment == 'assignments' ||
          segment == 'enrollments',
    );
  }

  String _safeUri(Uri uri) {
    if (uri.queryParameters.isEmpty) return _redactEmails(uri.toString());
    final query = uri.queryParameters.map(
      (key, value) => MapEntry(
        key,
        _isSensitiveKey(key) ? '[REDACTED]' : _redactEmails(value),
      ),
    );
    return _redactEmails(uri.replace(queryParameters: query).toString());
  }

  String _safeBody(dynamic body) {
    dynamic value = body;
    if (body is String) {
      try {
        value = jsonDecode(body);
      } on FormatException {
        return _redactEmails(body);
      }
    }
    return jsonEncode(_redactValue(value));
  }

  dynamic _redactValue(dynamic value) {
    if (value is Map) {
      return value.map(
        (key, value) => MapEntry(
          key.toString(),
          _isSensitiveKey(key.toString()) ? '[REDACTED]' : _redactValue(value),
        ),
      );
    }
    if (value is List) {
      return value.map(_redactValue).toList();
    }
    if (value is String) return _redactEmails(value);
    return value;
  }

  bool _isSensitiveKey(String key) {
    final normalized = key.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    return normalized.contains('token') ||
        normalized.contains('password') ||
        normalized.contains('email');
  }

  String _redactEmails(String value) =>
      value.replaceAll(_emailPattern, '[REDACTED_EMAIL]');
}
