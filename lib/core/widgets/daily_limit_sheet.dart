import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../../screens/paywall/paywall_screen.dart';

/// A bottom sheet that appears when a free user reaches their daily prompt limit
class DailyLimitSheet {
  /// Shows the daily limit reached bottom sheet
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _DailyLimitContent(),
    );
  }
}

class _DailyLimitContent extends StatelessWidget {
  const _DailyLimitContent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: AppColors.dividerLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Limit icon
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('⏰', style: TextStyle(fontSize: 32)),
            ),
          ),

          const SizedBox(height: 20),

          // Title
          Text(
            'Daily Limit Reached',
            style: AppTextStyles.headingMedium.copyWith(
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          // Description
          Text(
            "You've used all your free prompts for today. Upgrade to Premium for unlimited prompts!",
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // Upgrade button
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const PaywallScreen(),
                ),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Upgrade to Premium',
                textAlign: TextAlign.center,
                style: AppTextStyles.button.copyWith(color: Colors.white),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Maybe later button
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Come Back Tomorrow',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
          ),

          // Bottom padding for safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }
}
