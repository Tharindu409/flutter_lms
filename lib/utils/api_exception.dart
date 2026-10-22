import 'package:dio/dio.dart';

class ApiException implements Exception {
  final int? statusCode;
  final String message;
  final String? errorCode;
  final dynamic details;

  const ApiException({
    this.statusCode,
    required this.message,
    this.errorCode,
    this.details,
  });

  factory ApiException.fromDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(
          message: 'The request timed out. Please try again.',
        );
      case DioExceptionType.connectionError:
        return const ApiException(
          message:
              'Cannot reach the server. Check that the backend is running and your connection is working.',
        );
      case DioExceptionType.cancel:
        return const ApiException(message: 'The request was cancelled.');
      case DioExceptionType.badResponse:
        return _fromResponse(error.response);
      default:
        return const ApiException(
          message: 'Something went wrong. Please try again.',
        );
    }
  }

  static ApiException _fromResponse(Response<dynamic>? response) {
    final status = response?.statusCode;
    final body = response?.data;

    String? message;
    String? code;
    dynamic details;
    if (body is Map) {
      message = body['message']?.toString();
      code = body['errorCode']?.toString();
      details = body['details'] ?? body['errors'];
    }

    // Never show raw server errors for 5xx responses.
    final isServerError = status != null && status >= 500;
    return ApiException(
      statusCode: status,
      message: (isServerError || message == null || message.isEmpty)
          ? _defaultMessage(status)
          : message,
      errorCode: code,
      details: details,
    );
  }

  static String _defaultMessage(int? status) {
    switch (status) {
      case 400:
        return 'Invalid request. Please check your input.';
      case 401:
        return 'Your session has expired. Please log in again.';
      case 403:
        return 'You do not have permission to do this.';
      case 404:
        return 'The requested item was not found.';
      case 409:
        return 'This action conflicts with existing data.';
      case 413:
        return 'The selected file is too large.';
      case 415:
        return 'This file type is not supported.';
      case 422:
        return 'Some of the submitted data is not valid.';
      default:
        if (status != null && status >= 500) {
          return 'Server error. Please try again later.';
        }
        return 'Something went wrong. Please try again.';
    }
  }

  @override
  String toString() => message;
}