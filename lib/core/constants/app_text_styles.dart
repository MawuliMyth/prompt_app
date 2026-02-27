import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  // Heading Large: Poppins Bold, 28sp
  static final TextStyle headingLarge = GoogleFonts.poppins(
    fontWeight: FontWeight.bold,
    fontSize: 28,
  );

  // Heading Medium: Poppins SemiBold, 22sp
  static final TextStyle headingMedium = GoogleFonts.poppins(
    fontWeight: FontWeight.w600,
    fontSize: 22,
  );

  // Heading Small: Poppins SemiBold, 18sp
  static final TextStyle headingSmall = GoogleFonts.poppins(
    fontWeight: FontWeight.w600,
    fontSize: 18,
  );

  // Body: Poppins Regular, 14sp
  static final TextStyle body = GoogleFonts.poppins(
    fontWeight: FontWeight.w400,
    fontSize: 14,
  );

  // Caption: Poppins Regular, 12sp
  static final TextStyle caption = GoogleFonts.poppins(
    fontWeight: FontWeight.w400,
    fontSize: 12,
  );

  // Button: Poppins SemiBold, 16sp
  static final TextStyle button = GoogleFonts.poppins(
    fontWeight: FontWeight.w600,
    fontSize: 16,
  );
}
