import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../home/home_screen.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/platform_utils.dart';
import '../../core/widgets/adaptive_widgets.dart';
import '../../core/widgets/app_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.firebaseInitialized});
  final bool firebaseInitialized;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _showOnboarding = false;
  late AnimationController _logoController;
  late Animation<double> _logoAnimation;

  final List<Map<String, String>> _onboardingData = [
    {
      'title': 'Speak Your Mind',
      'subtitle': 'Just talk naturally. No need to be formal or perfect.',
      'icon': 'mic',
    },
    {
      'title': 'AI Does The Magic',
      'subtitle':
          'We instantly transform your rough idea into a professional prompt.',
      'icon': 'auto_awesome',
    },
    {
      'title': 'Use It Anywhere',
      'subtitle':
          'Copy your perfect prompt and paste it into any AI tool you love.',
      'icon': 'content_copy',
    },
  ];

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _logoAnimation = CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOutBack,
    );
    _logoController.forward();
    _checkInitialState();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _checkInitialState() async {
    await Future.delayed(const Duration(milliseconds: 2000));

    if (!mounted) return;

    if (!widget.firebaseInitialized) {
      _showFirebaseError();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

    if (!mounted) return;

    if (hasSeenOnboarding) {
      _navigateToHome();
    } else {
      setState(() {
        _showOnboarding = true;
      });
    }
  }

  void _navigateToHome() {
    PlatformUtils.navigateReplace(context, const HomeScreen());
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    if (!mounted) return;
    _navigateToHome();
  }

  void _nextPage() {
    if (_currentPage < _onboardingData.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'mic':
        return Icons.mic;
      case 'auto_awesome':
        return Icons.auto_awesome;
      case 'content_copy':
        return Icons.content_copy;
      default:
        return Icons.info;
    }
  }

  void _showFirebaseError() {
    AdaptiveDialog.show(
      context: context,
      title: 'Configuration Error',
      content:
          'Firebase could not be initialized. Please ensure you have configured firebase_options.dart with valid credentials. Run "flutterfire configure" to generate the configuration.',
      cancelText: 'Continue Anyway',
      confirmText: 'Continue Anyway',
    ).then((_) => _completeOnboarding());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AdaptiveScaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: _showOnboarding ? _buildOnboarding(theme) : _buildSplashLogo(),
      ),
    );
  }

  Widget _buildSplashLogo() {
    return Container(
      key: const ValueKey('splash'),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryLight, AppColors.accentLight],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            ScaleTransition(
              scale: _logoAnimation,
              child: const AppLogo(width: 200),
            ),
            const Spacer(),
            if (!widget.firebaseInitialized)
              const Text(
                'Firebase not configured',
                style: TextStyle(color: Colors.white70),
              ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboarding(ThemeData theme) {
    final isCupertino = PlatformUtils.useCupertino(context);

    return AdaptiveScaffold(
      key: const ValueKey('onboarding'),
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: isCupertino
                  ? CupertinoButton(
                      onPressed: _completeOnboarding,
                      child: Text(
                        'Skip',
                        style: AppTextStyles.button.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    )
                  : TextButton(
                      onPressed: _completeOnboarding,
                      child: Text(
                        'Skip',
                        style: AppTextStyles.button.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _onboardingData.length,
                itemBuilder: (context, index) {
                  return CustomScrollView(
                    slivers: [
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Padding(
                          padding: const EdgeInsets.all(40.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 150,
                                height: 150,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight.withValues(
                                    alpha: 0.1,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _getIconData(_onboardingData[index]['icon']!),
                                  size: 80,
                                  color: AppColors.primaryLight,
                                ),
                              ),
                              const SizedBox(height: 48),
                              Text(
                                _onboardingData[index]['title']!,
                                style: AppTextStyles.headingLarge.copyWith(
                                  color: theme.colorScheme.onSurface,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _onboardingData[index]['subtitle']!,
                                style: AppTextStyles.body.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(
                      _onboardingData.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 8),
                        height: 8,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? AppColors.primaryLight
                              : AppColors.dividerLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 150,
                    child: AdaptiveButton(
                      label: _currentPage == _onboardingData.length - 1
                          ? 'Get Started'
                          : 'Next',
                      onPressed: _nextPage,
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
