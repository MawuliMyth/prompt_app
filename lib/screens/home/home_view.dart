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

    String displayName = authProvider.currentUser?.displayName ?? 'there';
    if (displayName.contains(' ')) {
      displayName = displayName.split(' ').first;
    }

    final quickTemplates = configProvider.quickTemplates.take(3).toList();

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
                    _CircleUtility(
                      icon: isCupertino
                          ? CupertinoIcons.line_horizontal_3
                          : Icons.menu_rounded,
                    ),
                    const Spacer(),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: premiumProvider.hasPremiumAccess
                            ? AppColors.premiumGradient
                            : AppColors.primaryGradient,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        displayName.isEmpty
                            ? 'P'
                            : displayName[0].toUpperCase(),
                        style: AppTextStyles.title.copyWith(
                          color: Colors.white,
                        ),
                      ),
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
                _PremiumStatusCard(
                  isPremium: premiumProvider.hasPremiumAccess,
                  trialUsed: premiumProvider.trialUsed,
                ),
                const SizedBox(height: AppConstants.spacing24),
                _FeatureMosaic(
                  features: configProvider.homeFeatures,
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
                      'Hot Features',
                      style: AppTextStyles.heading.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'See all',
                      style: AppTextStyles.subtitle.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.spacing16),
                Wrap(
                  spacing: AppConstants.spacing12,
                  runSpacing: AppConstants.spacing12,
                  children: quickTemplates.map((template) {
                    return _QuickTemplateTile(
                      template: template,
                      onTap: () {
                        shellProvider.openComposer(
                          initialText: template.promptBody,
                          categoryId: template.categoryId,
                        );
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                child: Container(
                  height: 62,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.dark
                        ? AppColors.floatingSurfaceDark
                        : AppColors.floatingSurfaceLight,
                    borderRadius: BorderRadius.circular(
                      AppConstants.radiusFloating,
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
                              'What do you want help writing?',
                              style: AppTextStyles.body.copyWith(
                                color: theme.brightness == Brightness.dark
                                    ? AppColors.floatingOnDark.withValues(
                                        alpha: 0.7,
                                      )
                                    : AppColors.floatingOnLight.withValues(
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
                            color: Colors.white.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isCupertino
                                ? CupertinoIcons.mic
                                : Icons.mic_none_rounded,
                            size: 18,
                            color: Colors.white,
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

class _CircleUtility extends StatelessWidget {
  const _CircleUtility({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        size: 22,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}

class _PremiumStatusCard extends StatelessWidget {
  const _PremiumStatusCard({required this.isPremium, required this.trialUsed});

  final bool isPremium;
  final bool trialUsed;

  @override
  Widget build(BuildContext context) {
    return Container(
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
                  isPremium ? 'Premium is active' : 'Upgrade your writing flow',
                  style: AppTextStyles.title.copyWith(color: Colors.white),
                ),
                const SizedBox(height: AppConstants.spacing8),
                Text(
                  isPremium
                      ? 'Enjoy unlimited prompt refinement and pro tones.'
                      : trialUsed
                      ? 'You have already used your free trial.'
                      : 'Try pro tones, deeper prompt shaping, and richer analytics.',
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
                        bottom:
                            feature == secondary.first && secondary.length > 1
                            ? AppConstants.spacing12
                            : 0,
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
    final color = resolveVisualStyle(
      feature.id == 'refine'
          ? 'lime'
          : feature.id == 'voice'
          ? 'mint'
          : 'blush',
    );

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
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                Icon(
                  isCupertino
                      ? CupertinoIcons.arrow_up_right
                      : Icons.arrow_outward_rounded,
                  size: 22,
                  color: theme.colorScheme.onSurface,
                ),
              ],
            ),
            const Spacer(),
            Text(
              feature.title,
              style: (large ? AppTextStyles.display : AppTextStyles.heading)
                  .copyWith(
                    color: theme.colorScheme.onSurface,
                    fontSize: large ? 28 : 18,
                    height: large ? 1.05 : 1.1,
                  ),
            ),
            const SizedBox(height: AppConstants.spacing8),
            Text(
              feature.subtitle,
              maxLines: large ? 3 : 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickTemplateTile extends StatelessWidget {
  const _QuickTemplateTile({required this.template, required this.onTap});

  final TemplateConfig template;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final width = ((MediaQuery.of(context).size.width - 52) / 3)
        .clamp(96.0, 150.0)
        .toDouble();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        padding: const EdgeInsets.all(AppConstants.spacing16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppConstants.radiusCard),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariantLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome_outlined, size: 18),
            ),
            const SizedBox(height: AppConstants.spacing20),
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
