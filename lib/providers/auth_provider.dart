import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _authRepository.currentUser;
  bool get isAuthenticated => _authRepository.currentUser != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

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

  Future<bool> signInWithEmail(String email, String password) async {
    try {
      _setLoading(true);
      _setError(null);
      await _authRepository.signInWithEmail(email, password);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(e.message ?? 'An error occurred during sign in.');
      return false;
    } catch (e) {
      _setError('An unexpected error occurred.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signUpWithEmail(String name, String email, String password) async {
    try {
      _setLoading(true);
      _setError(null);
      await _authRepository.signUpWithEmail(name, email, password);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(e.message ?? 'An error occurred during sign up.');
      return false;
    } catch (e) {
      _setError('An unexpected error occurred.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      _setLoading(true);
      _setError(null);
      final credential = await _authRepository.signInWithGoogle();
      return credential != null;
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException during Google Sign-In: ${e.code} - ${e.message}');
      _setError(e.message ?? 'Google Sign-In failed.');
      return false;
    } catch (e) {
      debugPrint('Unexpected error during Google Sign-In: $e');
      _setError('Google Sign-In failed. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signInWithApple() async {
    try {
      _setLoading(true);
      _setError(null);
      final credential = await _authRepository.signInWithApple();
      return credential != null;
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException during Apple Sign-In: ${e.code} - ${e.message}');
      _setError(e.message ?? 'Apple Sign-In failed.');
      return false;
    } catch (e) {
      debugPrint('Unexpected error during Apple Sign-In: $e');
      // Show the actual error message for debugging
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
    await _authRepository.signOut();
  }

  Future<bool> deleteAccount() async {
    try {
      _setLoading(true);
      _setError(null);
      await _authRepository.deleteAccount();
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
