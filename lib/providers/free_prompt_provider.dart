import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FreePromptProvider extends ChangeNotifier {
  static const int maxFreePrompts = 5;
  static const String _key = 'free_prompts_used';
  int _used = 0;

  int get used => _used;
  int get remaining => maxFreePrompts - _used;
  bool get hasReachedLimit => _used >= maxFreePrompts;

  Future<void> loadCount() async {
    final prefs = await SharedPreferences.getInstance();
    _used = prefs.getInt(_key) ?? 0;
    notifyListeners();
  }

  Future<void> increment() async {
    _used++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, _used);
    notifyListeners();
  }

  Future<void> reset() async {
    _used = 0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, 0);
    notifyListeners();
  }
}
