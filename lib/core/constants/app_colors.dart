import 'package:flutter/material.dart';

class AppColors {
  // Light Mode
  static const Color primaryLight = Color(0xFFE53935);
  static const Color primaryDarkLight = Color(0xFFB71C1C);
  static const Color accentLight = Color(0xFFFF5252);
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFF5F5F5);
  static const Color textPrimaryLight = Color(0xFF1A1A1A);
  static const Color textSecondaryLight = Color(0xFF757575);
  static const Color dividerLight = Color(0xFFE0E0E0);

  // Dark Mode
  static const Color primaryDark = Color(0xFFE53935);
  static const Color primaryDarkDark = Color(0xFFB71C1C);
  static const Color accentDark = Color(0xFFFF5252);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFAAAAAA);
  static const Color dividerDark = Color(0xFF2C2C2C);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryLight, primaryDarkLight],
  );
}
