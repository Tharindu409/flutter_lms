import 'package:dio/dio.dart';
import 'package:flutter_lms/models/assignment.dart';
import 'package:flutter_lms/models/paged_result.dart';
import 'package:flutter_lms/services/api_client.dart';
import 'package:flutter_lms/utils/api_exception.dart';
import 'package:flutter_lms/utils/api_guard.dart';
import 'package:flutter_lms/utils/api_response.dart';
import 'package:flutter_lms/utils/json_utils.dart';

class AssignmentService {
  AssignmentService(this._apiClient);

  final ApiClient _apiClient;
  Dio get _dio => _apiClient.dio;

  Future<List<Assignment>> getCourseAssignments(String courseId) {
    return guardApi(() async {
      final response = await _dio.get<dynamic>(
        '/api/v1/courses/$courseId/assignments',
      );
      return PagedResult.fromData(
        ApiResponse.data(response),
        Assignment.fromJson,
      ).items.where((assignment) => assignment.id.isNotEmpty).toList();
    });
  }

  Future<Assignment> getAssignment(String assignmentId) {
    return guardApi(() async {
      final response = await _dio.get<dynamic>(
        '/api/v1/assignments/$assignmentId',
      );
      final json = JsonUtils.unwrap(ApiResponse.data(response), const [
        'assignment',
      ]);
      if (json == null) {
        throw const ApiException(
          message: 'Unexpected response from the server.',
        );
      }
      return Assignment.fromJson(json);
    });
  }
}
