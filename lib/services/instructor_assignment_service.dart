import 'package:dio/dio.dart';
import 'package:flutter_lms/models/instructor_assignment.dart';
import 'package:flutter_lms/models/paged_result.dart';
import 'package:flutter_lms/services/api_client.dart';
import 'package:flutter_lms/utils/api_exception.dart';
import 'package:flutter_lms/utils/api_guard.dart';
import 'package:flutter_lms/utils/api_response.dart';
import 'package:flutter_lms/utils/upload_helper.dart';

class InstructorAssignmentService {
  InstructorAssignmentService(this._apiClient);

  final ApiClient _apiClient;
  Dio get _dio => _apiClient.dio;

  Future<List<InstructorAssignment>> getCourseAssignments(String courseId) {
    return _run(() async {
      final response = await _dio.get<dynamic>(
        '/api/v1/courses/$courseId/assignments/instructor',
      );
      return PagedResult.fromData(
        ApiResponse.data(response),
        InstructorAssignment.fromJson,
      ).items.where((item) => item.id.isNotEmpty).toList();
    });
  }

  Future<InstructorEnrollmentPage> getCourseEnrollments(
    String courseId, {
    int page = 1,
    int limit = 20,
    String status = '',
  }) {
    return _run(() async {
      final response = await _dio.get<dynamic>(
        '/api/v1/courses/$courseId/enrollments',
        queryParameters: {'page': page, 'limit': limit, 'status': status},
      );
      final result = PagedResult.fromData(
        ApiResponse.data(response),
        InstructorEnrollment.fromJson,
        fallbackPage: page,
        fallbackLimit: limit,
      );
      return InstructorEnrollmentPage(
        items: result.items.where((item) => item.id.isNotEmpty).toList(),
        page: result.page,
        totalPages: result.totalPages,
      );
    });
  }

  Future<InstructorSubmissionPage> getSubmissions(
    String assignmentId, {
    int page = 1,
    int limit = 20,
    String status = '',
  }) {
    return _run(() async {
      final response = await _dio.get<dynamic>(
        '/api/v1/assignments/$assignmentId/submissions',
        queryParameters: {'page': page, 'limit': limit, 'status': status},
      );
      final result = PagedResult.fromData(
        ApiResponse.data(response),
        InstructorSubmission.fromJson,
        fallbackPage: page,
        fallbackLimit: limit,
      );
      return InstructorSubmissionPage(
        items: result.items.where((item) => item.id.isNotEmpty).toList(),
        page: result.page,
        totalPages: result.totalPages,
      );
    });
  }

  Future<void> createAssignment(String courseId, Map<String, dynamic> body) {
    return _run(() async {
      await _dio.post<dynamic>(
        '/api/v1/courses/$courseId/assignments',
        data: body,
      );
    });
  }

  Future<void> updateAssignment(
    String assignmentId,
    Map<String, dynamic> body,
  ) {
    return _run(() async {
      await _dio.patch<dynamic>(
        '/api/v1/assignments/$assignmentId',
        data: body,
      );
    });
  }

  Future<void> uploadAttachment(
    String assignmentId,
    String path,
    String fileName, {
    required ProgressCallback onSendProgress,
    required CancelToken cancelToken,
  }) {
    return _run(() async {
      final part = await UploadHelper.lessonPart(
        path: path,
        name: fileName,
        isVideo: false,
      );
      await _dio.post<dynamic>(
        '/api/v1/assignments/$assignmentId/attachment',
        data: FormData.fromMap({'attachment': part}),
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        options: Options(sendTimeout: const Duration(minutes: 10)),
      );
    });
  }

  Future<void> deleteAttachment(String assignmentId) {
    return _run(() async {
      await _dio.delete<dynamic>(
        '/api/v1/assignments/$assignmentId/attachment',
      );
    });
  }

  Future<void> publishAssignment(String assignmentId) {
    return _run(() async {
      await _dio.patch<dynamic>('/api/v1/assignments/$assignmentId/publish');
    });
  }

  Future<void> deleteAssignment(String assignmentId) {
    return _run(() async {
      await _dio.delete<dynamic>('/api/v1/assignments/$assignmentId');
    });
  }

  Future<void> gradeSubmission(String submissionId, Map<String, dynamic> body) {
    return _run(() async {
      await _dio.patch<dynamic>(
        '/api/v1/submissions/$submissionId/grade',
        data: body,
      );
    });
  }

  Future<T> _run<T>(Future<T> Function() action) async {
    try {
      return await guardApi<T>(action);
    } on ApiException catch (error) {
      if (error.statusCode == 403) {
        throw ApiException(
          statusCode: error.statusCode,
          message: 'You do not have access to this course',
        );
      }
      if (const [400, 409, 413, 415, 422].contains(error.statusCode)) {
        final message = error.backendMessage?.trim();
        if (message != null && message.isNotEmpty) {
          throw ApiException(statusCode: error.statusCode, message: message);
        }
      }
      rethrow;
    }
  }
}

class InstructorSubmissionPage {
  const InstructorSubmissionPage({
    required this.items,
    required this.page,
    required this.totalPages,
  });

  final List<InstructorSubmission> items;
  final int page;
  final int totalPages;
  bool get hasMore => page < totalPages;
}

class InstructorEnrollmentPage {
  const InstructorEnrollmentPage({
    required this.items,
    required this.page,
    required this.totalPages,
  });

  final List<InstructorEnrollment> items;
  final int page;
  final int totalPages;
  bool get hasMore => page < totalPages;
}
