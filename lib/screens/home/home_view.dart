// ignore_for_file: prefer_const_constructors

import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/app_icon_mapper.dart';
import '../../data/models/app_config_model.dart';
import '../../providers/app_config_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/premium_provider.dart';
import '../../providers/shell_provider.dart';
import '../analytics/analytics_screen.dart';
import '../paywall/paywall_screen.dart';
import 'voice_assessment_screen.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();
    final premiumProvider = context.watch<PremiumProvider>();
    final configProvider = context.watch<AppConfigProvider>();
    final shellProvider = context.read<ShellProvider>();
    final isCupertino = !kIsWeb && (Platform.isIOS || Platform.isMacOS);

    String displayName = authProvider.currentUser?.displayName?.trim() ?? '';
    if (displayName.isEmpty) {
      displayName = authProvider.currentUser?.email?.split('@').first ?? '';
    }
    if (displayName.contains(' ')) {
      displayName = displayName.split(' ').first;
    }

    final quickTemplates = configProvider.quickTemplates.take(3).toList();
    final homeFeatures = [
      ...configProvider.homeFeatures.take(3),
      if (premiumProvider.hasPremiumAccess)
        HomeFeatureConfig(
          id: 'analytics',
          title: 'Analytics',
          subtitle: 'See patterns in your prompt flow and usage.',
          iconKey: 'chart',
          imageAssetKey: 'analytics',
          actionType: 'analytics',
          visualSize: 'medium',
        ),
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 210),
              children: [
                Row(
                  children: [
                    const Spacer(),
                    _HomeStatusIdentity(
                      authProvider: authProvider,
                      premiumProvider: premiumProvider,
                      displayName: displayName,
                      onTap: () => shellProvider.selectTab(3),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.spacing32),
                Text(
                  authProvider.isAuthenticated
                      ? 'How can I assist you today, $displayName?'
                      : 'How can I assist you today?',
                  style: AppTextStyles.heroGreeting.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppConstants.spacing24),
                if (!premiumProvider.hasPremiumAccess) ...[
                  _PremiumStatusCard(
                    isPremium: premiumProvider.hasPremiumAccess,
                    trialUsed: premiumProvider.trialUsed,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PaywallScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacing24),
                ],
                _FeatureMosaic(
                  features: homeFeatures,
                  onAction: (feature) async {
                    switch (feature.actionType) {
                      case 'voice':
                        final transcript = await Navigator.of(context)
                            .push<String>(
                              MaterialPageRoute(
                                builder: (_) => const VoiceAssessmentScreen(),
                              ),
                            );
                        if (transcript != null && context.mounted) {
                          shellProvider.openComposer(initialText: transcript);
                        }
                        break;
                      case 'analytics':
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AnalyticsScreen(),
                          ),
                        );
                        break;
                      case 'templates':
                        shellProvider.selectTab(2);
                        break;
                      case 'compose':
                      default:
                        shellProvider.openComposer();
                        break;
                    }
                  },
                ),
                const SizedBox(height: AppConstants.spacing32),
                Row(
                  children: [
                    Text(
                      'Templates',
                      style: AppTextStyles.heading.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => shellProvider.selectTab(2),
                      child: Text(
                        'See all',
                        style: AppTextStyles.subtitle.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.spacing16),
                SizedBox(
                  height: 112,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: quickTemplates.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: AppConstants.spacing12),
                    itemBuilder: (context, index) {
                      final template = quickTemplates[index];
                      return SizedBox(
                        width: 180,
                        child: _QuickTemplateTile(
                          template: template,
                          onTap: () {
                            shellProvider.openComposer(
                              initialText: template.promptBody,
                              categoryId: template.categoryId,
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 126),
                child: Container(
                  height: 62,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.dark
                        ? AppColors.floatingSurfaceDark
                        : AppColors.surfaceLight.withValues(alpha: 0.96),
                    borderRadius: BorderRadius.circular(
                      AppConstants.radiusFloating,
                    ),
                    border: Border.all(
                      color: theme.brightness == Brightness.dark
                          ? AppColors.borderDark.withValues(alpha: 0.8)
                          : AppColors.borderLight.withValues(alpha: 0.85),
                    ),
                    boxShadow: theme.brightness == Brightness.dark
                        ? AppColors.cardShadowDark
                        : AppColors.cardShadowLight,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: shellProvider.openComposer,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Write your prompts',
                              style: AppTextStyles.body.copyWith(
                                color: theme.brightness == Brightness.dark
                                    ? AppColors.floatingOnDark.withValues(
                                        alpha: 0.7,
                                      )
                                    : AppColors.textPrimaryLight.withValues(
                                        alpha: 0.7,
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () async {
                          final transcript = await Navigator.of(context)
                              .push<String>(
                                MaterialPageRoute(
                                  builder: (_) => const VoiceAssessmentScreen(),
                                ),
                              );
                          if (transcript != null && context.mounted) {
                            shellProvider.openComposer(initialText: transcript);
                          }
                        },
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: theme.brightness == Brightness.dark
                                ? Colors.white.withValues(alpha: 0.12)
                                : AppColors.primaryLight.withValues(
                                    alpha: 0.12,
                                  ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isCupertino
                                ? CupertinoIcons.mic
                                : Icons.mic_none_rounded,
                            size: 18,
                            color: theme.brightness == Brightness.dark
                                ? Colors.white
                                : AppColors.primaryLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeStatusIdentity extends StatelessWidget {
  const _HomeStatusIdentity({
    required this.authProvider,
    required this.premiumProvider,
    required this.displayName,
    required this.onTap,
  });

  final AuthProvider authProvider;
  final PremiumProvider premiumProvider;
  final String displayName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!authProvider.isAuthenticated) {
      return Text(
        'GUEST MODE',
        style: AppTextStyles.sectionLabel.copyWith(
          color: theme.hintColor,
          letterSpacing: 1.1,
        ),
      );
    }

    final avatar = _ProfileAvatar(
      photoUrl: authProvider.currentUser?.photoURL,
      fallbackLabel: displayName.isEmpty ? 'P' : displayName[0].toUpperCase(),
      premium: premiumProvider.hasPremiumAccess,
    );

    if (!premiumProvider.hasPremiumAccess) {
      return GestureDetector(onTap: onTap, child: avatar);
    }

    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Text(
              'PREMIUM',
              style: AppTextStyles.caption.copyWith(
                color: theme.hintColor,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.9,
              ),
            ),
          ),
          const SizedBox(width: AppConstants.spacing12),
          avatar,
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.photoUrl,
    required this.fallbackLabel,
    required this.premium,
  });

  final String? photoUrl;
  final String fallbackLabel;
  final bool premium;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: premium ? AppColors.premiumGradient : AppColors.primaryGradient,
      ),
      alignment: Alignment.center,
      child: photoUrl != null && photoUrl!.isNotEmpty
          ? ClipOval(
              child: Image.network(
                photoUrl!,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Text(
                  fallbackLabel,
                  style: AppTextStyles.title.copyWith(color: Colors.white),
                ),
              ),
            )
          : Text(
              fallbackLabel,
              style: AppTextStyles.title.copyWith(color: Colors.white),
            ),
    );
  }
}

class _PremiumStatusCard extends StatelessWidget {
  const _PremiumStatusCard({
    required this.isPremium,
    required this.trialUsed,
    this.onTap,
  });

  final bool isPremium;
  final bool trialUsed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppConstants.spacing20),
        decoration: BoxDecoration(
          gradient: isPremium
              ? AppColors.premiumGradient
              : AppColors.darkGradient,
          borderRadius: BorderRadius.circular(AppConstants.radiusCard),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isPremium ? 'Premium is active' : 'Upgrade to premium',
                    style: AppTextStyles.title.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: AppConstants.spacing8),
                  Text(
                    isPremium
                        ? 'Enjoy unlimited prompt refinement and pro tones.'
                        : trialUsed
                        ? 'Your free trial has already been used.'
                        : 'Unlock premium tones, deeper prompt shaping, and richer insights.',
                    style: AppTextStyles.body.copyWith(
                      color: Colors.white.withValues(alpha: 0.82),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppConstants.spacing20),
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPremium
                    ? Icons.workspace_premium_rounded
                    : Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 34,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureMosaic extends StatelessWidget {
  const _FeatureMosaic({required this.features, required this.onAction});

  final List<HomeFeatureConfig> features;
  final ValueChanged<HomeFeatureConfig> onAction;

  @override
  Widget build(BuildContext context) {
    if (features.isEmpty) return const SizedBox.shrink();

    if (features.length >= 4) {
      final primary = features.first;
      final analytics = features.firstWhere(
        (feature) => feature.id == 'analytics',
        orElse: () => features[1],
      );
      final voice = features.firstWhere(
        (feature) => feature.id == 'voice',
        orElse: () => features[1],
      );
      final templates = features.firstWhere(
        (feature) => feature.id == 'templates',
        orElse: () => features[2],
      );

      final leftColumn = [primary, analytics];
      final rightColumn = [voice, templates];

      return SizedBox(
        height: 290,
        child: Row(
          children: [
            Expanded(
              child: Column(
                children: leftColumn.map((feature) {
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: feature == leftColumn.last
                            ? 0
                            : AppConstants.spacing12,
                      ),
                      child: _FeatureCard(
                        feature: feature,
                        onTap: () => onAction(feature),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(width: AppConstants.spacing12),
            Expanded(
              child: Column(
                children: rightColumn.map((feature) {
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: feature == rightColumn.last
                            ? 0
                            : AppConstants.spacing12,
                      ),
                      child: _FeatureCard(
                        feature: feature,
                        onTap: () => onAction(feature),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      );
    }

    final primary = features.first;
    final secondary = features.skip(1).take(2).toList();

    return SizedBox(
      height: 290,
      child: Row(
        children: [
          Expanded(
            flex: 6,
            child: _FeatureCard(
              feature: primary,
              large: true,
              onTap: () => onAction(primary),
            ),
          ),
          if (secondary.isNotEmpty) ...[
            const SizedBox(width: AppConstants.spacing12),
            Expanded(
              flex: 6,
              child: Column(
                children: secondary.map((feature) {
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: feature == secondary.last
                            ? 0
                            : AppConstants.spacing12,
                      ),
                      child: _FeatureCard(
                        feature: feature,
                        onTap: () => onAction(feature),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.feature,
    required this.onTap,
    this.large = false,
  });

  final HomeFeatureConfig feature;
  final VoidCallback onTap;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCupertino = !kIsWeb && (Platform.isIOS || Platform.isMacOS);
    final onCardColor = theme.brightness == Brightness.dark
        ? Colors.white
        : AppColors.textPrimaryLight;
    final color = _featureColor(theme, feature.id);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppConstants.spacing20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppConstants.radiusCard),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (large) ...[
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      resolveIcon(feature.iconKey, cupertino: isCupertino),
                      size: 18,
                      color: onCardColor,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    isCupertino
                        ? CupertinoIcons.arrow_up_right
                        : Icons.arrow_outward_rounded,
                    size: 22,
                    color: onCardColor,
                  ),
                ],
              ),
              const Spacer(),
            ] else ...[
              Row(
                children: [
                  const Spacer(),
                  Icon(
                    isCupertino
                        ? CupertinoIcons.arrow_up_right
                        : Icons.arrow_outward_rounded,
                    size: 20,
                    color: onCardColor,
                  ),
                ],
              ),
              const Spacer(flex: 2),
            ],
            Text(
              feature.title,
              maxLines: large ? 2 : 2,
              overflow: TextOverflow.ellipsis,
              style: (large ? AppTextStyles.display : AppTextStyles.heading)
                  .copyWith(
                    color: onCardColor,
                    fontSize: large ? 24 : 17,
                    height: large ? 1.05 : 1.1,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              feature.subtitle,
              maxLines: large ? 3 : 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body.copyWith(
                color: onCardColor.withValues(alpha: 0.78),
                fontSize: large ? 14 : 13,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _featureColor(ThemeData theme, String featureId) {
    final isDark = theme.brightness == Brightness.dark;
    switch (featureId) {
      case 'refine':
        return isDark ? const Color(0xFF42572A) : const Color(0xFFC9E6A5);
      case 'voice':
        return isDark ? const Color(0xFF1E5A51) : const Color(0xFF9EDDC9);
      case 'analytics':
        return isDark ? const Color(0xFF2E4371) : const Color(0xFFC9D9FF);
      case 'templates':
      default:
        return isDark ? const Color(0xFF5B3348) : const Color(0xFFF0CFE0);
    }
  }
}

class _QuickTemplateTile extends StatelessWidget {
  const _QuickTemplateTile({required this.template, required this.onTap});

  final TemplateConfig template;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppConstants.spacing16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppConstants.radiusCard),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              template.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.subtitle.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
