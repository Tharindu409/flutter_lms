import 'package:flutter/foundation.dart';
import 'package:flutter_lms/models/user_model.dart';
import 'package:flutter_lms/services/auth_service.dart';
import 'package:flutter_lms/utils/api_exception.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._authService);

  final AuthService _authService;

  bool isLoading = false;
  String? errorMessage;
  UserModel? user;

  String? get role => user?.role;
  bool get isLoggedIn => user != null;

  Future<bool> login({required String email, required String password}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final session = await _authService.login(
        email: email,
        password: password,
      );
      user = session.user;
      return true;
    } on ApiException catch (error) {
      errorMessage = error.message;
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> restoreSession() async {
    try {
      user = await _authService.restoreSession();
    } on ApiException {
      user = null;
    }
    notifyListeners();
    return user != null;
  }

  /// Used after email verification, which returns a ready session.
  void setUser(UserModel value) {
    user = value;
    notifyListeners();
  }

  void clearError() {
    if (errorMessage == null) return;
    errorMessage = null;
    notifyListeners();
  }

  Future<void> logout() async {
    await _authService.logout();
    _clear();
  }

  /// Returns null on success, or an error message to show.
  Future<String?> logoutAll() async {
    try {
      await _authService.logoutAll();
      _clear();
      return null;
    } on ApiException catch (error) {
      return error.message;
    }
  }

  /// Called when token refresh fails while the app is in use.
  void handleSessionExpired() => _clear();

  void _clear() {
    user = null;
    errorMessage = null;
    notifyListeners();
  }
}
