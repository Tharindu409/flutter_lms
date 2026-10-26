import 'package:dio/dio.dart';
import 'package:flutter_lms/models/auth_session.dart';
import 'package:flutter_lms/models/user_model.dart';
import 'package:flutter_lms/services/api_client.dart';
import 'package:flutter_lms/services/token_storage.dart';
import 'package:flutter_lms/utils/api_exception.dart';
import 'package:flutter_lms/utils/api_guard.dart';
import 'package:flutter_lms/utils/api_response.dart';
import 'package:flutter_lms/utils/json_utils.dart';

class AuthService {
  AuthService(this._apiClient, this._tokenStorage);

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Dio get _dio => _apiClient.dio;

  static const _unexpected = ApiException(
    message: 'Unexpected response from the server.',
  );

  // ---------------------------------------------------------------- login

  Future<AuthSession> login({
    required String email,
    required String password,
  }) {
    return guardApi(() async {
      final response = await _dio.post<dynamic>(
        '/api/v1/auth/login',
        data: {'email': email.trim(), 'password': password},
      );
      return _saveSessionFrom(response);
    });
  }

  Future<AuthSession> _saveSessionFrom(Response<dynamic> response) async {
    final data = JsonUtils.asMap(ApiResponse.data(response));
    if (data == null) throw _unexpected;

    final session = AuthSession.fromJson(data);
    await _tokenStorage.saveSession(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
      role: session.user.role,
    );
    return session;
  }

  // ---------------------------------------------------------------- logout

  /// Revokes the current session on the backend, then always clears local data.
  Future<void> logout() async {
    try {
      await _dio.post<dynamic>('/api/v1/auth/logout');
    } on DioException catch (_) {
      // Ignore: the local session is cleared below in any case.
    } finally {
      await _tokenStorage.clear();
    }
  }

  /// Revokes every session of this account. Local data is cleared only when
  /// the backend confirms it, so the user is never told it worked when it didn't.
  Future<void> logoutAll() {
    return guardApi<void>(() async {
      await _dio.post<dynamic>('/api/v1/auth/logout-all');
      await _tokenStorage.clear();
    });
  }

  // ------------------------------------------------------- session restore

  /// Returns the logged-in user from stored tokens, or null if there is no
  /// valid session. Expired access tokens are refreshed by the interceptor.
  Future<UserModel?> restoreSession() async {
    if (!await _tokenStorage.hasSession()) return null;

    try {
      final response = await _dio.get<dynamic>(
        '/api/v1/users/me/full-profile',
      );

      final data = JsonUtils.asMap(ApiResponse.data(response));
      if (data == null) return null;

      final userJson = JsonUtils.unwrap(data, ['user']) ?? data;
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

  // ---------------------------------------------------------- registration

  Future<void> registerStudent({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String confirmPassword,
    required String dateOfBirth,
    required String educationLevel,
    required List<String> learningGoals,
  }) {
    return guardApi<void>(() async {
      await _dio.post<dynamic>(
        '/api/v1/auth/register/student',
        data: {
          'firstName': firstName.trim(),
          'lastName': lastName.trim(),
          'email': email.trim(),
          'password': password,
          'confirmPassword': confirmPassword,
          'dateOfBirth': dateOfBirth,
          'educationLevel': educationLevel.trim(),
          'learningGoals': learningGoals,
        },
      );
    });
  }

  Future<void> registerInstructor({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String confirmPassword,
    required String headline,
    required String qualification,
    required int experienceYears,
    required List<String> expertise,
    required String biography,
  }) {
    return guardApi<void>(() async {
      await _dio.post<dynamic>(
        '/api/v1/auth/register/instructor',
        data: {
          'firstName': firstName.trim(),
          'lastName': lastName.trim(),
          'email': email.trim(),
          'password': password,
          'confirmPassword': confirmPassword,
          'headline': headline.trim(),
          'qualification': qualification.trim(),
          'experienceYears': experienceYears,
          'expertise': expertise,
          'biography': biography.trim(),
        },
      );
    });
  }

  // ------------------------------------------------------------ email OTP

  Future<void> resendVerificationOtp(String email) {
    return guardApi<void>(() async {
      await _dio.post<dynamic>(
        '/api/v1/auth/resend-verification-otp',
        data: {'email': email.trim()},
      );
    });
  }

  /// Verifies the email. The backend returns a new token pair, which logs the
  /// user in. Returns null if the response carries no session.
  Future<AuthSession?> verifyEmail({
    required String email,
    required String otp,
  }) {
    return guardApi(() async {
      final response = await _dio.post<dynamic>(
        '/api/v1/auth/verify-email',
        data: {'email': email.trim(), 'otp': otp.trim()},
      );

      final data = JsonUtils.asMap(ApiResponse.data(response));
      if (data == null || data['tokens'] == null) return null;
      return _saveSessionFrom(response);
    });
  }

  // ------------------------------------------------------ password recovery

  Future<void> forgotPassword(String email) {
    return guardApi<void>(() async {
      await _dio.post<dynamic>(
        '/api/v1/auth/forgot-password',
        data: {'email': email.trim()},
      );
    });
  }

  /// Returns the short-lived reset token needed by [resetPassword].
  Future<String> verifyPasswordResetOtp({
    required String email,
    required String otp,
  }) {
    return guardApi(() async {
      final response = await _dio.post<dynamic>(
        '/api/v1/auth/verify-password-reset-otp',
        data: {'email': email.trim(), 'otp': otp.trim()},
      );

      final data = JsonUtils.asMap(ApiResponse.data(response));
      final token = data?['resetToken']?.toString();
      if (token == null || token.isEmpty) throw _unexpected;
      return token;
    });
  }

  Future<void> resetPassword({
    required String resetToken,
    required String newPassword,
    required String confirmPassword,
  }) {
    return guardApi<void>(() async {
      await _dio.post<dynamic>(
        '/api/v1/auth/reset-password',
        data: {
          'resetToken': resetToken,
          'newPassword': newPassword,
          'confirmPassword': confirmPassword,
        },
      );
    });
  }
}