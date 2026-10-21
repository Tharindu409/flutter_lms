import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF6747D7);
  static const Color secondary = Color(0xFF12AFA3);
  static const Color tertiary = Color(0xFFFF936B);
  static const Color background = Color(0xFFF7F6FC);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF211B36);
  static const Color textSecondary = Color(0xFF77728A);
  static const Color info = Color(0xFF6747D7);
  static const Color success = Color(0xFF168B73);
  static const Color error = Color(0xFFD94B61);
  static const List<Color> loginHeaderGradient = [
    Color(0xFF6547D7),
    Color(0xFF9A5DEB),
    Color(0xFFCA69D6),
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
    Radius.circular(18),
  );
  static const BorderRadius largeRadius = BorderRadius.all(Radius.circular(24));

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'Poppins',
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: primary,
            brightness: Brightness.light,
          ).copyWith(
            primary: primary,
            secondary: secondary,
            tertiary: tertiary,
            surface: surface,
            error: error,
          ),
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          fontFamily: 'Poppins',
        ),
      ),
      textTheme: const TextTheme(
        headlineSmall: TextStyle(
          color: textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.8,
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
        fillColor: const Color(0xFFFAF9FD),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
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
          borderSide: BorderSide(color: Color(0xFFEAE7F1)),
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
          minimumSize: const Size.fromHeight(56),
          backgroundColor: primary,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
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
        elevation: 3,
        shadowColor: const Color(0x180F082B),
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(borderRadius: largeRadius),
      ),
    );
  }
}
