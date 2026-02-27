import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/config/api_config.dart';

class ClaudeService {
  /// Enhance a rough prompt using Claude API via Node backend
  ///
  /// [roughPrompt] - The user's rough/casual prompt text
  /// [category] - The category for context (e.g., 'General', 'Coding', 'Image Generation')
  ///
  /// Returns a map with 'success' and either 'enhancedPrompt' or 'error'
  Future<Map<String, dynamic>> enhancePrompt({
    required String roughPrompt,
    required String category,
  }) async {
    try {
      final uri = Uri.parse(ApiConfig.enhanceEndpoint);

      debugPrint('Sending enhancement request to $uri');
      debugPrint('Category: $category, Prompt length: ${roughPrompt.length}');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'prompt': roughPrompt,
          'category': category,
        }),
      );

      debugPrint('Enhancement response status: ${response.statusCode}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'enhancedPrompt': data['enhancedPrompt'],
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Something went wrong. Please try again.',
        };
      }
    } on http.ClientException catch (e) {
      debugPrint('Network error during enhancement: $e');
      return {
        'success': false,
        'error': 'Network error. Please check your connection.',
      };
    } catch (e) {
      debugPrint('Enhancement error: $e');
      return {
        'success': false,
        'error': 'Something went wrong. Please try again.',
      };
    }
  }
}
