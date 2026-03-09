import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/user_model.dart';
import '../../core/config/api_config.dart';
import 'installation_id_service.dart';

/// Service for handling premium subscription operations
abstract class PremiumServiceBase {
  Future<bool> checkIsPremium();
  Future<UserModel?> getUserData();
  Future<bool> activateTrial();
  Future<bool> upgradeToPremium({
    required String planType,
    DateTime? expiryDate,
  });
  Future<bool> downgradeToFree();
  Future<bool> updatePersona(String? persona);
}

class PremiumService implements PremiumServiceBase {
  PremiumService({InstallationIdServiceBase? installationIdService})
    : _installationIdService =
          installationIdService ?? InstallationIdService();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final InstallationIdServiceBase _installationIdService;

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
  @override
  Future<bool> checkIsPremium() async {
    final uid = _currentUserId;
    if (uid == null) return false;

    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return false;

      final data = doc.data()!;
      final isPremium = data['isPremium'] ?? false;
      final trialStartDate = data['trialStartDate'];

      if (trialStartDate != null) {
        final trialStart = (trialStartDate as Timestamp).toDate();
        final isTrialActive = DateTime.now().isBefore(
          trialStart.add(const Duration(days: 3)),
        );
        if (isTrialActive) {
          return true;
        }
      }

      // Check if premium has expired (for time-based plans)
      if (isPremium) {
        final planType = data['planType'] ?? 'free';
        if (planType == 'trial') {
          return false;
        }
        if (planType != 'lifetime') {
          final expiryDate = data['premiumExpiryDate'];
          if (expiryDate != null) {
            final expiry = (expiryDate as Timestamp).toDate();
            if (DateTime.now().isAfter(expiry)) {
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
  @override
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
  @override
  Future<bool> activateTrial() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      await user.reload();
      final refreshedUser = _auth.currentUser;
      if (refreshedUser == null) return false;

      final installationId = await _installationIdService.getInstallationId();
      final token = await refreshedUser.getIdToken(true);
      final response = await http.post(
        Uri.parse(ApiConfig.activateTrialEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'installationId': installationId}),
      );

      if (response.statusCode == 200) {
        debugPrint('Trial activated successfully');
        return true;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final message = data['error'] as String? ?? 'Failed to activate trial';
      debugPrint('Error activating trial: $message');
      throw Exception(message);
    } catch (e) {
      debugPrint('Error activating trial: $e');
      rethrow;
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
  @override
  Future<bool> upgradeToPremium({
    required String planType,
    DateTime? expiryDate,
  }) async {
    debugPrint(
      'upgradeToPremium is disabled on the client. planType=$planType expiryDate=$expiryDate',
    );
    return false;
  }

  /// Downgrade user to free plan
  @override
  Future<bool> downgradeToFree() async {
    debugPrint('downgradeToFree is disabled on the client.');
    return false;
  }

  /// Update user's AI persona (role/profession for personalized prompts)
  @override
  Future<bool> updatePersona(String? persona) async {
    final ref = _userDocRef();
    if (ref == null) return false;

    try {
      await ref.set({'persona': persona}, SetOptions(merge: true));

      debugPrint('Persona updated: $persona');
      return true;
    } catch (e) {
      debugPrint('Error updating persona: $e');
      return false;
    }
  }

  /// Stream of user data for real-time premium status updates
  Stream<UserModel?> userStream() {
    final uid = _currentUserId;
    if (uid == null) return Stream.value(null);

    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return UserModel.fromMap(doc.data()!, doc.id);
    });
  }
}
