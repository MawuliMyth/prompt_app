/// Platform-specific file operations for IO platforms (Android, iOS, macOS, Windows, Linux)
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

/// Get the directory for saving recordings
Future<String> getRecordingDirectory() async {
  final directory = await getTemporaryDirectory();
  return directory.path;
}

/// Read a recording file and return its bytes
Future<Uint8List?> readRecordingFile(String path) async {
  try {
    final file = File(path);
    if (await file.exists()) {
      return await file.readAsBytes();
    }
    return null;
  } catch (e) {
    return null;
  }
}

/// Delete a recording file
Future<void> deleteRecordingFile(String path) async {
  try {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  } catch (_) {
    // Ignore cleanup errors
  }
}
