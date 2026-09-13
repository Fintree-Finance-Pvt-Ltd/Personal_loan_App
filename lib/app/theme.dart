import 'package:flutter/material.dart';

/// Central application design system and theme tokens.
class AppTheme {
  AppTheme._();

  // ============================================================
  // BRAND COLORS (EMERALD GREEN & FOREST SLATE)
  // ============================================================

  static const Color primaryTeal = Color(0xFF047857);      // Deep Emerald Green
  static const Color primaryDarkTeal = Color(0xFF064E3B);  // Forest Dark Emerald
  static const Color primaryDeepTeal = Color(0xFF022C22);  // Deepest Forest Slate
  static const Color primaryLightTeal = Color(0xFFECFDF5); // Light Emerald Tint
  static const Color primarySoftTeal = Color(0xFFF0FDF4);  // Soft Mint Tint

  static const Color secondaryBlue = Color(0xFF0F766E);    // Deep Teal
  static const Color secondaryDarkBlue = Color(0xFF134E4A);
  static const Color secondaryLightBlue = Color(0xFFCCFBF1);

  static const Color accentCyan = Color(0xFF10B981);       // Vibrant Emerald Green
  static const Color accentMint = Color(0xFF34D399);       // Bright Mint Accent

  // ============================================================
  // BACKGROUND AND SURFACE COLORS
  // ============================================================

  static const Color backgroundLight = Color(0xFFFFFFFF);  // Clean Pure White Canvas
  static const Color backgroundSoft = Color(0xFFF8FAFC);   // Cool Slate Background

  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFF8FAFC);
  static const Color surfaceMuted = Color(0xFFF1F5F9);
  static const Color surfaceTeal = Color(0xFFECFDF5);

  // ============================================================
  // TEXT COLORS
  // ============================================================

  static const Color textDarkPrimary = Color(0xFF0F172A);   // Slate 900
  static const Color textDarkSecondary = Color(0xFF475569); // Slate 600
  static const Color textMuted = Color(0xFF94A3B8);         // Slate 400
  static const Color textDisabled = Color(0xFFCBD5E1);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ============================================================
  // BORDER AND DIVIDER COLORS
  // ============================================================

  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderMuted = Color(0xFFF1F5F9);
  static const Color borderFocused = primaryTeal;
  static const Color dividerColor = Color(0xFFE2E8F0);

  // ============================================================
  // STATUS COLORS
  // ============================================================

  static const Color successGreen = Color(0xFF059669);
  static const Color successDarkGreen = Color(0xFF047857);
  static const Color successBg = Color(0xFFECFDF5);

  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color warningDarkOrange = Color(0xFFB45309);
  static const Color warningBg = Color(0xFFFFF8E6);

  static const Color errorRed = Color(0xFFDC2626);
  static const Color errorDarkRed = Color(0xFFB91C1C);
  static const Color errorBg = Color(0xFFFEF2F2);

  static const Color infoBlue = Color(0xFF2563EB);
  static const Color infoDarkBlue = Color(0xFF1D4ED8);
  static const Color infoBg = Color(0xFFEFF6FF);

  // ============================================================
  // ICON COLORS (CENTRAL ICON TOKEN)
  // ============================================================

  static const Color iconPrimary = Color(0xFF2563EB);   // Central Button & Action Icon Color
  static const Color iconSecondary = Color(0xFF475569); // Secondary Icon Color
  static const Color iconMuted = Color(0xFF94A3B8);     // Muted / Disabled Icon Color

  // ============================================================
  // GRADIENTS
  // ============================================================

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF023118),
      Color(0xFF04582E),
      Color(0xFF012010),
    ],
  );

  static const LinearGradient buttonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFF059669),
      Color(0xFF0D9488),
    ],
  );

  // ============================================================
  // SHADOWS
  // ============================================================

  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: primaryDeepTeal.withValues(alpha: 0.06),
          blurRadius: 18,
          offset: const Offset(0, 7),
        ),
      ];

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: primaryDeepTeal.withValues(alpha: 0.08),
          blurRadius: 28,
          offset: const Offset(0, 12),
        ),
      ];

  static List<BoxShadow> get elevatedShadow => [
        BoxShadow(
          color: primaryDeepTeal.withValues(alpha: 0.14),
          blurRadius: 34,
          spreadRadius: 1,
          offset: const Offset(0, 16),
        ),
      ];

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryTeal,
      scaffoldBackgroundColor: backgroundLight,
      iconTheme: const IconThemeData(
        color: iconPrimary,
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryTeal,
        brightness: Brightness.light,
      ).copyWith(
        primary: primaryTeal,
        onPrimary: Colors.white,
        surface: surfaceWhite,
        onSurface: textDarkPrimary,
      ),
    );
  }
}