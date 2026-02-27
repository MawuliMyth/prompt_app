import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text(
          'This action cannot be undone. All your data, including saved prompts and favourites, will be permanently deleted.\n\nAre you sure you want to delete your account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await authProvider.deleteAccount();
      if (!success && context.mounted && authProvider.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authProvider.error!)),
        );
      }
    }
  }

  Future<void> _showSignOutConfirmation(BuildContext context, AuthProvider authProvider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out?'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await authProvider.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Settings', style: AppTextStyles.headingLarge.copyWith(color: AppColors.primaryLight)),
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          children: [
             // Section: Account
             _buildSectionHeader('Account', theme),
             if (authProvider.isAuthenticated) ...[
                ListTile(
                   contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                   leading: CircleAvatar(
                      backgroundColor: AppColors.primaryLight,
                      child: Text(
                        authProvider.currentUser?.displayName?.isNotEmpty == true ? authProvider.currentUser!.displayName![0].toUpperCase() : 'U',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                   ),
                   title: Text(authProvider.currentUser?.displayName ?? 'User', style: AppTextStyles.button.copyWith(color: theme.colorScheme.onSurface)),
                   subtitle: Text(authProvider.currentUser?.email ?? '', style: AppTextStyles.body.copyWith(color: AppColors.textSecondaryLight)),
                ),
             ] else ...[
                 ListTile(
                   contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                   leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.surface,
                      child: const Icon(Icons.person_outline, color: AppColors.textSecondaryLight),
                   ),
                   title: Text('Sign in to sync your prompts', style: AppTextStyles.body.copyWith(color: theme.colorScheme.onSurface)),
                   trailing: ElevatedButton(
                      onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
                      },
                      style: ElevatedButton.styleFrom(
                         padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: const Text('Sign In'),
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
                    SegmentedButton<ThemeMode>(
                       segments: const [
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
                      'Theme follows system settings by default',
                      style: AppTextStyles.caption.copyWith(color: AppColors.textSecondaryLight),
                    ),
                  ],
                ),
             ),

             const Divider(height: 32),

             // Section: App
             _buildSectionHeader('App', theme),
             _buildListTile('Rate the app', Icons.star_rate_outlined, theme),
             _buildListTile('Share the app', Icons.ios_share, theme, onTap: () => SharePlus.instance.share(ShareParams(text: 'Check out the new Prompt App to turn rough thoughts into perfect interactions.'))),
             _buildListTile(
               'Privacy Policy',
               Icons.privacy_tip_outlined,
               theme,
               onTap: () => _launchUrl(_privacyPolicyUrl),
             ),
             _buildListTile(
               'Terms of Service',
               Icons.description_outlined,
               theme,
               onTap: () => _launchUrl(_termsOfServiceUrl),
             ),
             ListTile(
                 contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                 title: Text('App version', style: AppTextStyles.body.copyWith(color: theme.colorScheme.onSurface)),
                 trailing: Text('1.0.0', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondaryLight)),
             ),

             if (authProvider.isAuthenticated) ...[
                const Divider(height: 32),
                _buildSectionHeader('Account Actions', theme),
                ListTile(
                   contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                   title: Text('Sign Out', style: AppTextStyles.button.copyWith(color: AppColors.primaryLight)),
                   onTap: () => _showSignOutConfirmation(context, authProvider),
                ),
                ListTile(
                   contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                   title: Text('Delete Account', style: AppTextStyles.button.copyWith(color: AppColors.textSecondaryLight)),
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

  Widget _buildListTile(String title, IconData icon, ThemeData theme, {VoidCallback? onTap}) {
     return ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 24),
        leading: Icon(icon, color: AppColors.textSecondaryLight),
        title: Text(title, style: AppTextStyles.body.copyWith(color: theme.colorScheme.onSurface)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondaryLight),
        onTap: onTap,
     );
  }
}
