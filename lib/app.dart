import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/utils/analytics.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'providers/theme_provider.dart';
import 'screens/splash/splash_screen.dart';

class PromptApp extends StatelessWidget {

  const PromptApp({super.key, required this.firebaseInitialized});
  final bool firebaseInitialized;

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          navigatorObservers: [analyticsObserver],
          home: SplashScreen(firebaseInitialized: firebaseInitialized),
        );
      },
    );
  }
}
