class Validators {
  static String? requiredField(String? value, String label) {
    if ((value ?? '').trim().isEmpty) return '$label is required';
    return null;
  }

  static String? email(String? value) {
    final trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) return 'Email is required';

    final emailRegex = RegExp(
      r"^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+@[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+$",
    );

    if (!emailRegex.hasMatch(trimmed)) {
      return 'Enter a valid email address';
    }

    return null;
  }

  static String? password(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Password is required';
    if (password.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }
}
