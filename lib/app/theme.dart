import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryTeal = Color(0xFF00897B);
  static const Color primaryDarkTeal = Color(0xFF004D40);
  static const Color primaryLightTeal = Color(0xFFE0F2F1);

  static const Color secondaryBlue = Color(0xFF0284C7);
  static const Color secondaryDarkBlue = Color(0xFF075985);
  static const Color secondaryLightBlue = Color(0xFFE0F2FE);

  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color textDarkPrimary = Color(0xFF0F172A);
  static const Color textDarkSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color borderLight = Color(0xFFE2E8F0);

  static const Color successGreen = Color(0xFF10B981);
  static const Color successBg = Color(0xFFECFDF5);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color warningBg = Color(0xFFFFFEF3);
  static const Color errorRed = Color(0xFFEF4444);
  static const Color errorBg = Color(0xFFFEF2F2);
  static const Color infoBlue = Color(0xFF3B82F6);
  static const Color infoBg = Color(0xFFEFF6FF);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryTeal,
      scaffoldBackgroundColor: backgroundLight,
      colorScheme: const ColorScheme.light(
        primary: primaryTeal,
        onPrimary: Colors.white,
        secondary: secondaryBlue,
        onSecondary: Colors.white,
        surface: surfaceWhite,
        onSurface: textDarkPrimary,
        error: errorRed,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: surfaceWhite,
        foregroundColor: textDarkPrimary,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textDarkPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderLight, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceWhite,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderLight, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderLight, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryTeal, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorRed, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorRed, width: 2),
        ),
        labelStyle: const TextStyle(color: textDarkSecondary, fontSize: 14),
        hintStyle: const TextStyle(color: textMuted, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryTeal,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryTeal,
          side: const BorderSide(color: primaryTeal, width: 1.5),
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
