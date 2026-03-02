import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_constants.dart';
import '../../screens/paywall/paywall_screen.dart';

class DailyLimitSheet {
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
      padding: const EdgeInsets.all(AppConstants.spacing24),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusBottomSheet),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: AppConstants.spacing24),
            decoration: BoxDecoration(
              color: AppColors.dividerLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.hourglass_empty,
              size: 40,
              color: AppColors.primaryLight,
            ),
          ),

          const SizedBox(height: AppConstants.spacing24),

          // Title
          Text(
            'Daily Limit Reached',
            style: AppTextStyles.title.copyWith(
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppConstants.spacing8),

          // Subtitle
          Text(
            'You have used all 10 free prompts today. Your limit resets at midnight.',
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppConstants.spacing24),

          // Divider
          Divider(color: AppColors.borderLight, height: 1),

          const SizedBox(height: AppConstants.spacing24),

          // Upgrade section
          Text(
            'Get unlimited prompts every day',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),

          const SizedBox(height: AppConstants.spacing12),

          // Upgrade button
          SizedBox(
            width: double.infinity,
            height: AppConstants.buttonHeight,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const PaywallScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryLight,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusButton),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.workspace_premium_outlined, size: 20),
                  const SizedBox(width: AppConstants.spacing8),
                  Text(
                    'Upgrade to Premium',
                    style: AppTextStyles.button.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppConstants.spacing12),

          // Come back tomorrow button
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Come back tomorrow',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
          ),

          // Bottom padding for safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom + AppConstants.spacing8),
        ],
      ),
    );
  }
}
