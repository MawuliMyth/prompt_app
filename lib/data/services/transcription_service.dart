import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/config/api_config.dart';

/// Service for transcribing audio via the Node.js backend
///
/// Uploads audio files to the backend which uses Groq Whisper API
class TranscriptionService {
  /// Transcribe audio bytes to text
  ///
  /// [audioBytes] - The raw audio bytes (M4A/AAC format recommended for Android)
  /// [filename] - Optional filename (defaults to 'audio.m4a')
  ///
  /// Returns the transcribed text, or throws an exception on error
  Future<String> transcribeAudio(
    Uint8List audioBytes, {
    String filename = 'audio.m4a',
  }) async {
    try {
      final uri = Uri.parse(ApiConfig.transcribeEndpoint);

      // Create multipart request
      final request = http.MultipartRequest('POST', uri)
        ..files.add(
          http.MultipartFile.fromBytes(
            'audio',
            audioBytes,
            filename: filename,
          ),
        );

      debugPrint('Sending transcription request to ${ApiConfig.transcribeEndpoint}');
      debugPrint('Audio size: ${audioBytes.length} bytes');

      // Send request
      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();

      debugPrint('Transcription response status: ${streamedResponse.statusCode}');

      if (streamedResponse.statusCode != 200) {
        final errorData = jsonDecode(responseBody);
        throw Exception(errorData['error'] ?? 'Transcription failed');
      }

      final data = jsonDecode(responseBody);

      if (data['success'] == true) {
        final text = data['text'] as String;
        debugPrint('Transcription successful: "${text.substring(0, text.length > 100 ? 100 : text.length)}..."');
        return text;
      } else {
        throw Exception(data['error'] ?? 'Transcription failed');
      }
    } on http.ClientException catch (e) {
      debugPrint('Network error during transcription: $e');
      throw Exception('Network error. Please check your connection.');
    } catch (e) {
      debugPrint('Transcription error: $e');
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to transcribe audio: $e');
    }
  }

  /// Check if the backend is healthy
  Future<bool> checkHealth() async {
    try {
      final response = await http
          .get(Uri.parse(ApiConfig.healthEndpoint))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == 'ok';
      }
      return false;
    } catch (e) {
      debugPrint('Health check failed: $e');
      return false;
    }
  }
}
