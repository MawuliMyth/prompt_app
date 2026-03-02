import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../providers/premium_provider.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  final List<_FeatureRow> _features = [
    _FeatureRow('Daily prompts', '5/day', 'Unlimited', true, true),
    _FeatureRow('AI Model', 'Standard', 'Advanced', false, true),
    _FeatureRow('Prompt variations', false, true),
    _FeatureRow('Tone selector', false, true),
    _FeatureRow('Prompt history', 'Last 10', 'Unlimited', true, true),
    _FeatureRow('Analytics', false, true),
    _FeatureRow('Custom persona', false, true),
    _FeatureRow('Export prompts', false, true),
    _FeatureRow('Ad free', false, true),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final premiumProvider = Provider.of<PremiumProvider>(context);
    final trialUsed = premiumProvider.trialUsed;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header with gradient
            SliverToBoxAdapter(
              child: _buildHeader(theme),
            ),

            // Scrollable content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.spacing24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Feature comparison
                    _buildFeatureComparison(theme),

                    const SizedBox(height: AppConstants.spacing32),

                    // Bottom section
                    _buildBottomSection(theme, premiumProvider, trialUsed),

                    const SizedBox(height: AppConstants.spacing24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spacing24,
        AppConstants.spacing16,
        AppConstants.spacing24,
        AppConstants.spacing48,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          // Close button
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(AppConstants.spacing8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 20),
              ),
            ),
          ),

          const SizedBox(height: AppConstants.spacing24),

          // Premium icon
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.workspace_premium_outlined,
              color: Colors.white,
              size: 36,
            ),
          ),

          const SizedBox(height: AppConstants.spacing24),

          Text(
            'Go Premium',
            style: AppTextStyles.display.copyWith(color: Colors.white),
          ),

          const SizedBox(height: AppConstants.spacing8),

          Text(
            'Unlock your full potential',
            style: AppTextStyles.subtitle.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureComparison(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Compare Plans',
          style: AppTextStyles.title.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppConstants.spacing16),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppConstants.radiusCard),
            boxShadow: AppColors.cardShadowLight,
          ),
          child: Column(
            children: [
              // Header row
              Container(
                padding: const EdgeInsets.all(AppConstants.spacing16),
                child: Row(
                  children: [
                    const Expanded(
                      flex: 2,
                      child: SizedBox(),
                    ),
                    Expanded(
                      child: Text(
                        'FREE',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'PRO',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.caption.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Feature rows
              ...List.generate(_features.length, (index) {
                final feature = _features[index];
                final isLast = index == _features.length - 1;

                return Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacing16),
                  decoration: BoxDecoration(
                    color: index.isEven
                        ? theme.colorScheme.surface
                        : theme.scaffoldBackgroundColor,
                    borderRadius: isLast
                        ? const BorderRadius.vertical(
                            bottom: Radius.circular(AppConstants.radiusCard),
                          )
                        : null,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          feature.name,
                          style: AppTextStyles.caption.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: feature.hasCustomFree
                              ? Text(
                                  feature.freeValue!,
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textSecondaryLight,
                                    fontSize: 11,
                                  ),
                                )
                              : Icon(
                                  feature.freeValue == true
                                      ? Icons.check_circle_outline
                                      : Icons.remove,
                                  size: 18,
                                  color: AppColors.textSecondaryLight,
                                ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: feature.hasCustomPremium
                              ? Text(
                                  feature.premiumValue!,
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.primaryLight,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                )
                              : Icon(
                                  Icons.check_circle,
                                  size: 18,
                                  color: AppColors.primaryLight,
                                ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomSection(
    ThemeData theme,
    PremiumProvider premiumProvider,
    bool trialUsed,
  ) {
    return Column(
      children: [
        // Coming Soon banner (for paid plans)
        Container(
          padding: const EdgeInsets.all(AppConstants.spacing16),
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppConstants.radiusCard),
            border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.primaryLight, size: 20),
              const SizedBox(width: AppConstants.spacing12),
              Expanded(
                child: Text(
                  'Paid subscriptions coming soon! Try our free 3-day trial now.',
                  style: AppTextStyles.caption.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppConstants.spacing24),

        // Main CTA button
        SizedBox(
          width: double.infinity,
          height: AppConstants.buttonHeight,
          child: ElevatedButton(
            onPressed: trialUsed ? null : () => _handleTrialActivation(premiumProvider),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryLight,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.textSecondaryLight.withValues(alpha: 0.3),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusButton),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.auto_awesome, size: 20),
                const SizedBox(width: 8),
                Text(
                  trialUsed ? 'Trial Already Used' : 'Start 3-Day Free Trial',
                  style: AppTextStyles.button.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppConstants.spacing12),

        // Subtext
        Text(
          trialUsed
              ? 'You\'ve already used your free trial.'
              : 'No credit card required. Cancel anytime.',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondaryLight,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: AppConstants.spacing24),

        // Trust badges
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildTrustBadge(Icons.lock_outline, 'Free'),
            const SizedBox(width: AppConstants.spacing24),
            _buildTrustBadge(Icons.timer_outlined, '3 Days'),
            const SizedBox(width: AppConstants.spacing24),
            _buildTrustBadge(Icons.cancel_outlined, 'Cancel anytime'),
          ],
        ),
      ],
    );
  }

  Widget _buildTrustBadge(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondaryLight),
        const SizedBox(width: 6),
        Text(
          text,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }

  Future<void> _handleTrialActivation(PremiumProvider premiumProvider) async {
    final success = await premiumProvider.activateTrial();
    if (success && mounted) {
      SnackbarUtils.showSuccess(context, 'Premium activated! Enjoy your 3-day free trial');
      Navigator.pop(context);
    } else if (mounted) {
      SnackbarUtils.showError(context, premiumProvider.error ?? 'Failed to activate trial');
    }
  }
}

class _FeatureRow {
  final String name;
  final dynamic freeValue;
  final dynamic premiumValue;
  final bool hasCustomFree;
  final bool hasCustomPremium;

  _FeatureRow(
    this.name,
    this.freeValue,
    this.premiumValue, [
    this.hasCustomFree = false,
    this.hasCustomPremium = false,
  ]);
}
