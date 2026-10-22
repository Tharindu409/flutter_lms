class AppConfig {
  // Android emulator reaches the Windows host through 10.0.2.2.
  // Do NOT add /api/v1 here; every endpoint path already contains it.
  static const String baseUrl = 'http://10.0.2.2:5000';
  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 30);
}