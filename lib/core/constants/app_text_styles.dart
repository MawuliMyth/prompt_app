import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  AppTextStyles._();

  // Display: Poppins Bold 32sp, letterSpacing -0.5
  static final TextStyle display = GoogleFonts.poppins(
    fontWeight: FontWeight.bold,
    fontSize: 32,
    letterSpacing: -0.5,
  );

  // Heading: Poppins SemiBold 24sp, letterSpacing -0.3
  static final TextStyle heading = GoogleFonts.poppins(
    fontWeight: FontWeight.w600,
    fontSize: 24,
    letterSpacing: -0.3,
  );

  // Title: Poppins SemiBold 18sp
  static final TextStyle title = GoogleFonts.poppins(
    fontWeight: FontWeight.w600,
    fontSize: 18,
  );

  // Subtitle: Poppins Medium 16sp
  static final TextStyle subtitle = GoogleFonts.poppins(
    fontWeight: FontWeight.w500,
    fontSize: 16,
  );

  // Body: Poppins Regular 14sp, height 1.5
  static final TextStyle body = GoogleFonts.poppins(
    fontWeight: FontWeight.w400,
    fontSize: 14,
    height: 1.5,
  );

  // Caption: Poppins Regular 12sp, color 60% opacity
  static final TextStyle caption = GoogleFonts.poppins(
    fontWeight: FontWeight.w400,
    fontSize: 12,
  );

  // Button: Poppins SemiBold 15sp, letterSpacing 0.3
  static final TextStyle button = GoogleFonts.poppins(
    fontWeight: FontWeight.w600,
    fontSize: 15,
    letterSpacing: 0.3,
  );

  // Legacy aliases for backward compatibility
  static final TextStyle headingLarge = display;
  static final TextStyle headingMedium = heading;
  static final TextStyle headingSmall = title;
}
