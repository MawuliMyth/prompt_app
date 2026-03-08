import 'package:flutter/foundation.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

// Conditional import for platform-specific file operations
import 'audio_recorder_io.dart'
    if (dart.library.html) 'audio_recorder_web.dart';

enum RecorderPermissionState { granted, denied, permanentlyDenied, unsupported }

/// Service for recording audio using flutter_sound
///
/// Records audio in MP4/AAC format which is compatible with Groq Whisper API
class AudioRecorderService {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final StreamController<double> _levelController =
      StreamController<double>.broadcast();
  bool _isInitialized = false;
  String? _currentRecordingPath;
  RecorderPermissionState _lastPermissionState = RecorderPermissionState.denied;
  StreamSubscription<RecordingDisposition>? _progressSubscription;
  double _currentLevel = 0;

  /// Check if currently recording
  bool get isRecording => _recorder.isRecording;

  /// Check if recording is supported on current platform
  bool get isSupported => !kIsWeb;

  RecorderPermissionState get lastPermissionState => _lastPermissionState;
  Stream<double> get levelStream => _levelController.stream;
  double get currentLevel => _currentLevel;

  /// Initialize the recorder
  /// Returns true if initialization was successful
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    // Web platform doesn't support flutter_sound recorder
    if (kIsWeb) {
      debugPrint('Audio recording is not supported on web platform');
      _lastPermissionState = RecorderPermissionState.unsupported;
      return false;
    }

    try {
      final permissionState = await _requestMicrophonePermission();
      _lastPermissionState = permissionState;

      if (permissionState != RecorderPermissionState.granted) {
        debugPrint('Microphone permission not granted: $permissionState');
        return false;
      }

      // Open the recorder
      await _recorder.openRecorder();
      await _recorder.setSubscriptionDuration(
        const Duration(milliseconds: 80),
      );
      _progressSubscription?.cancel();
      _progressSubscription = _recorder.onProgress?.listen((event) {
        final decibels = event.decibels ?? 0;
        final normalized = (decibels / 120).clamp(0.0, 1.0);
        _currentLevel = normalized;
        if (!_levelController.isClosed) {
          _levelController.add(normalized);
        }
      });
      _isInitialized = true;
      debugPrint('AudioRecorderService initialized successfully');
      return true;
    } catch (e) {
      debugPrint('Failed to initialize AudioRecorderService: $e');
      return false;
    }
  }

  Future<RecorderPermissionState> _requestMicrophonePermission() async {
    var status = await Permission.microphone.status;

    if (status.isGranted) {
      return RecorderPermissionState.granted;
    }

    if (status.isPermanentlyDenied || status.isRestricted) {
      return RecorderPermissionState.permanentlyDenied;
    }

    status = await Permission.microphone.request();

    if (status.isGranted) {
      return RecorderPermissionState.granted;
    }

    if (status.isPermanentlyDenied || status.isRestricted) {
      return RecorderPermissionState.permanentlyDenied;
    }

    return RecorderPermissionState.denied;
  }

  /// Start recording audio
  /// Returns the file path where audio is being recorded, or null on failure
  Future<String?> startRecording() async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) return null;
    }

    if (_recorder.isRecording) {
      debugPrint('Already recording');
      return null;
    }

    try {
      // Get temporary directory for recording using platform-specific implementation
      final directory = await getRecordingDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordingPath = '$directory/recording_$timestamp.mp4';

      debugPrint('Starting recording to: $_currentRecordingPath');

      // Start recording in MP4/AAC format (supported by Groq Whisper API as m4a)
      await _recorder.startRecorder(
        toFile: _currentRecordingPath,
        codec: Codec.aacMP4,
        sampleRate: 44100,
        bitRate: 128000,
        audioSource: AudioSource.microphone,
        enableVoiceProcessing: true,
      );

      return _currentRecordingPath;
    } catch (e) {
      debugPrint('Failed to start recording: $e');
      _currentRecordingPath = null;
      return null;
    }
  }

  /// Stop recording and return the audio bytes
  /// Returns null if no recording was in progress or on error
  Future<Uint8List?> stopRecording() async {
    if (!_recorder.isRecording) {
      debugPrint('Not recording');
      return null;
    }

    try {
      final path = await _recorder.stopRecorder();
      debugPrint('Recording stopped, saved to: $path');
      _currentLevel = 0;
      if (!_levelController.isClosed) {
        _levelController.add(0);
      }

      final resolvedPath = path ?? _currentRecordingPath;
      if (resolvedPath == null) {
        return null;
      }

      final fileSize = await waitForRecordingFile(resolvedPath);
      debugPrint('Recording file size: ${fileSize ?? 0} bytes');

      // Read the file as bytes using platform-specific implementation
      final bytes = await readRecordingFile(resolvedPath);
      if (bytes != null) {
        debugPrint('Read ${bytes.length} bytes from recording');

        // Clean up the temporary file
        await deleteRecordingFile(resolvedPath);

        return bytes;
      }

      return null;
    } catch (e) {
      debugPrint('Failed to stop recording: $e');
      return null;
    } finally {
      _currentRecordingPath = null;
    }
  }

  /// Cancel the current recording without returning audio
  Future<void> cancelRecording() async {
    if (_recorder.isRecording) {
      await _recorder.stopRecorder();
    }
    _currentLevel = 0;
    if (!_levelController.isClosed) {
      _levelController.add(0);
    }

    // Clean up temporary file
    if (_currentRecordingPath != null) {
      await deleteRecordingFile(_currentRecordingPath!);
    }

    _currentRecordingPath = null;
  }

  /// Dispose of resources
  Future<void> dispose() async {
    await _progressSubscription?.cancel();
    if (!_levelController.isClosed) {
      await _levelController.close();
    }
    await _recorder.closeRecorder();
    _isInitialized = false;
  }
}
