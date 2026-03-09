import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/platform_utils.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../core/widgets/adaptive_widgets.dart';
import '../../providers/auth_provider.dart';
import '../../providers/premium_provider.dart';
import '../auth/login_screen.dart';
import '../settings/settings_screen.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  int _selectedPlanIndex = 1;

  final List<_PlanOption> _plans = const [
    _PlanOption(
      id: 'monthly',
      title: 'Monthly',
      price: r'$8.99',
      period: '/month',
    ),
    _PlanOption(
      id: 'yearly',
      title: 'Yearly',
      price: r'$59.99',
      period: '/year',
      subtitle: r'$2.50/month',
      badge: 'SAVE 40%',
      isPopular: true,
    ),
    _PlanOption(
      id: 'lifetime',
      title: 'Lifetime',
      price: r'$89.99',
      period: ' once',
      badge: 'BEST VALUE',
    ),
  ];

  final List<_FeatureRow> _features = const [
    _FeatureRow('Daily prompts', '10/day', 'Unlimited'),
    _FeatureRow('Voice recording', 'Up to 3 min', 'Unlimited'),
    _FeatureRow('AI model depth', 'Standard', 'Advanced'),
    _FeatureRow('Prompt variations', 'No', 'Yes'),
    _FeatureRow('Tone selector', 'No', 'Yes'),
    _FeatureRow('Prompt history', 'Last 10', 'Unlimited'),
    _FeatureRow('Analytics', 'No', 'Yes'),
    _FeatureRow('Custom persona', 'No', 'Yes'),
    _FeatureRow('Ad free', 'No', 'Yes'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final premiumProvider = context.watch<PremiumProvider>();
    final trialUsed = premiumProvider.trialUsed;

    return AdaptiveScaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPricingCards(theme),
                    const SizedBox(height: 24),
                    _buildFeatureComparison(theme),
                    const SizedBox(height: 24),
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

  Color _primaryTextColor(ThemeData theme) =>
      theme.brightness == Brightness.dark
      ? Colors.white
      : const Color(0xFF0F172A);

  Color _secondaryTextColor(ThemeData theme) =>
      theme.brightness == Brightness.dark
      ? Colors.white70
      : const Color(0xFF475569);

  Color _softBorderColor(ThemeData theme) => theme.brightness == Brightness.dark
      ? Colors.white.withValues(alpha: 0.08)
      : const Color(0xFFD8E1F0);

  Widget _buildHeader() {
    final isCupertino = PlatformUtils.useCupertino(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
      decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCupertino ? CupertinoIcons.clear : Icons.close,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Go Premium',
            style: AppTextStyles.headingLarge.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Unlock your full prompt workflow',
            style: AppTextStyles.body.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCards(ThemeData theme) {
    final primaryText = _primaryTextColor(theme);
    final secondaryText = _secondaryTextColor(theme);
    final softBorder = _softBorderColor(theme);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose your plan',
          style: AppTextStyles.headingSmall.copyWith(color: primaryText),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(_plans.length, (index) {
            final plan = _plans[index];
            final isSelected = _selectedPlanIndex == index;

            return Expanded(
              child: GestureDetector(
                onTap: () => _selectPlan(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.only(
                    left: index == 0 ? 0 : 6,
                    right: index == _plans.length - 1 ? 0 : 6,
                  ),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.surface
                        : theme.colorScheme.surface.withValues(alpha: 0.84),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primaryLight.withValues(alpha: 0.72)
                          : softBorder,
                      width: isSelected ? 1.5 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primaryLight.withValues(
                                alpha: 0.18,
                              ),
                              blurRadius: 10,
                              offset: const Offset(0, 6),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    children: [
                      if (plan.badge != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            plan.badge!,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ] else
                        const SizedBox(height: 26),
                      Text(
                        plan.title,
                        style: AppTextStyles.caption.copyWith(
                          color: secondaryText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              plan.price,
                              style: AppTextStyles.headingMedium.copyWith(
                                color: primaryText,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              plan.period,
                              style: AppTextStyles.caption.copyWith(
                                color: secondaryText,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (plan.subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          plan.subtitle!,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primaryLight,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
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
    final primaryText = _primaryTextColor(theme);
    final secondaryText = _secondaryTextColor(theme);
    final softBorder = _softBorderColor(theme);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Compare plans',
          style: AppTextStyles.headingSmall.copyWith(color: primaryText),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: softBorder),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                child: Row(
                  children: [
                    const Expanded(child: SizedBox()),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: theme.brightness == Brightness.dark
                              ? Colors.white.withValues(alpha: 0.08)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'FREE',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.caption.copyWith(
                            fontWeight: FontWeight.bold,
                            color: secondaryText,
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
              ...List.generate(_features.length, (index) {
                final feature = _features[index];
                final isLast = index == _features.length - 1;

                return Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    border: isLast
                        ? null
                        : Border(bottom: BorderSide(color: softBorder)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          feature.name,
                          style: AppTextStyles.caption.copyWith(
                            color: primaryText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          feature.freeValue,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.caption.copyWith(
                            color: secondaryText,
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
                            fontWeight: FontWeight.w700,
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
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();
    final secondaryText = _secondaryTextColor(theme);
    final isBusy = premiumProvider.isLoading;
    final requiresVerificationForTrial =
        !trialUsed &&
        authProvider.isAuthenticated &&
        !(authProvider.currentUser?.emailVerified ?? false);

    final selectedPlan = _plans[_selectedPlanIndex];
    final priceText = '${selectedPlan.price}${selectedPlan.period}';

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: AdaptiveButton(
            label: trialUsed
                ? 'Upgrade Now'
                : requiresVerificationForTrial
                ? 'Verify Email to Start Trial'
                : 'Start 3-Day Free Trial',
            isLoading: isBusy,
            onPressed: isBusy
                ? null
                : () => _handleUpgrade(
                    premiumProvider,
                    trialUsed,
                    requiresVerificationForTrial,
                  ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          requiresVerificationForTrial
              ? 'Verify your email first, then return here to start your free trial.'
              : trialUsed
               ? '$priceText. Purchase integration is coming next.'
               : 'Then $priceText. Cancel anytime.',
          style: AppTextStyles.caption.copyWith(color: secondaryText),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildTrustBadge('Secure', Icons.lock_outline),
            const SizedBox(width: 24),
            _buildTrustBadge('Cancel anytime', Icons.cancel_outlined),
            const SizedBox(width: 24),
            _buildTrustBadge('Free trial', Icons.card_giftcard_outlined),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'By subscribing you agree to our Terms of Service.',
          style: AppTextStyles.caption.copyWith(
            color: secondaryText,
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTrustBadge(String text, IconData icon) {
    final secondaryText = _secondaryTextColor(Theme.of(context));

    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: AppColors.primaryLight,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: AppTextStyles.caption.copyWith(
            color: secondaryText,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _selectPlan(int index) {
    setState(() => _selectedPlanIndex = index);
  }

  Future<void> _handleUpgrade(
    PremiumProvider premiumProvider,
    bool trialUsed,
    bool requiresVerificationForTrial,
  ) async {
    final authProvider = context.read<AuthProvider>();
    final navigator = Navigator.of(context);

    if (!authProvider.isAuthenticated) {
      final shouldSignIn = await AdaptiveDialog.show(
        context: context,
        title: 'Sign in required',
        content:
            'Sign in to start a free trial or continue when billing is ready.',
        cancelText: 'Later',
        confirmText: 'Sign In',
      );
      if (shouldSignIn == true && mounted) {
        await PlatformUtils.navigateTo(context, const LoginScreen());
      }
      return;
    }

    if (requiresVerificationForTrial) {
      final shouldOpenSettings = await AdaptiveDialog.show(
        context: context,
        title: 'Verify your email first',
        content:
            'To prevent trial abuse, email/password accounts must verify their email before starting the free trial. You can resend the verification email from Settings.',
        cancelText: 'Later',
        confirmText: 'Open Settings',
      );
      if (shouldOpenSettings == true && mounted) {
        await PlatformUtils.navigateTo(context, const SettingsScreen());
      }
      return;
    }

    if (!trialUsed) {
      final success = await premiumProvider.activateTrial();
      if (!mounted) return;

      if (success) {
        SnackbarUtils.showSuccess(
          context,
          'Premium activated. Enjoy your 3-day free trial.',
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          navigator.maybePop();
        });
      } else {
        SnackbarUtils.showError(
          context,
          premiumProvider.error ?? 'Failed to activate trial.',
        );
      }
      return;
    }

    if (!mounted) return;
    SnackbarUtils.showError(
      context,
      'Store billing is not connected yet. This screen is ready for it.',
    );
  }
}

class _PlanOption {
  const _PlanOption({
    required this.id,
    required this.title,
    required this.price,
    required this.period,
    this.subtitle,
    this.badge,
    this.isPopular = false,
  });

  final String id;
  final String title;
  final String price;
  final String period;
  final String? subtitle;
  final String? badge;
  final bool isPopular;
}

class _FeatureRow {
  const _FeatureRow(this.name, this.freeValue, this.premiumValue);

  final String name;
  final String freeValue;
  final String premiumValue;
}
