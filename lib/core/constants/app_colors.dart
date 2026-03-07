import 'package:flutter/material.dart';

class AppColors {
  // Light Mode
  static const Color primaryLight = Color(0xFF7565FF);
  static const Color primaryDarkLight = Color(0xFF4F46E5);
  static const Color accentLight = Color(0xFF38BDF8);
  static const Color backgroundLight = Color(0xFFF3F4F8);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFEDEEF5);
  static const Color textPrimaryLight = Color(0xFF15172B);
  static const Color textSecondaryLight = Color(0xFF767B91);
  static const Color dividerLight = Color(0xFFE6E8F0);
  static const Color borderLight = Color(0xFFDFE3EE);
  static const Color floatingSurfaceLight = Color(0xFF111216);
  static const Color floatingOnLight = Color(0xFFFFFFFF);

  // Dark Mode
  static const Color primaryDark = Color(0xFF8B7CFF);
  static const Color primaryDarkDark = Color(0xFF5B53D6);
  static const Color accentDark = Color(0xFF3DD9FF);
  static const Color backgroundDark = Color(0xFF0E1018);
  static const Color surfaceDark = Color(0xFF171A24);
  static const Color surfaceVariantDark = Color(0xFF202431);
  static const Color textPrimaryDark = Color(0xFFF7F8FC);
  static const Color textSecondaryDark = Color(0xFF9BA2B8);
  static const Color dividerDark = Color(0xFF252A39);
  static const Color borderDark = Color(0xFF2A3041);
  static const Color floatingSurfaceDark = Color(0xFF080A0F);
  static const Color floatingOnDark = Color(0xFFF7F8FC);

  // Semantic Colors
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryLight, accentLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF181B26), Color(0xFF0D0F16)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient premiumGradient = LinearGradient(
    colors: [Color(0xFF7C6CFF), Color(0xFF27C5FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient voiceGradient = LinearGradient(
    colors: [Color(0xFF8A5CFF), Color(0xFF08D3FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Card Shadows
  static List<BoxShadow> cardShadowLight = [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.08),
      blurRadius: 32,
      offset: const Offset(0, 10),
    ),
  ];

  static List<BoxShadow> cardShadowDark = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.28),
      blurRadius: 28,
      offset: const Offset(0, 12),
    ),
  ];

  static const Color featureLime = Color(0xFFC7F36A);
  static const Color featureMint = Color(0xFF71D2AE);
  static const Color featureBlush = Color(0xFFF0C0D8);
  static const Color featureLavender = Color(0xFFDCCEFF);

  // Category Colors
  static const Color categoryGeneral = Color(0xFF7565FF);
  static const Color categoryImageGeneration = Color(0xFFF472B6);
  static const Color categoryCoding = Color(0xFF34D399);
  static const Color categoryWriting = Color(0xFFFBBF24);
  static const Color categoryBusiness = Color(0xFF38BDF8);
}
