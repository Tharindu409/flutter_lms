import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_lms/core/constants/api_endpoints.dart';
import 'package:flutter_lms/features/admin/categories/admin_categories_provider.dart';
import 'package:flutter_lms/features/admin/categories/admin_categories_service.dart';
import 'package:flutter_lms/features/admin/courses/admin_courses_service.dart';
import 'package:flutter_lms/features/admin/core/admin_paged_data.dart';
import 'package:flutter_lms/features/admin/dashboard/admin_dashboard_service.dart';
import 'package:flutter_lms/features/admin/enrollments/admin_enrollments_service.dart';
import 'package:flutter_lms/features/admin/models/admin_models.dart';
import 'package:flutter_lms/features/admin/reviews/admin_reviews_service.dart';
import 'package:flutter_lms/features/admin/users/admin_users_service.dart';
import 'package:flutter_lms/services/api_client.dart';
import 'package:flutter_lms/services/token_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'uses the documented admin endpoint paths, methods, and filters',
    () async {
      final adapter = _AdminAdapter();
      final api = ApiClient(TokenStorage.memory())
        ..dio.httpClientAdapter = adapter;

      await AdminDashboardService(api).load();
      final users = AdminUsersService(api);
      await users.list(search: 'Ada', role: 'STUDENT', status: 'ACTIVE');
      await users.details('user-api-id');
      await users.setStatus('user-api-id', 'SUSPENDED');
      final categories = AdminCategoriesService(api);
      await categories.list(search: 'Mobile');
      await categories.create({'name': 'Mobile', 'description': 'Apps'});
      await categories.setActive('category-api-id', false);
      await AdminCoursesService(api).list(
        search: 'Flutter',
        status: 'PUBLISHED',
        instructorId: 'instructor-api-id',
        categoryId: 'category-api-id',
      );
      await AdminCoursesService(api).publishedDetails('course-api-id');
      await AdminCoursesService(api).archive('course-api-id');
      await AdminEnrollmentsService(api).list(
        status: 'ACTIVE',
        courseId: 'course-api-id',
        studentId: 'student-api-id',
      );
      await AdminReviewsService(api).list('course-api-id');
      await AdminReviewsService(api).setVisibility('review-api-id', false);

      expect(
        adapter.requests
            .map((request) => '${request.method} ${request.path}')
            .toList(),
        [
          'GET ${ApiEndpoints.adminDashboard}',
          'GET ${ApiEndpoints.users}',
          'GET ${ApiEndpoints.user('user-api-id')}',
          'PATCH ${ApiEndpoints.userStatus('user-api-id')}',
          'GET ${ApiEndpoints.categories}',
          'POST ${ApiEndpoints.categories}',
          'PATCH ${ApiEndpoints.categoryStatus('category-api-id')}',
          'GET ${ApiEndpoints.adminCourses}',
          'GET ${ApiEndpoints.course('course-api-id')}',
          'PATCH ${ApiEndpoints.archiveCourse('course-api-id')}',
          'GET ${ApiEndpoints.adminEnrollments}',
          'GET ${ApiEndpoints.courseReviews('course-api-id')}',
          'PATCH ${ApiEndpoints.reviewVisibility('review-api-id')}',
        ],
      );
      expect(adapter.requests[1].query, {
        'page': 1,
        'limit': 20,
        'search': 'Ada',
        'role': 'STUDENT',
        'status': 'ACTIVE',
      });
      expect(adapter.requests[4].query, {
        'page': 1,
        'limit': 20,
        'activeOnly': false,
        'search': 'Mobile',
      });
      expect(adapter.requests[6].body, {'isActive': false});
      expect(adapter.requests[12].body, {'isVisible': false});
      expect(adapter.requests[7].query, {
        'page': 1,
        'limit': 20,
        'search': 'Flutter',
        'status': 'PUBLISHED',
        'instructorId': 'instructor-api-id',
        'categoryId': 'category-api-id',
      });
      expect(adapter.requests[10].query, {
        'page': 1,
        'limit': 20,
        'status': 'ACTIVE',
        'courseId': 'course-api-id',
        'studentId': 'student-api-id',
      });
      api.dio.close(force: true);
    },
  );

  test('category provider sends only changed category fields', () async {
    final adapter = _AdminAdapter();
    final api = ApiClient(TokenStorage.memory())
      ..dio.httpClientAdapter = adapter;
    final provider = AdminCategoriesProvider(AdminCategoriesService(api));
    const category = AdminCategory(
      id: 'category-api-id',
      name: 'Old name',
      description: 'Unchanged',
      slug: 'old-name',
      isActive: true,
    );

    await provider.updateCategory(
      category,
      name: 'New name',
      description: 'Unchanged',
    );

    expect(adapter.requests.single.method, 'PATCH');
    expect(
      adapter.requests.single.path,
      ApiEndpoints.category('category-api-id'),
    );
    expect(adapter.requests.single.body, {'name': 'New name'});
    provider.dispose();
    api.dio.close(force: true);
  });

  test('category creation refreshes backend pagination metadata', () async {
    final service = _CategoryRefreshService();
    final provider = AdminCategoriesProvider(service);

    await provider.createCategory('Created', 'Description');

    expect(service.listCalls, 1);
    expect(provider.total, 27);
    provider.dispose();
  });

  test('list requests omit unset optional filters', () async {
    final adapter = _AdminAdapter();
    final api = ApiClient(TokenStorage.memory())
      ..dio.httpClientAdapter = adapter;
    await AdminUsersService(api).list();
    await AdminCategoriesService(api).list();
    await AdminCoursesService(api).list();
    await AdminEnrollmentsService(api).list();
    expect(adapter.requests[0].query, {'page': 1, 'limit': 20});
    expect(adapter.requests[1].query, {
      'page': 1,
      'limit': 20,
      'activeOnly': false,
    });
    expect(adapter.requests[2].query, {'page': 1, 'limit': 20});
    expect(adapter.requests[3].query, {'page': 1, 'limit': 20});
    api.dio.close(force: true);
  });

  test(
    'missing admin dashboard metrics are safely represented as zero',
    () async {
      final summary = AdminDashboardSummary.fromJson(const {});
      expect(summary.totalStudents, isNull);
      expect(summary.completedEnrollments, isNull);
    },
  );
}

