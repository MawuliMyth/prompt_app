// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../core/widgets/page_header.dart';
import '../../providers/premium_provider.dart';

class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final premiumProvider = context.watch<PremiumProvider>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 180),
              children: [
                PageHeader(
                  title: 'Go Premium',
                  subtitle:
                      'A calmer, smarter workflow for serious prompt writing.',
                  onBack: () => Navigator.of(context).pop(),
                ),
                const SizedBox(height: AppConstants.spacing20),
                Container(
                  padding: const EdgeInsets.all(AppConstants.spacing24),
                  decoration: BoxDecoration(
                    gradient: AppColors.premiumGradient,
                    borderRadius: BorderRadius.circular(
                      AppConstants.radiusCard,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Unlock pro prompt shaping',
                        style: AppTextStyles.display.copyWith(
                          color: Colors.white,
                          fontSize: 30,
                        ),
                      ),
                      const SizedBox(height: AppConstants.spacing12),
                      Text(
                        'Use premium tones, stronger guidance, and richer insight into how you work.',
                        style: AppTextStyles.body.copyWith(
                          color: Colors.white.withValues(alpha: 0.84),
                        ),
                      ),
                      const SizedBox(height: AppConstants.spacing20),
                      Wrap(
                        spacing: AppConstants.spacing8,
                        runSpacing: AppConstants.spacing8,
                        children: const [
                          _PaywallTag(label: 'Premium tones'),
                          _PaywallTag(label: 'Unlimited prompts'),
                          _PaywallTag(label: 'Pro insights'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppConstants.spacing24),
                Container(
                  padding: const EdgeInsets.all(AppConstants.spacing20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(
                      AppConstants.radiusCard,
                    ),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Column(
                    children: const [
                      _FeatureLine(
                        title: 'Unlimited prompt refinement',
                        subtitle:
                            'Keep iterating without worrying about daily caps.',
                      ),
                      _FeatureLine(
                        title: 'Premium tones',
                        subtitle:
                            'Professional, creative, persuasive, casual, and technical modes.',
                      ),
                      _FeatureLine(
                        title: 'Richer insights',
                        subtitle:
                            'See stronger visual summaries of your writing activity.',
                      ),
                      _FeatureLine(
                        title: 'Better focus',
                        subtitle:
                            'A cleaner workflow designed around drafting and refinement.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor.withValues(alpha: 0.95),
                  border: Border(top: BorderSide(color: theme.dividerColor)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: AppColors.premiumGradient,
                          borderRadius: BorderRadius.circular(
                            AppConstants.radiusButton,
                          ),
                        ),
                        child: ElevatedButton(
                          onPressed: premiumProvider.trialUsed
                              ? null
                              : () => _activateTrial(context, premiumProvider),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                          ),
                          child: Text(
                            premiumProvider.trialUsed
                                ? 'Trial already used'
                                : 'Start 3-day free trial',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacing8),
                    Text(
                      premiumProvider.trialUsed
                          ? 'Your free trial has already been used on this account.'
                          : 'No credit card required. Cancel anytime.',
                      style: AppTextStyles.caption.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _activateTrial(
    BuildContext context,
    PremiumProvider premiumProvider,
  ) async {
    final success = await premiumProvider.activateTrial();
    if (!context.mounted) return;
    if (success) {
      SnackbarUtils.showSuccess(
        context,
        'Premium activated. Enjoy your free trial.',
      );
      Navigator.of(context).pop();
      return;
    }
    SnackbarUtils.showError(
      context,
      premiumProvider.error ?? 'Failed to activate trial.',
    );
  }
}

class _FeatureLine extends StatelessWidget {
  const _FeatureLine({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spacing16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.check_circle_rounded,
              color: AppColors.primaryLight,
              size: 18,
            ),
          ),
          const SizedBox(width: AppConstants.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.subtitle.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppConstants.spacing4),
                Text(
                  subtitle,
                  style: AppTextStyles.body.copyWith(
                    color: Theme.of(context).hintColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaywallTag extends StatelessWidget {
  const _PaywallTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppConstants.radiusChip),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
