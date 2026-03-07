import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../core/widgets/shimmer_loading.dart';
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
  static const Duration _minimumRecordingDuration = Duration(seconds: 1);

  bool _isRecording = false;
  bool _isProcessing = false;
  bool _isTransitioningRecorder = false;
  String _caption = 'Go ahead, I\'m listening...';
  String _transcript = '';
  DateTime? _recordingStartedAt;

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
    if (_isTransitioningRecorder) return;

    if (!context.read<ConnectivityProvider>().isOnline) {
      SnackbarUtils.showError(
        context,
        'Voice mode needs a network connection for transcription.',
      );
      return;
    }

    if (_isRecording) {
      _isTransitioningRecorder = true;
      setState(() {
        _isRecording = false;
        _isProcessing = true;
        _caption = 'Transcribing your voice...';
      });

      final audioBytes = await _audioRecorderService.stopRecording();
      final startedAt = _recordingStartedAt;
      _recordingStartedAt = null;
      _isTransitioningRecorder = false;

      if (startedAt != null &&
          DateTime.now().difference(startedAt) < _minimumRecordingDuration) {
        if (!mounted) return;
        setState(() {
          _isProcessing = false;
          _caption = 'Hold the mic a little longer, then try again.';
        });
        SnackbarUtils.showError(
          context,
          'Recording was too short. Hold the mic for a moment before stopping.',
        );
        return;
      }

      if (audioBytes == null) {
        if (mounted) {
          setState(() {
            _isProcessing = false;
            _caption = 'We could not capture that. Try again.';
          });
        }
        return;
      }

      if (audioBytes.length < 1024) {
        if (!mounted) return;
        setState(() {
          _isProcessing = false;
          _caption = 'We could not capture enough audio. Try again.';
        });
        SnackbarUtils.showError(
          context,
          'The recording was too short or invalid. Try speaking for a bit longer.',
        );
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

    _isTransitioningRecorder = true;
    final hasPermission = await _audioRecorderService.initialize();
    if (!hasPermission) {
      _isTransitioningRecorder = false;
      if (!mounted) return;
      await _handlePermissionFailure();
      return;
    }

    final path = await _audioRecorderService.startRecording();
    _isTransitioningRecorder = false;
    if (path == null) {
      if (!mounted) return;
      SnackbarUtils.showError(context, 'Failed to start recording.');
      return;
    }

    setState(() {
      _isRecording = true;
      _caption = 'Listening... speak naturally.';
    });
    _recordingStartedAt = DateTime.now();
  }

  Future<void> _handlePermissionFailure() async {
    final permissionState = _audioRecorderService.lastPermissionState;
    if (permissionState == RecorderPermissionState.permanentlyDenied) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Microphone access needed'),
          content: const Text(
            'Prompt needs microphone access to capture your voice. Open Settings and allow microphone access for the app.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Not now'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
      return;
    }

    SnackbarUtils.showError(
      context,
      'Microphone access is required before voice capture can start.',
    );
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
                    onTap: () => Navigator.of(context).pop(_transcript),
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
                          ? const ShimmerPulse(
                              width: 34,
                              height: 34,
                              baseColor: Color(0x66FFFFFF),
                              highlightColor: Color(0xAAFFFFFF),
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
