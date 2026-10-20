import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF3157C8);
  static const Color background = Color(0xFFF5F7FC);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF17233C);
  static const Color textSecondary = Color(0xFF68758D);
  static const Color info = Color(0xFF3157C8);
  static const Color success = Color(0xFF16845B);
  static const Color error = Color(0xFFC44242);
  static const List<Color> loginHeaderGradient = [
    Color(0xFF3157C8),
    Color(0xFF5278E8),
  ];
  static const TextStyle loginHeaderTitle = TextStyle(
    color: Colors.white,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.25,
  );
  static const TextStyle loginHeaderSubtitle = TextStyle(
    color: Color(0xDBFFFFFF),
    fontSize: 14,
    height: 1.45,
  );

  static const BorderRadius mediumRadius = BorderRadius.all(
    Radius.circular(14),
  );
  static const BorderRadius largeRadius = BorderRadius.all(Radius.circular(16));

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'Poppins',
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: background,
      textTheme: const TextTheme(
        headlineSmall: TextStyle(
          color: textPrimary,
          fontSize: 26,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.25,
        ),
        titleMedium: TextStyle(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(color: textPrimary, fontSize: 16, height: 1.45),
        bodyMedium: TextStyle(color: textSecondary, fontSize: 14, height: 1.45),
        bodySmall: TextStyle(color: textSecondary, fontSize: 12, height: 1.4),
        labelLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 17,
        ),
        prefixIconColor: textSecondary,
        suffixIconColor: textSecondary,
        labelStyle: const TextStyle(color: textSecondary),
        floatingLabelStyle: const TextStyle(
          color: primary,
          fontWeight: FontWeight.w600,
        ),
        border: const OutlineInputBorder(
          borderRadius: mediumRadius,
          borderSide: BorderSide(color: Color(0xFFDCE2EE)),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: mediumRadius,
          borderSide: BorderSide(color: Color(0xFFDCE2EE)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: mediumRadius,
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: mediumRadius,
          borderSide: BorderSide(color: error),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: mediumRadius,
          borderSide: BorderSide(color: error, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: mediumRadius),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
          shape: const RoundedRectangleBorder(borderRadius: mediumRadius),
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 2,
        shadowColor: const Color(0x140D1B38),
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(borderRadius: largeRadius),
      ),
    );
  }
}
