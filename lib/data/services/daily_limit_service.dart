import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class DailyLimitService {
  static const int freeDailyLimit = 10;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>>? _userDocRef() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return _firestore.collection('users').doc(user.uid);
  }

  bool _isSameCalendarDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  /// Get current daily usage
  Future<int> getDailyUsage() async {
    final ref = _userDocRef();
    if (ref == null) return 0;

    try {
      final doc = await ref.get();
      if (!doc.exists) return 0;

      final data = doc.data();
      final used = data?['dailyPromptsUsed']?.toInt() ?? 0;
      final resetDate = data?['dailyPromptsResetDate'];
      if (resetDate == null) return 0;

      final lastReset = (resetDate as Timestamp).toDate();
      if (!_isSameCalendarDay(lastReset, DateTime.now())) {
        return 0;
      }

      return used;
    } catch (e) {
      debugPrint('Error getting daily usage: $e');
      return 0;
    }
  }

  /// Get remaining prompts for today
  Future<int> getRemainingPrompts() async {
    final used = await getDailyUsage();
    return freeDailyLimit - used;
  }

  /// Check if user has reached daily limit
  Future<bool> hasReachedDailyLimit() async {
    final used = await getDailyUsage();
    return used >= freeDailyLimit;
  }

  /// Check if it's a new day and reset if needed
  /// Client now calculates the effective count locally; server resets on successful requests.
  Future<bool> resetIfNewDay() async {
    return false;
  }

  /// Increment daily usage by 1
  Future<bool> incrementDailyUsage() async {
    final ref = _userDocRef();
    if (ref == null) return false;

    try {
      await ref.update({'dailyPromptsUsed': FieldValue.increment(1)});
      return true;
    } catch (e) {
      debugPrint('Error incrementing daily usage: $e');
      return false;
    }
  }

  /// Load usage data and reset if new day
  /// Returns a map with 'used', 'remaining', 'hasReachedLimit'
  Future<Map<String, dynamic>> loadDailyUsageData() async {
    await resetIfNewDay();
    final used = await getDailyUsage();
    return {
      'used': used,
      'remaining': freeDailyLimit - used,
      'hasReachedLimit': used >= freeDailyLimit,
    };
  }
}
