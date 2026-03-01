import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/config/api_config.dart';
import 'premium_service.dart';

class ClaudeService {
  final PremiumService _premiumService = PremiumService();

  /// Enhance a rough prompt using Claude API via Node backend
  ///
  /// [roughPrompt] - The user's rough/casual prompt text
  /// [category] - The category for context (e.g., 'General', 'Coding', 'Image Generation')
  /// [isAuthenticated] - Whether the user is logged in (if false, always uses free model)
  ///
  /// Returns a map with 'success' and either 'enhancedPrompt' or 'error'
  Future<Map<String, dynamic>> enhancePrompt({
    required String roughPrompt,
    required String category,
    bool isAuthenticated = false,
  }) async {
    try {
      final uri = Uri.parse(ApiConfig.enhanceEndpoint);

      // Check premium status - only for authenticated users
      bool isPremium = false;
      if (isAuthenticated) {
        isPremium = await _premiumService.checkIsPremium();
        debugPrint('User is authenticated. Premium status: $isPremium');
      } else {
        debugPrint('User is guest - using free model');
      }

      debugPrint('Sending enhancement request to $uri');
      debugPrint('Category: $category, Prompt length: ${roughPrompt.length}, isPremium: $isPremium');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'prompt': roughPrompt,
          'category': category,
          'isPremium': isPremium,
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
