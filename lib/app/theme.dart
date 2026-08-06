import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // ============================================================
  // BRAND COLORS
  // ============================================================

  static const Color primaryTeal = Color(0xFF00897B);
  static const Color primaryDarkTeal = Color(0xFF005B52);
  static const Color primaryDeepTeal = Color(0xFF033F45);
  static const Color primaryLightTeal = Color(0xFFE6F6F4);
  static const Color primarySoftTeal = Color(0xFFF1FAF9);

  static const Color secondaryBlue = Color(0xFF0284C7);
  static const Color secondaryDarkBlue = Color(0xFF075985);
  static const Color secondaryLightBlue = Color(0xFFE0F2FE);

  static const Color accentCyan = Color(0xFF16B8AA);
  static const Color accentMint = Color(0xFF5EEAD4);

  // ============================================================
  // BACKGROUND AND SURFACE COLORS
  // ============================================================

  static const Color backgroundLight = Color(0xFFF4F8F8);
  static const Color backgroundSoft = Color(0xFFF8FBFB);

  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFF7FAFA);
  static const Color surfaceMuted = Color(0xFFF1F5F5);
  static const Color surfaceTeal = Color(0xFFF0F9F8);

  // ============================================================
  // TEXT COLORS
  // ============================================================

  static const Color textDarkPrimary = Color(0xFF102A2C);
  static const Color textDarkSecondary = Color(0xFF526769);
  static const Color textMuted = Color(0xFF8A9C9E);
  static const Color textDisabled = Color(0xFFB4C0C1);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ============================================================
  // BORDER AND DIVIDER COLORS
  // ============================================================

  static const Color borderLight = Color(0xFFDCE8E8);
  static const Color borderMuted = Color(0xFFE8EFEF);
  static const Color borderFocused = primaryTeal;
  static const Color dividerColor = Color(0xFFE6EEEE);

  // ============================================================
  // STATUS COLORS
  // ============================================================

  static const Color successGreen = Color(0xFF0E9F6E);
  static const Color successDarkGreen = Color(0xFF047857);
  static const Color successBg = Color(0xFFECFDF5);

  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color warningDarkOrange = Color(0xFFB45309);
  static const Color warningBg = Color(0xFFFFF8E6);

  static const Color errorRed = Color(0xFFDC3545);
  static const Color errorDarkRed = Color(0xFFB91C1C);
  static const Color errorBg = Color(0xFFFFF1F2);

  static const Color infoBlue = Color(0xFF2563EB);
  static const Color infoDarkBlue = Color(0xFF1D4ED8);
  static const Color infoBg = Color(0xFFEFF6FF);

  // ============================================================
  // GRADIENTS
  // ============================================================

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      primaryDeepTeal,
      primaryTeal,
      accentCyan,
    ],
  );

  static const LinearGradient softGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      primarySoftTeal,
      surfaceWhite,
    ],
  );

  static const LinearGradient buttonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      primaryDarkTeal,
      primaryTeal,
      accentCyan,
    ],
  );

  // ============================================================
  // SHADOWS
  // ============================================================

  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: primaryDeepTeal.withValues(alpha: 0.06),
          blurRadius: 18,
          spreadRadius: 0,
          offset: const Offset(0, 7),
        ),
      ];

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: primaryDeepTeal.withValues(alpha: 0.08),
          blurRadius: 28,
          spreadRadius: 0,
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

  // ============================================================
  // COLOR SCHEME
  // ============================================================

  static final ColorScheme _lightColorScheme =
      ColorScheme.fromSeed(
        seedColor: primaryTeal,
        brightness: Brightness.light,
      ).copyWith(
        primary: primaryTeal,
        onPrimary: Colors.white,
        primaryContainer: primaryLightTeal,
        onPrimaryContainer: primaryDarkTeal,
        secondary: secondaryBlue,
        onSecondary: Colors.white,
        secondaryContainer: secondaryLightBlue,
        onSecondaryContainer: secondaryDarkBlue,
        tertiary: accentCyan,
        onTertiary: Colors.white,
        error: errorRed,
        onError: Colors.white,
        errorContainer: errorBg,
        onErrorContainer: errorDarkRed,
        surface: surfaceWhite,
        onSurface: textDarkPrimary,
        surfaceContainerLowest: surfaceWhite,
        surfaceContainerLow: backgroundSoft,
        surfaceContainer: surfaceLight,
        surfaceContainerHigh: surfaceMuted,
        outline: borderLight,
        outlineVariant: borderMuted,
        shadow: primaryDeepTeal,
        scrim: Colors.black,
      );

  // ============================================================
  // TEXT THEME
  // ============================================================

  static const TextTheme _textTheme = TextTheme(
    displayLarge: TextStyle(
      fontSize: 40,
      height: 1.1,
      fontWeight: FontWeight.w800,
      letterSpacing: -1.2,
      color: textDarkPrimary,
    ),
    displayMedium: TextStyle(
      fontSize: 34,
      height: 1.12,
      fontWeight: FontWeight.w800,
      letterSpacing: -1,
      color: textDarkPrimary,
    ),
    displaySmall: TextStyle(
      fontSize: 30,
      height: 1.15,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.8,
      color: textDarkPrimary,
    ),
    headlineLarge: TextStyle(
      fontSize: 28,
      height: 1.2,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.6,
      color: textDarkPrimary,
    ),
    headlineMedium: TextStyle(
      fontSize: 24,
      height: 1.25,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.4,
      color: textDarkPrimary,
    ),
    headlineSmall: TextStyle(
      fontSize: 21,
      height: 1.3,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
      color: textDarkPrimary,
    ),
    titleLarge: TextStyle(
      fontSize: 19,
      height: 1.35,
      fontWeight: FontWeight.w700,
      color: textDarkPrimary,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      height: 1.4,
      fontWeight: FontWeight.w700,
      color: textDarkPrimary,
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      height: 1.4,
      fontWeight: FontWeight.w600,
      color: textDarkPrimary,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      height: 1.5,
      fontWeight: FontWeight.w400,
      color: textDarkSecondary,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      height: 1.5,
      fontWeight: FontWeight.w400,
      color: textDarkSecondary,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      height: 1.45,
      fontWeight: FontWeight.w400,
      color: textMuted,
    ),
    labelLarge: TextStyle(
      fontSize: 15,
      height: 1.2,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.1,
    ),
    labelMedium: TextStyle(
      fontSize: 13,
      height: 1.2,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      height: 1.2,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
    ),
  );

  // ============================================================
  // LIGHT THEME
  // ============================================================

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: _lightColorScheme,
      primaryColor: primaryTeal,
      scaffoldBackgroundColor: backgroundLight,
      canvasColor: backgroundLight,
      disabledColor: textDisabled,
      dividerColor: dividerColor,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      textTheme: _textTheme,

      // ========================================================
      // APP BAR
      // ========================================================

      appBarTheme: const AppBarThemeData(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: surfaceWhite,
        foregroundColor: textDarkPrimary,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(
          color: textDarkPrimary,
          size: 23,
        ),
        actionsIconTheme: IconThemeData(
          color: textDarkPrimary,
          size: 23,
        ),
        titleTextStyle: TextStyle(
          color: textDarkPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),

      // ========================================================
      // CARD
      // ========================================================

      cardTheme: CardThemeData(
        color: surfaceWhite,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(
            color: borderMuted,
            width: 1,
          ),
        ),
      ),

      // ========================================================
      // INPUT FIELDS
      // ========================================================

      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: surfaceWhite,
        hoverColor: primarySoftTeal,
        focusColor: primarySoftTeal,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 17,
        ),
        prefixIconColor: textDarkSecondary,
        suffixIconColor: textDarkSecondary,
        labelStyle: const TextStyle(
          color: textDarkSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: const TextStyle(
          color: primaryTeal,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        hintStyle: const TextStyle(
          color: textMuted,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        helperStyle: const TextStyle(
          color: textMuted,
          fontSize: 12,
        ),
        errorStyle: const TextStyle(
          color: errorRed,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: borderLight,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: borderLight,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: primaryTeal,
            width: 1.7,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: errorRed,
            width: 1.3,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: errorRed,
            width: 1.7,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: borderMuted,
          ),
        ),
      ),

      // ========================================================
      // ELEVATED BUTTON
      // ========================================================

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          elevation: WidgetStateProperty.all(0),
          minimumSize: WidgetStateProperty.all(
            const Size(double.infinity, 54),
          ),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(
              horizontal: 22,
              vertical: 16,
            ),
          ),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) {
              if (states.contains(WidgetState.disabled)) {
                return primaryTeal.withValues(alpha: 0.42);
              }

              if (states.contains(WidgetState.pressed)) {
                return primaryDarkTeal;
              }

              return primaryTeal;
            },
          ),
          foregroundColor: WidgetStateProperty.all(Colors.white),
          overlayColor: WidgetStateProperty.all(
            Colors.white.withValues(alpha: 0.12),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          textStyle: WidgetStateProperty.all(
            const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            ),
          ),
        ),
      ),

      // ========================================================
      // FILLED BUTTON
      // ========================================================

      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          elevation: WidgetStateProperty.all(0),
          minimumSize: WidgetStateProperty.all(
            const Size(double.infinity, 54),
          ),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(
              horizontal: 22,
              vertical: 16,
            ),
          ),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) {
              if (states.contains(WidgetState.disabled)) {
                return primaryTeal.withValues(alpha: 0.42);
              }

              if (states.contains(WidgetState.pressed)) {
                return primaryDarkTeal;
              }

              return primaryTeal;
            },
          ),
          foregroundColor: WidgetStateProperty.all(Colors.white),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          textStyle: WidgetStateProperty.all(
            const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),

      // ========================================================
      // OUTLINED BUTTON
      // ========================================================

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          elevation: WidgetStateProperty.all(0),
          minimumSize: WidgetStateProperty.all(
            const Size(double.infinity, 54),
          ),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(
              horizontal: 22,
              vertical: 15,
            ),
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) {
              if (states.contains(WidgetState.disabled)) {
                return textDisabled;
              }

              return primaryTeal;
            },
          ),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) {
              if (states.contains(WidgetState.pressed)) {
                return primaryLightTeal;
              }

              return Colors.transparent;
            },
          ),
          side: WidgetStateProperty.resolveWith(
            (states) {
              if (states.contains(WidgetState.disabled)) {
                return const BorderSide(
                  color: borderMuted,
                  width: 1.2,
                );
              }

              return const BorderSide(
                color: primaryTeal,
                width: 1.4,
              );
            },
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          textStyle: WidgetStateProperty.all(
            const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),

      // ========================================================
      // TEXT BUTTON
      // ========================================================

      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) {
              if (states.contains(WidgetState.disabled)) {
                return textDisabled;
              }

              if (states.contains(WidgetState.pressed)) {
                return primaryDarkTeal;
              }

              return primaryTeal;
            },
          ),
          overlayColor: WidgetStateProperty.all(
            primaryTeal.withValues(alpha: 0.08),
          ),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          textStyle: WidgetStateProperty.all(
            const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),

      // ========================================================
      // ICON BUTTON
      // ========================================================

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: textDarkPrimary,
          backgroundColor: Colors.transparent,
          disabledForegroundColor: textDisabled,
          hoverColor: primaryLightTeal,
          focusColor: primaryLightTeal,
          highlightColor: primaryLightTeal,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // ========================================================
      // CHECKBOX
      // ========================================================

      checkboxTheme: CheckboxThemeData(
        visualDensity: VisualDensity.compact,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
        ),
        side: const BorderSide(
          color: textMuted,
          width: 1.4,
        ),
        fillColor: WidgetStateProperty.resolveWith(
          (states) {
            if (states.contains(WidgetState.selected)) {
              return primaryTeal;
            }

            if (states.contains(WidgetState.disabled)) {
              return borderMuted;
            }

            return Colors.transparent;
          },
        ),
        checkColor: WidgetStateProperty.all(Colors.white),
        overlayColor: WidgetStateProperty.all(
          primaryTeal.withValues(alpha: 0.08),
        ),
      ),

      // ========================================================
      // RADIO
      // ========================================================

      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) {
            if (states.contains(WidgetState.selected)) {
              return primaryTeal;
            }

            if (states.contains(WidgetState.disabled)) {
              return textDisabled;
            }

            return textMuted;
          },
        ),
        overlayColor: WidgetStateProperty.all(
          primaryTeal.withValues(alpha: 0.08),
        ),
      ),

      // ========================================================
      // SWITCH
      // ========================================================

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.white;
            }

            if (states.contains(WidgetState.disabled)) {
              return textDisabled;
            }

            return surfaceWhite;
          },
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) {
            if (states.contains(WidgetState.selected)) {
              return primaryTeal;
            }

            if (states.contains(WidgetState.disabled)) {
              return borderMuted;
            }

            return textMuted.withValues(alpha: 0.45);
          },
        ),
        trackOutlineColor: WidgetStateProperty.all(
          Colors.transparent,
        ),
      ),

      // ========================================================
      // PROGRESS INDICATOR
      // ========================================================

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryTeal,
        linearTrackColor: primaryLightTeal,
        circularTrackColor: primaryLightTeal,
      ),

      // ========================================================
      // SNACKBAR
      // ========================================================

      snackBarTheme: SnackBarThemeData(
        elevation: 8,
        behavior: SnackBarBehavior.floating,
        backgroundColor: primaryDeepTeal,
        actionTextColor: accentMint,
        disabledActionTextColor: textDisabled,
        insetPadding: const EdgeInsets.all(16),
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          height: 1.4,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),

      // ========================================================
      // DIALOG
      // ========================================================

      dialogTheme: DialogThemeData(
        elevation: 0,
        backgroundColor: surfaceWhite,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 24,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        titleTextStyle: const TextStyle(
          color: textDarkPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
        contentTextStyle: const TextStyle(
          color: textDarkSecondary,
          fontSize: 14,
          height: 1.5,
        ),
      ),

      // ========================================================
      // BOTTOM SHEET
      // ========================================================

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceWhite,
        modalBackgroundColor: surfaceWhite,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalElevation: 0,
        showDragHandle: true,
        dragHandleColor: borderLight,
        dragHandleSize: Size(44, 5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(28),
          ),
        ),
      ),

      // ========================================================
      // DIVIDER
      // ========================================================

      dividerTheme: const DividerThemeData(
        color: dividerColor,
        thickness: 1,
        space: 1,
      ),

      // ========================================================
      // LIST TILE
      // ========================================================

      listTileTheme: const ListTileThemeData(
        iconColor: textDarkSecondary,
        textColor: textDarkPrimary,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 4,
        ),
        titleTextStyle: TextStyle(
          color: textDarkPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        subtitleTextStyle: TextStyle(
          color: textDarkSecondary,
          fontSize: 12,
          height: 1.4,
        ),
      ),

      // ========================================================
      // NAVIGATION BAR
      // ========================================================

      navigationBarTheme: NavigationBarThemeData(
        height: 70,
        elevation: 0,
        backgroundColor: surfaceWhite,
        surfaceTintColor: Colors.transparent,
        indicatorColor: primaryLightTeal,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) {
            return IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? primaryTeal
                  : textMuted,
              size: 24,
            );
          },
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) {
            return TextStyle(
              color: states.contains(WidgetState.selected)
                  ? primaryTeal
                  : textMuted,
              fontSize: 11,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w700
                  : FontWeight.w500,
            );
          },
        ),
      ),

      // ========================================================
      // BOTTOM NAVIGATION BAR
      // ========================================================

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        elevation: 8,
        backgroundColor: surfaceWhite,
        selectedItemColor: primaryTeal,
        unselectedItemColor: textMuted,
        selectedLabelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),

      // ========================================================
      // TAB BAR
      // ========================================================

      tabBarTheme: const TabBarThemeData(
        indicatorColor: primaryTeal,
        dividerColor: borderMuted,
        labelColor: primaryTeal,
        unselectedLabelColor: textMuted,
        labelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),

      // ========================================================
      // TEXT SELECTION
      // ========================================================

      textSelectionTheme: TextSelectionThemeData(
        cursorColor: primaryTeal,
        selectionColor: primaryTeal.withValues(alpha: 0.22),
        selectionHandleColor: primaryTeal,
      ),

      // ========================================================
      // TOOLTIP
      // ========================================================

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: primaryDeepTeal,
          borderRadius: BorderRadius.circular(10),
        ),
        textStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
      ),
    );
  }
}