import 'package:dio/dio.dart';

class ApiException implements Exception {
  final int? statusCode;
  final String message;
  final String? errorCode;
  final dynamic details;
  final String? backendMessage;

  const ApiException({
    this.statusCode,
    required this.message,
    this.errorCode,
    this.details,
    this.backendMessage,
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
          message: 'Cannot reach the server. Check that the backend is running and your connection is working.',
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

    final safeMessage = _defaultMessage(status);
    return ApiException(
      statusCode: status,
      message: safeMessage,
      errorCode: code,
      details: details,
      backendMessage: message,
    );
  }

  static ApiException forEnrollment(ApiException error) {
    final backendText = error.backendMessage?.toLowerCase() ?? '';
    final code = error.errorCode?.toUpperCase() ?? '';
    if (error.statusCode == 403) {
      return ApiException(
        statusCode: error.statusCode,
        message: 'Your account is not allowed to enroll in this course.',
      );
    }
    final alreadyEnrolled =
        error.statusCode == 409 ||
        code.contains('DUPLICATE') ||
        code.contains('ALREADY_ENROLLED') ||
        backendText.contains('already enrolled') ||
        (backendText.contains('duplicate') && backendText.contains('enroll')) ||
        backendText.contains('enrollment already exists');

    if (alreadyEnrolled) {
      return ApiException(
        statusCode: error.statusCode,
        message: 'You are already enrolled in this course.',
        errorCode: 'ENROLLMENT_ALREADY_EXISTS',
        details: error.details,
        backendMessage: error.backendMessage,
      );
    }
    if (error.statusCode == 400 || error.statusCode == 404) {
      return ApiException(
        statusCode: error.statusCode,
        message: 'This course is not available for enrollment.',
      );
    }
    return ApiException(
      statusCode: error.statusCode,
      message: 'Unable to enroll right now. Please check your connection and try again.',
    );
  }

  static String _defaultMessage(int? status) {
    switch (status) {
      case 400:
        return 'The request could not be completed. Please check and try again.';
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
