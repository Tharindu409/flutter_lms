import 'package:flutter/material.dart';
import '../../features/admin/admin_dashboard.dart';
import '../../features/auth/login_screen.dart';
import '../../features/instructor/instructor_dashboard.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/student/student_dashboard.dart';

class AppRoutes {
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const studentDashboard = '/student';
  static const instructorDashboard = '/instructor';
  static const adminDashboard = '/admin';

  static Map<String, WidgetBuilder> get routes => {
        onboarding: (_) => const OnboardingScreen(),
        login: (_) => const LoginScreen(),
        studentDashboard: (_) => const StudentDashboard(),
        instructorDashboard: (_) => const InstructorDashboard(),
        adminDashboard: (_) => const AdminDashboard(),
      };
}