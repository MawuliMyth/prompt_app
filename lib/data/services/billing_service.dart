import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';

const monthlySubscriptionId = 'prompt_premium_monthly';
const yearlySubscriptionId = 'prompt_premium_yearly';

class BillingException implements Exception {
  const BillingException(this.message);
  final String message;
  @override
  String toString() => message;
}

class BillingService {
  BillingService({InAppPurchase? store, FirebaseAuth? auth})
    : _store = store ?? InAppPurchase.instance,
      _auth = auth;

  final InAppPurchase _store;
  final FirebaseAuth? _auth;
  FirebaseAuth get _firebaseAuth => _auth ?? FirebaseAuth.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  final Map<String, ProductDetails> _products = {};
  void Function(bool busy, String? error)? _onStateChanged;
  VoidCallback? _onEntitlementChanged;

  Map<String, ProductDetails> get products => Map.unmodifiable(_products);

  Future<void> initialize({
    required void Function(bool busy, String? error) onStateChanged,
    required VoidCallback onEntitlementChanged,
  }) async {
    _onStateChanged = onStateChanged;
    _onEntitlementChanged = onEntitlementChanged;
    _purchaseSubscription ??= _store.purchaseStream.listen(
      _handlePurchases,
      onError: (Object error) =>
          _onStateChanged?.call(false, 'Store connection failed. Try again.'),
    );
    try {
      await loadProducts();
    } catch (error) {
      debugPrint('Unable to initialize store products: $error');
      _onStateChanged?.call(false, 'Google Play billing is unavailable.');
    }
  }

  Future<void> loadProducts() async {
    if (!await _store.isAvailable()) {
      _onStateChanged?.call(false, 'Google Play billing is unavailable.');
      return;
    }
    final response = await _store.queryProductDetails({
      monthlySubscriptionId,
      yearlySubscriptionId,
    });
    _products
      ..clear()
      ..addEntries(response.productDetails.map((p) => MapEntry(p.id, p)));
    if (response.error != null) {
      _onStateChanged?.call(false, response.error!.message);
    }
  }

  Future<void> purchase(String productId) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw const BillingException('Sign in to subscribe.');
    var product = _products[productId];
    if (product == null) {
      await loadProducts();
      product = _products[productId];
    }
    if (product == null) {
      throw const BillingException(
        'This subscription is not available yet. Check Google Play setup.',
      );
    }
    _onStateChanged?.call(true, null);
    final started = await _store.buyNonConsumable(
      purchaseParam: PurchaseParam(
        productDetails: product,
        applicationUserName: user.uid,
      ),
    );
    if (!started) {
      _onStateChanged?.call(false, 'Google Play could not start the purchase.');
    }
  }

  Future<void> restore() async {
    _onStateChanged?.call(true, null);
    try {
      await _store.restorePurchases();
    } finally {
      // Google Play can legitimately return no restored purchases for a free
      // user. Do not leave the entire premium UI stuck in a loading state.
      _onStateChanged?.call(false, null);
    }
  }

  Future<void> _handlePurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.pending) {
        _onStateChanged?.call(true, null);
        continue;
      }
      if (purchase.status == PurchaseStatus.error) {
        _onStateChanged?.call(
          false,
          purchase.error?.message ?? 'The purchase failed.',
        );
        continue;
      }
      if (purchase.status == PurchaseStatus.canceled) {
        _onStateChanged?.call(false, null);
        continue;
      }
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        try {
          _onStateChanged?.call(true, null);
          await _verifyWithBackend(purchase);
          if (purchase.pendingCompletePurchase) {
            await _store.completePurchase(purchase);
          }
          _onStateChanged?.call(false, null);
          _onEntitlementChanged?.call();
        } catch (error) {
          _onStateChanged?.call(
            false,
            error is BillingException
                ? error.message
                : 'Purchase verification failed. Try restoring purchases.',
          );
        }
      }
    }
  }

  Future<void> _verifyWithBackend(PurchaseDetails purchase) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw const BillingException('Sign in again to verify.');
    final token = await user.getIdToken(true);
    final response = await http.post(
      Uri.parse(ApiConfig.verifySubscriptionEndpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'productId': purchase.productID,
        'purchaseToken': purchase.verificationData.serverVerificationData,
      }),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200 || data['active'] != true) {
      throw BillingException(
        data['error'] as String? ?? 'Google Play could not verify this purchase.',
      );
    }
  }

  void dispose() {
    _purchaseSubscription?.cancel();
  }
}
