import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/adaptive_widgets.dart';
import '../../core/utils/platform_utils.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // Privacy Policy URL - replace with your actual URL
  static const String _privacyPolicyUrl = 'https://yourdomain.com/privacy';
  static const String _termsOfServiceUrl = 'https://yourdomain.com/terms';

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _showDeleteAccountConfirmation(BuildContext context, AuthProvider authProvider) async {
    final confirmed = await AdaptiveDialog.show(
      context: context,
      title: 'Delete Account?',
      content: 'This action cannot be undone. All your data, including saved prompts and favourites, will be permanently deleted.',
      cancelText: 'Cancel',
      confirmText: 'Delete',
      isDestructive: true,
    );

    if (confirmed == true && context.mounted) {
      final success = await authProvider.deleteAccount();
      if (!success && context.mounted && authProvider.error != null) {
        _showErrorSnackbar(context, authProvider.error!);
      }
    }
  }

  Future<void> _showSignOutConfirmation(BuildContext context, AuthProvider authProvider) async {
    final confirmed = await AdaptiveDialog.show(
      context: context,
      title: 'Sign Out?',
      content: 'Are you sure you want to sign out?',
      cancelText: 'Cancel',
      confirmText: 'Sign Out',
    );

    if (confirmed == true) {
      await authProvider.signOut();
    }
  }

  void _showErrorSnackbar(BuildContext context, String message) {
    final isCupertino = PlatformUtils.useCupertino(context);
    if (isCupertino) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: CupertinoColors.destructiveRed),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isCupertino = PlatformUtils.useCupertino(context);

    return SafeArea(
      child: Scaffold(
        appBar: AdaptiveAppBar(title: 'Settings'),
        body: ListView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          children: [
             // Section: Account
             _buildSectionHeader('Account', theme),
             if (authProvider.isAuthenticated) ...[
                AdaptiveListTile(
                   leading: CircleAvatar(
                      backgroundColor: AppColors.primaryLight,
                      child: Text(
                        authProvider.currentUser?.displayName?.isNotEmpty == true ? authProvider.currentUser!.displayName![0].toUpperCase() : 'U',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                   ),
                   title: authProvider.currentUser?.displayName ?? 'User',
                   subtitle: authProvider.currentUser?.email ?? '',
                ),
             ] else ...[
                 AdaptiveListTile(
                   leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.surface,
                      child: const Icon(Icons.person_outline, color: AppColors.textSecondaryLight),
                   ),
                   title: 'Sign in to sync your prompts',
                   trailing: AdaptiveButton(
                      label: 'Sign In',
                      onPressed: () => PlatformUtils.navigateTo(context, const LoginScreen()),
                      filled: false,
                   ),
                ),
             ],

             const Divider(height: 32),

             // Section: Appearance
             _buildSectionHeader('Appearance', theme),
             Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isCupertino)
                      CupertinoSegmentedControl<ThemeMode>(
                        groupValue: themeProvider.themeMode,
                        onValueChanged: (mode) => themeProvider.setTheme(mode),
                        children: const {
                          ThemeMode.system: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(CupertinoIcons.brightness, size: 16),
                              SizedBox(width: 4),
                              Text('System'),
                            ]),
                          ),
                          ThemeMode.light: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(CupertinoIcons.sun_max, size: 16),
                              SizedBox(width: 4),
                              Text('Light'),
                            ]),
                          ),
                          ThemeMode.dark: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(CupertinoIcons.moon, size: 16),
                              SizedBox(width: 4),
                              Text('Dark'),
                            ]),
                          ),
                        },
                      )
                    else
                      SegmentedButton<ThemeMode>(
                        segments: const [
                          ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.brightness_auto), label: Text('System')),
                          ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode), label: Text('Light')),
                          ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode), label: Text('Dark')),
                        ],
                        selected: {themeProvider.themeMode},
                        onSelectionChanged: (Set<ThemeMode> newSelection) {
                          themeProvider.setTheme(newSelection.first);
                        },
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.resolveWith<Color>(
                             (Set<WidgetState> states) {
                                if (states.contains(WidgetState.selected)) return AppColors.primaryLight.withValues(alpha: 0.1);
                                return Colors.transparent;
                             },
                          ),
                          foregroundColor: WidgetStateProperty.resolveWith<Color>(
                             (Set<WidgetState> states) {
                                if (states.contains(WidgetState.selected)) return AppColors.primaryLight;
                                return theme.colorScheme.onSurface;
                             },
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      'System mode follows your device settings',
                      style: AppTextStyles.caption.copyWith(color: AppColors.textSecondaryLight),
                    ),
                  ],
                ),
             ),

             const Divider(height: 32),

             // Section: App
             _buildSectionHeader('App', theme),
             _buildListTile('Rate the app', Icons.star_rate_outlined, CupertinoIcons.star, theme),
             _buildListTile(
               'Share the app',
               Icons.ios_share,
               CupertinoIcons.share,
               theme,
               onTap: () => SharePlus.instance.share(ShareParams(text: 'Check out the new Prompt App to turn rough thoughts into perfect interactions.')),
             ),
             _buildListTile(
               'Privacy Policy',
               Icons.privacy_tip_outlined,
               CupertinoIcons.shield,
               theme,
               onTap: () => _launchUrl(_privacyPolicyUrl),
             ),
             _buildListTile(
               'Terms of Service',
               Icons.description_outlined,
               CupertinoIcons.doc_text,
               theme,
               onTap: () => _launchUrl(_termsOfServiceUrl),
             ),
             AdaptiveListTile(
               title: 'App version',
               trailing: Text('1.0.0', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondaryLight)),
             ),

             if (authProvider.isAuthenticated) ...[
                const Divider(height: 32),
                _buildSectionHeader('Account Actions', theme),
                AdaptiveListTile(
                   title: 'Sign Out',
                   trailing: Icon(isCupertino ? CupertinoIcons.square_arrow_right : Icons.logout, color: AppColors.primaryLight),
                   onTap: () => _showSignOutConfirmation(context, authProvider),
                ),
                AdaptiveListTile(
                   title: 'Delete Account',
                   trailing: Icon(isCupertino ? CupertinoIcons.delete : Icons.delete_outline, color: AppColors.textSecondaryLight),
                   onTap: () => _showDeleteAccountConfirmation(context, authProvider),
                ),
             ]
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
     return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Text(
           title,
           style: AppTextStyles.headingSmall.copyWith(color: theme.colorScheme.onSurface),
        ),
     );
  }

  Widget _buildListTile(String title, IconData materialIcon, IconData cupertinoIcon, ThemeData theme, {VoidCallback? onTap}) {
     final isCupertino = !kIsWeb && (Platform.isIOS || Platform.isMacOS);
     return AdaptiveListTile(
        leading: Icon(isCupertino ? cupertinoIcon : materialIcon, color: AppColors.textSecondaryLight),
        title: title,
        trailing: Icon(isCupertino ? CupertinoIcons.chevron_right : Icons.chevron_right, color: AppColors.textSecondaryLight),
        onTap: onTap,
     );
  }
}
