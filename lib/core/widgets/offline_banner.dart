import 'package:flutter/material.dart';
import '../constants/app_text_styles.dart';

/// A compact banner that displays when the app is offline
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, this.onRetry});
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Previously these were hardcoded light-orange colors with no dark
    // variant, so the banner looked the same regardless of theme -
    // inconsistent with the "layered charcoal surfaces" dark-mode
    // direction used everywhere else in the app.
    final backgroundColor = isDark
        ? const Color(0xFF4A2E12) // muted dark amber surface
        : const Color(0xFFFFE0B2); // orange.shade100
    final iconAndAccentColor = isDark
        ? const Color(0xFFFFB74D) // orange.shade300, readable on dark amber
        : const Color(0xFFE65100); // orange.shade800
    final textColor = isDark
        ? const Color(0xFFFFCC80) // orange.shade200
        : const Color(0xFFBF360C); // orange.shade900

    return Material(
      color: backgroundColor,
      child: SafeArea(
        bottom: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi_off, color: iconAndAccentColor, size: 18),
              const SizedBox(width: 8),
              Text(
                'You are offline',
                style: AppTextStyles.sectionLabel.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (onRetry != null) ...[
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: onRetry,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: iconAndAccentColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Retry',
                      style: AppTextStyles.caption.copyWith(
                        color: isDark ? Colors.black : Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
