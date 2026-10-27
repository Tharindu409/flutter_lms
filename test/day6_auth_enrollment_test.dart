import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_lms/models/course_progress.dart';
import 'package:flutter_lms/services/auth_interceptor.dart';
import 'package:flutter_lms/services/token_storage.dart';
import 'package:flutter_lms/utils/api_exception.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('401 refreshes once and retries with the new bearer token', () async {
    final storage = TokenStorage.memory();
    await storage.saveSession(
      accessToken: 'expired-access',
      refreshToken: 'old-refresh',
      role: 'STUDENT',
    );
    final protectedAdapter = _ProtectedAdapter();
    final refreshAdapter = _RefreshAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'http://test.local'))
      ..httpClientAdapter = protectedAdapter;
    dio.interceptors.add(
      AuthInterceptor(
        dio: dio,
        tokenStorage: storage,
        refreshDioFactory: (options) =>
            Dio(options)..httpClientAdapter = refreshAdapter,
      ),
    );

    await dio.get<dynamic>('/api/v1/courses/course-from-response/sections');

    expect(protectedAdapter.authorizationHeaders, [
      _authorization('expired-access'),
      _authorization('fresh-access'),
    ]);
    expect(protectedAdapter.requestCount, 2);
    expect(refreshAdapter.refreshBody, {'refreshToken': 'old-refresh'});
    expect(await storage.readAccessToken(), 'fresh-access');
    expect(await storage.readRefreshToken(), 'fresh-refresh');
  });

  test('public category request works without an access token', () async {
    final adapter = _PublicAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'http://test.local'))
      ..httpClientAdapter = adapter;
    dio.interceptors.add(
      AuthInterceptor(dio: dio, tokenStorage: TokenStorage.memory()),
    );

    await dio.get<dynamic>('/api/v1/categories');

    expect(adapter.authorization, isNull);
  });

  test('enrollment errors map to safe user-facing messages', () {
    expect(
      _enrollmentError(409).message,
      'You are already enrolled in this course.',
    );
    expect(
      _enrollmentError(403).message,
      'Your account is not allowed to enroll in this course.',
    );
    expect(
      _enrollmentError(404).message,
      'This course is not available for enrollment.',
    );
    expect(
      _enrollmentError(
        400,
        message: 'Enrollment already exists for this student',
      ).message,
      'You are already enrolled in this course.',
    );
  });

  test('missing progress fields remain unknown instead of being inferred', () {
    final progress = CourseProgress.fromJson({
      'lessons': [
        {
          'lesson': {'id': 'lesson-from-response'},
        },
      ],
    });

    expect(progress.progressPercentage, isNull);
    expect(progress.completedLessons, isNull);
    expect(progress.totalLessons, isNull);
    expect(progress.enrollmentStatus, isNull);
    expect(progress.statusOf('lesson-from-response'), isNull);
  });
}

ApiException _enrollmentError(int statusCode, {String? message}) {
  final request = RequestOptions(path: '/api/v1/courses/course/enroll');
  return ApiException.forEnrollment(
    ApiException.fromDioException(
      DioException(
        requestOptions: request,
        response: Response<dynamic>(
          requestOptions: request,
          statusCode: statusCode,
          data: {'message': message},
        ),
        type: DioExceptionType.badResponse,
      ),
    ),
  );
}

class _ProtectedAdapter implements HttpClientAdapter {
  final List<String?> authorizationHeaders = [];
  int requestCount = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestCount++;
    final authorization = options.headers['Authorization'] as String?;
    authorizationHeaders.add(authorization);
    if (authorization == _authorization('fresh-access')) {
      return _response({'data': []});
    }
    return _response({'message': 'expired'}, statusCode: 401);
  }

  @override
  void close({bool force = false}) {}
}

class _RefreshAdapter implements HttpClientAdapter {
  Map<String, dynamic>? refreshBody;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    refreshBody = options.data as Map<String, dynamic>;
    return _response({
      'data': {
        'tokens': {
          'accessToken': 'fresh-access',
          'refreshToken': 'fresh-refresh',
        },
      },
    });
  }

  @override
  void close({bool force = false}) {}
}

class _PublicAdapter implements HttpClientAdapter {
  String? authorization;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    authorization = options.headers['Authorization'] as String?;
    return _response({'data': []});
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _response(Map<String, Object?> body, {int statusCode = 200}) {
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

String _authorization(String token) => ['Bearer', token].join(' ');
