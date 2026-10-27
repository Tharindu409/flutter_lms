import 'package:dio/dio.dart';
import 'package:flutter_lms/models/paged_result.dart';
import 'package:flutter_lms/models/quiz.dart';
import 'package:flutter_lms/services/api_client.dart';
import 'package:flutter_lms/utils/api_guard.dart';
import 'package:flutter_lms/utils/api_response.dart';

class QuizService {
  QuizService(this._apiClient);

  final ApiClient _apiClient;
  Dio get _dio => _apiClient.dio;

  Future<List<Quiz>> getCourseQuizzes(String courseId) {
    return guardApi(() async {
      final response = await _dio.get<dynamic>(
        '/api/v1/courses/$courseId/quizzes',
      );
      return PagedResult.fromData(
        ApiResponse.data(response),
        Quiz.fromJson,
      ).items.where((quiz) => quiz.id.isNotEmpty).toList();
    });
  }
}
