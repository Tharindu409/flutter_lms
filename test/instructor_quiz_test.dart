import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_lms/providers/instructor_quiz_provider.dart';
import 'package:flutter_lms/services/api_client.dart';
import 'package:flutter_lms/services/instructor_quiz_service.dart';
import 'package:flutter_lms/services/instructor_lesson_service.dart';
import 'package:flutter_lms/services/token_storage.dart';
import 'package:flutter_lms/utils/api_exception.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses the instructor quiz and question endpoint contracts', () async {
    final adapter = _QuizAdapter();
    final client = ApiClient(TokenStorage.memory())
      ..dio.httpClientAdapter = adapter;
    final service = InstructorQuizService(client);

    await service.getCourseQuizzes('course-response-id');
    await service.getQuiz('quiz-response-id');
    await service.createQuiz('course-response-id', {
      'sectionId': 'section-response-id',
      'title': 'Quiz',
      'description': '',
      'passingScore': 70,
      'timeLimitMinutes': 15,
      'maxAttempts': 3,
    });
    await service.updateQuiz('quiz-response-id', {'title': 'Changed'});
    await service.addQuestion('quiz-response-id', {
      'questionText': 'Question?',
      'questionType': 'SINGLE_CHOICE',
      'options': [
        {'id': 'A', 'text': 'A'},
        {'id': 'B', 'text': 'B'},
      ],
      'correctOptionIds': ['A'],
      'marks': 1,
    });
    await service.updateQuestion('question-response-id', {'marks': 2});
    await service.deleteQuestion('question-response-id');
    await service.publishQuiz('quiz-response-id');
    await service.deleteQuiz('quiz-response-id');
    final attempts = await service.getAttempts(
      'quiz-response-id',
      page: 2,
      limit: 20,
    );

    expect(
      adapter.requests.map((request) => '${request.method} ${request.path}'),
      [
        'GET /api/v1/courses/course-response-id/quizzes/instructor',
        'GET /api/v1/quizzes/quiz-response-id/instructor',
        'POST /api/v1/courses/course-response-id/quizzes',
        'PATCH /api/v1/quizzes/quiz-response-id',
        'POST /api/v1/quizzes/quiz-response-id/questions',
        'PATCH /api/v1/quiz-questions/question-response-id',
        'DELETE /api/v1/quiz-questions/question-response-id',
        'PATCH /api/v1/quizzes/quiz-response-id/publish',
        'DELETE /api/v1/quizzes/quiz-response-id',
        'GET /api/v1/quizzes/quiz-response-id/attempts/instructor',
      ],
    );
    expect(adapter.requests[3].body, {'title': 'Changed'});
    expect(adapter.requests[5].body, {'marks': 2});
    expect(adapter.requests[7].body, isNull);
    expect(adapter.requests[9].query, {'page': 2, 'limit': 20});
    expect(attempts.items.single.studentName, 'Sam Learner');
    expect(attempts.items.single.attemptNumber, '2');
    expect(attempts.items.single.score, '8');
    expect(attempts.items.single.percentage, '80');
    expect(attempts.items.single.result, 'PASS');
    expect(attempts.items.single.submittedAt, '2026-10-28T07:00:00Z');
  });

  test('refreshes quizzes after a successful create mutation', () async {
    final adapter = _QuizAdapter();
    final client = ApiClient(TokenStorage.memory())
      ..dio.httpClientAdapter = adapter;
    final provider = InstructorQuizProvider(
      InstructorQuizService(client),
      InstructorLessonService(client),
    );

    await provider.loadQuizzes('course-response-id');
    final error = await provider.createQuiz('course-response-id', {
      'title': 'New quiz',
      'passingScore': 70,
      'timeLimitMinutes': 10,
      'maxAttempts': 2,
    });

    expect(error, isNull);
    expect(provider.quizzes.single.id, 'quiz-response-id');
    expect(
      adapter.requests
          .where((request) => request.path.endsWith('/quizzes/instructor'))
          .length,
      2,
    );
    provider.dispose();
  });

  test(
    'parses questions returned beside the quiz in the detail payload',
    () async {
      final adapter = _QuizAdapter(
        quizDetail: {
          'quiz': {
            'id': 'quiz-response-id',
            'title': 'Published quiz',
            'isPublished': true,
          },
          'questions': [
            {
              'id': 'question-response-id',
              'questionText': 'Which answer is correct?',
              'questionType': 'SINGLE_CHOICE',
              'options': [
                {'id': 'A', 'text': 'Correct'},
                {'id': 'B', 'text': 'Incorrect'},
              ],
              'correctOptionIds': ['A'],
              'marks': 2,
            },
          ],
        },
      );
      final client = ApiClient(TokenStorage.memory())
        ..dio.httpClientAdapter = adapter;

      final quiz = await InstructorQuizService(client)
          .getQuiz('quiz-response-id');

      expect(quiz.isPublished, isTrue);
      expect(quiz.questions, hasLength(1));
      expect(quiz.questions.single.id, 'question-response-id');
      expect(quiz.questions.single.correctOptionIds, ['A']);
    },
  );

  test(
    'maps ownership errors and retains backend publish validation',
    () async {
      final forbiddenClient = ApiClient(TokenStorage.memory())
        ..dio.httpClientAdapter = _QuizAdapter(
          failureStatus: 403,
          failureMessage: 'ownership denied',
        );
      await expectLater(
        InstructorQuizService(forbiddenClient)
            .getCourseQuizzes('course-response-id'),
        throwsA(
          isA<ApiException>().having(
            (error) => error.message,
            'message',
            'You do not have access to this course.',
          ),
        ),
      );

      final invalidClient = ApiClient(TokenStorage.memory())
        ..dio.httpClientAdapter = _QuizAdapter(
          failureStatus: 400,
          failureMessage: 'Publish a section before publishing this quiz.',
        );
      await expectLater(
        InstructorQuizService(invalidClient).publishQuiz('quiz-response-id'),
        throwsA(
          isA<ApiException>().having(
            (error) => error.message,
            'message',
            'Publish a section before publishing this quiz.',
          ),
        ),
      );
    },
  );
}

