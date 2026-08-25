import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The single typography scale used throughout the app.
///
/// Prefer the semantic Material names for new UI. The shorter aliases at the
/// bottom keep existing screens readable while pointing to the same scale.
class AppTextStyles {
  AppTextStyles._();

  static final TextTheme textTheme = GoogleFonts.manropeTextTheme(
    const TextTheme(
      displayLarge: TextStyle(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.4,
        height: 1.1,
      ),
      displayMedium: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -1,
        height: 1.15,
      ),
      displaySmall: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
        height: 1.2,
      ),
      headlineLarge: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        height: 1.2,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        height: 1.25,
      ),
      headlineSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        height: 1.3,
      ),
      titleLarge: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        height: 1.35,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.1,
        height: 1.4,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.4,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
        height: 1.4,
      ),
      labelLarge: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        height: 1.35,
      ),
      labelMedium: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        height: 1.35,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
        height: 1.35,
      ),
    ),
  );

  static final TextStyle display = textTheme.displayLarge!;
  static final TextStyle heading = textTheme.headlineMedium!;
  static final TextStyle title = textTheme.titleLarge!;
  static final TextStyle subtitle = textTheme.titleMedium!;
  static final TextStyle body = textTheme.bodyMedium!;
  static final TextStyle caption = textTheme.bodySmall!;
  static final TextStyle button = textTheme.labelLarge!;
  static final TextStyle heroGreeting = textTheme.displayLarge!;
  static final TextStyle sectionLabel = textTheme.labelMedium!;
  static final TextStyle navigationLabel = textTheme.labelSmall!;
  static final TextStyle badge = textTheme.labelSmall!.copyWith(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.4,
  );

  // Legacy aliases kept while screens migrate to semantic Material names.
  static final TextStyle headingLarge = textTheme.displayLarge!;
  static final TextStyle headingMedium = textTheme.headlineMedium!;
  static final TextStyle headingSmall = textTheme.titleLarge!;
}
