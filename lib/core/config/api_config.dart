import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// API configuration for the Node.js backend
///
/// URLs are configurable via environment variables:
/// - Development: Uses platform-specific localhost (10.0.2.2 for Android emulator)
/// - Production: Set via --dart-define=API_URL=https://your-api.com
class ApiConfig {
  ApiConfig._();

  /// Production URL from environment variable (set via --dart-define)
  static const String? _productionUrl = String.fromEnvironment('API_URL');

  /// Local development URL - platform aware
  static String get localhostUrl {
    if (kIsWeb) return 'http://localhost:3001';
    if (!kIsWeb && Platform.isAndroid) {
      // Android emulator needs 10.0.2.2 to reach host machine
      return 'http://10.0.2.2:3001';
    }
    return 'http://localhost:3001';
  }

  /// Base URL for API calls
  /// Uses production URL if set, otherwise falls back to localhost
  static String get baseUrl =>
      (_productionUrl?.isNotEmpty == true) ? _productionUrl! : localhostUrl;

  /// Full API endpoint path
  static String get apiEndpoint => '$baseUrl/api';

  /// Transcription endpoint
  static String get transcribeEndpoint => '$apiEndpoint/transcribe';

  /// Prompt enhancement endpoint
  static String get enhanceEndpoint => '$apiEndpoint/enhance';

  /// Health check endpoint
  static String get healthEndpoint => '$baseUrl/health';

  /// Check if running in production mode
  static bool get isProduction => _productionUrl?.isNotEmpty == true;
}
