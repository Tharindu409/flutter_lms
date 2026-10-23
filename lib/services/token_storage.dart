import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';
  static const _roleKey = 'user_role';

  final FlutterSecureStorage? _storage;
  final Map<String, String> _fallback = {};

  TokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  TokenStorage.memory() : _storage = null;

  Future<void> _writeSecureValue(String key, String value) async {
    if (_storage == null) {
      _fallback[key] = value;
      return;
    }

    try {
      await _storage.write(key: key, value: value);
    } on MissingPluginException {
      _fallback[key] = value;
    }
  }

  Future<String?> _readSecureValue(String key) async {
    if (_storage == null) return _fallback[key];

    try {
      return await _storage.read(key: key);
    } on MissingPluginException {
      return _fallback[key];
    }
  }

  Future<void> _deleteAllSecureValues() async {
    if (_storage == null) {
      _fallback.clear();
      return;
    }

    try {
      await _storage.deleteAll();
    } on MissingPluginException {
      _fallback.clear();
    }
  }

  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required String role,
  }) async {
    await Future.wait([
      _writeSecureValue(_accessKey, accessToken),
      _writeSecureValue(_refreshKey, refreshToken),
      _writeSecureValue(_roleKey, role),
    ]);
  }

  Future<String?> readAccessToken() => _readSecureValue(_accessKey);
  Future<String?> readRefreshToken() => _readSecureValue(_refreshKey);
  Future<String?> readRole() => _readSecureValue(_roleKey);

  Future<bool> hasSession() async {
    final token = await readAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> clear() => _deleteAllSecureValues();
}