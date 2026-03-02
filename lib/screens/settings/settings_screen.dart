import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/premium_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/adaptive_widgets.dart';
import '../../core/utils/platform_utils.dart';
import '../auth/login_screen.dart';
import '../paywall/paywall_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const String _privacyPolicyUrl = 'https://yourdomain.com/privacy';
  static const String _termsOfServiceUrl = 'https://yourdomain.com/terms';

  final TextEditingController _personaController = TextEditingController();
  bool _isSavingPersona = false;
  bool _personaInitialized = false;

  @override
  void dispose() {
    _personaController.dispose();
    super.dispose();
  }

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
    final premiumProvider = Provider.of<PremiumProvider>(context);
    final isCupertino = PlatformUtils.useCupertino(context);

    return Scaffold(
      appBar: const AdaptiveAppBar(title: 'Settings'),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppConstants.spacing24),
        children: [
          // Section: Premium Status
          if (authProvider.isAuthenticated) ...[
            _buildSectionHeader('Subscription', theme),
            _buildPremiumTile(context, theme, premiumProvider, isCupertino),
            _buildDivider(),
          ],

          // Section: AI Persona (Premium Feature)
          if (authProvider.isAuthenticated) ...[
            _buildSectionHeader('AI Personalization', theme),
            _buildPersonaSection(context, theme, premiumProvider, isCupertino),
            _buildDivider(),
          ],

          // Section: Account
          _buildSectionHeader('Account', theme),
          if (authProvider.isAuthenticated) ...[
            _buildAccountTile(theme, authProvider, premiumProvider),
          ] else ...[
            _buildSignInPrompt(theme),
          ],

          _buildDivider(),

          // Section: Appearance
          _buildSectionHeader('Appearance', theme),
          _buildThemeSelector(theme, themeProvider, isCupertino),

          _buildDivider(),

          // Section: App
          _buildSectionHeader('App', theme),
          _buildListTile('Rate the app', Icons.star_rate_outlined, CupertinoIcons.star, theme),
          _buildListTile(
            'Share the app',
            Icons.ios_share,
            CupertinoIcons.share,
            theme,
            onTap: () => SharePlus.instance.share(
              ShareParams(text: 'Check out Prompt - turn rough thoughts into perfect prompts.'),
            ),
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
            trailing: Text(
              '1.0.0',
              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondaryLight),
            ),
          ),

          if (authProvider.isAuthenticated) ...[
            _buildDivider(),
            _buildSectionHeader('Account Actions', theme),
            AdaptiveListTile(
              title: 'Sign Out',
              trailing: Icon(
                isCupertino ? CupertinoIcons.square_arrow_right : Icons.logout,
                color: AppColors.primaryLight,
              ),
              onTap: () => _showSignOutConfirmation(context, authProvider),
            ),
            AdaptiveListTile(
              title: 'Delete Account',
              trailing: Icon(
                isCupertino ? CupertinoIcons.delete : Icons.delete_outline,
                color: AppColors.textSecondaryLight,
              ),
              onTap: () => _showDeleteAccountConfirmation(context, authProvider),
            ),
          ],

          const SizedBox(height: AppConstants.spacing48),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: AppConstants.spacing32, thickness: 0.5);
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacing24,
        vertical: AppConstants.spacing8,
      ),
      child: Text(
        title,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.textSecondaryLight,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildAccountTile(ThemeData theme, AuthProvider authProvider, PremiumProvider premiumProvider) {
    // Use Firestore UserModel data as primary source, fallback to Firebase Auth
    final userData = premiumProvider.userData;
    final firestoreName = userData?.displayName;
    final authName = authProvider.currentUser?.displayName;
    final displayName = (firestoreName?.isNotEmpty == true)
        ? firestoreName!
        : (authName?.isNotEmpty == true ? authName! : 'User');
    final email = (userData?.email?.isNotEmpty == true)
        ? userData!.email
        : (authProvider.currentUser?.email ?? '');
    final photoUrl = userData?.photoUrl ?? authProvider.currentUser?.photoURL;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppConstants.spacing16),
      padding: const EdgeInsets.all(AppConstants.spacing16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusCard),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primaryLight,
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
            child: photoUrl == null
                ? Text(
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  )
                : null,
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
                const SizedBox(height: 2),
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
    );
  }

  Widget _buildSignInPrompt(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppConstants.spacing16),
      padding: const EdgeInsets.all(AppConstants.spacing16),
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
            child: Text(
              'Sign in to sync your prompts',
              style: AppTextStyles.subtitle.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          TextButton(
            onPressed: () => PlatformUtils.navigateTo(context, const LoginScreen()),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryLight,
            ),
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSelector(ThemeData theme, ThemeProvider themeProvider, bool isCupertino) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacing24,
        vertical: AppConstants.spacing12,
      ),
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(CupertinoIcons.brightness, size: 16),
                      SizedBox(width: 4),
                      Text('System'),
                    ],
                  ),
                ),
                ThemeMode.light: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(CupertinoIcons.sun_max, size: 16),
                      SizedBox(width: 4),
                      Text('Light'),
                    ],
                  ),
                ),
                ThemeMode.dark: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(CupertinoIcons.moon, size: 16),
                      SizedBox(width: 4),
                      Text('Dark'),
                    ],
                  ),
                ),
              },
            )
          else
            SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: Icon(Icons.brightness_auto),
                  label: Text('System'),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode),
                  label: Text('Light'),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode),
                  label: Text('Dark'),
                ),
              ],
              selected: {themeProvider.themeMode},
              onSelectionChanged: (Set<ThemeMode> newSelection) {
                themeProvider.setTheme(newSelection.first);
              },
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith<Color>(
                  (Set<WidgetState> states) {
                    if (states.contains(WidgetState.selected)) {
                      return AppColors.primaryLight.withValues(alpha: 0.1);
                    }
                    return Colors.transparent;
                  },
                ),
                foregroundColor: WidgetStateProperty.resolveWith<Color>(
                  (Set<WidgetState> states) {
                    if (states.contains(WidgetState.selected)) {
                      return AppColors.primaryLight;
                    }
                    return theme.colorScheme.onSurface;
                  },
                ),
              ),
            ),
          const SizedBox(height: AppConstants.spacing8),
          Text(
            'System mode follows your device settings',
            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondaryLight),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(
    String title,
    IconData materialIcon,
    IconData cupertinoIcon,
    ThemeData theme, {
    VoidCallback? onTap,
  }) {
    final useCupertino = !kIsWeb && (Platform.isIOS || Platform.isMacOS);
    return AdaptiveListTile(
      leading: Icon(
        useCupertino ? cupertinoIcon : materialIcon,
        color: AppColors.textSecondaryLight,
      ),
      title: title,
      trailing: Icon(
        useCupertino ? CupertinoIcons.chevron_right : Icons.chevron_right,
        color: AppColors.textSecondaryLight,
        size: 18,
      ),
      onTap: onTap,
    );
  }

  Widget _buildPremiumTile(
    BuildContext context,
    ThemeData theme,
    PremiumProvider premiumProvider,
    bool isCupertino,
  ) {
    final hasPremium = premiumProvider.hasPremiumAccess;
    final isTrial = premiumProvider.isTrialActive;
    final planType = premiumProvider.planType;
    final daysLeft = premiumProvider.daysLeftInTrial;

    if (hasPremium) {
      String statusText;
      String subtitle;
      if (isTrial) {
        statusText = 'Trial Active';
        subtitle = '$daysLeft days remaining';
      } else if (planType == 'lifetime') {
        statusText = 'Premium';
        subtitle = 'Lifetime access';
      } else if (planType == 'yearly') {
        statusText = 'Premium';
        subtitle = 'Yearly subscription';
      } else if (planType == 'monthly') {
        statusText = 'Premium';
        subtitle = 'Monthly subscription';
      } else {
        statusText = 'Premium';
        subtitle = 'Active';
      }

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: AppConstants.spacing16),
        padding: const EdgeInsets.all(AppConstants.spacing16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppConstants.radiusCard),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
          boxShadow: AppColors.cardShadowLight,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppConstants.spacing12),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 24,
              ),
            ),
            const SizedBox(width: AppConstants.spacing16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusText,
                    style: AppTextStyles.subtitle.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
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
      );
    }

    // Show upgrade option
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PaywallScreen()),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppConstants.spacing16),
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
              padding: const EdgeInsets.all(AppConstants.spacing12),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.workspace_premium_outlined,
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
                  const SizedBox(height: 2),
                  Text(
                    'Unlock unlimited prompts & advanced AI',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(AppConstants.spacing8),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isCupertino ? CupertinoIcons.chevron_right : Icons.arrow_forward_ios,
                color: Colors.white,
                size: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonaSection(
    BuildContext context,
    ThemeData theme,
    PremiumProvider premiumProvider,
    bool isCupertino,
  ) {
    final hasPremium = premiumProvider.hasPremiumAccess;
    final currentPersona = premiumProvider.userData?.persona ?? '';

    // Initialize persona controller once when data is available
    if (!_personaInitialized && currentPersona.isNotEmpty) {
      _personaController.text = currentPersona;
      _personaInitialized = true;
    }

    if (!hasPremium) {
      return GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PaywallScreen()),
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: AppConstants.spacing16),
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
                padding: const EdgeInsets.all(AppConstants.spacing12),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: AppColors.primaryLight,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppConstants.spacing16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Custom AI Persona',
                          style: AppTextStyles.subtitle.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: AppConstants.spacing8),
                        const Icon(
                          Icons.lock_outline,
                          size: 14,
                          color: AppColors.textSecondaryLight,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Set your profession for personalized prompts',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isCupertino ? CupertinoIcons.chevron_right : Icons.arrow_forward_ios,
                color: AppColors.textSecondaryLight,
                size: 18,
              ),
            ],
          ),
        ),
      );
    }

    // Unlocked state for premium users
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppConstants.spacing16),
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
              Container(
                padding: const EdgeInsets.all(AppConstants.spacing12),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.person_outline,
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
                      'Custom AI Persona',
                      style: AppTextStyles.subtitle.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Set your profession for personalized prompts',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacing16),
          TextField(
            controller: _personaController,
            maxLength: 100,
            decoration: InputDecoration(
              hintText: 'e.g., Marketing manager, Software developer...',
              hintStyle: AppTextStyles.body.copyWith(
                color: AppColors.textSecondaryLight.withValues(alpha: 0.6),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusInput),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusInput),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusInput),
                borderSide: const BorderSide(color: AppColors.primaryLight, width: 2),
              ),
              filled: true,
              fillColor: theme.scaffoldBackgroundColor,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacing16,
                vertical: AppConstants.spacing12,
              ),
              counterStyle: AppTextStyles.caption.copyWith(color: AppColors.textSecondaryLight),
            ),
            style: AppTextStyles.body.copyWith(color: theme.colorScheme.onSurface),
          ),
          const SizedBox(height: AppConstants.spacing12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isSavingPersona ? null : () => _savePersona(premiumProvider),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryLight,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusButton),
                ),
              ),
              child: _isSavingPersona
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Save Persona'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _savePersona(PremiumProvider premiumProvider) async {
    final persona = _personaController.text.trim();

    setState(() => _isSavingPersona = true);

    final success = await premiumProvider.updatePersona(persona.isEmpty ? null : persona);

    setState(() => _isSavingPersona = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(persona.isEmpty ? 'Persona cleared' : 'Persona saved'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(premiumProvider.error ?? 'Failed to save persona'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }
}
