import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/analytics.dart';
import '../../core/utils/app_icon_mapper.dart';
import '../../core/utils/platform_utils.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../core/utils/strength_calculator.dart';
import '../../core/widgets/adaptive_widgets.dart';
import '../../core/widgets/daily_limit_sheet.dart';
import '../../core/widgets/locked_feature_sheet.dart';
import '../../data/services/claude_service.dart';
import '../../providers/app_config_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/connectivity_provider.dart';
import '../../providers/daily_limit_provider.dart';
import '../../providers/free_prompt_provider.dart';
import '../../providers/premium_provider.dart';
import '../auth/login_screen.dart';
import '../auth/signup_screen.dart';
import '../result/result_screen.dart';
import 'voice_assessment_screen.dart';

class PromptComposerScreen extends StatefulWidget {
  const PromptComposerScreen({
    super.key,
    this.initialText,
    this.initialCategoryId,
  });

  final String? initialText;
  final String? initialCategoryId;

  @override
  State<PromptComposerScreen> createState() => _PromptComposerScreenState();
}

class _PromptComposerScreenState extends State<PromptComposerScreen> {
  final TextEditingController _controller = TextEditingController();
  final ClaudeService _claudeService = ClaudeService();
  String? _selectedCategoryId;
  String _selectedToneId = 'auto';
  bool _isProcessing = false;
  bool _usedVoiceInput = false;

