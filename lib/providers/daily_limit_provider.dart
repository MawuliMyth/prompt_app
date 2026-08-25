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
  bool get canUsePrompt => !_hasReachedLimit;
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
      if (data['hadError'] == true) {
        _error = 'Could not confirm your remaining prompts. Please check your connection.';
      }
    } catch (e) {
      debugPrint('Error loading daily usage: $e');
      // Fail closed: an unexpected error here must not leave the UI showing
      // a fresh/unused quota.
      _dailyPromptsUsed = DailyLimitService.freeDailyLimit;
      _remainingPrompts = 0;
      _hasReachedLimit = true;
      _error = 'Failed to load usage data';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Increment usage after a prompt is enhanced.
  ///
  /// This persists the increment to Firestore via [DailyLimitService] - the
  /// backend has already atomically incremented the authoritative counter
  /// as part of the successful /api/enhance call, so this is keeping the
  /// client's local mirror in sync for the UI. If persistence fails we
  /// still reflect the usage locally (the prompt WAS already consumed
  /// server-side), but we surface an error so the user knows their visible
  /// count may be stale until it syncs.
  Future<bool> incrementUsage() async {
    if (_hasReachedLimit) return false;

    final persisted = await _dailyLimitService.incrementDailyUsage();
    if (!persisted) {
      _error = 'Could not sync your prompt usage. Your remaining count may be out of date.';
    }

    _dailyPromptsUsed++;
    _remainingPrompts--;
    if (_remainingPrompts <= 0) {
      _remainingPrompts = 0;
      _hasReachedLimit = true;
    }
    notifyListeners();
    return true;
  }

  Future<void> consumePromptUse() async {
    if (!_hasReachedLimit) {
      await incrementUsage();
    }
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
