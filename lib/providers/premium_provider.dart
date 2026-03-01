import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/models/user_model.dart';
import '../data/services/premium_service.dart';

/// Provider for managing premium subscription state
class PremiumProvider extends ChangeNotifier {
  final PremiumService _premiumService = PremiumService();

  // State
  bool _isPremium = false;
  String _planType = 'free';
  bool _isTrialActive = false;
  int _daysLeftInTrial = 0;
  bool _trialUsed = false;
  bool _isLoading = false;
  String? _error;
  UserModel? _userData;

  // Getters
  bool get isPremium => _isPremium;
  String get planType => _planType;
  bool get isTrialActive => _isTrialActive;
  int get daysLeftInTrial => _daysLeftInTrial;
  bool get trialUsed => _trialUsed;
  bool get isLoading => _isLoading;
  String? get error => _error;
  UserModel? get userData => _userData;

  /// Check if user can start a trial
  bool get canStartTrial => !_trialUsed && !_isPremium;

  /// Check if user has any premium access (subscription or trial)
  bool get hasPremiumAccess => _isPremium || _isTrialActive;

  /// Load premium status from Firestore
  Future<void> loadPremiumStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _resetState();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userData = await _premiumService.getUserData();
      if (userData != null) {
        _userData = userData;
        _isPremium = userData.hasPremiumAccess;
        _planType = userData.planType;
        _isTrialActive = userData.isTrialActive;
        _daysLeftInTrial = userData.daysLeftInTrial;
        _trialUsed = userData.trialUsed;
      } else {
        _resetState();
      }
    } catch (e) {
      debugPrint('Error loading premium status: $e');
      _error = 'Failed to load premium status';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Refresh premium status from Firestore
  Future<void> refreshPremiumStatus() async {
    await loadPremiumStatus();
  }

  /// Activate a 3-day trial
  Future<bool> activateTrial() async {
    if (_trialUsed) {
      _error = 'Trial already used';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _premiumService.activateTrial();
      if (success) {
        await loadPremiumStatus();
        return true;
      } else {
        _error = 'Failed to activate trial';
      }
    } catch (e) {
      debugPrint('Error activating trial: $e');
      _error = 'Failed to activate trial';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// Upgrade to premium plan
  Future<bool> upgradeToPremium({
    required String planType,
    DateTime? expiryDate,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _premiumService.upgradeToPremium(
        planType: planType,
        expiryDate: expiryDate,
      );
      if (success) {
        await loadPremiumStatus();
        return true;
      } else {
        _error = 'Failed to upgrade to premium';
      }
    } catch (e) {
      debugPrint('Error upgrading to premium: $e');
      _error = 'Failed to upgrade to premium';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// Downgrade to free plan
  Future<bool> downgradeToFree() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _premiumService.downgradeToFree();
      if (success) {
        await loadPremiumStatus();
        return true;
      } else {
        _error = 'Failed to downgrade';
      }
    } catch (e) {
      debugPrint('Error downgrading to free: $e');
      _error = 'Failed to downgrade';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// Clear any error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Reset state (used when user logs out)
  void _resetState() {
    _isPremium = false;
    _planType = 'free';
    _isTrialActive = false;
    _daysLeftInTrial = 0;
    _trialUsed = false;
    _userData = null;
    _error = null;
    notifyListeners();
  }

  /// Update user - called when auth state changes
  void updateUser(User? user) {
    if (user == null) {
      _resetState();
    } else {
      loadPremiumStatus();
    }
  }
}
