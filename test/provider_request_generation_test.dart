import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_lms/features/admin/dashboard/admin_dashboard_provider.dart';
import 'package:flutter_lms/features/admin/dashboard/admin_dashboard_service.dart';
import 'package:flutter_lms/features/admin/models/admin_models.dart';
import 'package:flutter_lms/models/instructor_summary.dart';
import 'package:flutter_lms/providers/instructor_dashboard_provider.dart';
import 'package:flutter_lms/providers/profile_provider.dart';
import 'package:flutter_lms/services/api_client.dart';
import 'package:flutter_lms/services/instructor_course_service.dart';
import 'package:flutter_lms/services/profile_service.dart';
import 'package:flutter_lms/services/token_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ignores a profile response that completes after reset', () async {
    final adapter = _DelayedAdapter();
    final client = ApiClient(TokenStorage.memory())
      ..dio.httpClientAdapter = adapter;
    final provider = ProfileProvider(ProfileService(client));
    var notifications = 0;
    provider.addListener(() => notifications++);

    final load = provider.load('ADMIN');
    await adapter.requestStarted.future;
    provider.reset();
    final notificationsAfterReset = notifications;
    adapter.response.complete(
      ResponseBody.fromString(
        jsonEncode({
          'data': {
            'user': {
              'id': 'old-user',
              'firstName': 'Old',
              'lastName': 'User',
              'email': 'old@example.test',
              'role': 'ADMIN',
            },
          },
        }),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      ),
    );

    await load;

    expect(provider.user, isNull);
    expect(notifications, notificationsAfterReset);
    provider.dispose();
    client.dio.close(force: true);
  });

  test('does not start a second dashboard load while one is running', () async {
    final instructorService = _DelayedInstructorCourseService();
    final instructorProvider = InstructorDashboardProvider(instructorService);
    final instructorLoad = instructorProvider.load();
    await instructorProvider.load();
    expect(instructorService.calls, 1);
    instructorService.response.complete(
      const InstructorSummary(
        totalCourses: 2,
        publishedCourses: 1,
        draftCourses: 1,
        archivedCourses: 0,
        totalEnrollments: 3,
        pendingSubmissions: 0,
        averageRating: 4.5,
      ),
    );
    await instructorLoad;
    instructorProvider.dispose();

    final adminService = _DelayedAdminDashboardService();
    final adminProvider = AdminDashboardProvider(adminService);
    final adminLoad = adminProvider.load();
    await adminProvider.load(refresh: true);
    expect(adminService.calls, 1);
    adminService.response.complete(const AdminDashboardSummary());
    await adminLoad;
    adminProvider.dispose();
  });
}

class _DelayedAdapter implements HttpClientAdapter {
  final requestStarted = Completer<void>();
  final response = Completer<ResponseBody>();

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    if (!requestStarted.isCompleted) requestStarted.complete();
    return response.future;
  }

  @override
  void close({bool force = false}) {}
}

class _DelayedInstructorCourseService extends InstructorCourseService {
  _DelayedInstructorCourseService() : super(ApiClient(TokenStorage.memory()));

  int calls = 0;
  final response = Completer<InstructorSummary>();

  @override
  Future<InstructorSummary> getDashboard() {
    calls++;
    return response.future;
  }
}

class _DelayedAdminDashboardService extends AdminDashboardService {
  _DelayedAdminDashboardService() : super(ApiClient(TokenStorage.memory()));

  int calls = 0;
  final response = Completer<AdminDashboardSummary>();

  @override
  Future<AdminDashboardSummary> load() {
    calls++;
    return response.future;
  }
}
