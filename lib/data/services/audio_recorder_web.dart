/// Stub implementation for web platform
/// Audio recording is not supported on web in this implementation
import 'dart:typed_data';

/// Get the directory for saving recordings (not supported on web)
Future<String> getRecordingDirectory() async {
  throw UnsupportedError('Audio recording is not supported on web platform');
}

/// Read a recording file and return its bytes (not supported on web)
Future<Uint8List?> readRecordingFile(String path) async {
  throw UnsupportedError('Audio recording is not supported on web platform');
}

/// Delete a recording file (not supported on web)
Future<void> deleteRecordingFile(String path) async {
  // No-op on web
}
