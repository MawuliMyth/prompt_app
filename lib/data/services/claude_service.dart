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
  /// [tone] - The tone style (e.g., 'Auto', 'Professional', 'Creative')
  /// [persona] - User's persona/context for personalized prompts
  ///
  /// Returns a map with 'success' and either 'enhancedPrompt' or 'error'
  Future<Map<String, dynamic>> enhancePrompt({
    required String roughPrompt,
    required String category,
    bool isAuthenticated = false,
    String tone = 'Auto',
    String? persona,
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
      debugPrint('Category: $category, Prompt length: ${roughPrompt.length}, isPremium: $isPremium, tone: $tone');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'prompt': roughPrompt,
          'category': category,
          'isPremium': isPremium,
          'tone': tone,
          'persona': persona,
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

  /// Generate 3 variations of a prompt (Formal, Creative, Concise)
  ///
  /// [roughPrompt] - The user's rough/casual prompt text
  /// [category] - The category for context
  /// [isAuthenticated] - Whether the user is logged in
  ///
  /// Returns a map with 'success' and either 'variations' (List<String>) or 'error'
  Future<Map<String, dynamic>> generateVariations({
    required String roughPrompt,
    required String category,
    bool isAuthenticated = false,
  }) async {
    try {
      final uri = Uri.parse(ApiConfig.variationsEndpoint);

      // Check premium status - only for authenticated users
      bool isPremium = false;
      if (isAuthenticated) {
        isPremium = await _premiumService.checkIsPremium();
      }

      debugPrint('Sending variations request to $uri');
      debugPrint('Category: $category, isPremium: $isPremium');

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

      debugPrint('Variations response status: ${response.statusCode}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'variations': List<String>.from(data['variations']),
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Failed to generate variations.',
        };
      }
    } on http.ClientException catch (e) {
      debugPrint('Network error during variations: $e');
      return {
        'success': false,
        'error': 'Network error. Please check your connection.',
      };
    } catch (e) {
      debugPrint('Variations error: $e');
      return {
        'success': false,
        'error': 'Something went wrong. Please try again.',
      };
    }
  }
}
