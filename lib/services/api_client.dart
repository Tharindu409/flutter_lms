import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_lms/services/auth_interceptor.dart';
import 'package:flutter_lms/services/token_storage.dart';
import 'package:flutter_lms/utils/app_config.dart';

class ApiClient {
  ApiClient(this.tokenStorage, {void Function()? onSessionExpired}) {
    dio = Dio(BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      headers: {'Accept': 'application/json'},
    ));

    dio.interceptors.add(AuthInterceptor(
      dio: dio,
      tokenStorage: tokenStorage,
      onSessionExpired: onSessionExpired,
    ));

    if (kDebugMode) {
      // Headers and bodies are off so tokens and passwords are never logged.
      dio.interceptors.add(LogInterceptor(
        requestHeader: false,
        requestBody: false,
        responseHeader: false,
        responseBody: false,
      ));
    }
  }

  final TokenStorage tokenStorage;
  late final Dio dio;
}