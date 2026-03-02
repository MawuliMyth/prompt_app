import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();
  bool _isLoading = false;
  String? _error;

  // Rate limiting
  int _failedAttempts = 0;
  DateTime? _lockoutUntil;
  static const int _maxFailedAttempts = 5;
  static const Duration _lockoutDuration = Duration(minutes: 15);

  User? get currentUser => _authRepository.currentUser;
  bool get isAuthenticated => _authRepository.currentUser != null;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLockedOut => _lockoutUntil != null && DateTime.now().isBefore(_lockoutUntil!);
  Duration? get remainingLockout {
    if (_lockoutUntil == null) return null;
    final remaining = _lockoutUntil!.difference(DateTime.now());
    return remaining.isNegative ? null : remaining;
  }

  AuthProvider() {
    _authRepository.authStateChanges.listen((user) {
      notifyListeners();
    });
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _error = message;
    notifyListeners();
  }

  void _incrementFailedAttempt() {
    _failedAttempts++;
    if (_failedAttempts >= _maxFailedAttempts) {
      _lockoutUntil = DateTime.now().add(_lockoutDuration);
      _setError('Too many failed attempts. Please try again in 15 minutes.');
    }
  }

  void _resetFailedAttempts() {
    _failedAttempts = 0;
    _lockoutUntil = null;
  }

  Future<bool> _checkLockout() async {
    if (isLockedOut) {
      final remaining = remainingLockout;
      if (remaining != null) {
        _setError('Please wait ${remaining.inMinutes} minutes before trying again.');
      }
      return true;
    }
    // Clear lockout if time has passed
    if (_lockoutUntil != null && DateTime.now().isAfter(_lockoutUntil!)) {
      _resetFailedAttempts();
    }
    return false;
  }

  Future<bool> signInWithEmail(String email, String password) async {
    if (await _checkLockout()) return false;

    try {
      _setLoading(true);
      _setError(null);
      await _authRepository.signInWithEmail(email, password);
      _resetFailedAttempts();
      return true;
    } on FirebaseAuthException catch (e) {
      _incrementFailedAttempt();
      _setError(e.message ?? 'An error occurred during sign in.');
      return false;
    } catch (e) {
      _incrementFailedAttempt();
      _setError('An unexpected error occurred.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signUpWithEmail(String name, String email, String password) async {
    if (await _checkLockout()) return false;

    try {
      _setLoading(true);
      _setError(null);
      await _authRepository.signUpWithEmail(name, email, password);
      _resetFailedAttempts();
      return true;
    } on FirebaseAuthException catch (e) {
      _incrementFailedAttempt();
      _setError(e.message ?? 'An error occurred during sign up.');
      return false;
    } catch (e) {
      _incrementFailedAttempt();
      _setError('An unexpected error occurred.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signInWithGoogle() async {
    if (await _checkLockout()) return false;

    try {
      _setLoading(true);
      _setError(null);
      final credential = await _authRepository.signInWithGoogle();
      if (credential != null) {
        _resetFailedAttempts();
        return true;
      }
      _incrementFailedAttempt();
      return false;
    } on FirebaseAuthException catch (e) {
      _incrementFailedAttempt();
      _setError(e.message ?? 'Google Sign-In failed.');
      return false;
    } catch (e) {
      _incrementFailedAttempt();
      _setError('Google Sign-In failed. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signInWithApple() async {
    if (await _checkLockout()) return false;

    try {
      _setLoading(true);
      _setError(null);
      final credential = await _authRepository.signInWithApple();
      if (credential != null) {
        _resetFailedAttempts();
        return true;
      }
      _incrementFailedAttempt();
      return false;
    } on FirebaseAuthException catch (e) {
      _incrementFailedAttempt();
      _setError(e.message ?? 'Apple Sign-In failed.');
      return false;
    } catch (e) {
      _incrementFailedAttempt();
      _setError(e.toString().replaceFirst('Exception: ', ''));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      _setLoading(true);
      _setError(null);
      await _authRepository.sendPasswordResetEmail(email);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(e.message ?? 'Failed to send reset email.');
      return false;
    } catch (e) {
      _setError('An unexpected error occurred.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    _resetFailedAttempts();
    await _authRepository.signOut();
  }

  Future<bool> deleteAccount() async {
    try {
      _setLoading(true);
      _setError(null);
      await _authRepository.deleteAccount();
      _resetFailedAttempts();
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
         _setError('Please sign in again before deleting your account.');
      } else {
        _setError(e.message ?? 'Failed to delete account.');
      }
      return false;
    } catch (e) {
      _setError('An unexpected error occurred.');
      return false;
    } finally {
      _setLoading(false);
    }
  }
}
