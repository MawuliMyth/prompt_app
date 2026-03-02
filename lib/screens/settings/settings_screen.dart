import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/adaptive_widgets.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/premium_provider.dart';
import '../paywall/paywall_screen.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final premiumProvider = Provider.of<PremiumProvider>(context);

    return Scaffold(
      appBar: AdaptiveAppBar(title: 'Settings'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.spacing24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Premium Status Card
            if (premiumProvider.hasPremiumAccess)
              _buildPremiumCard(theme)
            else
              _buildUpgradeCard(theme),

            const SizedBox(height: AppConstants.spacing32),

            // Theme Section
            _buildSectionHeader('Appearance'),
            const SizedBox(height: AppConstants.spacing12),
            _buildThemeSelector(theme, themeProvider),

            const SizedBox(height: AppConstants.spacing32),

            // Account Section
            _buildSectionHeader('Account'),
            const SizedBox(height: AppConstants.spacing12),
            if (authProvider.isAuthenticated)
              _buildAccountInfo(theme, authProvider)
            else
              _buildSignInPrompt(theme),

            const SizedBox(height: AppConstants.spacing32),

            // App Info
            _buildSectionHeader('About'),
            const SizedBox(height: AppConstants.spacing12),
            _buildAppInfo(theme),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppTextStyles.caption.copyWith(
        color: AppColors.textSecondaryLight,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildPremiumCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacing20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppConstants.radiusCard),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppConstants.spacing12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.workspace_premium,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: AppConstants.spacing16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Premium Active',
                  style: AppTextStyles.subtitle.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Enjoy all premium features',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpgradeCard(ThemeData theme) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PaywallScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppConstants.spacing20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppConstants.radiusCard),
          border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.3)),
          boxShadow: AppColors.cardShadowLight,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppConstants.spacing12),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.auto_awesome_outlined,
                color: AppColors.primaryLight,
                size: 24,
              ),
            ),
            const SizedBox(width: AppConstants.spacing16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upgrade to Premium',
                    style: AppTextStyles.subtitle.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Unlock all features and unlimited prompts',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.textSecondaryLight,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSelector(ThemeData theme, ThemeProvider themeProvider) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusCard),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          _buildThemeOption(
            theme,
            icon: Icons.brightness_auto_outlined,
            title: 'System',
            subtitle: 'Follow system settings',
            value: ThemeMode.system,
            themeProvider: themeProvider,
          ),
          Divider(height: 1, color: AppColors.borderLight),
          _buildThemeOption(
            theme,
            icon: Icons.light_mode_outlined,
            title: 'Light',
            subtitle: 'Always use light theme',
            value: ThemeMode.light,
            themeProvider: themeProvider,
          ),
          Divider(height: 1, color: AppColors.borderLight),
          _buildThemeOption(
            theme,
            icon: Icons.dark_mode_outlined,
            title: 'Dark',
            subtitle: 'Always use dark theme',
            value: ThemeMode.dark,
            themeProvider: themeProvider,
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String subtitle,
    required ThemeMode value,
    required ThemeProvider themeProvider,
  }) {
    final isSelected = themeProvider.themeMode == value;

    return InkWell(
      onTap: () => themeProvider.setTheme(value),
      borderRadius: BorderRadius.circular(AppConstants.radiusCard),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacing16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppConstants.spacing8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryLight.withValues(alpha: 0.1)
                    : AppColors.surfaceVariantLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected
                    ? AppColors.primaryLight
                    : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(width: AppConstants.spacing16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.body.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppColors.primaryLight,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountInfo(ThemeData theme, AuthProvider authProvider) {
    final user = authProvider.currentUser;
    final displayName = user?.displayName ?? 'User';
    final email = user?.email ?? '';

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusCard),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppConstants.spacing16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primaryLight.withValues(alpha: 0.1),
                  child: Text(
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                    style: AppTextStyles.heading.copyWith(
                      color: AppColors.primaryLight,
                    ),
                  ),
                ),
                const SizedBox(width: AppConstants.spacing16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: AppTextStyles.subtitle.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      if (email.isNotEmpty)
                        Text(
                          email,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.borderLight),
          _buildSettingItem(
            theme,
            icon: Icons.logout,
            title: 'Sign Out',
            subtitle: 'Sign out of your account',
            isDestructive: true,
            onTap: () => _showSignOutDialog(theme, authProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildSignInPrompt(ThemeData theme) {
    return GestureDetector(
      onTap: () {
        // Navigate to login screen
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(AppConstants.spacing20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppConstants.radiusCard),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppConstants.spacing12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariantLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.person_outline,
                color: AppColors.textSecondaryLight,
                size: 24,
              ),
            ),
            const SizedBox(width: AppConstants.spacing16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Not signed in',
                    style: AppTextStyles.subtitle.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sign in to sync your data across devices',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondaryLight,
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

  Widget _buildSettingItem(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String subtitle,
    bool isDestructive = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacing16),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isDestructive ? AppColors.error : AppColors.textSecondaryLight,
            ),
            const SizedBox(width: AppConstants.spacing16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.body.copyWith(
                      color: isDestructive ? AppColors.error : theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondaryLight,
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

  Widget _buildAppInfo(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacing20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusCard),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppConstants.spacing12),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppConstants.spacing16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Prompt Enhancer',
                      style: AppTextStyles.subtitle.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Version 1.0.0',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog(ThemeData theme, AuthProvider authProvider) {
    if (PlatformUtils.useCupertino(context)) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Sign Out'),
          content: const Text('Are you sure you want to sign out?'),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.pop(context);
                authProvider.signOut();
              },
              child: const Text('Sign Out'),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Sign Out'),
          content: const Text('Are you sure you want to sign out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                authProvider.signOut();
              },
              child: Text(
                'Sign Out',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        ),
      );
    }
  }
}

class PlatformUtils {
  static bool useCupertino(BuildContext context) {
    final platform = Theme.of(context).platform;
    return platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
  }
}
