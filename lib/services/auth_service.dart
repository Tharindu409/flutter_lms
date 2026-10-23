import 'package:dio/dio.dart';
import 'package:flutter_lms/models/auth_session.dart';
import 'package:flutter_lms/services/api_client.dart';
import 'package:flutter_lms/services/token_storage.dart';
import 'package:flutter_lms/utils/api_exception.dart';
import 'package:flutter_lms/utils/api_response.dart';
import 'package:flutter_lms/models/user_model.dart';

class AuthService {
  AuthService(this._apiClient, this._tokenStorage);

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim();

    try {
      final response = await _apiClient.dio.post<dynamic>(
        '/api/v1/auth/login',
        data: {'email': normalizedEmail, 'password': password},
      );

      final data = ApiResponse.data(response);
      if (data is! Map<String, dynamic>) {
        throw const ApiException(
          message: 'Unexpected response from the server.',
        );
      }

      final session = AuthSession.fromJson(data);
      await _tokenStorage.saveSession(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
        role: session.user.role,
      );
      return session;
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  /// Revokes the current session on the backend, then always clears local data.
  Future<void> logout() async {
    try {
      await _apiClient.dio.post<dynamic>('/api/v1/auth/logout');
    } on DioException catch (_) {
      // Ignore: the local session is cleared below in any case.
    } finally {
      await _tokenStorage.clear();
    }
  }

  /// Returns the logged-in user from stored tokens, or null if there is no
  /// valid session. Expired access tokens are refreshed by the interceptor.
  Future<UserModel?> restoreSession() async {
    if (!await _tokenStorage.hasSession()) return null;

    try {
      final response = await _apiClient.dio.get<dynamic>(
        '/api/v1/users/me/full-profile',
      );

      final data = ApiResponse.data(response);
      if (data is! Map<String, dynamic>) return null;

      // The account may be nested under "user" or returned directly.
      final userJson = data['user'] is Map<String, dynamic>
          ? data['user'] as Map<String, dynamic>
          : data;

      final user = UserModel.fromJson(userJson);
      if (user.role.isNotEmpty) return user;

      final storedRole = await _tokenStorage.readRole() ?? '';
      return storedRole.isEmpty ? null : user.withRole(storedRole);
    } on DioException catch (error) {
      final apiError = ApiException.fromDioException(error);
      if (apiError.statusCode == 401 || apiError.statusCode == 403) {
        await _tokenStorage.clear();
        return null;
      }
      throw apiError; // network/server problem: keep the tokens
    }
  }
}
