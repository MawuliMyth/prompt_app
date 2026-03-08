import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/platform_utils.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../core/widgets/adaptive_widgets.dart';
import '../../core/widgets/shimmer_loading.dart';
import '../../data/services/audio_recorder_service.dart';
import '../../data/services/transcription_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/connectivity_provider.dart';
import '../../providers/premium_provider.dart';
import '../auth/login_screen.dart';

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
  static const Duration _freeRecordingLimit = Duration(minutes: 3);

  bool _isRecording = false;
  bool _isProcessing = false;
  bool _isTransitioningRecorder = false;
  bool _showRetryAction = false;
  bool _canRetryTranscription = false;
  String _caption = 'Go ahead, I\'m listening...';
  String _transcript = '';
  double _audioLevel = 0;
  DateTime? _recordingStartedAt;
  StreamSubscription<double>? _levelSubscription;
  Uint8List? _lastRecordedAudio;
  Timer? _recordingLimitTimer;

  @override
  void initState() {
    super.initState();
    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _levelSubscription = _audioRecorderService.levelStream.listen((level) {
      if (!mounted) return;
      setState(() {
        _audioLevel = level;
      });
    });
  }

  @override
  void dispose() {
    _recordingLimitTimer?.cancel();
    _levelSubscription?.cancel();
    _audioRecorderService.dispose().ignore();
    _orbController.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    if (_isTransitioningRecorder) return;

    final authProvider = context.read<AuthProvider>();
    final premiumProvider = context.read<PremiumProvider>();

    if (!authProvider.isAuthenticated) {
      await _showGuestVoiceLock();
      return;
    }

    if (!context.read<ConnectivityProvider>().isOnline) {
      SnackbarUtils.showError(
        context,
        'Voice mode needs a network connection for transcription.',
      );
      return;
    }

    if (_isRecording) {
      _recordingLimitTimer?.cancel();
      _isTransitioningRecorder = true;
      setState(() {
        _isRecording = false;
        _isProcessing = true;
        _showRetryAction = false;
        _canRetryTranscription = false;
        _caption = 'Transcribing your voice...';
        _audioLevel = 0;
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
          _showRetryAction = true;
          _canRetryTranscription = false;
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
            _showRetryAction = true;
            _canRetryTranscription = false;
            _caption = 'We could not capture that. Try again.';
          });
        }
        return;
      }

      if (audioBytes.length < 1024) {
        if (!mounted) return;
        setState(() {
          _isProcessing = false;
          _showRetryAction = true;
          _canRetryTranscription = false;
          _caption = 'We could not capture enough audio. Try again.';
        });
        SnackbarUtils.showError(
          context,
          'The recording was too short or invalid. Try speaking for a bit longer.',
        );
        return;
      }

      _lastRecordedAudio = audioBytes;

      try {
        final transcript = await _transcribeRecordedAudio(audioBytes);
        if (!mounted) return;
        setState(() {
          _isProcessing = false;
          _transcript = transcript;
          _showRetryAction = false;
          _canRetryTranscription = false;
          _caption = 'Transcript ready. Opening editor...';
        });
        Navigator.of(context).pop(transcript);
      } catch (error) {
        if (!mounted) return;
        setState(() {
          _isProcessing = false;
          _showRetryAction = true;
          _canRetryTranscription = true;
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
      _showRetryAction = false;
      _canRetryTranscription = false;
      _caption = 'Listening... speak naturally.';
    });
    _recordingStartedAt = DateTime.now();

    if (!premiumProvider.hasPremiumAccess) {
      _recordingLimitTimer?.cancel();
      _recordingLimitTimer = Timer(_freeRecordingLimit, _handleRecordingLimitHit);
    }
  }

  Future<void> _showGuestVoiceLock() async {
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
  }

  Future<void> _handleRecordingLimitHit() async {
    if (!mounted || !_isRecording || _isTransitioningRecorder) return;

    setState(() {
      _caption = 'Free recording limit reached. Finishing transcription...';
    });
    SnackbarUtils.showError(
      context,
      'Free voice recordings are limited to 3 minutes per take.',
    );
    await _toggleRecording();
  }

  Future<String> _transcribeRecordedAudio(Uint8List audioBytes) {
    return _transcriptionService.transcribeAudio(audioBytes);
  }

  Future<void> _retryLastTranscription() async {
    final audioBytes = _lastRecordedAudio;
    if (audioBytes == null || _isProcessing) return;

    setState(() {
      _isProcessing = true;
      _showRetryAction = false;
      _caption = 'Retrying transcription...';
    });

    try {
      final transcript = await _transcribeRecordedAudio(audioBytes);
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _transcript = transcript;
        _canRetryTranscription = false;
        _caption = 'Transcript ready. Opening editor...';
      });
      Navigator.of(context).pop(transcript);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _showRetryAction = true;
        _canRetryTranscription = true;
        _caption = 'Still having trouble sending that recording.';
      });
      SnackbarUtils.showError(
        context,
        error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> _handlePermissionFailure() async {
    final permissionState = _audioRecorderService.lastPermissionState;
    if (permissionState == RecorderPermissionState.permanentlyDenied) {
      final shouldOpenSettings = await AdaptiveDialog.show(
        context: context,
        title: 'Microphone access needed',
        content:
            'Prompt needs microphone access to capture your voice. Open Settings and allow microphone access for the app.',
        cancelText: 'Not now',
        confirmText: 'Open Settings',
      );
      if (shouldOpenSettings == true) {
        await openAppSettings();
      }
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
    final isCupertino = PlatformUtils.useCupertino(context);
    final authProvider = context.watch<AuthProvider>();
    final premiumProvider = context.watch<PremiumProvider>();
    final hasVoiceAccess = authProvider.isAuthenticated;
    final isUnlimitedRecording = premiumProvider.hasPremiumAccess;

    return AdaptiveScaffold(
      appBar: const AdaptiveAppBar(
        title: 'Voice assessment',
        backgroundColor: Colors.transparent,
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            children: [
              Text(
                hasVoiceAccess
                    ? isUnlimitedRecording
                        ? 'Speak naturally and we will turn it into a prompt draft.'
                        : 'Speak naturally and we will turn it into a prompt draft. Free recordings are limited to 3 minutes.'
                    : 'Voice recording is locked in guest mode. Sign in to use it.',
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(color: theme.hintColor),
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
                      final pulse = _orbController.value;
                      final liveLevel = _isRecording
                          ? (_audioLevel * 0.85) + (pulse * 0.15)
                          : pulse * 0.18;
                      return SizedBox(
                        width: 290,
                        height: 290,
                        child: CustomPaint(
                          painter: _VoiceOrbPainter(
                            animationValue: pulse,
                            audioLevel: liveLevel,
                            glowColor: AppColors.primaryLight,
                          ),
                          child: Center(
                            child: Container(
                              width: 116,
                              height: 116,
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryLight.withValues(
                                      alpha: 0.22 + (liveLevel * 0.22),
                                    ),
                                    blurRadius: 26,
                                    spreadRadius: 2 + (liveLevel * 8),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                               child: Icon(
                                 hasVoiceAccess
                                     ? (_isRecording
                                           ? Icons.graphic_eq_rounded
                                           : Icons.mic_rounded)
                                     : Icons.lock_rounded,
                                 size: 42,
                                 color: Colors.white,
                               ),
                             ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Text(
                !hasVoiceAccess
                    ? 'Type your prompt instead, or sign in to unlock voice capture.'
                    : _transcript.isEmpty
                    ? 'Your transcript will appear here.'
                    : _transcript,
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.86),
                ),
              ),
              if (!hasVoiceAccess) ...[
                const SizedBox(height: AppConstants.spacing16),
                SizedBox(
                  width: double.infinity,
                  child: AdaptiveButton(
                    label: 'Sign In to Use Voice',
                    icon: Icons.lock_open_rounded,
                    onPressed: () {
                      _showGuestVoiceLock();
                    },
                  ),
                ),
              ],
              if (_showRetryAction) ...[
                const SizedBox(height: AppConstants.spacing16),
                SizedBox(
                  width: double.infinity,
                  child: AdaptiveButton(
                    label: _canRetryTranscription
                        ? 'Retry sending this recording'
                        : 'Try recording again',
                    icon: _canRetryTranscription
                        ? Icons.cloud_upload_rounded
                        : Icons.refresh_rounded,
                    filled: false,
                    foregroundColor: AppColors.primaryLight,
                    backgroundColor: theme.colorScheme.surface,
                    onPressed: _isProcessing
                        ? null
                        : _canRetryTranscription
                            ? _retryLastTranscription
                            : _toggleRecording,
                  ),
                ),
              ],
              const SizedBox(height: AppConstants.spacing24),
              Row(
                children: [
                  _RoundControl(
                    icon: isCupertino
                        ? CupertinoIcons.keyboard
                        : Icons.keyboard_alt_outlined,
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
                               hasVoiceAccess
                                   ? (_isRecording
                                         ? Icons.stop_rounded
                                         : Icons.mic_rounded)
                                   : Icons.lock_rounded,
                               size: 34,
                               color: Colors.white,
                             ),
                    ),
                  ),
                  const Spacer(),
                  _RoundControl(
                    icon: isCupertino ? CupertinoIcons.clear : Icons.close_rounded,
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

class _VoiceOrbPainter extends CustomPainter {
  const _VoiceOrbPainter({
    required this.animationValue,
    required this.audioLevel,
    required this.glowColor,
  });

  final double animationValue;
  final double audioLevel;
  final Color glowColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width * 0.31;
    final energy = audioLevel.clamp(0.0, 1.0);
    final wavePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..color = Colors.white.withValues(alpha: 0.18 + (energy * 0.16));

    final blobPaint = Paint()
      ..shader = AppColors.voiceGradient.createShader(
        Rect.fromCircle(center: center, radius: radius * 1.8),
      );

    final glowPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28)
      ..color = glowColor.withValues(alpha: 0.16 + (energy * 0.18));

    final blobPath = Path();
    const points = 72;
    for (var i = 0; i <= points; i++) {
      final theta = (i / points) * math.pi * 2;
      final wobble = math.sin(theta * 3 + (animationValue * math.pi * 2)) * 10;
      final ripple =
          math.sin(theta * 7 - (animationValue * math.pi * 4)) *
          (6 + energy * 22);
      final dynamicRadius = radius + wobble + ripple;
      final point = Offset(
        center.dx + math.cos(theta) * dynamicRadius,
        center.dy + math.sin(theta) * dynamicRadius,
      );

      if (i == 0) {
        blobPath.moveTo(point.dx, point.dy);
      } else {
        blobPath.lineTo(point.dx, point.dy);
      }
    }
    blobPath.close();

    canvas.drawPath(blobPath, glowPaint);
    canvas.drawPath(blobPath, blobPaint);

    for (var index = 0; index < 3; index++) {
      final waveRadius = radius + 36 + (index * 20) + (animationValue * 10);
      final opacity = (0.15 - (index * 0.03)) + (energy * 0.08);
      final ringPaint = wavePaint
        ..color = Colors.white.withValues(alpha: opacity.clamp(0.04, 0.24));
      canvas.drawCircle(center, waveRadius, ringPaint);
    }

    _drawWaveLine(
      canvas,
      size,
      energy: energy,
      verticalOffset: size.height * 0.16,
      reverse: false,
    );
    _drawWaveLine(
      canvas,
      size,
      energy: energy,
      verticalOffset: size.height * 0.84,
      reverse: true,
    );
  }

  void _drawWaveLine(
    Canvas canvas,
    Size size, {
    required double energy,
    required double verticalOffset,
    required bool reverse,
  }) {
    final path = Path();
    final width = size.width * 0.76;
    final startX = (size.width - width) / 2;
    final amplitude = 6 + (energy * 12);
    for (var x = 0.0; x <= width; x += 6) {
      final progress = x / width;
      final direction = reverse ? -1 : 1;
      final wave = math.sin(
        (progress * math.pi * 4 * direction) + (animationValue * math.pi * 2),
      );
      final y = verticalOffset + (wave * amplitude);
      if (x == 0) {
        path.moveTo(startX + x, y);
      } else {
        path.lineTo(startX + x, y);
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 2
        ..color = Colors.white.withValues(alpha: 0.14 + (energy * 0.1)),
    );
  }

  @override
  bool shouldRepaint(covariant _VoiceOrbPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.audioLevel != audioLevel ||
        oldDelegate.glowColor != glowColor;
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
