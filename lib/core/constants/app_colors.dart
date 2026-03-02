import 'package:flutter/material.dart';

class AppColors {
  // Light Mode
  static const Color primaryLight = Color(0xFFE53935);
  static const Color primaryDarkLight = Color(0xFFB71C1C);
  static const Color accentLight = Color(0xFFFF5252);
  static const Color backgroundLight = Color(0xFFFAFAFA);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFF5F5F5);
  static const Color textPrimaryLight = Color(0xFF1A1A2E);
  static const Color textSecondaryLight = Color(0xFF6B7280);
  static const Color dividerLight = Color(0xFFF0F0F0);
  static const Color borderLight = Color(0xFFF0F0F0);

  // Dark Mode
  static const Color primaryDark = Color(0xFFE53935);
  static const Color primaryDarkDark = Color(0xFFB71C1C);
  static const Color accentDark = Color(0xFFFF5252);
  static const Color backgroundDark = Color(0xFF0F0F0F);
  static const Color surfaceDark = Color(0xFF1A1A1A);
  static const Color surfaceVariantDark = Color(0xFF242424);
  static const Color textPrimaryDark = Color(0xFFF5F5F5);
  static const Color textSecondaryDark = Color(0xFF9CA3AF);
  static const Color dividerDark = Color(0xFF2A2A2A);
  static const Color borderDark = Color(0xFF2A2A2A);

  // Semantic Colors
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryLight, primaryDarkLight],
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF1A1A2E), Color(0xFF0F0F0F)],
  );

  // Card Shadows
  static List<BoxShadow> cardShadowLight = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 20,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> cardShadowDark = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.3),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ];

  // Category Colors (for icons)
  static const Color categoryGeneral = Color(0xFF6366F1);
  static const Color categoryImageGeneration = Color(0xFFEC4899);
  static const Color categoryCoding = Color(0xFF14B8A6);
  static const Color categoryWriting = Color(0xFFF59E0B);
  static const Color categoryBusiness = Color(0xFF3B82F6);
}
