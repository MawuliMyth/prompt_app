import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/adaptive_widgets.dart';
import '../../providers/auth_provider.dart';
import '../../providers/premium_provider.dart';
import '../../providers/prompt_provider.dart';
import '../../data/models/prompt_model.dart';
import '../paywall/paywall_screen.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _countController;
  late Animation<double> _countAnimation;

  @override
  void initState() {
    super.initState();
    _countController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _countAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _countController, curve: Curves.easeOutCubic),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isAuthenticated) {
      _countController.forward();
    }
  }

  @override
  void dispose() {
    _countController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final premiumProvider = Provider.of<PremiumProvider>(context);
    final promptProvider = Provider.of<PromptProvider>(context);

    if (!premiumProvider.hasPremiumAccess) {
      return _buildLockedScreen(theme);
    }

    if (!authProvider.isAuthenticated) {
      return _buildSignInPrompt(theme);
    }

    final prompts = promptProvider.prompts;
    final analytics = _calculateAnalytics(prompts);

    return Scaffold(
      appBar: AdaptiveAppBar(title: 'Analytics'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.spacing24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatCard(
              theme,
              icon: Icons.edit_note_outlined,
              title: 'Total Prompts',
              value: analytics.totalPrompts.toString(),
              color: AppColors.primaryLight,
              showAnimation: true,
            ),
            const SizedBox(height: AppConstants.spacing16),
            Row(
              children: [
                Expanded(
                  child: _buildCircularStatCard(
                    theme,
                    icon: Icons.auto_awesome_outlined,
                    title: 'Avg Strength',
                    value: analytics.avgStrength,
                    suffix: '%',
                  ),
                ),
                const SizedBox(width: AppConstants.spacing16),
                Expanded(
                  child: _buildCircularStatCard(
                    theme,
                    icon: Icons.star_outline,
                    title: 'Favourite Rate',
                    value: analytics.favouriteRate,
                    suffix: '%',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacing16),
            _buildStatCard(
              theme,
              icon: Icons.local_fire_department_outlined,
              title: 'Current Streak',
              value: '${analytics.streak} days',
              subtitle: analytics.streak > 0 ? 'Keep it going!' : 'Start your streak today!',
              color: AppColors.warning,
            ),
            const SizedBox(height: AppConstants.spacing16),
            _buildCategoryBarChart(theme, analytics),
            const SizedBox(height: AppConstants.spacing16),
            _buildWeeklyComparison(theme, analytics),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildLockedScreen(ThemeData theme) {
    return Scaffold(
      appBar: AdaptiveAppBar(title: 'Analytics'),
      body: Stack(
        children: [
          Opacity(
            opacity: 0.3,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.spacing24),
              child: Column(
                children: [
                  _buildPlaceholderCard(theme, Icons.edit_note_outlined, 'Total Prompts', '---'),
                  const SizedBox(height: AppConstants.spacing16),
                  Row(
                    children: [
                      Expanded(child: _buildPlaceholderCard(theme, Icons.auto_awesome_outlined, 'Avg Strength', '--')),
                      const SizedBox(width: AppConstants.spacing16),
                      Expanded(child: _buildPlaceholderCard(theme, Icons.star_outline, 'Fav Rate', '--')),
                    ],
                  ),
                  const SizedBox(height: AppConstants.spacing16),
                  _buildPlaceholderCard(theme, Icons.local_fire_department_outlined, 'Streak', '--'),
                ],
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Container(
                margin: const EdgeInsets.all(AppConstants.spacing32),
                padding: const EdgeInsets.all(AppConstants.spacing32),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(AppConstants.radiusCard),
                boxShadow: AppColors.cardShadowLight,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_outline,
                      size: 36,
                      color: AppColors.primaryLight,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacing24),
                  Text(
                    'Analytics',
                    style: AppTextStyles.title.copyWith(color: theme.colorScheme.onSurface),
                  ),
                  const SizedBox(height: AppConstants.spacing8),
                  Text(
                    'Track your prompt usage, strength scores, and productivity streaks.',
                    style: AppTextStyles.body.copyWith(color: AppColors.textSecondaryLight),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppConstants.spacing32),
                  SizedBox(
                    width: double.infinity,
                    height: AppConstants.buttonHeight,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const PaywallScreen()),
                      ),
                      child: const Text('Unlock with Premium'),
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

  Widget _buildSignInPrompt(ThemeData theme) {
    return Scaffold(
      appBar: AdaptiveAppBar(title: 'Analytics'),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.spacing32),
            child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.bar_chart_outlined,
                  size: 36,
                  color: AppColors.primaryLight,
                ),
              ),
              const SizedBox(height: AppConstants.spacing24),
              Text(
                'Sign in to view analytics',
                style: AppTextStyles.title.copyWith(color: theme.colorScheme.onSurface),
              ),
              const SizedBox(height: AppConstants.spacing8),
              Text(
                'Create an account to track your prompt history and productivity.',
                style: AppTextStyles.body.copyWith(color: AppColors.textSecondaryLight),
                textAlign: TextAlign.center,
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderCard(ThemeData theme, IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacing16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusCard),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: AppColors.textSecondaryLight),
          const SizedBox(height: AppConstants.spacing8),
          Text(title, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondaryLight)),
          const SizedBox(height: 4),
          Text(value, style: AppTextStyles.heading.copyWith(color: theme.colorScheme.onSurface)),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String value,
    String? subtitle,
    required Color color,
    bool showAnimation = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacing16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusCard),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppColors.cardShadowLight,
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 28, color: color),
          ),
          const SizedBox(width: AppConstants.spacing16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondaryLight),
                ),
                const SizedBox(height: 4),
                if (showAnimation)
                  AnimatedBuilder(
                    animation: _countAnimation,
                    builder: (context, child) {
                      final displayValue = (_countAnimation.value * int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), ''))!).toInt();
                      return Text(
                        value.contains(RegExp(r'[a-zA-Z]'))
                            ? '$displayValue ${value.split(' ').skip(1).join(' ')}'
                            : displayValue.toString(),
                        style: AppTextStyles.heading.copyWith(color: theme.colorScheme.onSurface),
                      );
                    },
                  )
                else
                  Text(
                    value,
                    style: AppTextStyles.heading.copyWith(color: theme.colorScheme.onSurface),
                  ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption.copyWith(color: color),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircularStatCard(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required int value,
    required String suffix,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacing16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusCard),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppColors.cardShadowLight,
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: AppColors.primaryLight),
          const SizedBox(height: AppConstants.spacing12),
          SizedBox(
            width: 60,
            height: 60,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: value / 100,
                  strokeWidth: 6,
                  backgroundColor: AppColors.surfaceVariantLight,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryLight),
                ),
                Center(
                  child: Text(
                    '$value$suffix',
                    style: AppTextStyles.subtitle.copyWith(
                      color: AppColors.primaryLight,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppConstants.spacing8),
          Text(title, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondaryLight)),
        ],
      ),
    );
  }

  Widget _buildCategoryBarChart(ThemeData theme, _AnalyticsData analytics) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacing16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusCard),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppColors.cardShadowLight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart_outlined, size: 20, color: AppColors.textSecondaryLight),
              const SizedBox(width: AppConstants.spacing8),
              Text(
                'Categories',
                style: AppTextStyles.subtitle.copyWith(color: theme.colorScheme.onSurface),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacing16),
          ...analytics.categoryCounts.entries.map((entry) {
            final percentage = analytics.totalPrompts > 0
                ? (entry.value / analytics.totalPrompts * 100).toInt()
                : 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppConstants.spacing12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(entry.key, style: AppTextStyles.caption),
                      Text(
                        '${entry.value}',
                        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondaryLight),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: AppColors.surfaceVariantLight,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryLight),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildWeeklyComparison(ThemeData theme, _AnalyticsData analytics) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacing16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusCard),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppColors.cardShadowLight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 20, color: AppColors.textSecondaryLight),
              const SizedBox(width: AppConstants.spacing8),
              Text(
                'This Week vs Last Week',
                style: AppTextStyles.subtitle.copyWith(color: theme.colorScheme.onSurface),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacing20),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Last Week',
                      style: AppTextStyles.caption.copyWith(color: AppColors.textSecondaryLight),
                    ),
                    const SizedBox(height: AppConstants.spacing8),
                    Container(
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariantLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '${analytics.lastWeekPrompts}',
                          style: AppTextStyles.heading.copyWith(color: theme.colorScheme.onSurface),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppConstants.spacing16),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'This Week',
                      style: AppTextStyles.caption.copyWith(color: AppColors.textSecondaryLight),
                    ),
                    const SizedBox(height: AppConstants.spacing8),
                    Container(
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '${analytics.thisWeekPrompts}',
                          style: AppTextStyles.heading.copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (analytics.thisWeekPrompts != analytics.lastWeekPrompts) ...[
            const SizedBox(height: AppConstants.spacing12),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    analytics.thisWeekPrompts > analytics.lastWeekPrompts
                        ? Icons.trending_up
                        : Icons.trending_down,
                    size: 16,
                    color: analytics.thisWeekPrompts > analytics.lastWeekPrompts
                        ? AppColors.success
                        : AppColors.warning,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    analytics.thisWeekPrompts > analytics.lastWeekPrompts
                        ? '${analytics.thisWeekPrompts - analytics.lastWeekPrompts} more than last week'
                        : '${analytics.lastWeekPrompts - analytics.thisWeekPrompts} fewer than last week',
                    style: AppTextStyles.caption.copyWith(
                      color: analytics.thisWeekPrompts > analytics.lastWeekPrompts
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  _AnalyticsData _calculateAnalytics(List<PromptModel> prompts) {
    if (prompts.isEmpty) {
      return _AnalyticsData(
        totalPrompts: 0,
        avgStrength: 0,
        favouriteRate: 0,
        streak: 0,
        categoryCounts: {},
        thisWeekPrompts: 0,
        lastWeekPrompts: 0,
      );
    }

    final totalPrompts = prompts.length;
    final avgStrength = prompts.isEmpty
        ? 0
        : (prompts.map((p) => p.strengthScore).reduce((a, b) => a + b) / prompts.length).round();

    final favouriteCount = prompts.where((p) => p.isFavourite).length;
    final favouriteRate = totalPrompts > 0 ? ((favouriteCount / totalPrompts) * 100).round() : 0;

    final categoryCounts = <String, int>{};
    for (final prompt in prompts) {
      categoryCounts[prompt.category] = (categoryCounts[prompt.category] ?? 0) + 1;
    }

    final now = DateTime.now();
    final thisWeekStart = now.subtract(Duration(days: now.weekday - 1));
    final lastWeekStart = thisWeekStart.subtract(const Duration(days: 7));

    final thisWeekPrompts = prompts.where((p) =>
        p.createdAt.isAfter(thisWeekStart) && p.createdAt.isBefore(now)).length;
    final lastWeekPrompts = prompts.where((p) =>
        p.createdAt.isAfter(lastWeekStart) && p.createdAt.isBefore(thisWeekStart)).length;

    int streak = 0;
    final uniqueDays = <DateTime>{};
    for (final prompt in prompts) {
      final date = DateTime(prompt.createdAt.year, prompt.createdAt.month, prompt.createdAt.day);
      uniqueDays.add(date);
    }
    final sortedDays = uniqueDays.toList()..sort((a, b) => b.compareTo(a));

    if (sortedDays.isNotEmpty) {
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));

      if (sortedDays.first == today || sortedDays.first == yesterday) {
        streak = 1;
        for (int i = 1; i < sortedDays.length; i++) {
          final expectedPrev = sortedDays[i - 1].subtract(const Duration(days: 1));
          if (sortedDays[i] == expectedPrev) {
            streak++;
          } else {
            break;
          }
        }
      }
    }

    return _AnalyticsData(
      totalPrompts: totalPrompts,
      avgStrength: avgStrength,
      favouriteRate: favouriteRate,
      streak: streak,
      categoryCounts: categoryCounts,
      thisWeekPrompts: thisWeekPrompts,
      lastWeekPrompts: lastWeekPrompts,
    );
  }
}

class _AnalyticsData {
  final int totalPrompts;
  final int avgStrength;
  final int favouriteRate;
  final int streak;
  final Map<String, int> categoryCounts;
  final int thisWeekPrompts;
  final int lastWeekPrompts;

  _AnalyticsData({
    required this.totalPrompts,
    required this.avgStrength,
    required this.favouriteRate,
    required this.streak,
    required this.categoryCounts,
    required this.thisWeekPrompts,
    required this.lastWeekPrompts,
  });
}
