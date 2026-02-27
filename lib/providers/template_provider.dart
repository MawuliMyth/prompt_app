import 'package:flutter/material.dart';

class TemplateProvider extends ChangeNotifier {
  String? _selectedTemplateContent;
  String? _selectedCategory;

  String? get selectedTemplateContent => _selectedTemplateContent;
  String? get selectedCategory => _selectedCategory;

  bool get hasTemplate => _selectedTemplateContent != null;

  void setTemplate(String content, String category) {
    _selectedTemplateContent = content;
    _selectedCategory = category;
    notifyListeners();
  }

  void clearTemplate() {
    _selectedTemplateContent = null;
    _selectedCategory = null;
    notifyListeners();
  }
}
