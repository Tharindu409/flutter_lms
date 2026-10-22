import 'package:dio/dio.dart';

class ApiResponse {
  const ApiResponse._();

  /// Backend success responses wrap the payload in a "data" field.
  static dynamic data(Response<dynamic> response) {
    final body = response.data;
    if (body is Map<String, dynamic> && body.containsKey('data')) {
      return body['data'];
    }
    return body;
  }

  static String? message(Response<dynamic> response) {
    final body = response.data;
    if (body is Map<String, dynamic>) return body['message']?.toString();
    return null;
  }
}