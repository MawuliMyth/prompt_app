import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/adaptive_widgets.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/utils/platform_utils.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../core/widgets/google_logo.dart';
import '../home/home_screen.dart';
import 'login_screen.dart';
import 'widgets/auth_action_widgets.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _termsAccepted = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  Future<void> _handleSignup() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (name.isEmpty) {
      SnackbarUtils.showError(context, 'Please enter your name');
      return;
    }
    if (name.length < 2) {
      SnackbarUtils.showError(context, 'Name must be at least 2 characters');
      return;
    }

    final emailError = _validateEmail(email);
    if (emailError != null) {
      SnackbarUtils.showError(context, emailError);
      return;
    }

    final passwordError = _validatePassword(password);
    if (passwordError != null) {
      SnackbarUtils.showError(context, passwordError);
      return;
    }

    final confirmPasswordError = _validateConfirmPassword(confirmPassword);
    if (confirmPasswordError != null) {
      SnackbarUtils.showError(context, confirmPasswordError);
      return;
    }

    if (!_termsAccepted) {
      SnackbarUtils.showError(context, 'Please accept the Terms of Service');
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.signUpWithEmail(name, email, password);

    if (success && mounted) {
      SnackbarUtils.showInfo(
        context,
        'Verification email sent. Confirm your email to unlock the free trial.',
      );
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
                const Center(
                  child: AppLogo(
                    width: 104,
                    height: 104,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Create Account',
                  style: AppTextStyles.headingLarge.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign up to get started',
                  style: AppTextStyles.body.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                AdaptiveTextField(
                  controller: _nameController,
                  hintText: 'Full Name',
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                const SizedBox(height: 16),
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
                const SizedBox(height: 16),
                AdaptiveTextField(
                  controller: _confirmPasswordController,
                  obscureText: _obscurePassword,
                  hintText: 'Confirm Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _termsAccepted = !_termsAccepted;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _termsAccepted
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: _termsAccepted
                              ? AppColors.primaryLight
                              : theme.hintColor,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'I agree to the Terms of Service',
                            style: AppTextStyles.caption.copyWith(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                AuthPrimaryButton(
                  label: 'Create Account',
                  loadingLabel: 'Creating account...',
                  isLoading: authProvider.isLoading,
                  onPressed: _handleSignup,
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
                        'Already have an account? ',
                        style: AppTextStyles.body,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Flexible(
                      child: GestureDetector(
                        onTap: () {
                          PlatformUtils.navigateReplace(
                            context,
                            const LoginScreen(),
                          );
                        },
                        child: Text(
                          'Sign In',
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
