import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/adaptive_widgets.dart';
import '../../core/utils/platform_utils.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../core/widgets/google_logo.dart';
import '../home/home_screen.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';
import 'widgets/auth_action_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter an email';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  Future<void> _handleLogin() async {
    final emailError = _validateEmail(_emailController.text.trim());
    if (emailError != null) {
      SnackbarUtils.showError(context, emailError);
      return;
    }

    if (_passwordController.text.trim().isEmpty) {
      SnackbarUtils.showError(context, 'Please enter your password');
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.signInWithEmail(email, password);

    if (success && mounted) {
      PlatformUtils.navigateReplace(context, const HomeScreen());
    } else if (mounted && authProvider.error != null) {
      SnackbarUtils.showError(context, authProvider.error!);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.signInWithGoogle();
    if (success && mounted) {
      PlatformUtils.navigateReplace(context, const HomeScreen());
    } else if (mounted && authProvider.error != null) {
      SnackbarUtils.showError(context, authProvider.error!);
    }
  }

  Future<void> _handleAppleSignIn() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.signInWithApple();
    if (success && mounted) {
      PlatformUtils.navigateReplace(context, const HomeScreen());
    } else if (mounted && authProvider.error != null) {
      SnackbarUtils.showError(context, authProvider.error!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isCupertino = PlatformUtils.useCupertino(context);

    return AdaptiveScaffold(
      appBar: AdaptiveAppBar(
        title: '',
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            isCupertino ? CupertinoIcons.back : Icons.arrow_back,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        'P',
                        style: AppTextStyles.headingLarge.copyWith(
                          color: Colors.white,
                          fontSize: 40,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Welcome Back',
                  style: AppTextStyles.headingLarge.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to continue',
                  style: AppTextStyles.body.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                AdaptiveTextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  hintText: 'Email',
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
                const SizedBox(height: 16),
                AdaptiveTextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  hintText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: isCupertino
                      ? CupertinoButton(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          onPressed: () {
                            PlatformUtils.navigateTo(
                              context,
                              const ForgotPasswordScreen(),
                            );
                          },
                          child: Text(
                            'Forgot Password?',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.primaryLight,
                            ),
                          ),
                        )
                      : TextButton(
                          onPressed: () {
                            PlatformUtils.navigateTo(
                              context,
                              const ForgotPasswordScreen(),
                            );
                          },
                          child: Text(
                            'Forgot Password?',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.primaryLight,
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 24),
                AuthPrimaryButton(
                  label: 'Sign In',
                  loadingLabel: 'Signing in...',
                  isLoading: authProvider.isLoading,
                  onPressed: _handleLogin,
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'or continue with',
                        style: AppTextStyles.caption.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 24),
                AuthSurfaceButton(
                  label: 'Continue with Google',
                  leading: const GoogleLogo(),
                  onPressed:
                      authProvider.isLoading ? null : _handleGoogleSignIn,
                ),
                if (!kIsWeb &&
                    (defaultTargetPlatform == TargetPlatform.iOS ||
                        defaultTargetPlatform == TargetPlatform.macOS)) ...[
                  const SizedBox(height: 16),
                  AuthSurfaceButton(
                    label: 'Continue with Apple',
                    leading: const AppleLogo(),
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    borderColor: Colors.black,
                    onPressed:
                        authProvider.isLoading ? null : _handleAppleSignIn,
                  ),
                ],
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        "Don't have an account? ",
                        style: AppTextStyles.body,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Flexible(
                      child: GestureDetector(
                        onTap: () {
                          PlatformUtils.navigateReplace(
                            context,
                            const SignupScreen(),
                          );
                        },
                        child: Text(
                          'Sign Up',
                          style: AppTextStyles.button.copyWith(
                            color: AppColors.primaryLight,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ),
      ),
    );
  }
}
