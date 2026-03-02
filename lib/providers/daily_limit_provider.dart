import 'package:flutter/material.dart';
import '../data/services/daily_limit_service.dart';

class DailyLimitProvider extends ChangeNotifier {
  final DailyLimitService _dailyLimitService = DailyLimitService();

  int _dailyPromptsUsed = 0;
  int _remainingPrompts = DailyLimitService.freeDailyLimit;
  bool _hasReachedLimit = false;
  bool _isLoading = false;
  String? _error;

  // Getters
  int get dailyPromptsUsed => _dailyPromptsUsed;
  int get remainingPrompts => _remainingPrompts;
  bool get hasReachedLimit => _hasReachedLimit;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get dailyLimit => DailyLimitService.freeDailyLimit;

  /// Load daily usage data (resets if new day)
  Future<void> loadDailyUsage() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _dailyLimitService.loadDailyUsageData();
      _dailyPromptsUsed = data['used'] as int;
      _remainingPrompts = data['remaining'] as int;
      _hasReachedLimit = data['hasReachedLimit'] as bool;
    } catch (e) {
      debugPrint('Error loading daily usage: $e');
      _error = 'Failed to load usage data';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Increment usage after a prompt is enhanced
  Future<bool> incrementUsage() async {
    if (_hasReachedLimit) return false;

    final success = await _dailyLimitService.incrementDailyUsage();
    if (success) {
      _dailyPromptsUsed++;
      _remainingPrompts--;
      if (_remainingPrompts <= 0) {
        _remainingPrompts = 0;
        _hasReachedLimit = true;
      }
      notifyListeners();
    }
    return success;
  }

  /// Reset the daily counter
  Future<void> reset() async {
    _dailyPromptsUsed = 0;
    _remainingPrompts = DailyLimitService.freeDailyLimit;
    _hasReachedLimit = false;
    notifyListeners();
  }

  /// Clear any error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
