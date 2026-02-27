import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;

/// API configuration for the Node.js backend
///
/// URLs are configurable via environment variables:
/// - Development: Uses platform-specific localhost (10.0.2.2 for Android emulator)
/// - Production: Set via --dart-define=API_URL=https://your-api.com
class ApiConfig {
  ApiConfig._();

  /// Default production URL (Render backend)
  static const String _defaultProductionUrl = 'https://prompt-app-05kv.onrender.com';

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
  /// Uses --dart-define URL if set, otherwise production URL for release builds,
  /// or localhost for debug builds
  static String get baseUrl {
    if (_productionUrl?.isNotEmpty == true) return _productionUrl!;
    if (kReleaseMode) return _defaultProductionUrl;
    return localhostUrl;
  }

  /// Full API endpoint path
  static String get apiEndpoint => '$baseUrl/api';

  /// Transcription endpoint
  static String get transcribeEndpoint => '$apiEndpoint/transcribe';

  /// Prompt enhancement endpoint
  static String get enhanceEndpoint => '$apiEndpoint/enhance';

  /// Health check endpoint
  static String get healthEndpoint => '$baseUrl/health';

  /// Check if running in production mode
  static bool get isProduction =>
      _productionUrl?.isNotEmpty == true || kReleaseMode;
}
