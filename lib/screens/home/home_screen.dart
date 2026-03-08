import 'dart:ui';
import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/platform_utils.dart';
import '../../core/widgets/adaptive_widgets.dart';
import '../../providers/auth_provider.dart';
import '../../providers/connectivity_provider.dart';
import '../../providers/shell_provider.dart';
import '../history/history_screen.dart';
import '../settings/settings_screen.dart';
import '../templates/templates_screen.dart';
import 'home_view.dart';
import 'prompt_composer_screen.dart';
import 'voice_assessment_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _lastComposerToken = 0;

  static const List<Widget> _screens = [
    HomeView(),
    HistoryScreen(),
    TemplatesScreen(),
    SettingsScreen(),
  ];

  void _maybeOpenComposer(BuildContext context, ShellProvider shellProvider) {
    final request = shellProvider.pendingComposerRequest;
    if (request == null || request.token == _lastComposerToken) {
      return;
    }

    _lastComposerToken = request.token;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      shellProvider.clearComposerRequest();
      if (!mounted) return;
      await Navigator.of(context).push(
        PlatformUtils.adaptivePageRoute(
          PromptComposerScreen(
            initialText: request.initialText,
            initialCategoryId: request.categoryId,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final shellProvider = context.watch<ShellProvider>();
    _maybeOpenComposer(context, shellProvider);

    return AdaptiveScaffold(
      extendBody: true,
      body: Stack(
        children: [
          Consumer<ConnectivityProvider>(
            builder: (context, connectivity, child) {
              return IndexedStack(
                index: shellProvider.currentIndex,
                children: _screens,
              );
            },
          ),
          const _FloatingShell(),
        ],
      ),
    );
  }
}

class _FloatingShell extends StatelessWidget {
  const _FloatingShell();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shellProvider = context.watch<ShellProvider>();
    final connectivity = context.watch<ConnectivityProvider>();
    final isCupertino = !kIsWeb && (Platform.isIOS || Platform.isMacOS);

    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!connectivity.isOnline)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warning,
                    borderRadius: BorderRadius.circular(
                      AppConstants.radiusControl,
                    ),
                  ),
                  child: const Text(
                    'Offline mode. Some actions may be unavailable.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppConstants.radiusFloating),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.dark
                          ? AppColors.floatingSurfaceDark.withValues(alpha: 0.78)
                          : AppColors.surfaceLight.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(
                        AppConstants.radiusFloating,
                      ),
                      border: Border.all(
                        color: theme.brightness == Brightness.dark
                            ? AppColors.borderDark.withValues(alpha: 0.8)
                            : AppColors.borderLight.withValues(alpha: 0.65),
                      ),
                      boxShadow: theme.brightness == Brightness.dark
                          ? AppColors.cardShadowDark
                          : AppColors.cardShadowLight,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _ShellItem(
                                label: 'Home',
                                icon: isCupertino
                                    ? CupertinoIcons.house
                                    : Icons.home_outlined,
                                selectedIcon: isCupertino
                                    ? CupertinoIcons.house_fill
                                    : Icons.home_rounded,
                                selected: shellProvider.currentIndex == 0,
                                onTap: () => shellProvider.selectTab(0),
                              ),
                              _ShellItem(
                                label: 'History',
                                icon: isCupertino
                                    ? CupertinoIcons.clock
                                    : Icons.history_outlined,
                                selectedIcon: isCupertino
                                    ? CupertinoIcons.clock_fill
                                    : Icons.history_rounded,
                                selected: shellProvider.currentIndex == 1,
                                onTap: () => shellProvider.selectTab(1),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: GestureDetector(
                            onTap: () async {
                              final authProvider = context.read<AuthProvider>();
                              if (!authProvider.isAuthenticated) {
                                final shouldSignIn = await AdaptiveDialog.show(
                                  context: context,
                                  title: 'Sign in to use voice',
                                  content:
                                      'Voice recording is available after sign in. Guest mode can still use typed prompts.',
                                  cancelText: 'Not now',
                                  confirmText: 'Sign In',
                                );
                                if (shouldSignIn == true && context.mounted) {
                                  shellProvider.selectTab(3);
                                }
                                return;
                              }

                              final transcript = await Navigator.of(context)
                                  .push<String>(
                                    PlatformUtils.adaptivePageRoute(
                                      const VoiceAssessmentScreen(),
                                    ),
                                  );
                              if (transcript != null && context.mounted) {
                                shellProvider.openComposer(
                                  initialText: transcript,
                                );
                              }
                            },
                            child: Container(
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                shape: BoxShape.circle,
                                boxShadow: theme.brightness == Brightness.dark
                                    ? AppColors.cardShadowDark
                                    : AppColors.cardShadowLight,
                              ),
                              child: Icon(
                                isCupertino
                                    ? CupertinoIcons.mic_fill
                                    : Icons.mic_rounded,
                                color: Colors.white,
                                size: AppConstants.iconSizeNav,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _ShellItem(
                                label: 'Templates',
                                icon: isCupertino
                                    ? CupertinoIcons.square_grid_2x2
                                    : Icons.grid_view_rounded,
                                selectedIcon: isCupertino
                                    ? CupertinoIcons.square_grid_2x2_fill
                                    : Icons.grid_view_rounded,
                                selected: shellProvider.currentIndex == 2,
                                onTap: () => shellProvider.selectTab(2),
                              ),
                              _ShellItem(
                                label: 'Settings',
                                icon: isCupertino
                                    ? CupertinoIcons.settings
                                    : Icons.settings_outlined,
                                selectedIcon: isCupertino
                                    ? CupertinoIcons.settings
                                    : Icons.settings_rounded,
                                selected: shellProvider.currentIndex == 3,
                                onTap: () => shellProvider.selectTab(3),
                              ),
                            ],
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
      ),
    );
  }
}

class _ShellItem extends StatelessWidget {
  const _ShellItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 62,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? selectedIcon : icon,
              size: AppConstants.iconSizeNav,
              color: selected ? AppColors.primaryLight : theme.hintColor,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: selected ? theme.colorScheme.onSurface : theme.hintColor,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
