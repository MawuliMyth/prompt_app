import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../core/widgets/shimmer_loading.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isSuccess = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      SnackbarUtils.showError(context, 'Please enter your email');
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.sendPasswordResetEmail(email);

    if (success && mounted) {
      setState(() {
        _isSuccess = true;
      });
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
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _isSuccess ? _buildSuccessState(theme) : _buildInputState(theme, authProvider),
        ),
      ),
    );
  }

  Widget _buildInputState(ThemeData theme, AuthProvider authProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        Flexible(
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mark_email_read_outlined,
              size: 60,
              color: AppColors.primaryLight,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Reset Password',
          style: AppTextStyles.headingLarge.copyWith(color: theme.colorScheme.onSurface),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Enter your email and we\'ll send you a link to reset your password.',
          style: AppTextStyles.body.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            hintText: 'Email address',
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: authProvider.isLoading ? null : _handleReset,
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
              child: authProvider.isLoading
                  ? const ShimmerButtonLoader(text: 'Sending...', height: 56)
                  : Text(
                      'Send Reset Link',
                      style: AppTextStyles.button.copyWith(color: Colors.white),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessState(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline,
              size: 60,
              color: Colors.green,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Email Sent!',
          style: AppTextStyles.headingLarge.copyWith(color: theme.colorScheme.onSurface),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'We\'ve sent a password reset link to\n${_emailController.text}',
          style: AppTextStyles.body.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(double.infinity, 56),
          ),
          child: Ink(
            decoration: BoxDecoration(
               color: AppColors.backgroundLight,
               border: Border.all(color: AppColors.primaryLight),
               borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              height: 56,
              alignment: Alignment.center,
              child: Text(
                'Back to Login',
                 style: AppTextStyles.button.copyWith(color: AppColors.primaryLight),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
