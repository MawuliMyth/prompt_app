import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../utils/platform_utils.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_constants.dart';
import 'adaptive_widgets.dart';
import '../../screens/paywall/paywall_screen.dart';

class DailyLimitSheet {
  static void show(BuildContext context) {
    if (PlatformUtils.useCupertino(context)) {
      showCupertinoModalPopup<void>(
        context: context,
        builder: (context) => const Material(
          color: Colors.transparent,
          child: _DailyLimitContent(),
        ),
      );
      return;
    }

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
          const Divider(color: AppColors.borderLight, height: 1),

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
            child: AdaptiveButton(
              label: 'Upgrade to Premium',
              icon: Icons.workspace_premium_outlined,
              onPressed: () {
                Navigator.pop(context);
                PlatformUtils.navigateTo(context, const PaywallScreen());
              },
            ),
          ),

          const SizedBox(height: AppConstants.spacing12),

          SizedBox(
            width: double.infinity,
            child: AdaptiveButton(
              label: 'Come back tomorrow',
              filled: false,
              foregroundColor: AppColors.textSecondaryLight,
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // Bottom padding for safe area
          SizedBox(
            height:
                MediaQuery.of(context).padding.bottom + AppConstants.spacing8,
          ),
        ],
      ),
    );
  }
}
