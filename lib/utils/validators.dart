import 'package:flutter/widgets.dart';

class Validators {
  const Validators._();

  static String? requiredField(String? value, String label) {
    if ((value ?? '').trim().isEmpty) return '$label is required';
    return null;
  }

  static String? email(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Email is required';
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!regex.hasMatch(email)) return 'Enter a valid email address';
    return null;
  }

  /// For registration and password reset. Login only checks that a value exists.
  static String? password(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Password is required';
    if (password.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  static String? Function(String?) confirmPassword(
    TextEditingController password,
  ) {
    return (value) {
      if ((value ?? '').isEmpty) return 'Please confirm your password';
      if (value != password.text) return 'Passwords do not match';
      return null;
    };
  }

  static String? otp(String? value) {
    final otp = value?.trim() ?? '';
    if (otp.isEmpty) return 'Enter the OTP';
    if (!RegExp(r'^\d+$').hasMatch(otp)) return 'OTP must contain digits only';
    return null;
  }

  static String? years(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Experience is required';
    final years = int.tryParse(text);
    if (years == null || years < 0 || years > 60) {
      return 'Enter a number between 0 and 60';
    }
    return null;
  }
}