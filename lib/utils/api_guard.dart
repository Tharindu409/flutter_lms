import 'package:dio/dio.dart';
import 'package:flutter_lms/utils/api_exception.dart';

/// Runs [action] and converts Dio errors into readable [ApiException]s.
Future<T> guardApi<T>(Future<T> Function() action) async {
  try {
    return await action();
  } on DioException catch (error) {
    throw ApiException.fromDioException(error);
  }
}