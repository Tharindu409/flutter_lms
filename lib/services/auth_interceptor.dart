import 'package:dio/dio.dart';
import 'package:flutter_lms/services/token_storage.dart';
import 'package:flutter_lms/utils/api_response.dart';
import 'package:flutter_lms/utils/app_config.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this.dio,
    required this.tokenStorage,
    this.onSessionExpired,
    this.refreshDioFactory,
  });

  final Dio dio;
  final TokenStorage tokenStorage;
  final void Function()? onSessionExpired;
  final Dio Function(BaseOptions options)? refreshDioFactory;

  static const _authPrefix = '/api/v1/auth/';
  static const _refreshPath = '/api/v1/auth/refresh-token';
  static const _retriedKey = 'retried';

  Future<String?>? _refreshing;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final isAuthCall = options.path.startsWith(_authPrefix);
    final needsAuth =
        !isAuthCall ||
        options.path == '/api/v1/auth/logout' ||
        options.path == '/api/v1/auth/logout-all';
    final isPublicCatalog =
        options.path == '/api/v1/categories' ||
        options.path == '/api/v1/courses';
    if (!needsAuth || isPublicCatalog) {
      options.headers.remove('Authorization');
      handler.next(options);
      return;
    }

    final token = await tokenStorage.readAccessToken();
    if (token != null && token.trim().isNotEmpty) {
      options.headers['Authorization'] = _bearerHeader(token);
    } else {
      options.headers.remove('Authorization');
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final isUnauthorized = err.response?.statusCode == 401;
    final isAuthCall = options.path.startsWith(_authPrefix);
    final alreadyRetried = options.extra[_retriedKey] == true;
    if (!isUnauthorized || isAuthCall || alreadyRetried) {
      handler.next(err);
      return;
    }

    final accessToken = await (_refreshing ??= _refreshTokens().whenComplete(
      () => _refreshing = null,
    ));
    if (accessToken == null || accessToken.isEmpty) {
      handler.next(err);
      return;
    }

    try {
      options.extra[_retriedKey] = true;
      options.headers['Authorization'] = _bearerHeader(accessToken);
      if (options.data is FormData) {
        options.data = (options.data as FormData).clone();
      }
      final response = await dio.fetch<dynamic>(options);
      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  Future<String?> _refreshTokens() async {
    try {
      final refreshToken = await tokenStorage.readRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        await _expireSession();
        return null;
      }

      final options = BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
      );
      final refreshDio = refreshDioFactory?.call(options) ?? Dio(options);
      try {
        final response = await refreshDio.post<dynamic>(
          _refreshPath,
          data: {'refreshToken': refreshToken},
        );
        final data = ApiResponse.data(response);
        final tokens = data is Map<String, dynamic> ? data['tokens'] : null;
        if (tokens is! Map<String, dynamic>) {
          throw const FormatException('Invalid token response');
        }
        final accessToken = tokens['accessToken']?.toString().trim() ?? '';
        final newRefreshToken = tokens['refreshToken']?.toString().trim() ?? '';
        if (accessToken.isEmpty || newRefreshToken.isEmpty) {
          throw const FormatException('Missing refreshed tokens');
        }
        await tokenStorage.saveSession(
          accessToken: accessToken,
          refreshToken: newRefreshToken,
          role: await tokenStorage.readRole() ?? '',
        );
        return accessToken;
      } finally {
        refreshDio.close(force: true);
      }
    } on Exception {
      await _expireSession();
      return null;
    }
  }

  Future<void> _expireSession() async {
    await tokenStorage.clear();
    onSessionExpired?.call();
  }

  String _bearerHeader(String token) => ['Bearer', token.trim()].join(' ');
}
