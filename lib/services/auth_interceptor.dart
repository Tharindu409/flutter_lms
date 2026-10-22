import 'package:dio/dio.dart';
import 'package:flutter_lms/services/token_storage.dart';
import 'package:flutter_lms/utils/api_response.dart';
import 'package:flutter_lms/utils/app_config.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this.dio,
    required this.tokenStorage,
    this.onSessionExpired,
  });

  final Dio dio;
  final TokenStorage tokenStorage;

  /// Called when refresh fails so the UI can send the user back to Login.
  final void Function()? onSessionExpired;

  static const _authPrefix = '/api/v1/auth/';
  static const _refreshPath = '/api/v1/auth/refresh-token';
  static const _retriedKey = 'auth_retried';

  Future<bool>? _refreshing;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.path != _refreshPath) {
      final token = await tokenStorage.readAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
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

    // No refresh for login/verify/refresh calls, and never retry twice.
    if (!isUnauthorized || isAuthCall || alreadyRetried) {
      return handler.next(err);
    }

    // If several requests fail together, only one refresh runs.
    final refreshed = await (_refreshing ??=
        _refreshTokens().whenComplete(() => _refreshing = null));

    if (!refreshed) return handler.next(err);

    try {
      options.extra[_retriedKey] = true;
      final token = await tokenStorage.readAccessToken();
      options.headers['Authorization'] = 'Bearer $token';
      if (options.data is FormData) {
        options.data = (options.data as FormData).clone();
      }
      final response = await dio.fetch<dynamic>(options);
      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  Future<bool> _refreshTokens() async {
    final refreshToken = await tokenStorage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      await _expireSession();
      return false;
    }

    try {
      // Separate Dio without interceptors, so refresh can never loop.
      final refreshDio = Dio(BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
      ));
      final response = await refreshDio.post<dynamic>(
        _refreshPath,
        data: {'refreshToken': refreshToken},
      );

      final data = ApiResponse.data(response) as Map<String, dynamic>;
      final tokens = data['tokens'] as Map<String, dynamic>;
      final role = await tokenStorage.readRole() ?? '';

      // Both tokens are replaced (refresh token rotation).
      await tokenStorage.saveSession(
        accessToken: tokens['accessToken'] as String,
        refreshToken: tokens['refreshToken'] as String,
        role: role,
      );
      return true;
    } catch (_) {
      await _expireSession();
      return false;
    }
  }

  Future<void> _expireSession() async {
    await tokenStorage.clear();
    onSessionExpired?.call();
  }
}