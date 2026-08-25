import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/services/analytics_bootstrap.dart';
import '../data/models/user_model.dart';
import '../data/services/premium_service.dart';
import '../data/services/billing_service.dart';

/// Provider for managing premium subscription state
class PremiumProvider extends ChangeNotifier {
  PremiumProvider({
    PremiumServiceBase? premiumService,
    BillingService? billingService,
    bool initializeBilling = true,
  }) : _premiumService = premiumService ?? PremiumService(),
       _billingService = billingService ?? BillingService() {
    if (initializeBilling) {
      _billingService.initialize(
        onStateChanged: _handleBillingState,
        onEntitlementChanged: refreshPremiumStatus,
      );
    }
  }

  final PremiumServiceBase _premiumService;
  final BillingService _billingService;

  // State
  bool _isPremium = false;
  String _planType = 'free';
  bool _isTrialActive = false;
  int _daysLeftInTrial = 0;
  bool _trialUsed = false;
  bool _isLoading = false;
  String? _error;
  UserModel? _userData;
  String? _activeUserId;

  // Getters
  bool get isPremium => _isPremium;
  String get planType => _planType;
  bool get isTrialActive => _isTrialActive;
  int get daysLeftInTrial => _daysLeftInTrial;
  bool get trialUsed => _trialUsed;
  bool get isLoading => _isLoading;
  String? get error => _error;
  UserModel? get userData => _userData;
  Map<String, dynamic> get storeProducts => _billingService.products;

  void _handleBillingState(bool busy, String? error) {
    _isLoading = busy;
    _error = error;
    notifyListeners();
  }

  String? priceForPlan(String planType) {
    final id = planType == 'monthly'
        ? monthlySubscriptionId
        : yearlySubscriptionId;
    return _billingService.products[id]?.price;
  }

  Future<bool> purchasePlan(String planType) async {
    if (FirebaseAuth.instance.currentUser == null) {
      _error = 'Sign in to subscribe.';
      notifyListeners();
      return false;
    }
    try {
      await _billingService.purchase(
        planType == 'monthly'
            ? monthlySubscriptionId
            : yearlySubscriptionId,
      );
      return true;
    } catch (error) {
      _handleBillingState(false, error.toString());
      return false;
    }
  }

  Future<void> restorePurchases() => _billingService.restore();

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
        trackAnalytics(
          () => analyticsService.setUserProperties(
            isPremium: hasPremiumAccess,
            planType: _planType,
          ),
        );
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
    if (FirebaseAuth.instance.currentUser == null) {
      _error = 'Sign in to start your free trial.';
      notifyListeners();
      return false;
    }

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
      _error = e.toString().replaceFirst('Exception: ', '');
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
    if (FirebaseAuth.instance.currentUser == null) {
      _error = 'Sign in to upgrade to premium.';
      notifyListeners();
      return false;
    }

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

  /// Update user's AI persona
  Future<bool> updatePersona(String? persona) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _premiumService.updatePersona(persona);
      if (success) {
        // Update local userData
        if (_userData != null) {
          _userData = _userData!.copyWith(persona: persona);
        }
        trackAnalytics(() => analyticsService.logPersonaUpdated());
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to update persona';
      }
    } catch (e) {
      debugPrint('Error updating persona: $e');
      _error = 'Failed to update persona';
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
    trackAnalytics(
      () => analyticsService.setUserProperties(
        isPremium: false,
        planType: 'free',
      ),
    );
    notifyListeners();
  }

  /// Update user - called when auth state changes
  void updateUser(User? user) {
    if (user == null) {
      _activeUserId = null;
      _resetState();
    } else if (_activeUserId != user.uid) {
      _activeUserId = user.uid;
      _syncUserEntitlement();
    }
  }

  Future<void> _syncUserEntitlement() async {
    await loadPremiumStatus();
    try {
      await _billingService.restore();
    } catch (error) {
      debugPrint('Unable to sync Google Play purchases: $error');
    }
  }

  @override
  void dispose() {
    _billingService.dispose();
    super.dispose();
  }
}
