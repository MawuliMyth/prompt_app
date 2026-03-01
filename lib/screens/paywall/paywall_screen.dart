import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
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
      price: '\$3.99',
      period: '/month',
      subtitle: null,
      badge: null,
    ),
    _PlanOption(
      id: 'yearly',
      title: 'Yearly',
      price: '\$29.99',
      period: '/year',
      subtitle: '\$2.50/month',
      badge: 'SAVE 37% 🔥',
      isPopular: true,
    ),
    _PlanOption(
      id: 'lifetime',
      title: 'Lifetime',
      price: '\$49.99',
      period: ' once',
      subtitle: null,
      badge: 'BEST VALUE ⭐',
    ),
  ];

  final List<_FeatureRow> _features = [
    _FeatureRow('Daily prompts', '5/day', 'Unlimited'),
    _FeatureRow('AI Model', 'Standard', 'Advanced ✨'),
    _FeatureRow('Prompt variations', '❌', '✅'),
    _FeatureRow('Tone selector', '❌', '✅'),
    _FeatureRow('Prompt history', 'Last 10', 'Unlimited'),
    _FeatureRow('Folders', '❌', '✅'),
    _FeatureRow('Analytics', '❌', '✅'),
    _FeatureRow('Custom persona', '❌', '✅'),
    _FeatureRow('Export prompts', '❌', '✅'),
    _FeatureRow('Ad free', '❌', '✅'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final premiumProvider = Provider.of<PremiumProvider>(context);
    final trialUsed = premiumProvider.trialUsed;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header with gradient
            _buildHeader(),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pricing cards
                    _buildPricingCards(theme),

                    const SizedBox(height: 24),

                    // Feature comparison
                    _buildFeatureComparison(theme),

                    const SizedBox(height: 24),

                    // Bottom section
                    _buildBottomSection(premiumProvider, trialUsed),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 20),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Crown icon
          const Text('👑', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            'Go Premium',
            style: AppTextStyles.headingLarge.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Unlock your full potential',
            style: AppTextStyles.body.copyWith(
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
          style: AppTextStyles.headingSmall.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
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
                    left: index == 0 ? 0 : 8,
                    right: index == _plans.length - 1 ? 0 : 8,
                  ),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? AppColors.primaryLight : AppColors.dividerLight,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primaryLight.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    children: [
                      // Badge
                      if (plan.badge != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            plan.badge!,
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ] else
                        const SizedBox(height: 22),

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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            plan.price,
                            style: AppTextStyles.headingMedium.copyWith(
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            plan.period,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),

                      // Subtitle
                      if (plan.subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          plan.subtitle!,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primaryLight,
                            fontSize: 10,
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
          style: AppTextStyles.headingSmall.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.dividerLight),
          ),
          child: Column(
            children: [
              // Header row
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    const Expanded(child: SizedBox()),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.textSecondaryLight.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'FREE',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.caption.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'PREMIUM',
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
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    border: isLast
                        ? null
                        : Border(
                            bottom: BorderSide(color: AppColors.dividerLight),
                          ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          feature.name,
                          style: AppTextStyles.caption.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          feature.freeValue,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          feature.premiumValue,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primaryLight,
                            fontWeight: FontWeight.w600,
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

  Widget _buildBottomSection(PremiumProvider premiumProvider, bool trialUsed) {
    final selectedPlan = _plans[_selectedPlanIndex];
    String priceText = '${selectedPlan.price}${selectedPlan.period}';

    return Column(
      children: [
        // Main CTA button
        GestureDetector(
          onTap: () => _handleUpgrade(premiumProvider, trialUsed),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryLight.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Text(
              trialUsed ? 'Upgrade Now' : 'Start 3-Day Free Trial',
              textAlign: TextAlign.center,
              style: AppTextStyles.button.copyWith(color: Colors.white),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Price subtext
        Text(
          trialUsed
              ? '$priceText. Cancel anytime.'
              : 'then $priceText. Cancel anytime.',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondaryLight,
          ),
        ),

        const SizedBox(height: 20),

        // Trust badges
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildTrustBadge('🔒', 'Secure'),
            const SizedBox(width: 24),
            _buildTrustBadge('↩️', 'Refund'),
            const SizedBox(width: 24),
            _buildTrustBadge('❌', 'Cancel anytime'),
          ],
        ),

        const SizedBox(height: 16),

        // Terms text
        Text(
          'By subscribing you agree to our Terms of Service',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondaryLight,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildTrustBadge(String emoji, String text) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 4),
        Text(
          text,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondaryLight,
            fontSize: 11,
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
        SnackbarUtils.showSuccess(context, 'Premium activated! Enjoy your 3-day free trial 🎉');
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
        SnackbarUtils.showSuccess(context, 'Welcome to Premium! 🎉');
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
  final String freeValue;
  final String premiumValue;

  _FeatureRow(this.name, this.freeValue, this.premiumValue);
}
