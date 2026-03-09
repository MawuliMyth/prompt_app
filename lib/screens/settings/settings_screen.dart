import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/platform_utils.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../core/widgets/adaptive_widgets.dart';
import '../../core/widgets/profile_avatar.dart';
import '../../providers/auth_provider.dart';
import '../../providers/premium_provider.dart';
import '../../providers/theme_provider.dart';
import '../auth/login_screen.dart';
import '../paywall/paywall_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const String _privacyPolicyUrl =
      'https://promptapp-legal.netlify.app/privacy.html';
  static const String _termsUrl =
      'https://promptapp-legal.netlify.app/terms.html';

  Future<void> _handleSignOut(
    BuildContext context,
    AuthProvider authProvider,
  ) async {
    await authProvider.signOut();
    if (!context.mounted) return;
    SnackbarUtils.showSuccess(context, 'Signed out successfully.');
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  Future<void> _handleLaunchUrl(BuildContext context, String url) async {
    try {
      await _launchURL(url);
    } catch (_) {
      if (!context.mounted) return;
      SnackbarUtils.showError(context, 'Unable to open link right now.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();
    final premiumProvider = context.watch<PremiumProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isIOS = PlatformUtils.isIOS;

    return AdaptiveScaffold(
      appBar: const AdaptiveAppBar(
        title: 'Settings',
        backgroundColor: Colors.transparent,
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 160),
          children: [
            Text(
              'Preferences, account, and app details.',
              style: AppTextStyles.body.copyWith(color: theme.hintColor),
            ),
            const SizedBox(height: AppConstants.spacing20),
            GestureDetector(
              onTap: premiumProvider.hasPremiumAccess
                  ? null
                  : () => PlatformUtils.navigateTo(
                      context,
                      const PaywallScreen(),
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
                                ? 'Prompt Pro'
                                : 'Upgrade to Premium',
                            style: AppTextStyles.heading.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: AppConstants.spacing8),
                          if (!premiumProvider.hasPremiumAccess)
                            Text(
                              'Unlock premium tones, deeper refinement, and richer insights.',
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
              title: 'Account',
              child: authProvider.isAuthenticated
                  ? Padding(
                      padding: const EdgeInsets.all(AppConstants.spacing16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                               ProfileAvatar(
                                 photoUrl: authProvider.currentUser?.photoURL,
                                 fallbackLabel:
                                     (authProvider.currentUser?.displayName ??
                                             authProvider.currentUser?.email ??
                                             'P')
                                         .trim(),
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
                          if (!(authProvider.currentUser?.emailVerified ?? true) &&
                              (authProvider.currentUser?.email?.isNotEmpty ?? false)) ...[
                            const SizedBox(height: AppConstants.spacing16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(
                                AppConstants.spacing16,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(
                                  AppConstants.radiusCard,
                                ),
                                border: Border.all(color: theme.dividerColor),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Verify your email to unlock the free trial.',
                                    style: AppTextStyles.subtitle.copyWith(
                                      color: theme.colorScheme.onSurface,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: AppConstants.spacing8),
                                  Text(
                                    'Didn\'t get the message? Resend it, then tap refresh after you verify.',
                                    style: AppTextStyles.body.copyWith(
                                      color: theme.hintColor,
                                    ),
                                  ),
                                  const SizedBox(height: AppConstants.spacing16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: AdaptiveButton(
                                          label: 'Resend Email',
                                          filled: !isIOS,
                                          onPressed: authProvider.isLoading
                                              ? null
                                              : () async {
                                                  final success =
                                                      await authProvider
                                                          .resendEmailVerification();
                                                  if (!context.mounted) return;
                                                  if (success) {
                                                    SnackbarUtils.showSuccess(
                                                      context,
                                                      'Verification email sent.',
                                                    );
                                                  } else if (authProvider.error !=
                                                      null) {
                                                    SnackbarUtils.showError(
                                                      context,
                                                      authProvider.error!,
                                                    );
                                                  }
                                                },
                                        ),
                                      ),
                                      const SizedBox(width: AppConstants.spacing12),
                                      Expanded(
                                        child: AdaptiveButton(
                                          label: 'Refresh',
                                          filled: false,
                                          foregroundColor:
                                              theme.colorScheme.onSurface,
                                          backgroundColor:
                                              theme.colorScheme.surface,
                                          onPressed: authProvider.isLoading
                                              ? null
                                              : () async {
                                                  await authProvider
                                                      .refreshCurrentUser();
                                                  if (!context.mounted) return;
                                                  if (authProvider
                                                          .currentUser
                                                          ?.emailVerified ==
                                                      true) {
                                                    SnackbarUtils.showSuccess(
                                                      context,
                                                      'Email verified successfully.',
                                                    );
                                                  } else {
                                                    SnackbarUtils.showInfo(
                                                      context,
                                                      'Your email is not verified yet.',
                                                    );
                                                  }
                                                },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: AppConstants.spacing16),
                          SizedBox(
                            width: double.infinity,
                            child: AdaptiveButton(
                              label: 'Sign out',
                              filled: !isIOS,
                              onPressed: authProvider.isLoading
                                  ? null
                                  : () => _handleSignOut(context, authProvider),
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
                            child: AdaptiveButton(
                              label: 'Sign in',
                              onPressed: () => PlatformUtils.navigateTo(
                                context,
                                const LoginScreen(),
                              ),
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
                    icon: Icons.brightness_auto_rounded,
                    selected: themeProvider.themeMode == ThemeMode.system,
                    onTap: () => themeProvider.setTheme(ThemeMode.system),
                  ),
                  _ThemeOptionTile(
                    label: 'Light',
                    subtitle: null,
                    icon: Icons.light_mode_rounded,
                    selected: themeProvider.themeMode == ThemeMode.light,
                    onTap: () => themeProvider.setTheme(ThemeMode.light),
                  ),
                  _ThemeOptionTile(
                    label: 'Dark',
                    subtitle: null,
                    icon: Icons.dark_mode_rounded,
                    selected: themeProvider.themeMode == ThemeMode.dark,
                    onTap: () => themeProvider.setTheme(ThemeMode.dark),
                  ),
                ],
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
            const SizedBox(height: AppConstants.spacing24),
            _SettingsGroup(
              title: 'Legal',
              child: Column(
                children: [
                  AdaptiveListTile(
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: 'Privacy Policy',
                    onTap: () => _handleLaunchUrl(context, _privacyPolicyUrl),
                  ),
                  Divider(height: 1, color: theme.dividerColor),
                  AdaptiveListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: 'Terms & Conditions',
                    onTap: () => _handleLaunchUrl(context, _termsUrl),
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
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String? subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AdaptiveListTile(
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
          icon,
          size: 18,
          color: selected
              ? AppColors.primaryLight
              : Theme.of(context).hintColor,
        ),
      ),
      title: label,
      subtitle: subtitle,
    );
  }
}
