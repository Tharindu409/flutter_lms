import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_lms/features/admin/core/admin_paged_data.dart';
import 'package:flutter_lms/features/admin/models/admin_models.dart';
import 'package:flutter_lms/features/admin/screens/admin_users_screen.dart';
import 'package:flutter_lms/features/admin/users/admin_users_provider.dart';
import 'package:flutter_lms/features/admin/users/admin_users_service.dart';
import 'package:flutter_lms/models/user_model.dart';
import 'package:flutter_lms/providers/auth_provider.dart';
import 'package:flutter_lms/services/api_client.dart';
import 'package:flutter_lms/services/auth_service.dart';
import 'package:flutter_lms/services/token_storage.dart';
import 'package:provider/provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('status filter and user details work after users load', (
    tester,
  ) async {
    final service = _DelayedAdminUsersService();
    final users = AdminUsersProvider(service);
    final apiClient = ApiClient(TokenStorage.memory());
    final auth = AuthProvider(AuthService(apiClient, TokenStorage.memory()))
      ..setUser(
        const UserModel(
          id: 'admin-id',
          firstName: 'Admin',
          lastName: 'User',
          email: 'admin@example.test',
          role: 'ADMIN',
        ),
      );
    addTearDown(users.dispose);
    addTearDown(auth.dispose);
    addTearDown(() => apiClient.dio.close(force: true));

    service.initialResponse.complete(
      _usersPage(const [
        AdminUser(
          id: 'student-id',
          firstName: 'Active',
          lastName: 'Student',
          email: 'student@example.test',
          role: 'STUDENT',
          status: 'ACTIVE',
        ),
      ]),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AdminUsersProvider>.value(value: users),
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ],
        child: const MaterialApp(
          home: Scaffold(body: AdminUsersScreen(onOpenMore: _noop)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilterChip, 'Active'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(service.statusFilters, ['', 'ACTIVE']);
    expect(find.text('Active Student'), findsOneWidget);

    await tester.tap(find.text('Active Student'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('User details'), findsOneWidget);
  });

  testWidgets('status filter handles a tap while initial users load', (
    tester,
  ) async {
    final service = _DelayedAdminUsersService();
    final users = AdminUsersProvider(service);
    final apiClient = ApiClient(TokenStorage.memory());
    final auth = AuthProvider(AuthService(apiClient, TokenStorage.memory()))
      ..setUser(
        const UserModel(
          id: 'admin-id',
          firstName: 'Admin',
          lastName: 'User',
          email: 'admin@example.test',
          role: 'ADMIN',
        ),
      );
    addTearDown(users.dispose);
    addTearDown(auth.dispose);
    addTearDown(() => apiClient.dio.close(force: true));

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AdminUsersProvider>.value(value: users),
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ],
        child: const MaterialApp(
          home: Scaffold(body: AdminUsersScreen(onOpenMore: _noop)),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.widgetWithText(FilterChip, 'Active'));
    await tester.pump();

    service.initialResponse.complete(
      _usersPage(const [
        AdminUser(
          id: 'student-id',
          firstName: 'Active',
          lastName: 'Student',
          email: 'student@example.test',
          role: 'STUDENT',
          status: 'ACTIVE',
        ),
      ]),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(service.statusFilters, ['', 'ACTIVE']);
    expect(find.text('Active Student'), findsOneWidget);
  });
}

void _noop() {}

AdminPagedData<AdminUser> _usersPage(List<AdminUser> users) => AdminPagedData(
  items: users,
  page: 1,
  limit: 20,
  total: users.length,
  totalPages: 1,
);

class _DelayedAdminUsersService extends AdminUsersService {
  _DelayedAdminUsersService() : super(ApiClient(TokenStorage.memory()));
  final Completer<AdminPagedData<AdminUser>> initialResponse = Completer();
  final List<String> statusFilters = [];

  @override
  Future<AdminPagedData<AdminUser>> list({
    int page = 1,
    int limit = 20,
    String search = '',
    String role = '',
    String status = '',
  }) {
    statusFilters.add(status);
    if (statusFilters.length == 1) return initialResponse.future;
    return Future.value(
      _usersPage(const [
        AdminUser(
          id: 'student-id',
          firstName: 'Active',
          lastName: 'Student',
          email: 'student@example.test',
          role: 'STUDENT',
          status: 'ACTIVE',
        ),
      ]),
    );
  }

  @override
  Future<AdminUser> details(String userId) async => const AdminUser(
    id: 'student-id',
    firstName: 'Active',
    lastName: 'Student',
    email: 'student@example.test',
    role: 'STUDENT',
    status: 'ACTIVE',
  );
}