class _CapturedRequest {
  const _CapturedRequest(this.method, this.path, this.body, this.query);

  final String method;
  final String path;
  final dynamic body;
  final Map<String, dynamic> query;
}

class _QuizAdapter implements HttpClientAdapter {
  _QuizAdapter({this.failureStatus, this.failureMessage, this.quizDetail});

  final int? failureStatus;
  final String? failureMessage;
  final Map<String, dynamic>? quizDetail;
  final requests = <_CapturedRequest>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final body = options.data is Map<String, dynamic> ? options.data : null;
    requests.add(
      _CapturedRequest(
        options.method,
        options.path,
        body,
        Map<String, dynamic>.from(options.queryParameters),
      ),
    );
    if (failureStatus != null) {
      return ResponseBody.fromString(
        jsonEncode({'message': failureMessage}),
        failureStatus!,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    dynamic data = {};
    if (options.path.endsWith('/quizzes/instructor')) {
      data = {
        'quizzes': [
          {
            'id': 'quiz-response-id',
            'title': 'Quiz',
            'isPublished': false,
            'questionCount': 2,
          },
        ],
      };
    } else if (options.path.endsWith('/attempts/instructor')) {
      data = {
        'attempts': [
          {
            'id': 'attempt-response-id',
            'attemptNumber': 2,
            'score': 8,
            'percentage': 80,
            'passed': true,
            'result': 'PASS',
            'submittedAt': '2026-10-28T07:00:00Z',
            'student': {'firstName': 'Sam', 'lastName': 'Learner'},
          },
        ],
        'pagination': {'page': 2, 'limit': 20, 'totalPages': 3, 'total': 45},
      };
    } else if (options.path.endsWith('/instructor') &&
        options.method == 'GET') {
      data =
          quizDetail ??
          {
            'quiz': {
              'id': 'quiz-response-id',
              'title': 'Quiz',
              'isPublished': false,
              'questions': [],
            },
          };
    }
    return ResponseBody.fromString(
      jsonEncode({'data': data}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
