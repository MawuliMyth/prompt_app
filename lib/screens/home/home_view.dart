import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/free_prompt_provider.dart';
import '../../providers/template_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../core/utils/platform_utils.dart';
import '../../core/widgets/adaptive_widgets.dart';
import '../../core/widgets/shimmer_loading.dart';
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
  bool _isRecording = false;
  bool _isProcessing = false;
  bool _isTranscribing = false;
  late AnimationController _pulseController;

  final List<Map<String, String>> _categories = [
    {'name': 'General', 'icon': '🌐'},
    {'name': 'Image Generation', 'icon': '🎨'},
    {'name': 'Coding', 'icon': '💻'},
    {'name': 'Writing', 'icon': '✍️'},
    {'name': 'Business', 'icon': '📊'},
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
      if (templateCategory != null && _categories.any((c) => c['name'] == templateCategory)) {
        _selectedCategory = templateCategory;
      }
      templateProvider.clearTemplate();
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    _pulseController.dispose();
    _audioRecorderService.dispose();
    super.dispose();
  }

  Future<void> _handleRecording() async {
    if (_isRecording) {
      // Stop recording and transcribe
      setState(() => _isRecording = false);

      final audioBytes = await _audioRecorderService.stopRecording();
      if (audioBytes == null) {
        if (mounted) SnackbarUtils.showError(context, 'Failed to record audio.');
        return;
      }

      // Transcribe the audio
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
      // Start recording
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
               Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_outline,
                    size: 40,
                    color: AppColors.primaryLight,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  "You've used all 5 free prompts!",
                  style: AppTextStyles.headingMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  "Create a free account to get unlimited prompts and save your history.",
                  style: AppTextStyles.body.copyWith(color: AppColors.textSecondaryLight),
                  textAlign: TextAlign.center,
                ),
                 const SizedBox(height: 32),
                 ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close sheet
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SignupScreen()));
                  },
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
                        'Create Free Account',
                        style: AppTextStyles.button.copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                ),
                 const SizedBox(height: 16),
                 TextButton(
                    onPressed: () {
                       Navigator.pop(context);
                       Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
                    },
                    child: Text('Sign in instead', style: AppTextStyles.button.copyWith(color: AppColors.textPrimaryLight))),
                 TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Maybe Later', style: AppTextStyles.button.copyWith(color: AppColors.textSecondaryLight))),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _enhancePrompt() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final freePromptProvider = Provider.of<FreePromptProvider>(context, listen: false);

    if (!authProvider.isAuthenticated && freePromptProvider.hasReachedLimit) {
      _showSignupBottomSheet();
      return;
    }

    setState(() => _isProcessing = true);

    final result = await _claudeService.enhancePrompt(
      roughPrompt: text,
      category: _selectedCategory,
    );

    setState(() => _isProcessing = false);

    if (result['success']) {
      if (!authProvider.isAuthenticated) {
        await freePromptProvider.increment();
      }
      
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

    // Get First Name if available
    String displayName = authProvider.currentUser?.displayName ?? '';
    if (displayName.contains(' ')) {
      displayName = displayName.split(' ')[0];
    }

    return SafeArea(
      child: Scaffold(
         appBar: AdaptiveAppBar(title: 'Prompt'),
         body: LayoutBuilder(
           builder: (context, constraints) {
             final contentMaxWidth = isTablet ? 600.0 : constraints.maxWidth;
             return Center(
               child: SizedBox(
                 width: contentMaxWidth,
                 child: SingleChildScrollView(
                    padding: EdgeInsets.all(isSmallScreen ? 12.0 : 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Section A
                        Text(
                          authProvider.isAuthenticated ? 'Hello, $displayName 👋' : 'Hello! 👋',
                          style: AppTextStyles.headingMedium.copyWith(color: theme.colorScheme.onSurface),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'What do you want to prompt today?',
                          style: AppTextStyles.body.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7)),
                        ),
                        const SizedBox(height: 24),

                        // Section B (Categories)
                        SizedBox(
                          height: 40,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _categories.length,
                            itemBuilder: (context, index) {
                              final category = _categories[index];
                              final isSelected = _selectedCategory == category['name'];
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ChoiceChip(
                                  label: Text('${category['icon']} ${category['name']}'),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() => _selectedCategory = category['name']!);
                                    }
                                  },
                                  labelStyle: TextStyle(
                                    color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                    fontSize: isSmallScreen ? 12 : 14,
                                  ),
                                  selectedColor: AppColors.primaryLight,
                                  backgroundColor: theme.colorScheme.surface,
                                  side: BorderSide(
                                    color: isSelected ? Colors.transparent : AppColors.primaryLight,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Section C
                        Container(
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              if (_isRecording || _isTranscribing)
                                Padding(
                                  padding: const EdgeInsets.only(top: 16.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(_isTranscribing ? 'Transcribing... ' : 'Listening... '),
                                      const SizedBox(width: 8),
                                      const ShimmerLoading(width: 60, height: 12, borderRadius: 4),
                                    ],
                                  ),
                                ),
                              TextField(
                                controller: _inputController,
                                maxLines: isSmallScreen ? 5 : 8,
                                minLines: isSmallScreen ? 3 : 4,
                                decoration: InputDecoration(
                                  hintText: 'Describe what you want to prompt... or tap the mic to speak',
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  filled: false,
                                  counterText: '${_inputController.text.length} chars',
                                  contentPadding: const EdgeInsets.all(16),
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    GestureDetector(
                                      onTap: _handleRecording,
                                      child: AnimatedBuilder(
                                        animation: _pulseController,
                                        builder: (context, child) {
                                          return Container(
                                            width: 48,
                                            height: 48,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: _isRecording ? Colors.redAccent.withOpacity(0.2 + (_pulseController.value * 0.3)) : AppColors.primaryLight,
                                            ),
                                            child: Center(
                                              child: Icon(
                                                _isRecording ? Icons.stop : Icons.mic,
                                                color: Colors.white,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                     if (_inputController.text.isNotEmpty)
                                        IconButton(
                                          icon: const Icon(Icons.clear, color: AppColors.textSecondaryLight),
                                          onPressed: () => setState(() => _inputController.clear()),
                                        ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Section D
                        ElevatedButton(
                          onPressed: (_inputController.text.isEmpty || _isProcessing) ? null : _enhancePrompt,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.zero,
                          ),
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: (_inputController.text.isEmpty || _isProcessing)
                                    ? [Colors.grey.shade400, Colors.grey.shade500]
                                    : [const Color(0xFFE53935), const Color(0xFFB71C1C)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Container(
                              height: 56,
                              alignment: Alignment.center,
                              child: _isProcessing
                                  ? Shimmer.fromColors(
                                      baseColor: Colors.white.withOpacity(0.5),
                                      highlightColor: Colors.white.withOpacity(0.9),
                                      child: Text(
                                        '✨ Enhancing...',
                                        style: AppTextStyles.button.copyWith(color: Colors.white),
                                      ),
                                    )
                                  : Text(
                                      '✨ Enhance My Prompt',
                                      style: AppTextStyles.button.copyWith(color: Colors.white),
                                    ),
                            ),
                          ),
                        ),

                        // Section E (Guest Counter)
                        if (!authProvider.isAuthenticated) ...[
                            const SizedBox(height: 16),
                            Center(
                              child: Column(
                                children: [
                                   Text(
                                     '${freePromptProvider.used} of ${FreePromptProvider.maxFreePrompts} free prompts used',
                                     style: AppTextStyles.caption.copyWith(color: theme.colorScheme.onSurface),
                                   ),
                                   const SizedBox(height: 8),
                                   SizedBox(
                                      width: isSmallScreen ? 150 : 200,
                                      child: LinearProgressIndicator(
                                         value: freePromptProvider.used / FreePromptProvider.maxFreePrompts,
                                         backgroundColor: AppColors.dividerLight,
                                         valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryLight),
                                         borderRadius: BorderRadius.circular(4),
                                      ),
                                   ),
                                   const SizedBox(height: 8),
                                   GestureDetector(
                                      onTap: () {
                                         Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SignupScreen()));
                                      },
                                      child: Text(
                                         'Sign up for unlimited prompts →',
                                         style: AppTextStyles.caption.copyWith(color: AppColors.primaryLight, fontWeight: FontWeight.bold),
                                      ),
                                   )
                                ],
                              ),
                            ),
                         ],
                         const SizedBox(height: 32),

                         // Section F
                         Text(
                           'Quick Templates',
                           style: AppTextStyles.headingSmall.copyWith(color: theme.colorScheme.onSurface),
                         ),
                         const SizedBox(height: 16),
                         SizedBox(
                           height: isSmallScreen ? 100 : 120,
                           child: ListView(
                             scrollDirection: Axis.horizontal,
                             children: [
                                _buildTemplateCard('🌐', 'Explain Concept', 'General', 'Explain a concept simply', isSmallScreen),
                                _buildTemplateCard('💻', 'Code Review', 'Coding', 'Review and improve this code...', isSmallScreen),
                                _buildTemplateCard('🎨', 'Realistic Portrait', 'Image Generation', 'Create a realistic portrait of...', isSmallScreen),
                             ],
                           ),
                         ),
                         const SizedBox(height: 24),
                      ],
                    ),
                 ),
               ),
             );
           },
         ),
      ),
    );
  }

  Widget _buildTemplateCard(String emoji, String title, String category, String textContent, bool isSmallScreen) {
     final theme = Theme.of(context);
     return GestureDetector(
        onTap: () {
           setState(() {
              _inputController.text = textContent;

              // Only switch if we found exactly the match (or mapping logic mapping 'Image Gen' to 'Image Generation' depending on design needs)
              final index = _categories.indexWhere((c) => c['name'] == category);
              if(index != -1) _selectedCategory = category;
           });
        },
        child: Container(
           width: isSmallScreen ? 140 : 160,
           margin: const EdgeInsets.only(right: 16),
           padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
           decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.dividerLight),
           ),
           child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                 Text(emoji, style: TextStyle(fontSize: isSmallScreen ? 20 : 24)),
                 SizedBox(height: isSmallScreen ? 6 : 8),
                 Text(title, style: AppTextStyles.button.copyWith(fontSize: isSmallScreen ? 12 : 14)),
                 const SizedBox(height: 4),
                 Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                       color: AppColors.primaryLight.withOpacity(0.1),
                       borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(category, style: AppTextStyles.caption.copyWith(color: AppColors.primaryLight, fontSize: isSmallScreen ? 8 : 10)),
                 ),
              ],
           ),
        ),
     );
  }
}
