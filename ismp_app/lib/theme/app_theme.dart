import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Core palette ──────────────────────────────────────────────────
  static const Color background = Color(0xFF0F0920);
  static const Color surface = Color(0xFF1F1635);
  static const Color primary = Color(0xFFD9278D);
  static const Color secondaryAccent = Color(0xFFE0B0FF);
  static const Color mutedText = Color(0xFFD6A3C4);
  static const Color error = Color(0xFFFF2450);
  static const Color warning = Color(0xFFFFB020);
  static const Color badgeBg = Color(0xFF3A3A4A);
  static const Color success = Color(0xFF10B981);

  // ── Common white/grey helpers ─────────────────────────────────────
  static Color white(double opacity) => Colors.white.withValues(alpha: opacity);
  static Color black(double opacity) => Colors.black.withValues(alpha: opacity);
  static Color primaryWith(double opacity) => primary.withValues(alpha: opacity);
  static Color errorWith(double opacity) => error.withValues(alpha: opacity);
  static Color secondaryWith(double opacity) => secondaryAccent.withValues(alpha: opacity);
  static Color surfaceWith(double opacity) => surface.withValues(alpha: opacity);
}

class AppTheme {
  AppTheme._();

  // ── Shared background gradient ────────────────────────────────────
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1F1635),
      Color(0xFF0F0920),
      Color(0xFF1F1635),
      Color(0xFF0F0920),
    ],
    stops: [0.0, 0.4, 0.7, 1.0],
  );

  static const LinearGradient statCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1F1635), Color(0xFF0F0920)],
  );

  // ── Selected day gradient ─────────────────────────────────────────
  static const LinearGradient selectedDayGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD9278D), Color(0xFFE0B0FF)],
  );

  // ── Card gradient overlay for moments ─────────────────────────────
  static LinearGradient momentOverlayGradient = LinearGradient(
    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ── Carousel card overlay gradient ────────────────────────────────
  static LinearGradient carouselOverlayGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Colors.black.withValues(alpha: 0.85),
      Colors.black.withValues(alpha: 0.3),
      Colors.transparent,
    ],
    stops: const [0.0, 0.5, 1.0],
  );

  // ── Avatar ring gradient ──────────────────────────────────────────
  static LinearGradient avatarRingGradient = LinearGradient(
    colors: [AppColors.primary, AppColors.secondaryAccent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient avatarRingFadedGradient = LinearGradient(
    colors: [AppColors.primary, AppColors.primaryWith(0.2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── ThemeData for MaterialApp ─────────────────────────────────────
  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        primaryColor: AppColors.primary,
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: Colors.grey,
        ),
      );

  // ── Blog tag colors ───────────────────────────────────────────────
  static Color blogTagColor(String tagName) => AppColors.secondaryAccent;
  static Color blogTagBgColor(String tagName) => AppColors.primaryWith(0.3);

  // ── Event dot colors ──────────────────────────────────────────────
  static Color eventDotColor(String type) =>
      type == 'C' ? AppColors.primary : AppColors.mutedText;
}
