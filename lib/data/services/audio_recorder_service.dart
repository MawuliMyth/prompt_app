import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service for recording audio using flutter_sound
///
/// Records audio in WebM/Opus format which is compatible with Groq Whisper API
class AudioRecorderService {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isInitialized = false;
  String? _currentRecordingPath;

  /// Check if currently recording
  bool get isRecording => _recorder.isRecording;

  /// Initialize the recorder
  /// Returns true if initialization was successful
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Request microphone permission
      final micPermission = await Permission.microphone.request();
      if (!micPermission.isGranted) {
        debugPrint('Microphone permission denied');
        return false;
      }

      // Open the recorder
      await _recorder.openRecorder();
      _isInitialized = true;
      debugPrint('AudioRecorderService initialized successfully');
      return true;
    } catch (e) {
      debugPrint('Failed to initialize AudioRecorderService: $e');
      return false;
    }
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
      // Get temporary directory for recording
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordingPath = '${directory.path}/recording_$timestamp.m4a';

      debugPrint('Starting recording to: $_currentRecordingPath');

      // Start recording in MP4/AAC format (supported by Groq Whisper API as m4a)
      await _recorder.startRecorder(
        toFile: _currentRecordingPath,
        codec: Codec.aacMP4,
        numChannels: 1,
        sampleRate: 44100,
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

      if (path == null || _currentRecordingPath == null) {
        return null;
      }

      // Read the file as bytes
      final file = File(_currentRecordingPath!);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        debugPrint('Read ${bytes.length} bytes from recording');

        // Clean up the temporary file
        try {
          await file.delete();
        } catch (_) {
          // Ignore cleanup errors
        }

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

    // Clean up temporary file
    if (_currentRecordingPath != null) {
      try {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {
        // Ignore cleanup errors
      }
    }

    _currentRecordingPath = null;
  }

  /// Dispose of resources
  Future<void> dispose() async {
    await _recorder.closeRecorder();
    _isInitialized = false;
  }
}