  void _onTextChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialText ?? '';
    _selectedCategoryId = widget.initialCategoryId;
    _controller.addListener(_onTextChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final categories = context.read<AppConfigProvider>().categories;
    _selectedCategoryId ??= categories.isNotEmpty ? categories.first.id : null;

    final authProvider = context.read<AuthProvider>();
    final premiumProvider = context.read<PremiumProvider>();
    if (authProvider.isAuthenticated && !premiumProvider.hasPremiumAccess) {
      unawaited(context.read<DailyLimitProvider>().loadDailyUsage());
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openVoice() async {
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated) {
      final shouldSignIn = await AdaptiveDialog.show(
        context: context,
        title: 'Sign in to use voice',
        content:
            'Voice recording is available after sign in. Guest mode can still use typed prompts.',
        cancelText: 'Not now',
        confirmText: 'Sign In',
      );
      if (shouldSignIn == true && mounted) {
        await PlatformUtils.navigateTo(context, const LoginScreen());
      }
      return;
    }

    final transcript = await Navigator.of(context).push<String>(
      PlatformUtils.adaptivePageRoute(const VoiceAssessmentScreen()),
    );
    if (!mounted || transcript == null) return;
    setState(() {
      _controller.text = transcript;
      _usedVoiceInput = true;
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
    });
  }

  Future<void> _enhancePrompt() async {
    final navigator = Navigator.of(context);
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final connectivityProvider = context.read<ConnectivityProvider>();
    if (!connectivityProvider.isOnline) {
      SnackbarUtils.showError(
        context,
        'You appear to be offline. Check your connection and try again.',
      );
      return;
    }

    final configProvider = context.read<AppConfigProvider>();
    final authProvider = context.read<AuthProvider>();
    final premiumProvider = context.read<PremiumProvider>();
    final freePromptProvider = context.read<FreePromptProvider>();
    final dailyLimitProvider = context.read<DailyLimitProvider>();

    if (!authProvider.isAuthenticated) {
      if (freePromptProvider.hasReachedLimit) {
        trackAnalytics(() => analyticsService.logGuestLimitReached());
        final shouldSignUp = await AdaptiveDialog.show(
          context: context,
          title: 'Create an account',
          content:
              'You have used today\'s free guest prompts. Create an account to keep going.',
          cancelText: 'Later',
          confirmText: 'Sign up',
        );
        if (shouldSignUp == true && mounted) {
          await PlatformUtils.navigateTo(context, const SignupScreen());
        }
        return;
      }
    } else if (!premiumProvider.hasPremiumAccess) {
      await dailyLimitProvider.loadDailyUsage();
      if (!mounted) return;
      if (dailyLimitProvider.hasReachedLimit) {
        trackAnalytics(() => analyticsService.logDailyLimitReached());
        DailyLimitSheet.show(context);
        return;
      }
    }

    final category = configProvider.categories.firstWhere(
      (item) => item.id == _selectedCategoryId,
      orElse: () => configProvider.categories.first,
    );
    final tone = configProvider.tones.firstWhere(
      (item) => item.id == _selectedToneId,
      orElse: () => configProvider.tones.first,
    );

    HapticFeedback.lightImpact();
    setState(() => _isProcessing = true);

    final result = await _claudeService.enhancePrompt(
      roughPrompt: text,
      category: category.label,
      isAuthenticated: authProvider.isAuthenticated,
      tone: tone.label,
      persona: premiumProvider.userData?.persona,
    );

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (result['success'] == true) {
      final enhancedPrompt = result['enhancedPrompt'] as String;
      final strengthScore = StrengthCalculator.calculate(
        text,
        enhancedPrompt,
        category.label,
      );
      trackAnalytics(
        () => analyticsService.logPromptEnhanced(
          category: category.label,
          tone: tone.label,
          isVoice: _usedVoiceInput,
          isPremium: premiumProvider.hasPremiumAccess,
          strengthScore: strengthScore,
        ),
      );
      if (!authProvider.isAuthenticated) {
        await freePromptProvider.increment();
      } else if (!premiumProvider.hasPremiumAccess) {
        await dailyLimitProvider.loadDailyUsage();
        if (!mounted) return;
      }

      await navigator.push(
        PlatformUtils.adaptivePageRoute(
          ResultScreen(
            originalText: text,
            enhancedPrompt: enhancedPrompt,
            category: category.label,
          ),
        ),
      );
      return;
    }

    SnackbarUtils.showError(
      context,
      result['error'] as String? ?? 'Something went wrong.',
    );
  }

  String _usageLabel(
    AuthProvider authProvider,
    PremiumProvider premiumProvider,
    FreePromptProvider freePromptProvider,
    DailyLimitProvider dailyLimitProvider,
  ) {
    if (!authProvider.isAuthenticated) {
      return '${freePromptProvider.used} / ${FreePromptProvider.maxFreePrompts} guest prompts used';
    }
    return '${dailyLimitProvider.dailyPromptsUsed} / ${dailyLimitProvider.dailyLimit} prompts used today';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCupertino = !kIsWeb && (Platform.isIOS || Platform.isMacOS);
    final configProvider = context.watch<AppConfigProvider>();
    final authProvider = context.watch<AuthProvider>();
    final premiumProvider = context.watch<PremiumProvider>();
    final freePromptProvider = context.watch<FreePromptProvider>();
    final dailyLimitProvider = context.watch<DailyLimitProvider>();

    final categories = configProvider.categories;
    final tones = configProvider.tones;

    return AdaptiveScaffold(
      appBar: const AdaptiveAppBar(
        title: 'Refine your prompt',
        backgroundColor: Colors.transparent,
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Start rough. We will shape it into something clear.',
                      style: AppTextStyles.body.copyWith(color: theme.hintColor),
                    ),
                    const SizedBox(height: AppConstants.spacing20),
                    if (!premiumProvider.hasPremiumAccess) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppConstants.spacing16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(
                            AppConstants.radiusCard,
                          ),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: Text(
                          _usageLabel(
                            authProvider,
                            premiumProvider,
                            freePromptProvider,
                            dailyLimitProvider,
                          ),
                          style: AppTextStyles.subtitle.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppConstants.spacing20),
                    ],
                    AdaptiveTextField(
                      controller: _controller,
                      maxLines: 12,
                      minLines: 10,
                      hintText:
                          'Describe what you want. Add context, goals, and any details you already know.',
                      suffixIcon: _controller.text.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () => setState(() => _controller.clear()),
                              icon: const Icon(Icons.close_rounded),
                            ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: AppConstants.spacing20),
                    Text(
                      'Category',
                      style: AppTextStyles.sectionLabel.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacing12),
                    Wrap(
                      spacing: AppConstants.spacing8,
                      runSpacing: AppConstants.spacing8,
                      children: categories.map((category) {
                        final selected = category.id == _selectedCategoryId;
                        return AdaptiveSelectionChip(
                          label: category.label,
                          selected: selected,
                          icon: Icon(
                            resolveIcon(
                              category.iconKey,
                              cupertino: isCupertino,
                            ),
                          ),
                          onTap: () {
                            setState(() => _selectedCategoryId = category.id);
                            trackAnalytics(
                              () => analyticsService.logCategorySelected(
                                category: category.label,
                              ),
                            );
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppConstants.spacing24),
                    Row(
                      children: [
                        Text(
                          'Tone',
                          style: AppTextStyles.sectionLabel.copyWith(
                            color: theme.hintColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.spacing12),
                    Wrap(
                      spacing: AppConstants.spacing8,
                      runSpacing: AppConstants.spacing8,
                      children: tones.map((tone) {
                        final selected = tone.id == _selectedToneId;
                        final locked =
                            tone.premiumOnly &&
                            !premiumProvider.hasPremiumAccess;

                        return GestureDetector(
                          onTap: () {
                            if (locked) {
                              trackAnalytics(
                                () => analyticsService.logFeatureLockedTapped(
                                  featureName: 'premium_tones',
                                ),
                              );
                              LockedFeatureSheet.show(
                                context,
                                'Premium tones',
                                'Choose from richer prompt styles when you upgrade.',
                              );
                              return;
                            }
                            setState(() => _selectedToneId = tone.id);
                            trackAnalytics(
                              () => analyticsService.logToneSelected(
                                tone: tone.label,
                              ),
                            );
                          },
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? AppColors.primaryLight
                                      : theme.colorScheme.surface,
                                  borderRadius: BorderRadius.circular(
                                    AppConstants.radiusChip,
                                  ),
                                  border: Border.all(color: theme.dividerColor),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      resolveIcon(
                                        tone.iconKey,
                                        cupertino: isCupertino,
                                      ),
                                      size: 16,
                                      color: selected
                                          ? Colors.white
                                          : locked
                                          ? theme.hintColor
                                          : theme.colorScheme.onSurface,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      tone.label,
                                      style: AppTextStyles.caption.copyWith(
                                        color: selected
                                            ? Colors.white
                                            : locked
                                            ? theme.hintColor
                                            : theme.colorScheme.onSurface,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (tone.premiumOnly)
                                Positioned(
                                  top: -7,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: AppColors.premiumGradient,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      'PRO',
                                      style: AppTextStyles.caption.copyWith(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppConstants.spacing24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppConstants.spacing20),
                      decoration: BoxDecoration(
                        gradient: theme.brightness == Brightness.dark
                            ? AppColors.darkGradient
                            : LinearGradient(
                                colors: [
                                  AppColors.featureLavender.withValues(
                                    alpha: 0.7,
                                  ),
                                  AppColors.surfaceLight,
                                ],
                              ),
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusCard,
                        ),
                      ),
                      child: Text(
                        'Tip: write naturally. Mention your goal, audience, and any examples you already have.',
                        style: AppTextStyles.body.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor.withValues(alpha: 0.92),
                border: Border(top: BorderSide(color: theme.dividerColor)),
              ),
              child: Row(
                children: [
                   isCupertino
                       ? CupertinoButton(
                           padding: EdgeInsets.zero,
                           onPressed: _openVoice,
                           child: Container(
                             width: 52,
                             height: 52,
                             decoration: BoxDecoration(
                               color: theme.colorScheme.surface,
                               borderRadius: BorderRadius.circular(16),
                               border: Border.all(color: theme.dividerColor),
                             ),
                             alignment: Alignment.center,
                             child: const Icon(CupertinoIcons.mic),
                           ),
                         )
                       : IconButton(
                           onPressed: _openVoice,
                           style: IconButton.styleFrom(
                             backgroundColor: theme.colorScheme.surface,
                             minimumSize: const Size(52, 52),
                           ),
                           icon: const Icon(Icons.mic_none_rounded),
                         ),
                   const SizedBox(width: AppConstants.spacing12),
                   Expanded(
                     child: AdaptiveButton(
                       label: 'Enhance Prompt',
                       icon: Icons.auto_awesome_rounded,
                       isLoading: _isProcessing,
                       onPressed: _controller.text.trim().isEmpty || _isProcessing
                           ? null
                           : _enhancePrompt,
                     ),
                   ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
