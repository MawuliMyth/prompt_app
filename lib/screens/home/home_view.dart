import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/free_prompt_provider.dart';
import '../../providers/template_provider.dart';
import '../../providers/premium_provider.dart';
import '../../providers/daily_limit_provider.dart';
import '../../providers/connectivity_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../core/widgets/adaptive_widgets.dart';
import '../../core/widgets/upgrade_banner.dart';
import '../../core/widgets/locked_feature_sheet.dart';
import '../../core/widgets/daily_limit_sheet.dart';
import '../../data/services/audio_recorder_service.dart';
import '../../data/services/transcription_service.dart';
import '../../data/services/claude_service.dart';
import '../result/result_screen.dart';
import '../auth/signup_screen.dart';
import '../auth/login_screen.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with SingleTickerProviderStateMixin {
  final _inputController = TextEditingController();
  final AudioRecorderService _audioRecorderService = AudioRecorderService();
  final TranscriptionService _transcriptionService = TranscriptionService();
  final ClaudeService _claudeService = ClaudeService();

  String _selectedCategory = 'General';
  String _selectedTone = 'Auto';
  bool _isRecording = false;
  bool _isProcessing = false;
  bool _isTranscribing = false;
  late AnimationController _pulseController;

  final List<_CategoryItem> _categories = [
    _CategoryItem(name: 'General', icon: Icons.public_outlined, color: AppColors.categoryGeneral),
    _CategoryItem(name: 'Image Generation', icon: Icons.palette_outlined, color: AppColors.categoryImageGeneration),
    _CategoryItem(name: 'Coding', icon: Icons.code_outlined, color: AppColors.categoryCoding),
    _CategoryItem(name: 'Writing', icon: Icons.edit_outlined, color: AppColors.categoryWriting),
    _CategoryItem(name: 'Business', icon: Icons.business_center_outlined, color: AppColors.categoryBusiness),
  ];

  final List<_ToneItem> _tones = [
    _ToneItem(name: 'Auto', icon: Icons.auto_awesome_outlined),
    _ToneItem(name: 'Professional', icon: Icons.work_outline),
    _ToneItem(name: 'Creative', icon: Icons.palette_outlined),
    _ToneItem(name: 'Casual', icon: Icons.sentiment_satisfied_outlined),
    _ToneItem(name: 'Persuasive', icon: Icons.lightbulb_outline),
    _ToneItem(name: 'Technical', icon: Icons.settings_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkForTemplate();
  }

  void _checkForTemplate() {
    final templateProvider = Provider.of<TemplateProvider>(context, listen: false);
    if (templateProvider.hasTemplate) {
      _inputController.text = templateProvider.selectedTemplateContent ?? '';
      final templateCategory = templateProvider.selectedCategory;
      if (templateCategory != null && _categories.any((c) => c.name == templateCategory)) {
        _selectedCategory = templateCategory;
      }
      templateProvider.clearTemplate();
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    _pulseController.dispose();
    // AudioRecorderService.dispose() is async - fire and forget
    // This is safe because the recorder will be closed eventually
    _audioRecorderService.dispose().ignore();
    super.dispose();
  }

  Future<void> _handleRecording() async {
    if (_isRecording) {
      setState(() => _isRecording = false);
      final audioBytes = await _audioRecorderService.stopRecording();
      if (audioBytes == null) {
        if (mounted) SnackbarUtils.showError(context, 'Failed to record audio.');
        return;
      }
      setState(() => _isTranscribing = true);
      try {
        final text = await _transcriptionService.transcribeAudio(audioBytes);
        setState(() {
          _inputController.text = text;
        });
      } catch (e) {
        if (mounted) SnackbarUtils.showError(context, e.toString());
      } finally {
        setState(() => _isTranscribing = false);
      }
    } else {
      final hasPermission = await _audioRecorderService.initialize();
      if (!hasPermission) {
        if (mounted) SnackbarUtils.showError(context, 'Microphone permission denied.');
        return;
      }
      final path = await _audioRecorderService.startRecording();
      if (path == null) {
        if (mounted) SnackbarUtils.showError(context, 'Failed to start recording.');
        return;
      }
      setState(() => _isRecording = true);
    }
  }

  void _showSignupBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppConstants.radiusBottomSheet),
          ),
        ),
        padding: EdgeInsets.fromLTRB(
          AppConstants.spacing24,
          AppConstants.spacing24,
          AppConstants.spacing24,
          MediaQuery.of(context).viewInsets.bottom + AppConstants.spacing24,
        ),
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
                Icons.lock_outline,
                size: 40,
                color: AppColors.primaryLight,
              ),
            ),
            const SizedBox(height: AppConstants.spacing24),
            Text(
              "You've used all 5 free prompts!",
              style: AppTextStyles.title,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacing12),
            Text(
              "Create a free account to save your history and sync across devices.",
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  child: Text(
                    'Sign in instead',
                    style: AppTextStyles.body.copyWith(color: AppColors.primaryLight),
                  ),
                ),
                Text(
                  '  |  ',
                  style: AppTextStyles.body.copyWith(color: AppColors.textSecondaryLight),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Maybe Later',
                    style: AppTextStyles.body.copyWith(color: AppColors.textSecondaryLight),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _enhancePrompt() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    // Check connectivity first
    final connectivityProvider = Provider.of<ConnectivityProvider>(context, listen: false);
    if (!connectivityProvider.isOnline) {
      SnackbarUtils.showError(context, 'You are offline. Please check your connection.');
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final freePromptProvider = Provider.of<FreePromptProvider>(context, listen: false);
    final premiumProvider = Provider.of<PremiumProvider>(context, listen: false);
    final dailyLimitProvider = Provider.of<DailyLimitProvider>(context, listen: false);

    // Check limits based on user type
    if (!authProvider.isAuthenticated) {
      // Guest user: check 5 total limit
      if (freePromptProvider.hasReachedLimit) {
        _showSignupBottomSheet();
        return;
      }
    } else if (!premiumProvider.hasPremiumAccess) {
      // Free authenticated user: check daily limit
      await dailyLimitProvider.loadDailyUsage();
      if (dailyLimitProvider.hasReachedLimit) {
        DailyLimitSheet.show(context);
        return;
      }
    }
    // Premium users: no limit check

    setState(() => _isProcessing = true);
    HapticFeedback.lightImpact();
    // Announce for accessibility
    // ignore: deprecated_member_use
    SemanticsService.announce('Enhancing your prompt', TextDirection.ltr);

    String? persona;
    if (premiumProvider.hasPremiumAccess && premiumProvider.userData?.persona != null) {
      persona = premiumProvider.userData!.persona;
    }

    final result = await _claudeService.enhancePrompt(
      roughPrompt: text,
      category: _selectedCategory,
      isAuthenticated: authProvider.isAuthenticated,
      tone: _selectedTone,
      persona: persona,
    );

    setState(() => _isProcessing = false);

    if (result['success']) {
      // Increment the appropriate counter based on user type
      if (!authProvider.isAuthenticated) {
        // Guest user: increment local counter
        await freePromptProvider.increment();
      } else if (!premiumProvider.hasPremiumAccess) {
        // Free authenticated user: increment daily counter
        await dailyLimitProvider.incrementUsage();
      }
      // Premium users: no counter to increment

      // Announce for accessibility
      // ignore: deprecated_member_use
      SemanticsService.announce('Prompt enhanced successfully', TextDirection.ltr);

      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ResultScreen(
              originalText: text,
              enhancedPrompt: result['enhancedPrompt'],
              category: _selectedCategory,
            ),
          ),
        ).then((_) {
          _inputController.clear();
        });
      }
    } else {
      if (mounted) {
        // Announce error for accessibility
        // ignore: deprecated_member_use
        SemanticsService.announce('Error: ${result['error']}', TextDirection.ltr);
        SnackbarUtils.showError(context, result['error']);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final freePromptProvider = Provider.of<FreePromptProvider>(context);
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;
    final isTablet = screenSize.width >= 600;

    String displayName = authProvider.currentUser?.displayName ?? '';
    if (displayName.contains(' ')) {
      displayName = displayName.split(' ')[0];
    }

    return Scaffold(
      appBar: AdaptiveAppBar(title: 'Prompt'),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final contentMaxWidth = isTablet ? 600.0 : constraints.maxWidth;
          return Center(
            child: SizedBox(
              width: contentMaxWidth,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isSmallScreen ? AppConstants.spacing16 : AppConstants.spacing24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Greeting Section
                    Text(
                      authProvider.isAuthenticated ? 'Hello, $displayName' : 'Hello!',
                      style: AppTextStyles.heading.copyWith(color: theme.colorScheme.onSurface),
                    ),
                    const SizedBox(height: AppConstants.spacing8),
                    Text(
                      'What do you want to prompt today?',
                      style: AppTextStyles.subtitle.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),

                    const SizedBox(height: AppConstants.spacing24),

                    // Upgrade Banner
                    const UpgradeBanner(),

                    const SizedBox(height: AppConstants.spacing32),

                    // Category Section
                    _buildSectionLabel('Category'),
                    const SizedBox(height: AppConstants.spacing12),
                    SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final category = _categories[index];
                          final isSelected = _selectedCategory == category.name;
                          return Padding(
                            padding: const EdgeInsets.only(right: AppConstants.spacing8),
                            child: _buildCategoryChip(category, isSelected, isSmallScreen),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: AppConstants.spacing24),

                    // Tone Section (Premium)
                    Consumer<PremiumProvider>(
                      builder: (context, premiumProvider, child) {
                        final hasPremium = premiumProvider.hasPremiumAccess;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _buildSectionLabel('Tone'),
                                if (!hasPremium) ...[
                                  const SizedBox(width: AppConstants.spacing8),
                                  Icon(
                                    Icons.lock_outline,
                                    size: 14,
                                    color: AppColors.textSecondaryLight,
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: AppConstants.spacing12),
                            SizedBox(
                              height: 40,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _tones.length,
                                itemBuilder: (context, index) {
                                  final tone = _tones[index];
                                  final isSelected = _selectedTone == tone.name;
                                  final isLocked = !hasPremium && index > 0;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: AppConstants.spacing8),
                                    child: _buildToneChip(tone, isSelected, isLocked, isSmallScreen),
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: AppConstants.spacing32),

                    // Input Card
                    _buildInputCard(theme, isSmallScreen),

                    const SizedBox(height: AppConstants.spacing24),

                    // Enhance Button
                    _buildEnhanceButton(isSmallScreen),

                    // Guest Counter (only for non-authenticated users)
                    if (!authProvider.isAuthenticated) ...[
                      const SizedBox(height: AppConstants.spacing16),
                      _buildGuestCounter(freePromptProvider, theme, isSmallScreen),
                    ],

                    // Daily Usage Indicator (only for free authenticated users)
                    if (authProvider.isAuthenticated) ...[
                      Consumer2<PremiumProvider, DailyLimitProvider>(
                        builder: (context, premiumProvider, dailyLimitProvider, child) {
                          if (premiumProvider.hasPremiumAccess) {
                            return const SizedBox.shrink(); // Hide for premium users
                          }
                          return _buildDailyUsageIndicator(dailyLimitProvider, theme, isSmallScreen);
                        },
                      ),
                    ],

                    const SizedBox(height: AppConstants.spacing48),

                    // Quick Templates
                    _buildSectionLabel('Quick Templates'),
                    const SizedBox(height: AppConstants.spacing16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none,
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildTemplateCard(
                              Icons.lightbulb_outline,
                              'Explain Concept',
                              'General',
                              'Explain a concept simply',
                              AppColors.categoryGeneral,
                              isSmallScreen,
                            ),
                            _buildTemplateCard(
                              Icons.code_outlined,
                              'Code Review',
                              'Coding',
                              'Review and improve this code...',
                              AppColors.categoryCoding,
                              isSmallScreen,
                            ),
                            _buildTemplateCard(
                              Icons.palette_outlined,
                              'Realistic Portrait',
                              'Image Generation',
                              'Create a realistic portrait of...',
                              AppColors.categoryImageGeneration,
                              isSmallScreen,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacing24),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: AppTextStyles.caption.copyWith(
        color: AppColors.textSecondaryLight,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildCategoryChip(_CategoryItem category, bool isSelected, bool isSmallScreen) {
    return Semantics(
      label: 'Category: ${category.name}',
      hint: isSelected ? 'Selected' : 'Tap to select',
      button: true,
      child: GestureDetector(
        onTap: () => setState(() => _selectedCategory = category.name),
        child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? AppConstants.spacing12 : AppConstants.spacing16,
          vertical: AppConstants.spacing8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? category.color : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppConstants.radiusChip),
          border: Border.all(
            color: isSelected ? category.color : AppColors.borderLight,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: category.color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              category.icon,
              size: isSmallScreen ? 14 : 16,
              color: isSelected ? Colors.white : category.color,
            ),
            const SizedBox(width: AppConstants.spacing8),
            Text(
              category.name,
              style: AppTextStyles.caption.copyWith(
                color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: isSmallScreen ? 11 : 13,
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildToneChip(_ToneItem tone, bool isSelected, bool isLocked, bool isSmallScreen) {
    return Semantics(
      label: 'Tone: ${tone.name}',
      hint: isLocked
          ? 'Locked. Tap to unlock with Premium'
          : isSelected
              ? 'Selected'
              : 'Tap to select',
      button: true,
      child: GestureDetector(
      onTap: () {
        if (isLocked) {
          LockedFeatureSheet.show(
            context,
            'Tone Selection',
            'Choose from 6 different tones to customize your prompts',
          );
        } else {
          setState(() => _selectedTone = tone.name);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? AppConstants.spacing12 : AppConstants.spacing16,
          vertical: AppConstants.spacing8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppConstants.radiusChip),
          border: Border.all(
            color: isSelected ? AppColors.primaryLight : AppColors.borderLight,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isLocked ? Icons.lock_outline : tone.icon,
              size: isSmallScreen ? 14 : 16,
              color: isSelected
                  ? Colors.white
                  : isLocked
                      ? AppColors.textSecondaryLight
                      : Theme.of(context).colorScheme.onSurface,
            ),
            if (!isLocked) ...[
              const SizedBox(width: AppConstants.spacing8),
              Text(
                tone.name,
                style: AppTextStyles.caption.copyWith(
                  color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: isSmallScreen ? 11 : 13,
                ),
              ),
            ],
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildInputCard(ThemeData theme, bool isSmallScreen) {
    return Container(
      constraints: const BoxConstraints(minHeight: 180),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusCard),
        boxShadow: AppColors.cardShadowLight,
      ),
      child: Column(
        children: [
          // Recording indicator
          if (_isRecording || _isTranscribing)
            Container(
              padding: const EdgeInsets.all(AppConstants.spacing16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryLight,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryLight.withValues(alpha: 0.4 + _pulseController.value * 0.4),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: AppConstants.spacing12),
                  Text(
                    _isTranscribing ? 'Transcribing...' : 'Listening...',
                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondaryLight),
                  ),
                ],
              ),
            ),

          // Text field
          TextField(
            controller: _inputController,
            maxLines: isSmallScreen ? 5 : 6,
            minLines: isSmallScreen ? 3 : 4,
            decoration: InputDecoration(
              hintText: 'Describe what you want to prompt...',
              hintStyle: AppTextStyles.body.copyWith(color: AppColors.textSecondaryLight),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              contentPadding: const EdgeInsets.all(AppConstants.spacing24),
            ),
            style: AppTextStyles.body.copyWith(color: theme.colorScheme.onSurface),
            onChanged: (_) => setState(() {}),
          ),

          // Bottom row
          Container(
            padding: const EdgeInsets.fromLTRB(
              AppConstants.spacing16,
              0,
              AppConstants.spacing16,
              AppConstants.spacing16,
            ),
            child: Row(
              children: [
                // Mic button
                Semantics(
                  label: _isRecording ? 'Stop recording' : 'Start recording',
                  hint: _isRecording ? 'Double tap to stop' : 'Double tap to start',
                  button: true,
                  child: GestureDetector(
                    onTap: _handleRecording,
                    child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isRecording
                              ? AppColors.primaryLight.withValues(alpha: 0.1 + _pulseController.value * 0.15)
                              : AppColors.primaryLight,
                          boxShadow: _isRecording
                              ? [
                                  BoxShadow(
                                    color: AppColors.primaryLight.withValues(alpha: 0.2 + _pulseController.value * 0.2),
                                    blurRadius: 12,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          _isRecording ? Icons.stop : Icons.mic_none,
                          color: _isRecording ? AppColors.primaryLight : Colors.white,
                          size: 24,
                        ),
                      );
                    },
                  ),
                ),
                ),

                const Spacer(),

                // Character count
                Text(
                  '${_inputController.text.length} chars',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondaryLight),
                ),

                // Clear button
                if (_inputController.text.isNotEmpty) ...[
                  const SizedBox(width: AppConstants.spacing12),
                  GestureDetector(
                    onTap: () => setState(() => _inputController.clear()),
                    child: Container(
                      padding: const EdgeInsets.all(AppConstants.spacing8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariantLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhanceButton(bool isSmallScreen) {
    final isDisabled = _inputController.text.isEmpty || _isProcessing;

    return Semantics(
      label: 'Enhance Prompt',
      hint: isDisabled
          ? 'Enter some text to enable'
          : _isProcessing
              ? 'Processing your prompt'
              : 'Tap to enhance your prompt',
      button: true,
      enabled: !isDisabled,
      child: AnimatedScale(
        scale: 1.0,
        duration: const Duration(milliseconds: 100),
        child: SizedBox(
        width: double.infinity,
        height: AppConstants.buttonHeight,
        child: ElevatedButton(
          onPressed: isDisabled ? null : _enhancePrompt,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryLight,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.textSecondaryLight.withValues(alpha: 0.3),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusButton),
            ),
          ),
          child: _isProcessing
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.auto_awesome, size: 20),
                    const SizedBox(width: AppConstants.spacing8),
                    Text(
                      'Enhance Prompt',
                      style: AppTextStyles.button.copyWith(color: Colors.white),
                    ),
                  ],
                ),
        ),
      ),
    ),
    );
  }

  Widget _buildDailyUsageIndicator(DailyLimitProvider provider, ThemeData theme, bool isSmallScreen) {
    final used = provider.dailyPromptsUsed;
    final limit = provider.dailyLimit;
    final remaining = provider.remainingPrompts;
    final isWarning = remaining <= 5 && remaining > 0;
    final isExhausted = remaining <= 0;

    // Load usage on first build if needed
    if (used == 0 && !provider.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        provider.loadDailyUsage();
      });
    }

    return Container(
      margin: const EdgeInsets.only(top: AppConstants.spacing16),
      padding: const EdgeInsets.all(AppConstants.spacing16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusCard),
        border: Border.all(
          color: isWarning || isExhausted
              ? AppColors.warning.withValues(alpha: 0.5)
              : AppColors.borderLight,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.bolt_outlined,
                size: 16,
                color: isWarning || isExhausted ? AppColors.warning : AppColors.primaryLight,
              ),
              const SizedBox(width: AppConstants.spacing8),
              Text(
                '$used of $limit prompts used today',
                style: AppTextStyles.caption.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                '$remaining remaining',
                style: AppTextStyles.caption.copyWith(
                  color: isWarning || isExhausted ? AppColors.warning : AppColors.textSecondaryLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacing12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: used / limit,
              backgroundColor: AppColors.surfaceVariantLight,
              valueColor: AlwaysStoppedAnimation<Color>(
                isWarning || isExhausted ? AppColors.warning : AppColors.primaryLight,
              ),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestCounter(FreePromptProvider provider, ThemeData theme, bool isSmallScreen) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacing16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusCard),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Free Prompts',
                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondaryLight),
              ),
              Text(
                '${provider.used} / ${FreePromptProvider.maxFreePrompts}',
                style: AppTextStyles.caption.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacing12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: provider.used / FreePromptProvider.maxFreePrompts,
              backgroundColor: AppColors.surfaceVariantLight,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryLight),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: AppConstants.spacing12),
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SignupScreen()),
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Sign up to save your progress',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_forward,
                  size: 14,
                  color: AppColors.primaryLight,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(
    IconData icon,
    String title,
    String category,
    String textContent,
    Color color,
    bool isSmallScreen,
  ) {
    final theme = Theme.of(context);
    return Semantics(
      label: 'Template: $title',
      hint: 'Tap to use this template',
      button: true,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _inputController.text = textContent;
            final index = _categories.indexWhere((c) => c.name == category);
            if (index != -1) _selectedCategory = category;
          });
        },
        child: Container(
        width: isSmallScreen ? 140 : 160,
        margin: const EdgeInsets.only(right: AppConstants.spacing16),
        padding: EdgeInsets.all(isSmallScreen ? AppConstants.spacing12 : AppConstants.spacing16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppConstants.radiusCard),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: AppColors.cardShadowLight,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(isSmallScreen ? AppConstants.spacing4 : AppConstants.spacing8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: isSmallScreen ? 18 : 22, color: color),
            ),
            SizedBox(height: isSmallScreen ? AppConstants.spacing4 : AppConstants.spacing12),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.subtitle.copyWith(
                fontSize: isSmallScreen ? 12 : 14,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              category,
              style: AppTextStyles.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}

class _CategoryItem {
  final String name;
  final IconData icon;
  final Color color;

  _CategoryItem({
    required this.name,
    required this.icon,
    required this.color,
  });
}

class _ToneItem {
  final String name;
  final IconData icon;

  _ToneItem({
    required this.name,
    required this.icon,
  });
}
