import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/page_header.dart';
import '../../providers/auth_provider.dart';
import '../../providers/premium_provider.dart';
import '../../providers/theme_provider.dart';
import '../auth/login_screen.dart';
import '../paywall/paywall_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _handleSignOut(
    BuildContext context,
    AuthProvider authProvider,
  ) async {
    await authProvider.signOut();
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Signed out successfully.')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();
    final premiumProvider = context.watch<PremiumProvider>();
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 160),
          children: [
            const PageHeader(
              title: 'Settings',
              subtitle: 'Preferences, account, and app details.',
            ),
            const SizedBox(height: AppConstants.spacing20),
            GestureDetector(
              onTap: premiumProvider.hasPremiumAccess
                  ? null
                  : () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PaywallScreen()),
                    ),
              child: Container(
                padding: const EdgeInsets.all(AppConstants.spacing20),
                decoration: BoxDecoration(
                  gradient: premiumProvider.hasPremiumAccess
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
                            premiumProvider.hasPremiumAccess
                                ? 'Premium active'
                                : 'Upgrade to Premium',
                            style: AppTextStyles.heading.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: AppConstants.spacing8),
                          Text(
                            premiumProvider.hasPremiumAccess
                                ? 'Unlocked tones, deeper prompt shaping, and pro insights.'
                                : 'Unlock premium tones, deeper refinement, and richer insights.',
                            style: AppTextStyles.body.copyWith(
                              color: Colors.white.withValues(alpha: 0.82),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacing16),
                    Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.workspace_premium_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppConstants.spacing24),
            _SettingsGroup(
              title: 'Appearance',
              child: Column(
                children: [
                  _ThemeOptionTile(
                    label: 'System',
                    subtitle: 'Follow the device appearance',
                    selected: themeProvider.themeMode == ThemeMode.system,
                    onTap: () => themeProvider.setTheme(ThemeMode.system),
                  ),
                  _ThemeOptionTile(
                    label: 'Light',
                    subtitle: 'Bright surfaces and soft contrast',
                    selected: themeProvider.themeMode == ThemeMode.light,
                    onTap: () => themeProvider.setTheme(ThemeMode.light),
                  ),
                  _ThemeOptionTile(
                    label: 'Dark',
                    subtitle: 'Low-glare surfaces and muted edges',
                    selected: themeProvider.themeMode == ThemeMode.dark,
                    onTap: () => themeProvider.setTheme(ThemeMode.dark),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.spacing24),
            _SettingsGroup(
              title: 'Account',
              child: authProvider.isAuthenticated
                  ? Padding(
                      padding: const EdgeInsets.all(AppConstants.spacing16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: const BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  ((authProvider.currentUser?.displayName ??
                                                  authProvider
                                                      .currentUser
                                                      ?.email ??
                                                  'P')
                                              .trim()
                                              .isEmpty
                                          ? 'P'
                                          : (authProvider
                                                    .currentUser
                                                    ?.displayName ??
                                                authProvider
                                                    .currentUser
                                                    ?.email ??
                                                'P')[0])
                                      .toUpperCase(),
                                  style: AppTextStyles.subtitle.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppConstants.spacing16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      authProvider.currentUser?.displayName ??
                                          'Signed in',
                                      style: AppTextStyles.subtitle.copyWith(
                                        color: theme.colorScheme.onSurface,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(
                                      height: AppConstants.spacing4,
                                    ),
                                    Text(
                                      authProvider.currentUser?.email ?? '',
                                      style: AppTextStyles.body.copyWith(
                                        color: theme.hintColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (authProvider.error != null) ...[
                            const SizedBox(height: AppConstants.spacing12),
                            Text(
                              authProvider.error!,
                              style: AppTextStyles.body.copyWith(
                                color: theme.colorScheme.error,
                              ),
                            ),
                          ],
                          const SizedBox(height: AppConstants.spacing16),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: authProvider.isLoading
                                  ? null
                                  : () => _handleSignOut(context, authProvider),
                              child: const Text('Sign out'),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(AppConstants.spacing16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sign in to sync your prompts',
                            style: AppTextStyles.subtitle.copyWith(
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: AppConstants.spacing4),
                          Text(
                            'Save history and access your prompts across devices.',
                            style: AppTextStyles.body.copyWith(
                              color: theme.hintColor,
                            ),
                          ),
                          const SizedBox(height: AppConstants.spacing16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const LoginScreen(),
                                ),
                              ),
                              child: const Text('Sign in'),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: AppConstants.spacing24),
            _SettingsGroup(
              title: 'About',
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.spacing16),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusControl,
                        ),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacing16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Prompt v1',
                          style: AppTextStyles.subtitle.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.sectionLabel.copyWith(
            color: Theme.of(context).hintColor,
          ),
        ),
        const SizedBox(height: AppConstants.spacing12),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(AppConstants.radiusCard),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: child,
        ),
      ],
    );
  }
}

class _ThemeOptionTile extends StatelessWidget {
  const _ThemeOptionTile({
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryLight.withValues(alpha: 0.14)
              : Theme.of(context).dividerColor.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(AppConstants.radiusControl),
        ),
        child: Icon(
          selected ? Icons.check_rounded : Icons.circle_outlined,
          size: 18,
          color: selected
              ? AppColors.primaryLight
              : Theme.of(context).hintColor,
        ),
      ),
      title: Text(label, style: AppTextStyles.subtitle),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.body.copyWith(color: Theme.of(context).hintColor),
      ),
    );
  }
}