class _CategoryRefreshService extends AdminCategoriesService {
  _CategoryRefreshService() : super(ApiClient(TokenStorage.memory()));

  int listCalls = 0;

  @override
  Future<AdminCategory> create(Map<String, dynamic> body) async =>
      const AdminCategory(
        id: 'created-category',
        name: 'Created',
        description: 'Description',
        slug: 'created',
        isActive: true,
      );

  @override
  Future<AdminPagedData<AdminCategory>> list({
    int page = 1,
    int limit = 20,
    String search = '',
  }) async {
    listCalls++;
    return const AdminPagedData(
      items: [],
      page: 1,
      limit: 20,
      total: 27,
      totalPages: 2,
    );
  }
}

class _CapturedRequest {
  const _CapturedRequest({
    required this.method,
    required this.path,
    required this.query,
    required this.body,
  });

  final String method;
  final String path;
  final Map<String, dynamic> query;
  final dynamic body;
}

class _AdminAdapter implements HttpClientAdapter {
  final requests = <_CapturedRequest>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(
      _CapturedRequest(
        method: options.method,
        path: options.path,
        query: Map<String, dynamic>.from(options.queryParameters),
        body: options.data is Map
            ? Map<String, dynamic>.from(options.data as Map)
            : null,
      ),
    );
    final path = options.path;
    final payload = switch (path) {
      '/api/v1/users/user-api-id' || '/api/v1/users/user-api-id/status' => {
        'user': {
          'id': 'user-api-id',
          'firstName': 'Ada',
          'lastName': 'Lovelace',
          'email': 'ada@example.test',
          'role': 'STUDENT',
          'status': 'ACTIVE',
        },
      },
      '/api/v1/categories' || '/api/v1/categories/category-api-id/status' => {
        'category': {
          'id': 'category-api-id',
          'name': 'Mobile',
          'description': 'Apps',
          'slug': 'mobile',
          'isActive': true,
        },
      },
      '/api/v1/categories/category-api-id' => {
        'category': {
          'id': 'category-api-id',
          'name': 'New name',
          'description': 'Unchanged',
          'slug': 'new-name',
          'isActive': true,
        },
      },
      '/api/v1/courses/course-api-id' ||
      '/api/v1/courses/course-api-id/admin/archive' => {
        'course': {
          'id': 'course-api-id',
          'title': 'Course',
          'status': 'PUBLISHED',
        },
      },
      '/api/v1/reviews/review-api-id/visibility' => {
        'review': {
          'id': 'review-api-id',
          'rating': 5,
          'comment': 'Nice',
          'isVisible': false,
        },
      },
      _ => <String, dynamic>{},
    };
    return ResponseBody.fromString(
      jsonEncode({'data': payload}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
