import 'package:flutter/material.dart';
import '../data/models/app_config_model.dart';
import '../data/services/app_config_service.dart';

class AppConfigProvider extends ChangeNotifier {
  final AppConfigService _service = AppConfigService();

  AppConfigModel _config = AppConfigModel.bootstrap();
  bool _isLoading = false;
  String? _error;

  AppConfigModel get config => _config;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<CategoryConfig> get categories =>
      _config.categories.where((item) => item.enabled).toList();
  List<ToneConfig> get tones => _config.tones;
  List<TemplateCategoryConfig> get templateCategories =>
      _config.templateCategories;
  List<TemplateConfig> get templates =>
      _config.templates.where((item) => item.enabled).toList();
  List<TemplateConfig> get quickTemplates =>
      templates.where((item) => item.isQuick).toList();
  List<HomeFeatureConfig> get homeFeatures => _config.homeFeatures;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _config = await _service.loadConfig();
    } catch (error) {
      _error = 'Failed to load app content.';
    }

    _isLoading = false;
    notifyListeners();
  }
}
