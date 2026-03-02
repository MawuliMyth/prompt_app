import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../core/utils/strength_calculator.dart';
import '../../core/utils/platform_utils.dart';
import '../../core/widgets/adaptive_widgets.dart';
import '../../core/widgets/locked_feature_sheet.dart';
import '../../data/models/prompt_model.dart';
import '../../data/services/claude_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/prompt_provider.dart';
import '../../providers/premium_provider.dart';
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
  final PromptModel? existingPrompt;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> with SingleTickerProviderStateMixin {
  late int _strengthScore;
  late String _strengthLabel;
  bool _isCopied = false;
  late bool _isFavourited;
  late AnimationController _progressController;
  late Animation<double> _animation;

  PromptModel? _currentPrompt;

  final ClaudeService _claudeService = ClaudeService();
  bool _isLoadingVariations = false;
  List<String>? _variations;
  bool _showVariations = false;

  final List<_VariationType> _variationTypes = [
    _VariationType(name: 'Formal', icon: Icons.work_outline),
    _VariationType(name: 'Creative', icon: Icons.palette_outlined),
    _VariationType(name: 'Concise', icon: Icons.compress_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _strengthScore = StrengthCalculator.calculate(
      widget.originalText,
      widget.enhancedPrompt,
      widget.category,
    );
    _strengthLabel = StrengthCalculator.getLabel(_strengthScore);

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
      final success = await promptProvider.savePrompt(
        authProvider.currentUser,
        _currentPrompt!,
      );
      if (mounted) {
        if (success) {
          SnackbarUtils.showSuccess(context, 'Saved to history');
        } else {
          SnackbarUtils.showError(context, promptProvider.error ?? 'Failed to save prompt');
        }
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

    if (_currentPrompt == null) {
      SnackbarUtils.showError(context, 'Unable to favourite. Please try again.');
      return;
    }

    final newFavouriteStatus = !_isFavourited;
    setState(() {
      _isFavourited = newFavouriteStatus;
    });

    _currentPrompt = _currentPrompt!.copyWith(isFavourite: _isFavourited);
    final success = await promptProvider.toggleFavourite(
      authProvider.currentUser,
      _currentPrompt!,
    );

    if (!success && mounted) {
      setState(() {
        _isFavourited = !newFavouriteStatus;
      });
      SnackbarUtils.showError(
        context,
        promptProvider.error ?? 'Failed to update favourite',
      );
    } else if (mounted) {
      SnackbarUtils.showSuccess(
        context,
        _isFavourited ? 'Added to favourites' : 'Removed from favourites',
      );
    }
  }

  void _showSignupPrompt() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppConstants.radiusBottomSheet),
          ),
        ),
        padding: const EdgeInsets.all(AppConstants.spacing24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.dividerLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppConstants.spacing24),
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
            const SizedBox(height: AppConstants.spacing24),
            Text(
              'Sign up to save prompts',
              style: AppTextStyles.title,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacing12),
            Text(
              'Create a free account to save this prompt and build a library of your favourites.',
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondaryLight),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacing32),
            SizedBox(
              width: double.infinity,
              height: AppConstants.buttonHeight,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SignupScreen()),
                  );
                },
                child: const Text('Create Free Account'),
              ),
            ),
            const SizedBox(height: AppConstants.spacing12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Maybe Later',
                style: AppTextStyles.body.copyWith(color: AppColors.textSecondaryLight),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: widget.enhancedPrompt));
    setState(() {
      _isCopied = true;
    });
    HapticFeedback.lightImpact();
    if (mounted) {
      SnackbarUtils.showSuccess(context, 'Copied to clipboard');
    }
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isCopied = false);
    });
  }

  void _copyVariationToClipboard(String variation) async {
    await Clipboard.setData(ClipboardData(text: variation));
    HapticFeedback.lightImpact();
    if (mounted) {
      SnackbarUtils.showSuccess(context, 'Variation copied');
    }
  }

  Future<void> _loadVariations() async {
    final premiumProvider = Provider.of<PremiumProvider>(context, listen: false);

    if (!premiumProvider.hasPremiumAccess) {
      LockedFeatureSheet.show(
        context,
        'Prompt Variations',
        'Get 3 different versions of every prompt',
      );
      return;
    }

    setState(() {
      _isLoadingVariations = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final result = await _claudeService.generateVariations(
      roughPrompt: widget.originalText,
      category: widget.category,
      isAuthenticated: authProvider.isAuthenticated,
    );

    if (mounted) {
      setState(() {
        _isLoadingVariations = false;
        if (result['success'] == true) {
          _variations = result['variations'] as List<String>;
          _showVariations = true;
        } else {
          SnackbarUtils.showError(context, result['error'] ?? 'Failed to load variations');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    final isSmallScreen = screenWidth < 360;
    final contentMaxWidth = isTablet ? 600.0 : screenWidth;

    return Scaffold(
      appBar: AdaptiveAppBar(
        title: 'Enhanced Prompt',
        actions: [
          IconButton(
            icon: Icon(PlatformUtils.useCupertino(context) ? CupertinoIcons.share : Icons.share_outlined),
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
                  padding: EdgeInsets.all(isSmallScreen ? AppConstants.spacing16 : AppConstants.spacing24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Strength Meter
                      _buildStrengthMeter(theme, isSmallScreen),
                      const SizedBox(height: AppConstants.spacing24),

                      // Original Card
                      _buildOriginalCard(theme, isSmallScreen),
                      const SizedBox(height: AppConstants.spacing16),

                      // Enhanced Card
                      _buildEnhancedCard(theme, isSmallScreen),
                      const SizedBox(height: AppConstants.spacing24),

                      // Variations Section
                      _buildVariationsSection(theme, isSmallScreen),

                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(theme, isSmallScreen),
    );
  }

  Widget _buildStrengthMeter(ThemeData theme, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? AppConstants.spacing16 : AppConstants.spacing20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusCard),
        boxShadow: AppColors.cardShadowLight,
      ),
      child: Row(
        children: [
          SizedBox(
            width: isSmallScreen ? 64 : 80,
            height: isSmallScreen ? 64 : 80,
            child: Stack(
              fit: StackFit.expand,
              children: [
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return CircularProgressIndicator(
                      value: _animation.value,
                      strokeWidth: isSmallScreen ? 5 : 6,
                      backgroundColor: AppColors.surfaceVariantLight,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryLight),
                    );
                  },
                ),
                Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '$_strengthScore',
                      style: AppTextStyles.heading.copyWith(
                        color: AppColors.primaryLight,
                        fontSize: isSmallScreen ? 20 : 28,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppConstants.spacing20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _strengthLabel,
                  style: AppTextStyles.subtitle.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Prompt Strength',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondaryLight),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOriginalCard(ThemeData theme, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? AppConstants.spacing12 : AppConstants.spacing16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusCard),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.edit_outlined,
                size: 16,
                color: AppColors.textSecondaryLight,
              ),
              const SizedBox(width: AppConstants.spacing8),
              Text(
                'Original',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondaryLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacing12),
          Text(
            widget.originalText,
            style: AppTextStyles.body.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              fontStyle: FontStyle.italic,
              fontSize: isSmallScreen ? 13 : 14,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedCard(ThemeData theme, bool isSmallScreen) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusCard),
        boxShadow: AppColors.cardShadowLight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(AppConstants.spacing16),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: AppColors.primaryLight, width: 3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: AppColors.primaryLight,
                  size: 18,
                ),
                const SizedBox(width: AppConstants.spacing8),
                Text(
                  'Enhanced Prompt',
                  style: AppTextStyles.subtitle.copyWith(
                    color: AppColors.primaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(isSmallScreen ? AppConstants.spacing16 : AppConstants.spacing20),
            child: SelectableText(
              widget.enhancedPrompt,
              style: AppTextStyles.body.copyWith(
                color: theme.colorScheme.onSurface,
                height: 1.7,
                fontSize: isSmallScreen ? 14 : 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVariationsSection(ThemeData theme, bool isSmallScreen) {
    return Consumer<PremiumProvider>(
      builder: (context, premiumProvider, child) {
        final hasPremium = premiumProvider.hasPremiumAccess;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Variations button
            GestureDetector(
              onTap: _isLoadingVariations ? null : _loadVariations,
              child: Container(
                padding: const EdgeInsets.all(AppConstants.spacing16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppConstants.radiusCard),
                  border: Border.all(
                    color: hasPremium
                        ? AppColors.primaryLight.withValues(alpha: 0.3)
                        : AppColors.borderLight,
                  ),
                  boxShadow: AppColors.cardShadowLight,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isLoadingVariations)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else ...[
                      Icon(
                        hasPremium ? Icons.auto_awesome_outlined : Icons.lock_outline,
                        size: 18,
                        color: hasPremium ? AppColors.primaryLight : AppColors.textSecondaryLight,
                      ),
                      const SizedBox(width: AppConstants.spacing8),
                      Text(
                        hasPremium ? 'See 3 Variations' : 'Unlock Variations',
                        style: AppTextStyles.subtitle.copyWith(
                          color: hasPremium ? AppColors.primaryLight : AppColors.textSecondaryLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Variations cards
            if (_showVariations && _variations != null) ...[
              const SizedBox(height: AppConstants.spacing16),
              ...List.generate(_variations!.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppConstants.spacing12),
                  child: GestureDetector(
                    onTap: () => _copyVariationToClipboard(_variations![index]),
                    child: Container(
                      padding: const EdgeInsets.all(AppConstants.spacing16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(AppConstants.radiusCard),
                        border: Border.all(color: AppColors.borderLight),
                        boxShadow: AppColors.cardShadowLight,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _variationTypes[index].icon,
                                size: 16,
                                color: AppColors.primaryLight,
                              ),
                              const SizedBox(width: AppConstants.spacing8),
                              Text(
                                _variationTypes[index].name,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.primaryLight,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                Icons.copy_outlined,
                                size: 16,
                                color: AppColors.textSecondaryLight,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppConstants.spacing12),
                          Text(
                            _variations![index],
                            style: AppTextStyles.body.copyWith(
                              color: theme.colorScheme.onSurface,
                              fontSize: isSmallScreen ? 13 : 14,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ],
        );
      },
    );
  }

  Widget _buildBottomBar(ThemeData theme, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        isSmallScreen ? AppConstants.spacing12 : AppConstants.spacing20,
        AppConstants.spacing12,
        isSmallScreen ? AppConstants.spacing12 : AppConstants.spacing20,
        MediaQuery.of(context).padding.bottom + AppConstants.spacing12,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: AppColors.borderLight, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              icon: Icons.refresh,
              label: 'New',
              onPressed: () => Navigator.of(context).pop(),
              isOutlined: true,
              isSmallScreen: isSmallScreen,
            ),
          ),
          const SizedBox(width: AppConstants.spacing8),
          Expanded(
            child: _buildActionButton(
              icon: _isFavourited ? Icons.star : Icons.star_border,
              label: _isFavourited ? 'Saved' : 'Save',
              onPressed: _handleFavourite,
              backgroundColor: _isFavourited ? AppColors.warning : AppColors.primaryLight,
              isSmallScreen: isSmallScreen,
            ),
          ),
          const SizedBox(width: AppConstants.spacing8),
          Expanded(
            child: _buildActionButton(
              icon: _isCopied ? Icons.check : Icons.copy_outlined,
              label: _isCopied ? 'Copied' : 'Copy',
              onPressed: _copyToClipboard,
              backgroundColor: _isCopied ? AppColors.success : AppColors.primaryLight,
              isSmallScreen: isSmallScreen,
            ),
          ),
          const SizedBox(width: AppConstants.spacing8),
          Expanded(
            child: _buildActionButton(
              icon: Icons.share_outlined,
              label: 'Share',
              onPressed: () => SharePlus.instance.share(ShareParams(text: widget.enhancedPrompt)),
              isSmallScreen: isSmallScreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color? backgroundColor,
    bool isOutlined = false,
    bool isSmallScreen = false,
  }) {
    final color = backgroundColor ?? AppColors.primaryLight;

    if (isOutlined) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          side: const BorderSide(color: AppColors.borderLight, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusButton),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18),
            if (!isSmallScreen) ...[
              const SizedBox(width: 4),
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
            ],
          ],
        ),
      );
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusButton),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          if (!isSmallScreen) ...[
            const SizedBox(width: 4),
            Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
          ],
        ],
      ),
    );
  }
}

class _VariationType {
  final String name;
  final IconData icon;

  _VariationType({
    required this.name,
    required this.icon,
  });
}
