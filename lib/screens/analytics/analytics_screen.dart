import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/platform_utils.dart';
import '../../core/widgets/adaptive_widgets.dart';
import '../../data/models/prompt_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/premium_provider.dart';
import '../../providers/prompt_provider.dart';
import '../paywall/paywall_screen.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();
    final premiumProvider = context.watch<PremiumProvider>();
    final promptProvider = context.watch<PromptProvider>();

    if (!authProvider.isAuthenticated || !premiumProvider.hasPremiumAccess) {
      return _AnalyticsLockedState(signedIn: authProvider.isAuthenticated);
    }

    final prompts = promptProvider.prompts;
    final avgStrength = prompts.isEmpty
        ? 0
        : prompts.map((item) => item.strengthScore).reduce((a, b) => a + b) /
              prompts.length;
    final favourites = prompts.where((item) => item.isFavourite).length;
    final categoryCounts = _buildCategoryCounts(prompts);
    final weeklyPoints = _buildWeeklyPoints(prompts);

    return AdaptiveScaffold(
      appBar: const AdaptiveAppBar(
        title: 'Insights',
        backgroundColor: Colors.transparent,
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 160),
          children: [
            Text(
              'A visual summary of how you refine prompts.',
              style: AppTextStyles.body.copyWith(color: theme.hintColor),
            ),
            const SizedBox(height: AppConstants.spacing20),
            Container(
              padding: const EdgeInsets.all(AppConstants.spacing20),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(AppConstants.radiusCard),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _StatBlock(
                      label: 'Prompts',
                      value: '${prompts.length}',
                      onDark: true,
                    ),
                  ),
                  Expanded(
                    child: _StatBlock(
                      label: 'Avg Strength',
                      value: '${avgStrength.round()}%',
                      onDark: true,
                    ),
                  ),
                  Expanded(
                    child: _StatBlock(
                      label: 'Saved',
                      value: '$favourites',
                      onDark: true,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.spacing20),
            Container(
              height: 240,
              padding: const EdgeInsets.all(AppConstants.spacing20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(AppConstants.radiusCard),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Weekly momentum',
                    style: AppTextStyles.heading.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacing8),
                  Text(
                    'A lightweight view of your recent prompt activity.',
                    style: AppTextStyles.body.copyWith(color: theme.hintColor),
                  ),
                  const SizedBox(height: AppConstants.spacing20),
                  Expanded(
                    child: CustomPaint(
                      painter: _LineGraphPainter(
                        points: weeklyPoints,
                        lineColor: AppColors.primaryLight,
                        fillColor: AppColors.primaryLight.withValues(
                          alpha: 0.12,
                        ),
                        gridColor: theme.dividerColor,
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.spacing20),
            ...categoryCounts.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppConstants.spacing12),
                child: Container(
                  padding: const EdgeInsets.all(AppConstants.spacing20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(
                      AppConstants.radiusCard,
                    ),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.key,
                          style: AppTextStyles.subtitle.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        '${entry.value}',
                        style: AppTextStyles.heading.copyWith(
                          color: AppColors.primaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Map<String, int> _buildCategoryCounts(List<PromptModel> prompts) {
    final counts = <String, int>{};
    for (final prompt in prompts) {
      counts[prompt.category] = (counts[prompt.category] ?? 0) + 1;
    }
    return counts;
  }

  List<double> _buildWeeklyPoints(List<PromptModel> prompts) {
    final now = DateTime.now();
    final counts = List<int>.filled(7, 0);
    for (final prompt in prompts) {
      final difference = now.difference(prompt.createdAt).inDays;
      if (difference >= 0 && difference < 7) {
        counts[6 - difference] += 1;
      }
    }
    final maxCount = counts.reduce(math.max);
    if (maxCount == 0) {
      return const [0.2, 0.34, 0.28, 0.48, 0.44, 0.62, 0.58];
    }
    return counts.map((item) => item / maxCount).toList();
  }
}

class _AnalyticsLockedState extends StatelessWidget {
  const _AnalyticsLockedState({required this.signedIn});

  final bool signedIn;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AdaptiveScaffold(
      appBar: const AdaptiveAppBar(
        title: 'Insights',
        backgroundColor: Colors.transparent,
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 160),
          children: [
            Text(
              'See how your prompt writing evolves over time.',
              style: AppTextStyles.body.copyWith(color: theme.hintColor),
            ),
            const SizedBox(height: AppConstants.spacing20),
            Container(
              padding: const EdgeInsets.all(AppConstants.spacing24),
              decoration: BoxDecoration(
                gradient: AppColors.darkGradient,
                borderRadius: BorderRadius.circular(AppConstants.radiusCard),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    signedIn
                        ? 'Unlock premium insights'
                        : 'Sign in to unlock insights',
                    style: AppTextStyles.heading.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: AppConstants.spacing8),
                  Text(
                    signedIn
                        ? 'Track patterns, prompt strength, and category usage with a more visual analytics view.'
                        : 'Create an account first, then upgrade for the full insight view.',
                    style: AppTextStyles.body.copyWith(
                      color: Colors.white.withValues(alpha: 0.82),
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacing20),
                  Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(
                        AppConstants.radiusCard,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.query_stats_rounded,
                        color: Colors.white,
                        size: 60,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacing20),
                  SizedBox(
                    width: double.infinity,
                    child: AdaptiveButton(
                      label: signedIn ? 'Unlock Premium' : 'See Premium',
                      onPressed: () => PlatformUtils.navigateTo(
                        context,
                        const PaywallScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  const _StatBlock({
    required this.label,
    required this.value,
    this.onDark = false,
  });

  final String label;
  final String value;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.display.copyWith(
            fontSize: 28,
            color: onDark
                ? Colors.white
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppConstants.spacing4),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: onDark
                ? Colors.white.withValues(alpha: 0.74)
                : Theme.of(context).hintColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _LineGraphPainter extends CustomPainter {
  _LineGraphPainter({
    required this.points,
    required this.lineColor,
    required this.fillColor,
    required this.gridColor,
  });

  final List<double> points;
  final Color lineColor;
  final Color fillColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var i = 1; i < 4; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (points.isEmpty) return;

    final path = Path();
    final fillPath = Path();
    final step = size.width / (points.length - 1);

    for (var i = 0; i < points.length; i++) {
      final x = step * i;
      final y = size.height - (size.height * points[i].clamp(0.0, 1.0));
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, Paint()..color = fillColor);

    canvas.drawPath(
      path,
      Paint()
        ..color = lineColor
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _LineGraphPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}
