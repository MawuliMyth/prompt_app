import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/config/api_config.dart';
import '../models/app_config_model.dart';

class AppConfigService {
  Future<AppConfigModel> loadConfig() async {
    final uri = Uri.parse(ApiConfig.appConfigEndpoint);

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final config = data['config'];
        if (data['success'] == true && config is Map<String, dynamic>) {
          return AppConfigModel.fromJson(config);
        }
      }
    } catch (error) {
      debugPrint('App config fetch failed, using bootstrap config: $error');
    }

    return AppConfigModel.bootstrap();
  }
}
