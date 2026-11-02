import 'package:flutter/foundation.dart';
import 'package:flutter_lms/models/user_model.dart';
import 'package:flutter_lms/services/auth_service.dart';
import 'package:flutter_lms/utils/api_exception.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._authService, {this._onSessionCleared});

  final AuthService _authService;
  final void Function()? _onSessionCleared;
  final Set<void Function()> _sessionResetCallbacks = {};

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
    try {
      await _authService.logout();
    } finally {
      _clear();
    }
  }

  /// Returns null on success, or an error message to show.
  Future<String?> logoutAll() async {
    try {
      await _authService.logoutAll();
    } finally {
      _clear();
    }
    return null;
  }

  /// Called when token refresh fails while the app is in use.
  void handleSessionExpired() => _clear();

  void addSessionResetCallback(void Function() callback) {
    _sessionResetCallbacks.add(callback);
  }

  void removeSessionResetCallback(void Function() callback) {
    _sessionResetCallbacks.remove(callback);
  }

  void _clear() {
    user = null;
    errorMessage = null;
    _onSessionCleared?.call();
    for (final callback in List<void Function()>.of(_sessionResetCallbacks)) {
      callback();
    }
    notifyListeners();
  }
}
