/// Platform-specific file operations for IO platforms (Android, iOS, macOS, Windows, Linux)
library;
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

/// Wait for a recording file to finish flushing to disk and return its size.
Future<int?> waitForRecordingFile(
  String path, {
  Duration timeout = const Duration(seconds: 2),
}) async {
  try {
    final file = File(path);
    final deadline = DateTime.now().add(timeout);
    int? previousLength;
    int stableReads = 0;

    while (DateTime.now().isBefore(deadline)) {
      if (await file.exists()) {
        final length = await file.length();
        if (length > 0 && previousLength == length) {
          stableReads += 1;
          if (stableReads >= 2) {
            return length;
          }
        } else {
          stableReads = 0;
        }
        previousLength = length;
      }
      await Future<void>.delayed(const Duration(milliseconds: 120));
    }

    if (await file.exists()) {
      return await file.length();
    }
    return null;
  } catch (_) {
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
