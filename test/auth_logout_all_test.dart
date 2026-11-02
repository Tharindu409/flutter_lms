import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_lms/models/user_model.dart';
import 'package:flutter_lms/providers/auth_provider.dart';
import 'package:flutter_lms/providers/profile_provider.dart';
import 'package:flutter_lms/services/api_client.dart';
import 'package:flutter_lms/services/auth_service.dart';
import 'package:flutter_lms/services/profile_service.dart';
import 'package:flutter_lms/services/token_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('logout resets the profile provider', () async {
    final tokenStorage = TokenStorage.memory();
    final apiClient = ApiClient(tokenStorage)
      ..dio.httpClientAdapter = _ForbiddenAdapter();
    final profileProvider = ProfileProvider(ProfileService(apiClient))
      ..user = const UserModel(
        id: 'student-id',
        firstName: 'Student',
        lastName: 'User',
        email: 'student@example.test',
        role: 'STUDENT',
      );
    final authProvider =
        AuthProvider(
          AuthService(apiClient, tokenStorage),
          onSessionCleared: profileProvider.reset,
        )..setUser(
          const UserModel(
            id: 'student-id',
            firstName: 'Student',
            lastName: 'User',
            email: 'student@example.test',
            role: 'STUDENT',
          ),
        );

    await authProvider.logout();

    expect(profileProvider.user, isNull);
    profileProvider.dispose();
    authProvider.dispose();
    apiClient.dio.close(force: true);
  });

  test(
    'logout-all clears stored session when the server rejects the request',
    () async {
      final tokenStorage = TokenStorage.memory();
      await tokenStorage.saveSession(
        accessToken: 'access',
        refreshToken: 'refresh',
        role: 'INSTRUCTOR',
      );
      final apiClient = ApiClient(tokenStorage)
        ..dio.httpClientAdapter = _ForbiddenAdapter();
      final authService = AuthService(apiClient, tokenStorage);
      final authProvider = AuthProvider(authService)
        ..setUser(
          const UserModel(
            id: 'instructor-id',
            firstName: 'Instructor',
            lastName: 'User',
            email: 'instructor@example.test',
            role: 'INSTRUCTOR',
          ),
        );

      expect(await authProvider.logoutAll(), isNull);

      expect(await tokenStorage.readAccessToken(), isNull);
      expect(await tokenStorage.readRefreshToken(), isNull);
      expect(await tokenStorage.readRole(), isNull);
      expect(authProvider.user, isNull);
    },
  );
}

class _ForbiddenAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      '{"message":"Forbidden"}',
      403,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
