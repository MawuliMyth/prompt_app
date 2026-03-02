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

  /// Get current daily usage
  Future<int> getDailyUsage() async {
    final ref = _userDocRef();
    if (ref == null) return 0;

    try {
      final doc = await ref.get();
      if (!doc.exists) return 0;
      return doc.data()?['dailyPromptsUsed']?.toInt() ?? 0;
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
  /// Returns true if reset was performed
  Future<bool> resetIfNewDay() async {
    final ref = _userDocRef();
    if (ref == null) return false;

    try {
      final doc = await ref.get();
      if (!doc.exists) return false;

      final data = doc.data();
      final resetDate = data?['dailyPromptsResetDate'];

      if (resetDate == null) {
        // First time, set the reset date
        await ref.set({
          'dailyPromptsUsed': 0,
          'dailyPromptsResetDate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        return true;
      }

      final lastReset = (resetDate as Timestamp).toDate();
      final now = DateTime.now();

      // Check if it's a different calendar day
      if (lastReset.year != now.year ||
          lastReset.month != now.month ||
          lastReset.day != now.day) {
        // It's a new day, reset the counter
        await ref.set({
          'dailyPromptsUsed': 0,
          'dailyPromptsResetDate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error checking/resetting daily limit: $e');
      return false;
    }
  }

  /// Increment daily usage by 1
  Future<bool> incrementDailyUsage() async {
    final ref = _userDocRef();
    if (ref == null) return false;

    try {
      await ref.update({
        'dailyPromptsUsed': FieldValue.increment(1),
      });
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
