import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../home/home_screen.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/app_logo.dart';

class SplashScreen extends StatefulWidget {
  final bool firebaseInitialized;

  const SplashScreen({super.key, required this.firebaseInitialized});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
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
      'subtitle': 'We instantly transform your rough idea into a professional prompt.',
      'icon': 'auto_awesome',
    },
    {
      'title': 'Use It Anywhere',
      'subtitle': 'Copy your perfect prompt and paste it into any AI tool you love.',
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
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
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
      case 'mic': return Icons.mic;
      case 'auto_awesome': return Icons.auto_awesome;
      case 'content_copy': return Icons.content_copy;
      default: return Icons.info;
    }
  }

  void _showFirebaseError() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Configuration Error'),
        content: const Text(
          'Firebase could not be initialized. Please ensure you have '
          'configured firebase_options.dart with valid credentials. '
          'Run "flutterfire configure" to generate the configuration.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _completeOnboarding();
            },
            child: const Text('Continue Anyway'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: _showOnboarding
            ? _buildOnboarding(theme)
            : _buildSplashLogo(),
      ),
    );
  }

  Widget _buildSplashLogo() {
    return Container(
      key: const ValueKey('splash'),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
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
    return Scaffold(
      key: const ValueKey('onboarding'),
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _completeOnboarding,
                child: Text('Skip', style: AppTextStyles.button.copyWith(color: AppColors.textSecondaryLight)),
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
                  return Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight.withOpacity(0.1),
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
                          style: AppTextStyles.headingLarge.copyWith(color: theme.colorScheme.onSurface),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _onboardingData[index]['subtitle']!,
                          style: AppTextStyles.body.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7)),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
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
                          color: _currentPage == index ? AppColors.primaryLight : AppColors.dividerLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        child: Text(
                          _currentPage == _onboardingData.length - 1 ? 'Get Started' : 'Next',
                          style: AppTextStyles.button.copyWith(color: Colors.white),
                        ),
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
