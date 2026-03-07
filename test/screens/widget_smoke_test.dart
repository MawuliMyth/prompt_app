import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart'
    show FirebaseAuthException, User, UserCredential;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:promt_app/core/widgets/google_logo.dart';
import 'package:promt_app/data/models/user_model.dart';
import 'package:promt_app/data/repositories/auth_repository.dart';
import 'package:promt_app/data/services/premium_service.dart';
import 'package:promt_app/providers/auth_provider.dart';
import 'package:promt_app/providers/premium_provider.dart';
import 'package:promt_app/providers/theme_provider.dart';
import 'package:promt_app/screens/auth/forgot_password_screen.dart';
import 'package:promt_app/screens/auth/login_screen.dart';
import 'package:promt_app/screens/auth/signup_screen.dart';
import 'package:promt_app/screens/paywall/paywall_screen.dart';
import 'package:promt_app/screens/settings/settings_screen.dart';

class FakeAuthRepository implements AuthRepositoryBase {
  final StreamController<User?> _authStateController =
      StreamController<User?>.broadcast();

  User? currentUserValue;
  Object? passwordResetError;

  @override
  User? get currentUser => currentUserValue;

  @override
  Stream<User?> get authStateChanges => _authStateController.stream;

  @override
  Future<void> deleteAccount() async {}

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    if (passwordResetError != null) {
      throw passwordResetError!;
    }
  }

  @override
  Future<Map<String, dynamic>?> signInWithApple() async => null;

  @override
  Future<UserCredential> signInWithEmail(String email, String password) async {
    throw FirebaseAuthException(code: 'invalid-credential');
  }

  @override
  Future<Map<String, dynamic>?> signInWithGoogle() async => null;

  @override
  Future<UserCredential> signUpWithEmail(
    String name,
    String email,
    String password,
  ) async {
    throw FirebaseAuthException(code: 'email-already-in-use');
  }

  @override
  Future<void> signOut() async {}

  void dispose() {
    _authStateController.close();
  }
}

class FakePremiumService implements PremiumServiceBase {
  @override
  Future<bool> activateTrial() async => true;

  @override
  Future<bool> checkIsPremium() async => false;

  @override
  Future<bool> downgradeToFree() async => false;

  @override
  Future<UserModel?> getUserData() async => null;

  @override
  Future<bool> updatePersona(String? persona) async => true;

  @override
  Future<bool> upgradeToPremium({
    required String planType,
    DateTime? expiryDate,
  }) async => false;
}

Widget buildTestApp({
  required Widget child,
  required AuthProvider authProvider,
  PremiumProvider? premiumProvider,
  ThemeProvider? themeProvider,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
      ChangeNotifierProvider<PremiumProvider>.value(
        value:
            premiumProvider ??
            PremiumProvider(premiumService: FakePremiumService()),
      ),
      ChangeNotifierProvider<ThemeProvider>.value(
        value: themeProvider ?? ThemeProvider(),
      ),
    ],
    child: MaterialApp(home: child),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Widget smoke tests', () {
    late FakeAuthRepository authRepository;
    late AuthProvider authProvider;

    setUp(() {
      authRepository = FakeAuthRepository();
      authProvider = AuthProvider(authRepository: authRepository);
    });

    tearDown(() {
      authProvider.dispose();
      authRepository.dispose();
    });

    testWidgets(
      'Login screen renders core actions including Apple button on iOS',
      (tester) async {
        await tester.pumpWidget(
          buildTestApp(child: const LoginScreen(), authProvider: authProvider),
        );
        await tester.pumpAndSettle();

        expect(find.text('Welcome Back'), findsOneWidget);
        expect(find.text('Continue with Google'), findsOneWidget);
        expect(find.text('Continue with Apple'), findsOneWidget);
        expect(find.byType(GoogleLogo), findsOneWidget);
        expect(find.byType(AppleLogo), findsOneWidget);
      },
      variant: const TargetPlatformVariant(<TargetPlatform>{
        TargetPlatform.iOS,
      }),
    );

    testWidgets(
      'Signup screen renders core actions including Apple button on iOS',
      (tester) async {
        await tester.pumpWidget(
          buildTestApp(child: const SignupScreen(), authProvider: authProvider),
        );
        await tester.pumpAndSettle();

        expect(find.text('Create Account'), findsAtLeastNWidgets(1));
        expect(find.text('Continue with Google'), findsOneWidget);
        expect(find.text('Continue with Apple'), findsOneWidget);
        expect(find.byType(AppleLogo), findsOneWidget);
      },
      variant: const TargetPlatformVariant(<TargetPlatform>{
        TargetPlatform.iOS,
      }),
    );

    testWidgets('Forgot password screen can reach success state', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          child: const ForgotPasswordScreen(),
          authProvider: authProvider,
        ),
      );

      await tester.enterText(find.byType(TextField), 'person@example.com');
      await tester.tap(find.text('Send Reset Link'));
      await tester.pumpAndSettle();

      expect(find.text('Email Sent!'), findsOneWidget);
      expect(find.textContaining('person@example.com'), findsOneWidget);
    });

    testWidgets('Paywall screen renders premium upgrade content', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(child: const PaywallScreen(), authProvider: authProvider),
      );
      await tester.pumpAndSettle();

      expect(find.text('Go Premium'), findsOneWidget);
      expect(find.text('Choose your plan'), findsOneWidget);
      expect(find.text('Compare plans'), findsOneWidget);
      expect(find.text('Start 3-Day Free Trial'), findsOneWidget);
    });

    testWidgets('Settings screen renders guest account prompt', (tester) async {
      await tester.pumpWidget(
        buildTestApp(child: const SettingsScreen(), authProvider: authProvider),
      );
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Sign in to sync your prompts'), findsOneWidget);
      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('Account'), findsOneWidget);
    });
  });
}
