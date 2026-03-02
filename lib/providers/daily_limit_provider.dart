import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DailyLimitProvider extends ChangeNotifier {
  static const int _defaultDailyLimit = 5;
  static const String _usedKey = 'daily_prompts_used';
  static const String _dateKey = 'daily_prompts_date';

  int _dailyPromptsUsed = 0;
  int _dailyLimit = _defaultDailyLimit;
  String _lastResetDate = '';
  bool _isLoading = false;

  int get dailyPromptsUsed => _dailyPromptsUsed;
  int get dailyLimit => _dailyLimit;
  int get remainingPrompts => _dailyLimit - _dailyPromptsUsed;
  bool get hasReachedLimit => _dailyPromptsUsed >= _dailyLimit;
  bool get isLoading => _isLoading;

  Future<void> loadCount() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final today = _getTodayString();

    _lastResetDate = prefs.getString(_dateKey) ?? '';
    _dailyPromptsUsed = prefs.getInt(_usedKey) ?? 0;

    // Reset if it's a new day
    if (_lastResetDate != today) {
      await reset();
    }

    _isLoading = false;
    notifyListeners();
  }

  // Alias for loadCount
  Future<void> loadDailyUsage() async {
    await loadCount();
  }

  Future<void> increment() async {
    _dailyPromptsUsed++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_usedKey, _dailyPromptsUsed);
    notifyListeners();
  }

  // Alias for increment
  Future<void> incrementUsage() async {
    await increment();
  }

  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _getTodayString();

    _dailyPromptsUsed = 0;
    _lastResetDate = today;

    await prefs.setInt(_usedKey, 0);
    await prefs.setString(_dateKey, today);
    notifyListeners();
  }

  String _getTodayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }
}
