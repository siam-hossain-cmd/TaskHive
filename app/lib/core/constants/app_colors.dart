import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ══════════════════════════════════════════════════════
  //  BRIGHTNESS CONTROL
  //  Set once in app.dart before the widget tree builds.
  // ══════════════════════════════════════════════════════
  static Brightness _brightness = Brightness.light;

  static void updateBrightness(Brightness b) => _brightness = b;

  static bool get isDark => _brightness == Brightness.dark;

  // ══════════════════════════════════════════════════════
  //  RAW CONSTANTS  (used by AppTheme for ThemeData defs)
  // ══════════════════════════════════════════════════════

  // ── Light ──
  static const lightBg = Color(0xFFF6F8FA);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightBorder = Colors.transparent;
  static const lightTextPrimary = Color(0xFF1A1D1E);
  static const lightTextSecondary = Color(0xFF8A94A6);
  static const lightTextTertiary = Color(0xFFB0B7C3);

  // ── Dark ──
  static const darkBg = Color(0xFF0F1117);
  static const darkSurface = Color(0xFF1A1D2E);
  static const darkCard = Color(0xFF1E2235);
  static const darkBorder = Color(0xFF2A2E45);
  static const darkTextPrimary = Color(0xFFF1F5F9);
  static const darkTextSecondary = Color(0xFF94A3B8);
  static const darkTextTertiary = Color(0xFF64748B);

  // ══════════════════════════════════════════════════════
  //  THEME-AWARE GETTERS  (auto-switch with brightness)
  // ══════════════════════════════════════════════════════
  static Color get bgColor => isDark ? darkBg : lightBg;
  static Color get surfaceColor => isDark ? darkSurface : lightSurface;
  static Color get textPrimary => isDark ? darkTextPrimary : lightTextPrimary;
  static Color get textSecondary => isDark ? darkTextSecondary : lightTextSecondary;

  // ── Accent Colors (same in both modes) ──
  static const primary = Color(0xFF5D5FEF);
  static const secondary = Color(0xFFA5A6F6);
  static const accent = Color(0xFF4EE1C1);

  // ── Priority Colors ──
  static const priorityHighText = Color(0xFFF05252);
  static Color get priorityHighBg =>
      isDark ? const Color(0xFF3C1618) : const Color(0xFFFDE8E8);
  static const priorityMediumText = Color(0xFFF59E0B);
  static Color get priorityMediumBg =>
      isDark ? const Color(0xFF3C2E10) : const Color(0xFFFEF3C7);
  static const priorityLowText = Color(0xFF10B981);
  static Color get priorityLowBg =>
      isDark ? const Color(0xFF0F2D20) : const Color(0xFFD1FAE5);

  // ── Vibrant Glass Gradients ──
  static const gradientPurpleBlue = LinearGradient(
    colors: [Color(0xFFE0C3FC), Color(0xFF8EC5FC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientPinkOrange = LinearGradient(
    colors: [Color(0xFFFFD1FF), Color(0xFFFAD0C4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientTealBlue = LinearGradient(
    colors: [Color(0xFF8FD3F4), Color(0xFF84FAB0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientIndigo = LinearGradient(
    colors: [Color(0xFFC2E9FB), Color(0xFFA1C4FD)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient getGradientTheme(int index) {
    const gradients = [
      gradientPurpleBlue,
      gradientPinkOrange,
      gradientTealBlue,
      gradientIndigo,
    ];
    return gradients[index % gradients.length];
  }

  // ── Status Colors (same in both modes) ──
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF97316);
  static const error = Color(0xFFEF4444);
  static const info = Color(0xFF3B82F6);

  // ── Gradient aliases ──
  static const groupGradient = gradientPurpleBlue;
  static const primaryGradient = gradientIndigo;
  static const accentGradient = gradientTealBlue;
  static const warmGradient = gradientPinkOrange;
  static const coolGradient = gradientTealBlue;

  // ── Priority aliases ──
  static const priorityHigh = priorityHighText;
  static const priorityMedium = priorityMediumText;
  static const priorityLow = priorityLowText;
}
