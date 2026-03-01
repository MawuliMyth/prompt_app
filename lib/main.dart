import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/prompt_provider.dart';
import 'providers/free_prompt_provider.dart';
import 'providers/template_provider.dart';
import 'providers/premium_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool firebaseInitialized = false;
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    firebaseInitialized = true;
  } catch (e) {
    debugPrint("Firebase initialization error: $e");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()..loadTheme()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, PremiumProvider>(
          create: (_) => PremiumProvider(),
          update: (context, auth, premium) {
            premium!.updateUser(auth.currentUser);
            return premium;
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, PromptProvider>(
          create: (_) => PromptProvider(),
          update: (context, auth, prompt) {
            prompt!.updateUser(auth.currentUser);
            return prompt;
          },
        ),
        ChangeNotifierProvider(create: (_) => FreePromptProvider()..loadCount()),
        ChangeNotifierProvider(create: (_) => TemplateProvider()),
      ],
      child: PromptApp(firebaseInitialized: firebaseInitialized),
    ),
  );
}
