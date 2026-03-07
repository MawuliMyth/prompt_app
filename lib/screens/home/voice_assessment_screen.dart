import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../core/widgets/page_header.dart';
import '../../data/services/audio_recorder_service.dart';
import '../../data/services/transcription_service.dart';
import '../../providers/connectivity_provider.dart';

class VoiceAssessmentScreen extends StatefulWidget {
  const VoiceAssessmentScreen({super.key});

  @override
  State<VoiceAssessmentScreen> createState() => _VoiceAssessmentScreenState();
}

class _VoiceAssessmentScreenState extends State<VoiceAssessmentScreen>
    with SingleTickerProviderStateMixin {
  final AudioRecorderService _audioRecorderService = AudioRecorderService();
  final TranscriptionService _transcriptionService = TranscriptionService();
  late final AnimationController _orbController;

  bool _isRecording = false;
  bool _isProcessing = false;
  String _caption = 'Go ahead, I\'m listening...';
  String _transcript = '';

  @override
  void initState() {
    super.initState();
    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _audioRecorderService.dispose().ignore();
    _orbController.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    if (!context.read<ConnectivityProvider>().isOnline) {
      SnackbarUtils.showError(
        context,
        'Voice mode needs a network connection for transcription.',
      );
      return;
    }

    if (_isRecording) {
      setState(() {
        _isRecording = false;
        _isProcessing = true;
        _caption = 'Transcribing your voice...';
      });

      final audioBytes = await _audioRecorderService.stopRecording();
      if (audioBytes == null) {
        if (mounted) {
          setState(() {
            _isProcessing = false;
            _caption = 'We could not capture that. Try again.';
          });
        }
        return;
      }

      try {
        final transcript = await _transcriptionService.transcribeAudio(
          audioBytes,
        );
        if (!mounted) return;
        setState(() {
          _isProcessing = false;
          _transcript = transcript;
          _caption = 'Tap use text to continue editing.';
        });
      } catch (error) {
        if (!mounted) return;
        setState(() {
          _isProcessing = false;
          _caption = 'Something went wrong. Try again.';
        });
        SnackbarUtils.showError(
          context,
          error.toString().replaceFirst('Exception: ', ''),
        );
      }
      return;
    }

    final hasPermission = await _audioRecorderService.initialize();
    if (!hasPermission) {
      if (!mounted) return;
      SnackbarUtils.showError(
        context,
        'Microphone access is required before voice capture can start.',
      );
      return;
    }

    final path = await _audioRecorderService.startRecording();
    if (path == null) {
      if (!mounted) return;
      SnackbarUtils.showError(context, 'Failed to start recording.');
      return;
    }

    setState(() {
      _isRecording = true;
      _caption = 'Listening... speak naturally.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Column(
            children: [
              PageHeader(
                title: 'Voice assessment',
                onBack: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: AppConstants.spacing32),
              Text(
                _caption,
                textAlign: TextAlign.center,
                style: AppTextStyles.subtitle.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppConstants.spacing20),
              Expanded(
                child: Center(
                  child: AnimatedBuilder(
                    animation: _orbController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 0.94 + (_orbController.value * 0.08),
                        child: Container(
                          width: 270,
                          height: 270,
                          decoration: BoxDecoration(
                            gradient: AppColors.voiceGradient,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryLight.withValues(
                                  alpha: 0.28 + (_orbController.value * 0.14),
                                ),
                                blurRadius: 40,
                                spreadRadius: 12,
                              ),
                            ],
                          ),
                          child: Container(
                            margin: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withValues(alpha: 0.22),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Text(
                _transcript.isEmpty
                    ? 'Your transcript will appear here.'
                    : _transcript,
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.86),
                ),
              ),
              const SizedBox(height: AppConstants.spacing24),
              Row(
                children: [
                  _RoundControl(
                    icon: Icons.keyboard_alt_outlined,
                    onTap: _transcript.isEmpty
                        ? null
                        : () => Navigator.of(context).pop(_transcript),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _isProcessing ? null : _toggleRecording,
                    child: Container(
                      width: 86,
                      height: 86,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primaryLight.withValues(alpha: 0.25),
                          width: 6,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: _isProcessing
                          ? const SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              _isRecording
                                  ? Icons.stop_rounded
                                  : Icons.mic_rounded,
                              size: 34,
                              color: Colors.white,
                            ),
                    ),
                  ),
                  const Spacer(),
                  _RoundControl(
                    icon: Icons.close_rounded,
                    onTap: () => Navigator.of(context).pop(),
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

class _RoundControl extends StatelessWidget {
  const _RoundControl({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          shape: BoxShape.circle,
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          color: enabled
              ? Theme.of(context).colorScheme.onSurface
              : Theme.of(context).hintColor,
        ),
      ),
    );
  }
}
