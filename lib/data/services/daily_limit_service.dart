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

  /// Get current daily usage.
  ///
  /// Note: the backend is the authoritative source of truth for quota
  /// enforcement (it re-checks and atomically increments on every
  /// /api/enhance call). This local read only drives what the UI shows the
  /// user *before* they tap enhance, so a Firestore read failure here must
  /// NOT be treated as "0 used" - that would show a stale/fresh-looking
  /// quota after a network hiccup. Callers should treat a thrown error as
  /// "unknown usage" and fail closed (see [loadDailyUsageData]).
  Future<int> getDailyUsage() async {
    final ref = _userDocRef();
    if (ref == null) return 0;

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

  /// Increment daily usage by 1. This is a best-effort local mirror of the
  /// count the backend already incremented atomically as part of a
  /// successful /api/enhance call - it exists so the UI reflects the new
  /// count immediately without waiting on a fresh Firestore read. It is
  /// NOT itself the source of quota truth.
  Future<bool> incrementDailyUsage() async {
    final ref = _userDocRef();
    if (ref == null) return false;

    try {
      await ref.set({
        'dailyPromptsUsed': FieldValue.increment(1),
        'dailyPromptsResetDate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return true;
    } catch (e) {
      debugPrint('Error incrementing daily usage: $e');
      return false;
    }
  }

  /// Load usage data and reset if new day.
  /// Returns a map with 'used', 'remaining', 'hasReachedLimit', 'hadError'.
  ///
  /// Fails CLOSED: if the Firestore read throws (offline, permission error,
  /// etc.) we report the limit as reached rather than defaulting to "0
  /// used", so a transient error can't make the UI show a full fresh quota
  /// to a user who has already used it up today. The backend still has the
  /// final say when the user actually taps enhance.
  Future<Map<String, dynamic>> loadDailyUsageData() async {
    await resetIfNewDay();
    try {
      final used = await getDailyUsage();
      return {
        'used': used,
        'remaining': (freeDailyLimit - used).clamp(0, freeDailyLimit),
        'hasReachedLimit': used >= freeDailyLimit,
        'hadError': false,
      };
    } catch (e) {
      debugPrint('Error loading daily usage, failing closed: $e');
      return {
        'used': freeDailyLimit,
        'remaining': 0,
        'hasReachedLimit': true,
        'hadError': true,
      };
    }
  }
}
