import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_lms/utils/app_routes.dart';
import 'package:flutter_lms/utils/app_theme.dart';
import 'package:flutter_lms/widgets/app_logo.dart';

void main() {
  Future<void> openLogin(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        initialRoute: AppRoutes.onboarding,
        routes: AppRoutes.routes,
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
    expect(find.text('68%'), findsNWidgets(2));
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

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Hello, Student!'), findsNothing);
    expect(
      tester.state<NavigatorState>(find.byType(Navigator)).canPop(),
      isFalse,
    );
  });
}
