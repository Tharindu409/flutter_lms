import 'package:flutter_lms/models/user_model.dart';
import 'package:flutter_lms/utils/api_exception.dart';

class AuthSession {
  final UserModel user;
  final String accessToken;
  final String refreshToken;

  const AuthSession({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });

  /// [json] is the "data" object of the login response.
  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    final tokens = json['tokens'];

    if (user is! Map<String, dynamic> || tokens is! Map<String, dynamic>) {
      throw const ApiException(message: 'Unexpected response from the server.');
    }

    final accessToken = tokens['accessToken']?.toString();
    final refreshToken = tokens['refreshToken']?.toString();
    if (accessToken == null || refreshToken == null) {
      throw const ApiException(message: 'Unexpected response from the server.');
    }

    return AuthSession(
      user: UserModel.fromJson(user),
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }
}
