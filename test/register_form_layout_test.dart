import 'package:flutter/material.dart';
import 'package:flutter_lms/screens/auth/register_student_screen.dart';
import 'package:flutter_lms/services/api_client.dart';
import 'package:flutter_lms/services/auth_service.dart';
import 'package:flutter_lms/services/token_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('student registration form fits a narrow scrollable viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final tokenStorage = TokenStorage.memory();
    final authService = AuthService(ApiClient(tokenStorage), tokenStorage);
    await tester.pumpWidget(
      Provider<AuthService>.value(
        value: authService,
        child: const MaterialApp(home: RegisterStudentScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Create a student account'), findsOneWidget);
    expect(find.text('First name'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
