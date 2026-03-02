import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();
  StreamSubscription<User?>? _authStateSubscription;
  bool _isLoading = false;
  String? _error;

  // Rate limiting
  int _failedAttempts = 0;
  DateTime? _lockoutUntil;
  static const int _maxFailedAttempts = 5;
  static const Duration _lockoutDuration = Duration(minutes: 15);

  // Password reset rate limiting (separate from auth)
  int _passwordResetAttempts = 0;
  DateTime? _passwordResetLockoutUntil;
  static const int _maxPasswordResetAttempts = 3;
  static const Duration _passwordResetLockoutDuration = Duration(minutes: 30);

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

  bool get isPasswordResetLockedOut => _passwordResetLockoutUntil != null && DateTime.now().isBefore(_passwordResetLockoutUntil!);
  Duration? get remainingPasswordResetLockout {
    if (_passwordResetLockoutUntil == null) return null;
    final remaining = _passwordResetLockoutUntil!.difference(DateTime.now());
    return remaining.isNegative ? null : remaining;
  }

  AuthProvider() {
    _authStateSubscription = _authRepository.authStateChanges.listen((user) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
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
      _setError(_getFriendlyErrorMessage(e.code, 'Sign in'));
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
      _setError(_getFriendlyErrorMessage(e.code, 'Sign up'));
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
      final result = await _authRepository.signInWithGoogle();

      // result is null when user cancelled - don't count as failure
      if (result == null) {
        _setError(null); // Clear any previous error
        return false;
      }

      final credential = result['credential'];
      final wasCancelled = result['cancelled'] ?? false;

      if (credential != null) {
        _resetFailedAttempts();
        return true;
      }

      // User cancelled - don't count as failed attempt
      if (!wasCancelled) {
        _incrementFailedAttempt();
      }
      return false;
    } on FirebaseAuthException catch (e) {
      _incrementFailedAttempt();
      _setError(_getFriendlyErrorMessage(e.code, 'Google Sign-In'));
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
      final result = await _authRepository.signInWithApple();

      // result is null when user cancelled or not supported
      if (result == null) {
        _setError(null); // Clear any previous error
        return false;
      }

      final credential = result['credential'];
      final wasCancelled = result['cancelled'] ?? false;

      if (credential != null) {
        _resetFailedAttempts();
        return true;
      }

      // User cancelled - don't count as failed attempt
      if (!wasCancelled) {
        _incrementFailedAttempt();
      }
      return false;
    } on FirebaseAuthException catch (e) {
      _incrementFailedAttempt();
      _setError(_getFriendlyErrorMessage(e.code, 'Apple Sign-In'));
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
    // Check password reset rate limiting
    if (isPasswordResetLockedOut) {
      final remaining = remainingPasswordResetLockout;
      if (remaining != null) {
        _setError('Too many reset attempts. Please wait ${remaining.inMinutes} minutes.');
      }
      return false;
    }
    // Clear lockout if time has passed
    if (_passwordResetLockoutUntil != null && DateTime.now().isAfter(_passwordResetLockoutUntil!)) {
      _passwordResetAttempts = 0;
      _passwordResetLockoutUntil = null;
    }

    try {
      _setLoading(true);
      _setError(null);
      await _authRepository.sendPasswordResetEmail(email);
      _passwordResetAttempts = 0; // Reset on success
      return true;
    } on FirebaseAuthException catch (e) {
      _passwordResetAttempts++;
      if (_passwordResetAttempts >= _maxPasswordResetAttempts) {
        _passwordResetLockoutUntil = DateTime.now().add(_passwordResetLockoutDuration);
        _setError('Too many reset attempts. Please wait 30 minutes before trying again.');
      } else {
        _setError(_getFriendlyErrorMessage(e.code, 'Password reset'));
      }
      return false;
    } catch (e) {
      _passwordResetAttempts++;
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
        _setError(_getFriendlyErrorMessage(e.code, 'delete account'));
      }
      return false;
    } catch (e) {
      _setError('An unexpected error occurred.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Convert Firebase error codes to user-friendly messages
  String _getFriendlyErrorMessage(String errorCode, String context) {
    switch (errorCode) {
      // Sign in errors
      case 'user-not-found':
        return 'No account found with this email. Please sign up first.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'Invalid email or password. Please check and try again.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled. Contact support for help.';

      // Sign up errors
      case 'email-already-in-use':
        return 'An account already exists with this email. Try signing in instead.';
      case 'weak-password':
        return 'Please choose a stronger password (at least 8 characters with letters and numbers).';

      // Password reset errors
      case 'invalid-continue-uri':
        return 'Invalid request. Please try again.';

      // Rate limiting
      case 'too-many-requests':
        return 'Too many attempts. Please wait a few minutes and try again.';

      // Network errors
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';

      // Google/Apple specific
      case 'sign-in-failed':
        return '$context failed. Please try again.';
      case 'canceled':
        return '$context was cancelled.';

      // Default
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}
