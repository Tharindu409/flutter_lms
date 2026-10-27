import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_lms/services/api_client.dart';
import 'package:flutter_lms/services/quiz_service.dart';
import 'package:flutter_lms/services/token_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loads course quizzes from the course quizzes endpoint', () async {
    final adapter = _QuizAdapter();
    final apiClient = ApiClient(TokenStorage.memory())
      ..dio.httpClientAdapter = adapter;
    final quizzes = await QuizService(apiClient)
        .getCourseQuizzes('course-response-id');

    expect(adapter.requestPath, '/api/v1/courses/course-response-id/quizzes');
    expect(quizzes, hasLength(1));
    expect(quizzes.single.id, 'quiz-response-id');
    expect(quizzes.single.title, 'Dart basics');
    expect(quizzes.single.passingScore, 70);
  });
}

class _QuizAdapter implements HttpClientAdapter {
  String? requestPath;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestPath = options.path;
    return ResponseBody.fromString(
      jsonEncode({
        'data': {
          'quizzes': [
            {
              'id': 'quiz-response-id',
              'title': 'Dart basics',
              'passingScore': 70,
              'timeLimitMinutes': 15,
              'maxAttempts': 3,
            },
          ],
        },
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
