import 'package:dio/dio.dart';
import 'package:flutter_lms/models/paged_result.dart';
import 'package:flutter_lms/models/quiz.dart';
import 'package:flutter_lms/services/api_client.dart';
import 'package:flutter_lms/utils/api_exception.dart';
import 'package:flutter_lms/utils/api_guard.dart';
import 'package:flutter_lms/utils/api_response.dart';
import 'package:flutter_lms/utils/json_utils.dart';

class InstructorQuizService {
  InstructorQuizService(this._apiClient);

  final ApiClient _apiClient;

  Dio get _dio => _apiClient.dio;

  Future<List<Quiz>> getCourseQuizzes(String courseId) {
    return _run(() async {
      final response = await _dio.get<dynamic>(
        '/api/v1/courses/$courseId/quizzes/instructor',
      );
      return PagedResult.fromData(
        ApiResponse.data(response),
        Quiz.fromJson,
      ).items.where((quiz) => quiz.id.isNotEmpty).toList();
    });
  }

  Future<Quiz> getQuiz(String quizId) {
    return _run(() async {
      final response = await _dio.get<dynamic>(
        '/api/v1/quizzes/$quizId/instructor',
      );
      final payload = JsonUtils.asMap(ApiResponse.data(response));
      if (payload == null) {
        throw const ApiException(
          message: 'Unexpected response from the server.',
        );
      }
      final quiz = JsonUtils.asMap(payload['quiz']) ?? payload;
      final questions = quiz['questions'] ?? payload['questions'];
      return Quiz.fromJson({
        ...quiz,
        if (questions is List) 'questions': questions,
      });
    });
  }

  Future<void> createQuiz(String courseId, Map<String, dynamic> body) {
    return _run(() async {
      await _dio.post<dynamic>('/api/v1/courses/$courseId/quizzes', data: body);
    });
  }

  Future<void> updateQuiz(String quizId, Map<String, dynamic> body) {
    return _run(() async {
      await _dio.patch<dynamic>('/api/v1/quizzes/$quizId', data: body);
    });
  }

  Future<void> addQuestion(String quizId, Map<String, dynamic> body) {
    return _run(() async {
      await _dio.post<dynamic>('/api/v1/quizzes/$quizId/questions', data: body);
    });
  }

  Future<void> updateQuestion(
    String questionId,
    Map<String, dynamic> changedFields,
  ) {
    return _run(() async {
      await _dio.patch<dynamic>(
        '/api/v1/quiz-questions/$questionId',
        data: changedFields,
      );
    });
  }

  Future<void> deleteQuestion(String questionId) {
    return _run(() async {
      await _dio.delete<dynamic>('/api/v1/quiz-questions/$questionId');
    });
  }

  Future<void> publishQuiz(String quizId) {
    return _run(() async {
      await _dio.patch<dynamic>('/api/v1/quizzes/$quizId/publish');
    });
  }

  Future<void> deleteQuiz(String quizId) {
    return _run(() async {
      await _dio.delete<dynamic>('/api/v1/quizzes/$quizId');
    });
  }

  Future<PagedResult<QuizAttempt>> getAttempts(
    String quizId, {
    int page = 1,
    int limit = 20,
  }) {
    return _run(() async {
      final response = await _dio.get<dynamic>(
        '/api/v1/quizzes/$quizId/attempts/instructor',
        queryParameters: {'page': page, 'limit': limit},
      );
      final result = PagedResult.fromData(
        ApiResponse.data(response),
        QuizAttempt.fromJson,
        fallbackPage: page,
        fallbackLimit: limit,
      );
      return PagedResult<QuizAttempt>(
        items: result.items.where((attempt) => attempt.id.isNotEmpty).toList(),
        page: result.page,
        limit: result.limit,
        total: result.total,
        totalPages: result.totalPages,
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
          message: 'You do not have access to this course.',
        );
      }
      final backendMessage = error.backendMessage?.trim();
      if (backendMessage != null &&
          backendMessage.isNotEmpty &&
          const [400, 409, 422].contains(error.statusCode)) {
        throw ApiException(
          statusCode: error.statusCode,
          message: backendMessage,
        );
      }
      rethrow;
    }
  }
}
