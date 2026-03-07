import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FreePromptProvider extends ChangeNotifier {
  static const int maxFreePrompts = 5;
  static const String _key = 'free_prompts_used';
  static const String _dateKey = 'free_prompts_date';
  int _used = 0;

  String _todayKey() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }

  Future<void> _resetIfNewDay(SharedPreferences prefs) async {
    final today = _todayKey();
    final storedDate = prefs.getString(_dateKey);
    if (storedDate != today) {
      _used = 0;
      await prefs.setString(_dateKey, today);
      await prefs.setInt(_key, 0);
    }
  }

  int get used => _used;
  int get remaining => maxFreePrompts - _used;
  bool get hasReachedLimit => _used >= maxFreePrompts;

  Future<void> loadCount() async {
    final prefs = await SharedPreferences.getInstance();
    await _resetIfNewDay(prefs);
    _used = prefs.getInt(_key) ?? 0;
    notifyListeners();
  }

  Future<void> increment() async {
    final prefs = await SharedPreferences.getInstance();
    await _resetIfNewDay(prefs);
    _used++;
    await prefs.setInt(_key, _used);
    notifyListeners();
  }

  Future<void> reset() async {
    _used = 0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, 0);
    await prefs.setString(_dateKey, _todayKey());
    notifyListeners();
  }
}
