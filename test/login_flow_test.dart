import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_lms/core/routes/app_routes.dart';
import 'package:flutter_lms/core/theme/app_theme.dart';

void main() {
  Future<void> openLogin(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        initialRoute: AppRoutes.onboarding,
        routes: AppRoutes.routes,
      ),
    );

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

  for (final role in [
    (email: 'student1@test.com', dashboard: 'Student Dashboard'),
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

      expect(find.text(role.dashboard), findsWidgets);
      expect(
        tester.state<NavigatorState>(find.byType(Navigator)).canPop(),
        isFalse,
      );
    });
  }

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

    await tester.tap(find.byIcon(Icons.logout));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Student Dashboard'), findsNothing);
    expect(
      tester.state<NavigatorState>(find.byType(Navigator)).canPop(),
      isFalse,
    );
  });
}
