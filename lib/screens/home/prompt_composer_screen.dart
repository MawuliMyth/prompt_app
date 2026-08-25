import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_text_styles.dart';
import '../../data/services/analytics_bootstrap.dart';
import '../../core/utils/app_icon_mapper.dart';
import '../../core/utils/platform_utils.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../core/utils/strength_calculator.dart';
import '../../core/widgets/adaptive_widgets.dart';
import '../../core/widgets/daily_limit_sheet.dart';
import '../../core/widgets/locked_feature_sheet.dart';
import '../../data/services/claude_service.dart';
import '../../data/models/app_config_model.dart';
import '../../providers/app_config_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/connectivity_provider.dart';
import '../../providers/daily_limit_provider.dart';
import '../../providers/free_prompt_provider.dart';
import '../../providers/premium_provider.dart';
import '../auth/login_screen.dart';
import '../auth/signup_screen.dart';
import '../paywall/paywall_screen.dart';
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
  static const String _aiToolPreferenceKey = 'selected_ai_tool';
  static const String _defaultAiTool = 'Cursor';

  final TextEditingController _controller = TextEditingController();
  final TextEditingController _audienceController = TextEditingController();
  final TextEditingController _firstFlowController = TextEditingController();
  final TextEditingController _stackController = TextEditingController();
  final TextEditingController _filesController = TextEditingController();
  final TextEditingController _acceptanceController = TextEditingController();
  final ClaudeService _claudeService = ClaudeService();
  String? _selectedCategoryId;
  String _selectedToneId = 'auto';
  String _selectedAiTool = _defaultAiTool;
  String _selectedCodingIntentId = _codingIntents.first.id;
  String _selectedPlatform = 'Not sure';
  String _selectedAuthNeed = 'Not sure';
  String _selectedPaymentNeed = 'Not sure';
  bool _showAdvancedDetails = false;
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
    unawaited(_loadSelectedAiTool());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final categories = context.read<AppConfigProvider>().categories;
    _selectedCategoryId ??= _defaultCategoryId(categories);

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
    _audienceController.dispose();
    _firstFlowController.dispose();
    _stackController.dispose();
    _filesController.dispose();
    _acceptanceController.dispose();
    super.dispose();
  }

  Future<void> _loadSelectedAiTool() async {
    final prefs = await SharedPreferences.getInstance();
    final storedTool = prefs.getString(_aiToolPreferenceKey) ?? _defaultAiTool;
    if (!mounted) return;
    setState(() {
      _selectedAiTool = _aiTools.any((tool) => tool.name == storedTool)
          ? storedTool
          : _defaultAiTool;
    });
  }

  Future<void> _selectAiTool(String toolName) async {
    if (_selectedAiTool == toolName) return;

    setState(() => _selectedAiTool = toolName);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_aiToolPreferenceKey, toolName);
    if (!mounted) return;
    trackAnalytics(
      () => analyticsService.logAIToolSelected(toolName: toolName),
    );
  }

  String? _defaultCategoryId(List<CategoryConfig> categories) {
    for (final category in categories) {
      if (category.id == 'coding') {
        return category.id;
      }
    }
    return categories.isNotEmpty ? categories.first.id : null;
  }

  bool get _isCodingSelected => _selectedCategoryId == 'coding';

  String _placeholderForCategory() {
    switch (_selectedCategoryId) {
      case 'coding':
        return 'Describe what you want to build or fix...';
      case 'image-generation':
        return 'Describe the image you want to create...';
      case 'writing':
        return 'Describe what you want to write...';
      case 'business':
        return 'Describe your business task...';
      case 'general':
      default:
        return 'Describe what you need help with...';
    }
  }

  _CodingIntent get _selectedCodingIntent => _codingIntents.firstWhere(
    (intent) => intent.id == _selectedCodingIntentId,
    orElse: () => _codingIntents.first,
  );

  String _buildEffectivePrompt(String baseText) {
    if (!_isCodingSelected) {
      return baseText;
    }

    final parts = <String>[
      'Coding task:',
      baseText,
      '',
      'Task type: ${_selectedCodingIntent.label}',
    ];

    if (_audienceController.text.trim().isNotEmpty) {
      parts
        ..add('')
        ..add('Who this is for:')
        ..add(_audienceController.text.trim());
    }

    if (_firstFlowController.text.trim().isNotEmpty) {
      parts
        ..add('')
        ..add('What users should be able to do first:')
        ..add(_firstFlowController.text.trim());
    }

    parts
      ..add('')
      ..add('Preferred product type: $_selectedPlatform')
      ..add('Authentication needed: $_selectedAuthNeed')
      ..add('Payments needed: $_selectedPaymentNeed')
      ..add(
        'If the user does not specify a stack, architecture, or implementation approach, infer the best practical option and include it in the final prompt.',
      );

    if (_stackController.text.trim().isNotEmpty) {
      parts
        ..add('')
        ..add('Tech stack / language / framework:')
        ..add(_stackController.text.trim());
    }

    if (_filesController.text.trim().isNotEmpty) {
      parts
        ..add('')
        ..add('Relevant files, components, or systems:')
        ..add(_filesController.text.trim());
    }

    if (_acceptanceController.text.trim().isNotEmpty) {
      parts
        ..add('')
        ..add('Constraints, edge cases, or acceptance criteria:')
        ..add(_acceptanceController.text.trim());
    }

    parts
      ..add('')
      ..add(
        'Optimize the final prompt so it is ready to paste into ${_selectedAiTool.replaceAll(' / ', '/')}.',
      );

    return parts.join('\n');
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
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    // Guard against double-submit: without this, a rapid double-tap could
    // fire two enhance requests before the button visually disables, since
    // several awaits below (e.g. loadDailyUsage) happen before _isProcessing
    // was previously flipped to true. Set it synchronously, first thing.
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    final navigator = Navigator.of(context);
    try {
      final effectivePrompt = _buildEffectivePrompt(text);

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
        if (!freePromptProvider.canUsePrompt) {
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
        if (!dailyLimitProvider.canUsePrompt) {
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

      final result = await _claudeService.enhancePrompt(
        roughPrompt: effectivePrompt,
        // Send the stable backend id, not the display label, per
        // architecture.md ("stable IDs, never display names as business
        // identifiers"). The backend's normalizeCategory/normalizeTone
        // already resolve either id or label, so this is a safe, purely
        // client-side hardening - it just stops the request contract from
        // silently breaking if copy/labels are ever renamed.
        category: category.id,
        isAuthenticated: authProvider.isAuthenticated,
        tone: tone.id,
        persona: premiumProvider.userData?.persona,
        aiTool: _selectedAiTool,
      );

      if (!mounted) return;

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
        trackAnalytics(
          () => analyticsService.logSpecialistCategoryUsed(
            category: category.label,
          ),
        );
        if (!authProvider.isAuthenticated) {
          await freePromptProvider.consumePromptUse();
          if (!mounted) return;
        } else if (!premiumProvider.hasPremiumAccess) {
          await dailyLimitProvider.consumePromptUse();
          await dailyLimitProvider.loadDailyUsage();
          if (!mounted) return;
        }

        await navigator.push(
          PlatformUtils.adaptivePageRoute(
            ResultScreen(
              originalText: text,
              enhancedPrompt: enhancedPrompt,
              category: category.label,
              aiTool: _selectedAiTool,
            ),
          ),
        );
        return;
      }

      // The client already checks quota/premium before calling enhance, but
      // the backend is the authoritative source of truth and can still
      // reject with one of these codes (e.g. another device used up the
      // day's quota in the meantime). Route to the same UI a proactive
      // client-side check would have shown, instead of a generic error
      // snackbar that leaves the user unsure what to do next.
      final code = result['code'] as String?;
      if ((code == 'daily-limit-reached' || code == 'guest-limit-reached') &&
          mounted) {
        DailyLimitSheet.show(context);
      } else if (code == 'premium-required' && mounted) {
        await PlatformUtils.navigateTo(
          context,
          const PaywallScreen(trigger: 'enhance_rejected'),
        );
      } else {
        SnackbarUtils.showError(
          context,
          result['error'] as String? ?? 'Something went wrong.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
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
                      'Build faster with better prompts',
                      style: AppTextStyles.heading.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacing8),
                    Text(
                      'Turn your rough ideas into prompts that AI actually understands',
                      style: AppTextStyles.body.copyWith(
                        color: theme.hintColor,
                      ),
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
                    if (_isCodingSelected) ...[
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight.withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.code_rounded,
                                    color: AppColors.primaryLight,
                                  ),
                                ),
                                const SizedBox(width: AppConstants.spacing12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Simple builder brief',
                                        style: AppTextStyles.subtitle.copyWith(
                                          color: theme.colorScheme.onSurface,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'You do not need technical knowledge. Just answer in plain English and Prompt will fill in the rest.',
                                        style: AppTextStyles.caption.copyWith(
                                          color: theme.hintColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppConstants.spacing16),
                            AdaptiveTextField(
                              controller: _audienceController,
                              minLines: 2,
                              maxLines: 3,
                              hintText:
                                  'Who is this for? e.g. students, barbershop customers, small business owners',
                            ),
                            const SizedBox(height: AppConstants.spacing12),
                            AdaptiveTextField(
                              controller: _firstFlowController,
                              minLines: 2,
                              maxLines: 3,
                              hintText:
                                  'What should users be able to do first? e.g. sign up, browse listings, book appointments, upload files',
                            ),
                            const SizedBox(height: AppConstants.spacing16),
                            Text(
                              'What are you building?',
                              style: AppTextStyles.sectionLabel.copyWith(
                                color: theme.hintColor,
                              ),
                            ),
                            const SizedBox(height: AppConstants.spacing12),
                            Wrap(
                              spacing: AppConstants.spacing8,
                              runSpacing: AppConstants.spacing8,
                              children: _simpleOptions['platform']!.map((
                                option,
                              ) {
                                return AdaptiveSelectionChip(
                                  label: option,
                                  selected: option == _selectedPlatform,
                                  onTap: () => setState(
                                    () => _selectedPlatform = option,
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: AppConstants.spacing16),
                            Text(
                              'Should people sign in?',
                              style: AppTextStyles.sectionLabel.copyWith(
                                color: theme.hintColor,
                              ),
                            ),
                            const SizedBox(height: AppConstants.spacing12),
                            Wrap(
                              spacing: AppConstants.spacing8,
                              runSpacing: AppConstants.spacing8,
                              children: _simpleOptions['yesNo']!.map((option) {
                                return AdaptiveSelectionChip(
                                  label: option,
                                  selected: option == _selectedAuthNeed,
                                  onTap: () => setState(
                                    () => _selectedAuthNeed = option,
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: AppConstants.spacing16),
                            Text(
                              'Will it need payments?',
                              style: AppTextStyles.sectionLabel.copyWith(
                                color: theme.hintColor,
                              ),
                            ),
                            const SizedBox(height: AppConstants.spacing12),
                            Wrap(
                              spacing: AppConstants.spacing8,
                              runSpacing: AppConstants.spacing8,
                              children: _simpleOptions['yesNo']!.map((option) {
                                return AdaptiveSelectionChip(
                                  label: option,
                                  selected: option == _selectedPaymentNeed,
                                  onTap: () => setState(
                                    () => _selectedPaymentNeed = option,
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: AppConstants.spacing16),
                            Text(
                              'Task type',
                              style: AppTextStyles.sectionLabel.copyWith(
                                color: theme.hintColor,
                              ),
                            ),
                            const SizedBox(height: AppConstants.spacing12),
                            Wrap(
                              spacing: AppConstants.spacing8,
                              runSpacing: AppConstants.spacing8,
                              children: _codingIntents.map((intent) {
                                final selected =
                                    intent.id == _selectedCodingIntentId;
                                return AdaptiveSelectionChip(
                                  label: intent.label,
                                  selected: selected,
                                  icon: Icon(intent.icon),
                                  onTap: () => setState(
                                    () => _selectedCodingIntentId = intent.id,
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: AppConstants.spacing16),
                            GestureDetector(
                              onTap: () => setState(
                                () => _showAdvancedDetails =
                                    !_showAdvancedDetails,
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    'Advanced details (optional)',
                                    style: AppTextStyles.sectionLabel.copyWith(
                                      color: theme.hintColor,
                                    ),
                                  ),
                                  const Spacer(),
                                  Icon(
                                    _showAdvancedDetails
                                        ? Icons.keyboard_arrow_up_rounded
                                        : Icons.keyboard_arrow_down_rounded,
                                    color: theme.hintColor,
                                  ),
                                ],
                              ),
                            ),
                            if (_showAdvancedDetails) ...[
                              const SizedBox(height: AppConstants.spacing12),
                              AdaptiveTextField(
                                controller: _stackController,
                                minLines: 2,
                                maxLines: 3,
                                hintText:
                                    'Optional: stack, language, framework, or environment if you already know it',
                              ),
                              const SizedBox(height: AppConstants.spacing12),
                              AdaptiveTextField(
                                controller: _filesController,
                                minLines: 2,
                                maxLines: 3,
                                hintText:
                                    'Optional: relevant files, components, APIs, or systems already involved',
                              ),
                              const SizedBox(height: AppConstants.spacing12),
                              AdaptiveTextField(
                                controller: _acceptanceController,
                                minLines: 3,
                                maxLines: 4,
                                hintText:
                                    'Optional: constraints, edge cases, performance needs, testing expectations, or what to avoid',
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: AppConstants.spacing20),
                    ],
                    AdaptiveTextField(
                      controller: _controller,
                      maxLines: 12,
                      minLines: 10,
                      hintText: _placeholderForCategory(),
                      suffixIcon: _controller.text.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () =>
                                  setState(() => _controller.clear()),
                              icon: const Icon(Icons.close_rounded),
                            ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: AppConstants.spacing20),
                    if (_isCodingSelected) ...[
                      Text(
                        'Optimizing for',
                        style: AppTextStyles.sectionLabel.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                      const SizedBox(height: AppConstants.spacing12),
                      SizedBox(
                        height: 44,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _aiTools.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(width: AppConstants.spacing8),
                          itemBuilder: (context, index) {
                            final tool = _aiTools[index];
                            final selected = tool.name == _selectedAiTool;

                            return GestureDetector(
                              onTap: () => _selectAiTool(tool.name),
                              child: Container(
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
                                  border: Border.all(
                                    color: selected
                                        ? AppColors.primaryLight
                                        : AppColors.primaryLight,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      tool.icon,
                                      size: 18,
                                      color: selected
                                          ? Colors.white
                                          : theme.hintColor,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      tool.name,
                                      style: AppTextStyles.caption.copyWith(
                                        color: selected
                                            ? Colors.white
                                            : theme.hintColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: AppConstants.spacing24),
                    ],
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
                                      style: AppTextStyles.badge.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
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
                        _isCodingSelected
                            ? 'Tip: mention your stack, what already exists, what should change, and how success should be verified.'
                            : 'Tip: write naturally. Mention your goal, audience, and any examples you already have.',
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
                      onPressed:
                          _controller.text.trim().isEmpty || _isProcessing
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

class _AiToolOption {
  const _AiToolOption({required this.name, required this.icon});

  final String name;
  final IconData icon;
}

class _CodingIntent {
  const _CodingIntent({
    required this.id,
    required this.label,
    required this.icon,
  });

  final String id;
  final String label;
  final IconData icon;
}

const List<_AiToolOption> _aiTools = [
  _AiToolOption(name: 'Cursor', icon: Icons.code),
  _AiToolOption(name: 'Claude Code', icon: Icons.terminal),
  _AiToolOption(name: 'GitHub Copilot', icon: Icons.hub_outlined),
  _AiToolOption(name: 'Bolt / Lovable', icon: Icons.bolt),
  _AiToolOption(name: 'ChatGPT', icon: Icons.smart_toy_outlined),
  _AiToolOption(name: 'Gemini', icon: Icons.auto_awesome),
];

const List<_CodingIntent> _codingIntents = [
  _CodingIntent(
    id: 'add-feature',
    label: 'Add feature',
    icon: Icons.add_box_outlined,
  ),
  _CodingIntent(
    id: 'fix-bug',
    label: 'Fix bug',
    icon: Icons.bug_report_outlined,
  ),
  _CodingIntent(
    id: 'build-screen',
    label: 'Build screen',
    icon: Icons.web_asset_outlined,
  ),
  _CodingIntent(id: 'refactor', label: 'Refactor', icon: Icons.tune_outlined),
  _CodingIntent(id: 'debug', label: 'Debug', icon: Icons.search_outlined),
  _CodingIntent(
    id: 'tests',
    label: 'Write tests',
    icon: Icons.fact_check_outlined,
  ),
];

const Map<String, List<String>> _simpleOptions = {
  'platform': ['Mobile app', 'Website', 'Both', 'Not sure'],
  'yesNo': ['Yes', 'No', 'Not sure'],
};
