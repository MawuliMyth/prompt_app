import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

/// Service for handling premium subscription operations
class PremiumService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get the current user's ID, or null if not authenticated
  String? get _currentUserId => _auth.currentUser?.uid;

  /// Reference to the user's document
  DocumentReference<Map<String, dynamic>>? _userDocRef() {
    final uid = _currentUserId;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid);
  }

  /// Check if current user is premium
  /// Returns false for guests (not logged in)
  Future<bool> checkIsPremium() async {
    final uid = _currentUserId;
    if (uid == null) return false;

    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return false;

      final data = doc.data()!;
      final isPremium = data['isPremium'] ?? false;

      // Check if premium has expired (for time-based plans)
      if (isPremium) {
        final planType = data['planType'] ?? 'free';
        if (planType != 'lifetime') {
          final expiryDate = data['premiumExpiryDate'];
          if (expiryDate != null) {
            final expiry = (expiryDate as Timestamp).toDate();
            if (DateTime.now().isAfter(expiry)) {
              // Premium has expired, downgrade to free
              await downgradeToFree();
              return false;
            }
          }
        }
      }

      return isPremium;
    } catch (e) {
      debugPrint('Error checking premium status: $e');
      return false;
    }
  }

  /// Get full user model with premium data
  /// Returns null for guests or on error
  Future<UserModel?> getUserData() async {
    final uid = _currentUserId;
    if (uid == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists || doc.data() == null) return null;
      return UserModel.fromMap(doc.data()!, doc.id);
    } catch (e) {
      debugPrint('Error getting user data: $e');
      return null;
    }
  }

  /// Activate a 3-day trial for the user
  /// Returns true if successful, false otherwise
  Future<bool> activateTrial() async {
    final ref = _userDocRef();
    if (ref == null) return false;

    try {
      await ref.set({
        'trialStartDate': FieldValue.serverTimestamp(),
        'trialUsed': true,
        'isPremium': true,
        'planType': 'trial',
      }, SetOptions(merge: true));

      debugPrint('Trial activated successfully');
      return true;
    } catch (e) {
      debugPrint('Error activating trial: $e');
      return false;
    }
  }

  /// Check if trial is currently active (within 3 days of start)
  Future<bool> isTrialActive() async {
    final user = await getUserData();
    if (user == null) return false;
    return user.isTrialActive;
  }

  /// Check if trial has expired
  Future<bool> isTrialExpired() async {
    final user = await getUserData();
    if (user == null) return false;
    if (user.trialStartDate == null) return false;
    return !user.isTrialActive;
  }

  /// Get days left in trial (0 if no active trial)
  Future<int> getDaysLeftInTrial() async {
    final user = await getUserData();
    if (user == null) return 0;
    return user.daysLeftInTrial;
  }

  /// Check if user has used their trial
  Future<bool> hasUsedTrial() async {
    final user = await getUserData();
    if (user == null) return false;
    return user.trialUsed;
  }

  /// Upgrade user to premium plan
  /// [planType] should be 'monthly', 'yearly', or 'lifetime'
  /// [expiryDate] is required for monthly/yearly plans
  Future<bool> upgradeToPremium({
    required String planType,
    DateTime? expiryDate,
  }) async {
    final ref = _userDocRef();
    if (ref == null) return false;

    if (!['monthly', 'yearly', 'lifetime'].contains(planType)) {
      debugPrint('Invalid plan type: $planType');
      return false;
    }

    try {
      final data = <String, dynamic>{
        'isPremium': true,
        'planType': planType,
      };

      // Set expiry date for time-based plans
      if (planType != 'lifetime') {
        DateTime effectiveExpiryDate;
        if (expiryDate != null) {
          effectiveExpiryDate = expiryDate;
        } else if (planType == 'monthly') {
          effectiveExpiryDate = DateTime.now().add(const Duration(days: 30));
        } else {
          effectiveExpiryDate = DateTime.now().add(const Duration(days: 365));
        }
        data['premiumExpiryDate'] = Timestamp.fromDate(effectiveExpiryDate);
      }

      await ref.set(data, SetOptions(merge: true));

      debugPrint('Upgraded to $planType plan successfully');
      return true;
    } catch (e) {
      debugPrint('Error upgrading to premium: $e');
      return false;
    }
  }

  /// Downgrade user to free plan
  Future<bool> downgradeToFree() async {
    final ref = _userDocRef();
    if (ref == null) return false;

    try {
      await ref.set({
        'isPremium': false,
        'planType': 'free',
        'premiumExpiryDate': null,
      }, SetOptions(merge: true));

      debugPrint('Downgraded to free plan');
      return true;
    } catch (e) {
      debugPrint('Error downgrading to free: $e');
      return false;
    }
  }

  /// Stream of user data for real-time premium status updates
  Stream<UserModel?> userStream() {
    final uid = _currentUserId;
    if (uid == null) return Stream.value(null);

    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) {
          if (!doc.exists || doc.data() == null) return null;
          return UserModel.fromMap(doc.data()!, doc.id);
        });
  }
}
