import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_lms/providers/auth_provider.dart';
import 'package:flutter_lms/providers/profile_provider.dart';
import 'package:flutter_lms/services/api_client.dart';
import 'package:flutter_lms/services/auth_service.dart';
import 'package:flutter_lms/services/profile_service.dart';
import 'package:flutter_lms/services/token_storage.dart';
import 'package:flutter_lms/utils/app_routes.dart';
import 'package:flutter_lms/utils/app_theme.dart';
import 'package:flutter_lms/widgets/app_logo.dart';
import 'package:provider/provider.dart';

void main() {
  test('stores API tokens and sends the access token on logout', () async {
    final tokenStorage = TokenStorage.memory();
    final apiClient = ApiClient(tokenStorage)
      ..dio.options.baseUrl = 'http://test.local';
    final adapter = _FakeAuthAdapter();
    apiClient.dio.httpClientAdapter = adapter;
    final authService = AuthService(apiClient, tokenStorage);

    await authService.login(email: 'student1@test.com', password: 'password8');
    expect(await tokenStorage.readAccessToken(), 'access-student-1');
    expect(await tokenStorage.readRefreshToken(), 'refresh-student-1');

    await authService.logout();

    expect(adapter.logoutAuthorization, 'Bearer access-student-1');
    expect(await tokenStorage.hasSession(), isFalse);
  });

  Future<void> openLogin(WidgetTester tester) async {
    final tokenStorage = TokenStorage.memory();
    final apiClient = ApiClient(tokenStorage)
      ..dio.options.baseUrl = 'http://test.local'
      ..dio.httpClientAdapter = _FakeAuthAdapter();
    final authService = AuthService(apiClient, tokenStorage);
    final profileService = ProfileService(apiClient);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider(authService)),
          ChangeNotifierProvider(
            create: (_) => ProfileProvider(profileService),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          initialRoute: AppRoutes.onboarding,
          routes: AppRoutes.routes,
        ),
      ),
    );

    for (var page = 0; page < 2; page++) {
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
    }
    expect(find.byType(AppLogo), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
  }

  Future<void> submitLogin(WidgetTester tester) async {
    final loginButton = find.text('Login');
    await tester.ensureVisible(loginButton);
    await tester.tap(loginButton);
    await tester.pumpAndSettle();
  }

  testWidgets('splash advances to onboarding', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        initialRoute: AppRoutes.splash,
        routes: AppRoutes.routes,
      ),
    );

    expect(find.text('A brighter way to learn'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('Learn anywhere'), findsOneWidget);
  });

  testWidgets('onboarding pages use separate illustration assets', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        initialRoute: AppRoutes.onboarding,
        routes: AppRoutes.routes,
      ),
    );

    const illustrations = [
      'assets/images/onboarding_learn.png',
      'assets/images/onboarding_progress.png',
      'assets/images/onboarding_goals.png',
    ];

    for (var i = 0; i < illustrations.length; i++) {
      final displayedAssets = tester
          .widgetList<Image>(find.byType(Image))
          .map((image) => image.image)
          .whereType<AssetImage>()
          .map((image) => image.assetName);
      expect(displayedAssets, contains(illustrations[i]));

      if (i < illustrations.length - 1) {
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
      }
    }
  });

  testWidgets('student dashboard shows progress and quick actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        initialRoute: AppRoutes.studentDashboard,
        routes: AppRoutes.routes,
      ),
    );

    expect(find.text('Hello, Student!'), findsOneWidget);
    expect(find.text('Semester Progress'), findsOneWidget);
    expect(find.text('68% complete'), findsOneWidget);
    expect(find.text('Quick Tasks'), findsOneWidget);
    expect(find.text('Join Online Class'), findsOneWidget);
    expect(find.text('Submit Assignment'), findsOneWidget);
    expect(find.text('Check Grades'), findsOneWidget);
    expect(find.text('Contact Teacher'), findsOneWidget);
    expect(find.text('Quick Access'), findsOneWidget);
    expect(find.text('Courses'), findsOneWidget);

    await tester.ensureVisible(find.text('Join Online Class'));
    await tester.tap(find.text('Join Online Class'));
    await tester.pumpAndSettle();
    expect(find.text('Join Online Class coming soon'), findsOneWidget);
  });

  testWidgets('Get Started opens login and empty fields show validation', (
    tester,
  ) async {
    await openLogin(tester);

    await submitLogin(tester);

    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
  });

  testWidgets('invalid email and short password show validation', (
    tester,
  ) async {
    await openLogin(tester);

    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'abc');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'short',
    );
    await submitLogin(tester);

    expect(find.text('Enter a valid email address'), findsOneWidget);
    expect(find.text('Password must be at least 8 characters'), findsOneWidget);
  });

  testWidgets('backend login errors are displayed without routing', (
    tester,
  ) async {
    await openLogin(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'unknown@test.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'password8',
    );
    await submitLogin(tester);

    expect(find.text('Invalid email or password.'), findsOneWidget);
    expect(find.text('Welcome back'), findsOneWidget);
  });

  for (final role in [
    (email: 'student1@test.com', dashboard: 'Hello, Student!'),
    (email: 'instructor1@test.com', dashboard: 'Instructor Dashboard'),
    (email: 'admin1@test.com', dashboard: 'Admin Dashboard'),
  ]) {
    testWidgets('${role.email} opens ${role.dashboard}', (tester) async {
      await openLogin(tester);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        role.email,
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'password8',
      );
      await submitLogin(tester);

      expect(find.text(role.dashboard), findsOneWidget);
      expect(
        tester.state<NavigatorState>(find.byType(Navigator)).canPop(),
        isFalse,
      );
    });
  }

  testWidgets('student account menu opens profile', (tester) async {
    await openLogin(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'student1@test.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'password8',
    );
    await submitLogin(tester);

    await tester.tap(find.text('ST'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('logout returns to login without dashboard in back stack', (
    tester,
  ) async {
    await openLogin(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'student1@test.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'password8',
    );
    await submitLogin(tester);

    await tester.tap(find.text('ST'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();
    expect(find.text('Are you sure you want to logout?'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Logout'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Hello, Student!'), findsNothing);
    expect(
      tester.state<NavigatorState>(find.byType(Navigator)).canPop(),
      isFalse,
    );
  });
}

class _FakeAuthAdapter implements HttpClientAdapter {
  String? logoutAuthorization;

  static const _accounts = {
    'student1@test.com': ('student-1', 'Student', 'STUDENT'),
    'instructor1@test.com': ('instructor-1', 'Instructor', 'INSTRUCTOR'),
    'admin1@test.com': ('admin-1', 'Admin', 'ADMIN'),
  };

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path == '/api/v1/auth/login') {
      final request = options.data as Map<String, dynamic>;
      final account = _accounts[request['email']];
      if (account == null || request['password'] != 'password8') {
        return _response({
          'message': 'Invalid email or password.',
        }, statusCode: 401);
      }

      return _response({
        'data': {
          'user': {
            'id': account.$1,
            'firstName': account.$2,
            'lastName': 'User',
            'email': request['email'],
            'role': account.$3,
          },
          'tokens': {
            'accessToken': 'access-${account.$1}',
            'refreshToken': 'refresh-${account.$1}',
          },
        },
      });
    }

    if (options.path == '/api/v1/auth/logout') {
      logoutAuthorization = options.headers['Authorization'] as String?;
      return _response({'message': 'Logged out.'});
    }

    return _response({'message': 'Unexpected test endpoint.'}, statusCode: 404);
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

  @override
  void close({bool force = false}) {}
}
