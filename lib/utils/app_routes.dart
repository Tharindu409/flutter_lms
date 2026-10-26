import 'package:flutter/material.dart';
import 'package:flutter_lms/screens/admin_dashboard.dart';
import 'package:flutter_lms/screens/auth/forgot_password_screen.dart';
import 'package:flutter_lms/screens/auth/login_screen.dart';
import 'package:flutter_lms/screens/auth/register_instructor_screen.dart';
import 'package:flutter_lms/screens/auth/register_student_screen.dart';
import 'package:flutter_lms/screens/auth/reset_password_screen.dart';
import 'package:flutter_lms/screens/auth/verify_otp_screen.dart';
import 'package:flutter_lms/screens/instructor_dashboard.dart';
import 'package:flutter_lms/screens/onboarding_screen.dart';
import 'package:flutter_lms/screens/profile/edit_profile_screen.dart';
import 'package:flutter_lms/screens/profile/profile_screen.dart';
import 'package:flutter_lms/screens/splash_screen.dart';
import 'package:flutter_lms/screens/student_dashboard.dart';

class AppRoutes {
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const studentDashboard = '/student';
  static const instructorDashboard = '/instructor';
  static const adminDashboard = '/admin';
  static const registerStudent = '/register/student';
  static const registerInstructor = '/register/instructor';
  static const verifyOtp = '/verify-otp';
  static const forgotPassword = '/forgot-password';
  static const resetPassword = '/reset-password';
  static const profile = '/profile';
  static const editProfile = '/profile/edit';

  static Map<String, WidgetBuilder> get routes => {
    splash: (_) => const SplashScreen(),
    onboarding: (_) => const OnboardingScreen(),
    login: (_) => const LoginScreen(),
    studentDashboard: (_) => const StudentDashboard(),
    instructorDashboard: (_) => const InstructorDashboard(),
    adminDashboard: (_) => const AdminDashboard(),
    registerStudent: (_) => const RegisterStudentScreen(),
    registerInstructor: (_) => const RegisterInstructorScreen(),
    verifyOtp: (_) => const VerifyOtpScreen(),
    forgotPassword: (_) => const ForgotPasswordScreen(),
    resetPassword: (_) => const ResetPasswordScreen(),
    profile: (_) => const ProfileScreen(),
    editProfile: (_) => const EditProfileScreen(),
  };

  /// Dashboard route for the role returned by the backend.
  static String? homeForRole(String? role) {
    switch (role) {
      case 'STUDENT':
        return studentDashboard;
      case 'INSTRUCTOR':
        return instructorDashboard;
      case 'ADMIN':
        return adminDashboard;
      default:
        return null;
    }
  }
}
