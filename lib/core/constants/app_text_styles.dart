import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  AppTextStyles._();

  static final TextStyle display = GoogleFonts.manrope(
    fontWeight: FontWeight.w700,
    fontSize: 40,
    letterSpacing: -1.4,
    height: 1.02,
  );

  static final TextStyle heading = GoogleFonts.manrope(
    fontWeight: FontWeight.w600,
    fontSize: 20,
    letterSpacing: -0.5,
    height: 1.1,
  );

  static final TextStyle title = GoogleFonts.manrope(
    fontWeight: FontWeight.w600,
    fontSize: 17,
    letterSpacing: -0.2,
  );

  static final TextStyle subtitle = GoogleFonts.manrope(
    fontWeight: FontWeight.w500,
    fontSize: 16,
    letterSpacing: -0.2,
  );

  static final TextStyle body = GoogleFonts.manrope(
    fontWeight: FontWeight.w400,
    fontSize: 14,
    height: 1.45,
  );

  static final TextStyle caption = GoogleFonts.manrope(
    fontWeight: FontWeight.w400,
    fontSize: 12,
    letterSpacing: 0.1,
  );

  static final TextStyle button = GoogleFonts.manrope(
    fontWeight: FontWeight.w600,
    fontSize: 15,
    letterSpacing: 0.3,
  );

  static final TextStyle heroGreeting = GoogleFonts.manrope(
    fontWeight: FontWeight.w700,
    fontSize: 40,
    letterSpacing: -1.3,
    height: 1.04,
  );

  static final TextStyle sectionLabel = GoogleFonts.manrope(
    fontWeight: FontWeight.w600,
    fontSize: 13,
    letterSpacing: 0.2,
  );

  // Legacy aliases for backward compatibility
  static final TextStyle headingLarge = display;
  static final TextStyle headingMedium = heading;
  static final TextStyle headingSmall = title;
}
