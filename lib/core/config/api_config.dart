import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  ApiConfig._();

  static const String _defaultProductionUrl =
      'https://prompt-app-05kv.onrender.com';
  static const String _productionUrl = String.fromEnvironment('API_URL');
  static const bool _useLocalApi = bool.fromEnvironment('USE_LOCAL_API');

  static String get localhostUrl {
    if (kIsWeb) return 'http://localhost:3001';
    if (Platform.isAndroid) return 'http://10.0.2.2:3001';
    return 'http://localhost:3001';
  }

  static String get baseUrl {
    if (_productionUrl.isNotEmpty) return _productionUrl;
    if (_useLocalApi) return localhostUrl;
    return _defaultProductionUrl;
  }

  static String get apiEndpoint => '$baseUrl/api';
  static String get transcribeEndpoint => '$apiEndpoint/transcribe';
  static String get enhanceEndpoint => '$apiEndpoint/enhance';
  static String get variationsEndpoint => '$apiEndpoint/variations';
  static String get activateTrialEndpoint => '$apiEndpoint/trial/activate';
  static String get deleteAccountEndpoint => '$apiEndpoint/account';
  static String get appConfigEndpoint => '$apiEndpoint/app-config';
  static String get healthEndpoint => '$baseUrl/health';
}
