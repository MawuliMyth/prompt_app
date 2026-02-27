import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../core/widgets/google_logo.dart';
import '../home/home_screen.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
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
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.signInWithEmail(email, password);

    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else if (mounted && authProvider.error != null) {
      SnackbarUtils.showError(context, authProvider.error!);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.signInWithGoogle();
     if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else if (mounted && authProvider.error != null) {
      SnackbarUtils.showError(context, authProvider.error!);
    }
  }

  Future<void> _handleAppleSignIn() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.signInWithApple();
     if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else if (mounted && authProvider.error != null) {
      SnackbarUtils.showError(context, authProvider.error!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
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
                  style: AppTextStyles.headingLarge.copyWith(color: theme.colorScheme.onSurface),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to continue',
                  style: AppTextStyles.body.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: _validateEmail,
                ),
                const SizedBox(height: 16),
                 TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                     Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                    );
                  },
                  child: Text(
                    'Forgot Password?',
                    style: AppTextStyles.body.copyWith(color: AppColors.primaryLight),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Sign In Button with Shimmer
              authProvider.isLoading
                  ? Shimmer.fromColors(
                      baseColor: const Color(0xFFE53935),
                      highlightColor: const Color(0xFFB71C1C),
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            'Signing in...',
                            style: AppTextStyles.button.copyWith(color: Colors.white),
                          ),
                        ),
                      ),
                    )
                  : ElevatedButton(
                    onPressed: _handleLogin,
                    style: ElevatedButton.styleFrom(
                       padding: EdgeInsets.zero,
                    ),
                     child: Ink(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Container(
                        height: 56,
                        alignment: Alignment.center,
                        child: Text(
                          'Sign In',
                          style: AppTextStyles.button.copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
              const SizedBox(height: 32),
              Row(
                children: [
                   const Expanded(child: Divider()),
                   Padding(
                     padding: const EdgeInsets.symmetric(horizontal: 16),
                     child: Text('or continue with', style: AppTextStyles.caption.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.5))),
                   ),
                   const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 24),
              // Google Sign In Button with Google Logo
              SizedBox(
                height: 56,
                child: OutlinedButton(
                  onPressed: authProvider.isLoading ? null : _handleGoogleSignIn,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: theme.brightness == Brightness.light ? Colors.white : AppColors.surfaceDark,
                    foregroundColor: theme.colorScheme.onSurface,
                    side: BorderSide(color: theme.brightness == Brightness.light ? Colors.grey[300]! : Colors.grey[700]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const GoogleLogo(size: 24),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          'Continue with Google',
                          style: AppTextStyles.button.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (!kIsWeb && (Platform.isIOS || Platform.isMacOS)) ...[
                const SizedBox(height: 16),
                // Apple Sign In Button with Apple Logo
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: authProvider.isLoading ? null : _handleAppleSignIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const AppleLogo(size: 24),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            'Continue with Apple',
                            style: AppTextStyles.button.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text("Don't have an account? ", style: AppTextStyles.body, overflow: TextOverflow.ellipsis),
                  ),
                  Flexible(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const SignupScreen()),
                        );
                      },
                      child: Text(
                        'Sign Up',
                        style: AppTextStyles.button.copyWith(color: AppColors.primaryLight),
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
      ),
    );
  }
}
