import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Base Backgrounds & Surfaces ──
  static const bgColor = Color(0xFFF6F8FA); // Very soft gray-white background
  static const surfaceColor = Color(0xFFFFFFFF); // Pure white cards

  // ── Typography ──
  static const textPrimary = Color(0xFF1A1D1E); // Deep slate/almost black
  static const textSecondary = Color(0xFF8A94A6); // Soft metallic gray

  // ── Accent Colors ──
  static const primary = Color(0xFF5D5FEF); // Vibrant Purple/Indigo
  static const secondary = Color(0xFFA5A6F6); // Soft Purple
  static const accent = Color(0xFF4EE1C1); // Vibrant Teal/Mint

  // ── Priority Colors (Pastel + Vibrant text) ──
  static const priorityHighText = Color(0xFFF05252);
  static const priorityHighBg = Color(0xFFFDE8E8);
  static const priorityMediumText = Color(0xFFF59E0B);
  static const priorityMediumBg = Color(0xFFFEF3C7);
  static const priorityLowText = Color(0xFF10B981);
  static const priorityLowBg = Color(0xFFD1FAE5);

  // ── Vibrant Glass Gradients ──
  // Gradient 1: Soft Purple to Blue
  static const gradientPurpleBlue = LinearGradient(
    colors: [Color(0xFFE0C3FC), Color(0xFF8EC5FC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Gradient 2: Soft Pink to Orange
  static const gradientPinkOrange = LinearGradient(
    colors: [Color(0xFFFFD1FF), Color(0xFFFAD0C4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Gradient 3: Soft Teal to Blue
  static const gradientTealBlue = LinearGradient(
    colors: [Color(0xFF8FD3F4), Color(0xFF84FAB0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Gradient 4: Soft Blue to Indigo
  static const gradientIndigo = LinearGradient(
    colors: [Color(0xFFC2E9FB), Color(0xFFA1C4FD)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Helper to get a cyclic gradient based on index
  static LinearGradient getGradientTheme(int index) {
    const gradients = [
      gradientPurpleBlue,
      gradientPinkOrange,
      gradientTealBlue,
      gradientIndigo,
    ];
    return gradients[index % gradients.length];
  }

  // ── Legacy (Kept for compatibility with untouched files) ──
  static const darkBg = Color(0xFF020617);
  static const darkSurface = Color(0xFF0F172A);
  static const darkCard = Color(0xFF0F172A);
  static const darkBorder = Color(0xFF1E293B);
  static const darkTextPrimary = Color(0xFFF8FAFC);
  static const darkTextSecondary = Color(0xFF94A3B8);
  static const darkTextTertiary = Color(0xFF64748B);

  static const lightBg = bgColor;
  static const lightSurface = surfaceColor;
  static const lightCard = surfaceColor;
  static const lightBorder = Colors.transparent;
  static const lightTextPrimary = textPrimary;
  static const lightTextSecondary = textSecondary;
  static const lightTextTertiary = Color(0xFFB0B7C3);

  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF97316);
  static const error = Color(0xFFEF4444);
  static const info = Color(0xFF3B82F6);

  static const groupGradient = gradientPurpleBlue;
  static const primaryGradient = gradientIndigo;
  static const accentGradient = gradientTealBlue;
  static const warmGradient = gradientPinkOrange;
  static const coolGradient = gradientTealBlue;

  static const priorityHigh = priorityHighText;
  static const priorityMedium = priorityMediumText;
  static const priorityLow = priorityLowText;
}
