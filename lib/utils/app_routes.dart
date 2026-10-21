import 'package:flutter/material.dart';

import 'package:flutter_lms/screens/admin_dashboard.dart';
import 'package:flutter_lms/screens/instructor_dashboard.dart';
import 'package:flutter_lms/screens/login_screen.dart';
import 'package:flutter_lms/screens/onboarding_screen.dart';
import 'package:flutter_lms/screens/splash_screen.dart';
import 'package:flutter_lms/screens/student_dashboard.dart';

class AppRoutes {
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const studentDashboard = '/student';
  static const instructorDashboard = '/instructor';
  static const adminDashboard = '/admin';

  static Map<String, WidgetBuilder> get routes => {
    splash: (_) => const SplashScreen(),
    onboarding: (_) => const OnboardingScreen(),
    login: (_) => const LoginScreen(),
    studentDashboard: (_) => const StudentDashboard(),
    instructorDashboard: (_) => const InstructorDashboard(),
    adminDashboard: (_) => const AdminDashboard(),
  };
}
