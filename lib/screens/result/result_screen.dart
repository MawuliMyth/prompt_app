import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../core/utils/strength_calculator.dart';
import '../../data/models/prompt_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/prompt_provider.dart';
import '../auth/signup_screen.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({
    super.key,
    required this.originalText,
    required this.enhancedPrompt,
    required this.category,
    this.existingPrompt,
  });

  final String originalText;
  final String enhancedPrompt;
  final String category;
  final PromptModel? existingPrompt; // If provided, skip auto-save (viewing history)

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  late int _strengthScore;
  late String _strengthLabel;
  bool _isCopied = false;
  late bool _isFavourited;
  late AnimationController _progressController;
  late Animation<double> _animation;

  PromptModel? _currentPrompt;

  @override
  void initState() {
    super.initState();
    _strengthScore = StrengthCalculator.calculate(
      widget.originalText,
      widget.enhancedPrompt,
      widget.category,
    );
    _strengthLabel = StrengthCalculator.getLabel(_strengthScore);

    // If viewing existing prompt, use its favourite status
    _isFavourited = widget.existingPrompt?.isFavourite ?? false;
    _currentPrompt = widget.existingPrompt;

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animation = Tween<double>(begin: 0, end: _strengthScore / 100).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic),
    );
    _progressController.forward();

    // Auto save only if this is a NEW prompt (not viewing history)
    if (widget.existingPrompt == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _autoSaveIfAuthenticated();
      });
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _autoSaveIfAuthenticated() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final promptProvider = Provider.of<PromptProvider>(context, listen: false);

    if (authProvider.isAuthenticated) {
      final id = const Uuid().v4();
      _currentPrompt = PromptModel(
        id: id,
        originalText: widget.originalText,
        enhancedPrompt: widget.enhancedPrompt,
        category: widget.category,
        strengthScore: _strengthScore,
        createdAt: DateTime.now(),
        userId: authProvider.currentUser!.uid,
      );
      await promptProvider.savePrompt(
        authProvider.currentUser,
        _currentPrompt!,
      );
      if (mounted) {
        SnackbarUtils.showSuccess(context, 'Saved to history!');
      }
    }
  }

  Future<void> _handleFavourite() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final promptProvider = Provider.of<PromptProvider>(context, listen: false);

    if (!authProvider.isAuthenticated) {
      _showSignupPrompt();
      return;
    }

    setState(() {
      _isFavourited = !_isFavourited;
    });

    if (_currentPrompt != null) {
      _currentPrompt = _currentPrompt!.copyWith(isFavourite: _isFavourited);
      await promptProvider.toggleFavourite(
        authProvider.currentUser,
        _currentPrompt!,
      );
      if (mounted) {
        SnackbarUtils.showSuccess(
          context,
          _isFavourited ? 'Added to favourites!' : 'Removed from favourites',
        );
      }
    }
  }

  void _showSignupPrompt() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.save_outlined,
                  size: 40,
                  color: AppColors.primaryLight,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Sign up to save prompts!',
                style: AppTextStyles.headingMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Create a free account to save this prompt and build a library of your favourites.',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SignupScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(padding: EdgeInsets.zero),
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
                      'Create Free Account',
                      style: AppTextStyles.button.copyWith(color: Colors.white),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Maybe Later',
                  style: AppTextStyles.button.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: widget.enhancedPrompt));
    setState(() {
      _isCopied = true;
    });
    HapticFeedback.lightImpact();
    if (mounted) {
      SnackbarUtils.showSuccess(context, 'Copied to clipboard!');
    }
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isCopied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    final isSmallScreen = screenWidth < 360;
    final contentMaxWidth = isTablet ? 600.0 : screenWidth;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Enhanced Prompt',
          style: AppTextStyles.headingMedium.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () => SharePlus.instance.share(ShareParams(text: widget.enhancedPrompt)),
            tooltip: 'Share',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: SizedBox(
                width: contentMaxWidth,
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isSmallScreen ? 12.0 : 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Section A - Strength Meter (compact)
                      Container(
                        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              offset: const Offset(0, 4),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: isSmallScreen ? 60 : 80,
                              height: isSmallScreen ? 60 : 80,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  AnimatedBuilder(
                                    animation: _animation,
                                    builder: (context, child) {
                                      return CircularProgressIndicator(
                                        value: _animation.value,
                                        strokeWidth: isSmallScreen ? 6 : 8,
                                        backgroundColor: AppColors.dividerLight,
                                        valueColor:
                                            const AlwaysStoppedAnimation<Color>(
                                              AppColors.primaryLight,
                                            ),
                                      );
                                    },
                                  ),
                                  Center(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        '$_strengthScore',
                                        style: AppTextStyles.headingMedium
                                            .copyWith(
                                              color: AppColors.primaryLight,
                                              fontSize: isSmallScreen ? 18 : 24,
                                            ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _strengthLabel,
                                    style: AppTextStyles.headingSmall.copyWith(
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Prompt Strength',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.textSecondaryLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Section B - Original Card (compact)
                      Container(
                        padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.dividerLight),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Original',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondaryLight,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              widget.originalText,
                              style: AppTextStyles.body.copyWith(
                                color: theme.colorScheme.onSurface,
                                fontSize: isSmallScreen ? 13 : 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Section C - Enhanced Card
                      Container(
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primaryLight.withValues(alpha: 0.3),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryLight.withValues(alpha: 0.1),
                              offset: const Offset(0, 4),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight.withValues(alpha: 0.1),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(14),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.auto_awesome,
                                    color: AppColors.primaryLight,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Enhanced Prompt ✨',
                                    style: AppTextStyles.body.copyWith(
                                      color: AppColors.primaryLight,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                              child: SelectableText(
                                widget.enhancedPrompt,
                                style: AppTextStyles.body.copyWith(
                                  color: theme.colorScheme.onSurface,
                                  height: 1.6,
                                  fontSize: isSmallScreen ? 14 : 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 100), // Space for bottom bar
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
          isSmallScreen ? 12 : 20,
          12,
          isSmallScreen ? 12 : 20,
          MediaQuery.of(context).padding.bottom + 12,
        ),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.onSurface,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 4,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.refresh, size: 18),
                    if (!isSmallScreen) ...[
                      const SizedBox(width: 4),
                      const Text('New'),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: _handleFavourite,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isFavourited
                      ? Colors.amber
                      : AppColors.primaryLight,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 4,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isFavourited ? Icons.star : Icons.star_border,
                      size: 18,
                    ),
                    if (!isSmallScreen) ...[
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          _isFavourited ? 'Favourited' : 'Favourite',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: _copyToClipboard,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isCopied
                      ? Colors.green
                      : AppColors.primaryLight,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 4,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_isCopied ? Icons.check : Icons.copy, size: 18),
                    if (!isSmallScreen) ...[
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          _isCopied ? 'Copied' : 'Copy',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () => SharePlus.instance.share(ShareParams(text: widget.enhancedPrompt)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryLight,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 4,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.share, size: 18),
                    if (!isSmallScreen) ...[
                      const SizedBox(width: 4),
                      const Flexible(
                        child: Text('Share', overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
