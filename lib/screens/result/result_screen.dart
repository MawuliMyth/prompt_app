import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';
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
import '../../core/widgets/shimmer_loading.dart';
import '../../data/models/prompt_model.dart';
import '../../data/services/ai_handoff_service.dart';
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

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  late int _strengthScore;
  late String _strengthLabel;
  bool _isCopied = false;
  late bool _isFavourited;
  late AnimationController _progressController;
  late Animation<double> _animation;

  PromptModel? _currentPrompt;

  final ClaudeService _claudeService = ClaudeService();
  final AiHandoffService _aiHandoffService = AiHandoffService();
  bool _isLoadingVariations = false;
  List<String>? _variations;
  bool _showVariations = false;
  bool _isSendingToAi = false;

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
          SnackbarUtils.showError(
            context,
            promptProvider.error ?? 'Failed to save prompt',
          );
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
      SnackbarUtils.showError(
        context,
        'Unable to favourite. Please try again.',
      );
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
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacing32),
            SizedBox(
              width: double.infinity,
              height: AppConstants.buttonHeight,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  PlatformUtils.navigateTo(context, const SignupScreen());
                },
                child: const Text('Create Free Account'),
              ),
            ),
            const SizedBox(height: AppConstants.spacing12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Maybe Later',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
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
    // Announce for accessibility
    // ignore: deprecated_member_use
    SemanticsService.announce('Copied to clipboard', TextDirection.ltr);
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

  Future<void> _sharePrompt() async {
    await SharePlus.instance.share(ShareParams(text: widget.enhancedPrompt));
  }

  Future<void> _sendToAi(AiHandoffTarget target) async {
    if (_isSendingToAi) return;

    setState(() => _isSendingToAi = true);
    final result = await _aiHandoffService.sendPrompt(
      prompt: widget.enhancedPrompt,
      target: target,
    );
    if (!mounted) return;
    setState(() => _isSendingToAi = false);

    if (result.success) {
      SnackbarUtils.showSuccess(context, result.message);
      return;
    }
    SnackbarUtils.showError(context, result.message);
  }

  void _showSendToAiSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppConstants.radiusBottomSheet),
            ),
          ),
          child: SafeArea(
            top: false,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(sheetContext).size.height * 0.72,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.dividerColor,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacing20),
                    Text(
                      'Send to AI',
                      style: AppTextStyles.title.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacing8),
                    Text(
                      'We will copy your prompt, then open the AI destination you choose.',
                      style: AppTextStyles.body.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacing20),
                    _AiTargetTile(
                      target: AiHandoffTarget.chatgpt,
                      description: 'Open app or web, prompt copied',
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        _sendToAi(AiHandoffTarget.chatgpt);
                      },
                    ),
                    const SizedBox(height: AppConstants.spacing12),
                    _AiTargetTile(
                      target: AiHandoffTarget.claude,
                      description: 'Open app or web, prompt copied',
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        _sendToAi(AiHandoffTarget.claude);
                      },
                    ),
                    const SizedBox(height: AppConstants.spacing12),
                    _AiTargetTile(
                      target: AiHandoffTarget.gemini,
                      description: 'Open app or web, prompt copied',
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        _sendToAi(AiHandoffTarget.gemini);
                      },
                    ),
                    const SizedBox(height: AppConstants.spacing12),
                    _AiTargetTile(
                      target: AiHandoffTarget.deepseek,
                      description: 'Open app or web, prompt copied',
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        _sendToAi(AiHandoffTarget.deepseek);
                      },
                    ),
                    const SizedBox(height: AppConstants.spacing12),
                    _AiTargetTile(
                      target: AiHandoffTarget.systemShare,
                      description: 'Use the native share sheet',
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        _sendToAi(AiHandoffTarget.systemShare);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _loadVariations() async {
    final premiumProvider = Provider.of<PremiumProvider>(
      context,
      listen: false,
    );

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
          SnackbarUtils.showError(
            context,
            result['error'] ?? 'Failed to load variations',
          );
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

    return AdaptiveScaffold(
      appBar: AdaptiveAppBar(
        title: 'Enhanced Prompt',
        actions: [
          IconButton(
            icon: Icon(
              PlatformUtils.useCupertino(context)
                  ? CupertinoIcons.share
                  : Icons.share_outlined,
            ),
            onPressed: _sharePrompt,
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
                  padding: EdgeInsets.all(
                    isSmallScreen
                        ? AppConstants.spacing16
                        : AppConstants.spacing24,
                  ),
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
      padding: EdgeInsets.all(
        isSmallScreen ? AppConstants.spacing16 : AppConstants.spacing20,
      ),
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
                      valueColor: const AlwaysStoppedAnimation<Color>(
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
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
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
      padding: EdgeInsets.all(
        isSmallScreen ? AppConstants.spacing12 : AppConstants.spacing16,
      ),
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
              const Icon(
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
            decoration: const BoxDecoration(
              border: Border(
                left: BorderSide(color: AppColors.primaryLight, width: 3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
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
            padding: EdgeInsets.all(
              isSmallScreen ? AppConstants.spacing16 : AppConstants.spacing20,
            ),
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
                      const ShimmerPulse(
                        width: 92,
                        height: 16,
                        borderRadius: 999,
                      )
                    else ...[
                      Icon(
                        hasPremium
                            ? Icons.auto_awesome_outlined
                            : Icons.lock_outline,
                        size: 18,
                        color: hasPremium
                            ? AppColors.primaryLight
                            : AppColors.textSecondaryLight,
                      ),
                      const SizedBox(width: AppConstants.spacing8),
                      Text(
                        hasPremium ? 'See 3 Variations' : 'Unlock Variations',
                        style: AppTextStyles.subtitle.copyWith(
                          color: hasPremium
                              ? AppColors.primaryLight
                              : AppColors.textSecondaryLight,
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
                  padding: const EdgeInsets.only(
                    bottom: AppConstants.spacing12,
                  ),
                  child: Semantics(
                    label: '${_variationTypes[index].name} variation',
                    hint: 'Tap to copy this variation',
                    button: true,
                    child: GestureDetector(
                      onTap: () =>
                          _copyVariationToClipboard(_variations![index]),
                      child: Container(
                        padding: const EdgeInsets.all(AppConstants.spacing16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(
                            AppConstants.radiusCard,
                          ),
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
                                const Icon(
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
        border: const Border(
          top: BorderSide(color: AppColors.borderLight, width: 0.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
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
                  backgroundColor: _isFavourited
                      ? AppColors.warning
                      : AppColors.primaryLight,
                  isSmallScreen: isSmallScreen,
                ),
              ),
              const SizedBox(width: AppConstants.spacing8),
              Expanded(
                child: _buildActionButton(
                  icon: _isCopied ? Icons.check : Icons.copy_outlined,
                  label: _isCopied ? 'Copied' : 'Copy',
                  onPressed: _copyToClipboard,
                  backgroundColor: _isCopied
                      ? AppColors.success
                      : AppColors.primaryLight,
                  isSmallScreen: isSmallScreen,
                ),
              ),
              const SizedBox(width: AppConstants.spacing8),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.share_outlined,
                  label: 'Share',
                  onPressed: _sharePrompt,
                  isSmallScreen: isSmallScreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacing12),
          SizedBox(
            width: double.infinity,
            child: _buildActionButton(
              icon: _isSendingToAi
                  ? Icons.hourglass_top_rounded
                  : Icons.send_rounded,
              label: _isSendingToAi ? 'Opening...' : 'Send to AI',
              onPressed: _isSendingToAi ? null : _showSendToAiSheet,
              backgroundColor: AppColors.primaryLight,
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
    required VoidCallback? onPressed,
    Color? backgroundColor,
    bool isOutlined = false,
    bool isSmallScreen = false,
  }) {
    final color = backgroundColor ?? AppColors.primaryLight;

    if (isOutlined) {
      return Semantics(
        label: label,
        button: true,
        child: OutlinedButton(
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
        ),
      );
    }

    return Semantics(
      label: label,
      button: true,
      child: ElevatedButton(
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
      ),
    );
  }
}

class _AiTargetTile extends StatelessWidget {
  const _AiTargetTile({
    required this.target,
    required this.description,
    required this.onTap,
  });

  final AiHandoffTarget target;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.radiusCard),
      child: Container(
        padding: const EdgeInsets.all(AppConstants.spacing16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppConstants.radiusCard),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _backgroundForTarget(target),
                borderRadius: BorderRadius.circular(AppConstants.radiusControl),
              ),
              child: _AiBrandMark(target: target),
            ),
            const SizedBox(width: AppConstants.spacing16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    target.displayName,
                    style: AppTextStyles.subtitle.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacing4),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body.copyWith(
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppConstants.spacing12),
            Icon(
              Icons.arrow_outward_rounded,
              size: 20,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ],
        ),
      ),
    );
  }

  Color _backgroundForTarget(AiHandoffTarget target) {
    switch (target) {
      case AiHandoffTarget.chatgpt:
        return const Color(0xFF10A37F);
      case AiHandoffTarget.claude:
        return Colors.white;
      case AiHandoffTarget.gemini:
        return Colors.black;
      case AiHandoffTarget.deepseek:
        return const Color(0xFF2563EB);
      case AiHandoffTarget.systemShare:
        return AppColors.primaryLight;
    }
  }
}

class _AiBrandMark extends StatelessWidget {
  const _AiBrandMark({required this.target});

  final AiHandoffTarget target;

  @override
  Widget build(BuildContext context) {
    final assetPath = switch (target) {
      AiHandoffTarget.chatgpt => 'assets/images/chagpt.png',
      AiHandoffTarget.claude => 'assets/images/claude.png',
      AiHandoffTarget.gemini => 'assets/images/Gemini-Icon.webp',
      AiHandoffTarget.deepseek => 'assets/images/deepseek.jpg',
      AiHandoffTarget.systemShare => null,
    };

    if (assetPath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.asset(assetPath, width: 28, height: 28, fit: BoxFit.cover),
      );
    }

    switch (target) {
      case AiHandoffTarget.systemShare:
        return const Icon(Icons.add_rounded, color: Colors.white, size: 24);
      case AiHandoffTarget.chatgpt:
      case AiHandoffTarget.claude:
      case AiHandoffTarget.gemini:
      case AiHandoffTarget.deepseek:
        return const SizedBox.shrink();
    }
  }
}

class _VariationType {
  _VariationType({required this.name, required this.icon});
  final String name;
  final IconData icon;
}
