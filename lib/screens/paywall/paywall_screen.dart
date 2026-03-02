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
  int _selectedPlanIndex = 1; // Default to Yearly

  final List<_PlanOption> _plans = [
    _PlanOption(
      id: 'monthly',
      title: 'Monthly',
      price: '\$8.99',
      period: '/month',
      subtitle: null,
      badge: null,
    ),
    _PlanOption(
      id: 'yearly',
      title: 'Yearly',
      price: '\$59.99',
      period: '/year',
      subtitle: '\$5.00/month',
      badge: 'SAVE 44%',
      isPopular: true,
    ),
    _PlanOption(
      id: 'lifetime',
      title: 'Lifetime',
      price: '\$89.99',
      period: ' once',
      subtitle: null,
      badge: 'BEST VALUE',
    ),
  ];

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
                    // Pricing cards
                    _buildPricingCards(theme),

                    const SizedBox(height: AppConstants.spacing32),

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

  Widget _buildPricingCards(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Your Plan',
          style: AppTextStyles.title.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppConstants.spacing16),
        Row(
          children: List.generate(_plans.length, (index) {
            final plan = _plans[index];
            final isSelected = _selectedPlanIndex == index;

            return Expanded(
              child: GestureDetector(
                onTap: () => _selectPlan(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.only(
                    left: index == 0 ? 0 : AppConstants.spacing8,
                    right: index == _plans.length - 1 ? 0 : AppConstants.spacing8,
                  ),
                  padding: const EdgeInsets.all(AppConstants.spacing12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppConstants.radiusCard),
                    border: Border.all(
                      color: isSelected ? AppColors.primaryLight : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: isSelected ? AppColors.cardShadowLight : null,
                  ),
                  child: Column(
                    children: [
                      // Badge or spacer
                      if (plan.badge != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: plan.isPopular
                                ? AppColors.primaryLight
                                : theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: plan.isPopular
                                ? null
                                : Border.all(color: AppColors.primaryLight),
                          ),
                          child: Text(
                            plan.badge!,
                            style: AppTextStyles.caption.copyWith(
                              color: plan.isPopular
                                  ? Colors.white
                                  : AppColors.primaryLight,
                              fontWeight: FontWeight.bold,
                              fontSize: 9,
                            ),
                          ),
                        )
                      else
                        const SizedBox(height: 24),

                      const SizedBox(height: AppConstants.spacing12),

                      // Title
                      Text(
                        plan.title,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondaryLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Price
                      Text(
                        plan.price,
                        style: AppTextStyles.title.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      // Period
                      Text(
                        plan.period,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondaryLight,
                          fontSize: 10,
                        ),
                      ),

                      // Subtitle
                      if (plan.subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          plan.subtitle!,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primaryLight,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ],
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
    final selectedPlan = _plans[_selectedPlanIndex];
    String priceText = '${selectedPlan.price}${selectedPlan.period}';

    return Column(
      children: [
        // Main CTA button
        SizedBox(
          width: double.infinity,
          height: AppConstants.buttonHeight,
          child: ElevatedButton(
            onPressed: () => _handleUpgrade(premiumProvider, trialUsed),
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
                const Icon(Icons.auto_awesome, size: 20),
                const SizedBox(width: 8),
                Text(
                  trialUsed ? 'Upgrade Now' : 'Start 3-Day Free Trial',
                  style: AppTextStyles.button.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppConstants.spacing12),

        // Price subtext
        Text(
          trialUsed
              ? '$priceText. Cancel anytime.'
              : 'then $priceText. Cancel anytime.',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondaryLight,
          ),
        ),

        const SizedBox(height: AppConstants.spacing24),

        // Trust badges
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildTrustBadge(Icons.lock_outline, 'Secure'),
            const SizedBox(width: AppConstants.spacing24),
            _buildTrustBadge(Icons.replay, 'Refund'),
            const SizedBox(width: AppConstants.spacing24),
            _buildTrustBadge(Icons.cancel_outlined, 'Cancel anytime'),
          ],
        ),

        const SizedBox(height: AppConstants.spacing24),

        // Restore purchases
        TextButton(
          onPressed: () {
            SnackbarUtils.showInfo(context, 'Purchases restored');
          },
          child: Text(
            'Restore Purchases',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondaryLight,
              decoration: TextDecoration.underline,
            ),
          ),
        ),

        const SizedBox(height: AppConstants.spacing8),

        // Terms text
        Text(
          'By subscribing you agree to our Terms of Service',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondaryLight.withValues(alpha: 0.7),
            fontSize: 11,
          ),
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

  void _selectPlan(int index) {
    setState(() => _selectedPlanIndex = index);
  }

  Future<void> _handleUpgrade(PremiumProvider premiumProvider, bool trialUsed) async {
    final selectedPlan = _plans[_selectedPlanIndex];

    if (!trialUsed) {
      // Activate trial first
      final success = await premiumProvider.activateTrial();
      if (success && mounted) {
        SnackbarUtils.showSuccess(context, 'Premium activated! Enjoy your 3-day free trial');
        Navigator.pop(context);
      } else if (mounted) {
        SnackbarUtils.showError(context, premiumProvider.error ?? 'Failed to activate trial');
      }
    } else {
      // Direct upgrade (simulated for now)
      final success = await premiumProvider.upgradeToPremium(
        planType: selectedPlan.id,
      );
      if (success && mounted) {
        SnackbarUtils.showSuccess(context, 'Welcome to Premium!');
        Navigator.pop(context);
      } else if (mounted) {
        SnackbarUtils.showError(context, premiumProvider.error ?? 'Failed to upgrade');
      }
    }
  }
}

class _PlanOption {
  final String id;
  final String title;
  final String price;
  final String period;
  final String? subtitle;
  final String? badge;
  final bool isPopular;

  _PlanOption({
    required this.id,
    required this.title,
    required this.price,
    required this.period,
    this.subtitle,
    this.badge,
    this.isPopular = false,
  });
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
