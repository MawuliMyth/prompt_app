import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../utils/platform_utils.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_constants.dart';
import 'adaptive_widgets.dart';
import '../../screens/paywall/paywall_screen.dart';

/// A bottom sheet that appears when a free user taps on a premium feature
class LockedFeatureSheet {
  /// Shows the locked feature bottom sheet
  ///
  /// [context] - Build context
  /// [featureName] - Name of the locked feature (e.g., "Tone Selector")
  /// [benefit] - One-line benefit description (e.g., "Customize the tone of your prompts")
  static void show(BuildContext context, String featureName, String benefit) {
    if (PlatformUtils.useCupertino(context)) {
      showCupertinoModalPopup<void>(
        context: context,
        builder: (context) => Material(
          color: Colors.transparent,
          child: _LockedFeatureContent(
            featureName: featureName,
            benefit: benefit,
          ),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _LockedFeatureContent(featureName: featureName, benefit: benefit),
    );
  }
}

class _LockedFeatureContent extends StatelessWidget {
  const _LockedFeatureContent({
    required this.featureName,
    required this.benefit,
  });
  final String featureName;
  final String benefit;

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

          // Lock icon
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.lock_outline,
                size: 32,
                color: AppColors.primaryLight,
              ),
            ),
          ),

          const SizedBox(height: AppConstants.spacing24),

          // Feature name
          Text(
            featureName,
            style: AppTextStyles.title.copyWith(
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppConstants.spacing8),

          // Benefit
          Text(
            benefit,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppConstants.spacing32),

          // Unlock button
          SizedBox(
            width: double.infinity,
            height: AppConstants.buttonHeight,
            child: AdaptiveButton(
              label: 'Unlock with Premium',
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
              label: 'Maybe Later',
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
