import 'package:flutter/material.dart';

/// Paleta de colores premium para Chazin Food
class AppColors {
  AppColors._();

  // ─── Brand Primary: Crimson/Coral Red ───
  static const Color primary = Color(0xFFE25858);
  static const Color primaryLight = Color(0xFFFA7D7D);
  static const Color primaryDark = Color(0xFFC73E3E);
  static const Color primarySurface = Color(0xFFFFF1F1);

  // ─── Brand Accent: Gold/Warm Orange ───
  static const Color accent = Color(0xFFFFB347);
  static const Color accentLight = Color(0xFFFFCC80);
  static const Color accentDark = Color(0xFFE09A30);

  // ─── Backgrounds ───
  static const Color backgroundLight = Color(0xFFFCF9F9);
  static const Color backgroundDark = Color(0xFF0F0F1A);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1A1A2E);
  static const Color cardDark = Color(0xFF222240);

  // ─── Text ───
  static const Color textPrimaryLight = Color(0xFF2D2E33);
  static const Color textSecondaryLight = Color(0xFF7E818C);
  static const Color textPrimaryDark = Color(0xFFF1F1F6);
  static const Color textSecondaryDark = Color(0xFF9CA3AF);

  // ─── Semantic ───
  static const Color success = Color(0xFF2EBF6C);
  static const Color successLight = Color(0xFFE8F8EE);
  static const Color warning = Color(0xFFFBBF24);
  static const Color warningLight = Color(0xFFFEF9C3);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);

  // ─── Neutrals ───
  static const Color grey50 = Color(0xFFF9FAFB);
  static const Color grey100 = Color(0xFFF3F4F6);
  static const Color grey200 = Color(0xFFE5E7EB);
  static const Color grey300 = Color(0xFFD1D5DB);
  static const Color grey400 = Color(0xFF9CA3AF);
  static const Color grey500 = Color(0xFF6B7280);
  static const Color grey600 = Color(0xFF4B5563);
  static const Color grey700 = Color(0xFF374151);
  static const Color grey800 = Color(0xFF1F2937);
  static const Color grey900 = Color(0xFF111827);

  // ─── Gradients ───
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFFFA7D7D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFE25858), Color(0xFFFA7D7D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
