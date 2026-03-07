import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart'
    show FirebaseAuthException, User, UserCredential;
import 'package:flutter_test/flutter_test.dart';
import 'package:promt_app/data/repositories/auth_repository.dart';
import 'package:promt_app/providers/auth_provider.dart' as app_auth;

class FakeAuthRepository implements AuthRepositoryBase {
  final StreamController<User?> _authStateController =
      StreamController<User?>.broadcast();

  User? _currentUser;
  Object? signInError;
  Object? signUpError;
  Object? googleError;
  Object? appleError;
  Object? passwordResetError;
  Object? deleteError;
  Map<String, dynamic>? googleResult;
  Map<String, dynamic>? appleResult;
  int signOutCalls = 0;

  @override
  User? get currentUser => _currentUser;

  @override
  Stream<User?> get authStateChanges => _authStateController.stream;

  @override
  Future<void> deleteAccount() async {
    if (deleteError != null) throw deleteError!;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    if (passwordResetError != null) throw passwordResetError!;
  }

  @override
  Future<Map<String, dynamic>?> signInWithApple() async {
    if (appleError != null) throw appleError!;
    return appleResult;
  }

  @override
  Future<UserCredential> signInWithEmail(String email, String password) async {
    if (signInError != null) throw signInError!;
    throw UnimplementedError('No fake UserCredential needed for this test');
  }

  @override
  Future<Map<String, dynamic>?> signInWithGoogle() async {
    if (googleError != null) throw googleError!;
    return googleResult;
  }

  @override
  Future<UserCredential> signUpWithEmail(
    String name,
    String email,
    String password,
  ) async {
    if (signUpError != null) throw signUpError!;
    throw UnimplementedError('No fake UserCredential needed for this test');
  }

  @override
  Future<void> signOut() async {
    signOutCalls += 1;
  }

  void dispose() {
    _authStateController.close();
  }
}

void main() {
  group('AuthProvider', () {
    late FakeAuthRepository authRepository;
    late app_auth.AuthProvider provider;

    setUp(() {
      authRepository = FakeAuthRepository();
      provider = app_auth.AuthProvider(authRepository: authRepository);
    });

    tearDown(() {
      provider.dispose();
      authRepository.dispose();
    });

    test('signInWithEmail returns friendly Firebase error', () async {
      authRepository.signInError = FirebaseAuthException(
        code: 'invalid-credential',
      );

      final success = await provider.signInWithEmail('user@test.com', 'bad');

      expect(success, isFalse);
      expect(
        provider.error,
        'Invalid email or password. Please check and try again.',
      );
      expect(provider.isLoading, isFalse);
    });

    test('locks out after five failed sign-in attempts', () async {
      authRepository.signInError = FirebaseAuthException(
        code: 'wrong-password',
      );

      for (var i = 0; i < 5; i++) {
        await provider.signInWithEmail('user@test.com', 'bad');
      }

      expect(provider.isLockedOut, isTrue);
      expect(
        provider.error,
        'Too many failed attempts. Please try again in 15 minutes.',
      );

      final blockedAttempt = await provider.signInWithEmail(
        'user@test.com',
        'bad',
      );
      expect(blockedAttempt, isFalse);
      expect(provider.error, startsWith('Please wait '));
    });

    test('Google cancellation does not count as failure', () async {
      authRepository.googleResult = {'credential': null, 'cancelled': true};

      final success = await provider.signInWithGoogle();

      expect(success, isFalse);
      expect(provider.error, isNull);
      expect(provider.isLockedOut, isFalse);
    });

    test('Apple unsupported error is surfaced to the UI', () async {
      authRepository.appleError = Exception(
        'Apple Sign-In is only supported on iOS and macOS devices.',
      );

      final success = await provider.signInWithApple();

      expect(success, isFalse);
      expect(
        provider.error,
        'Apple Sign-In is only supported on iOS and macOS devices.',
      );
    });

    test('password reset locks out after three Firebase failures', () async {
      authRepository.passwordResetError = FirebaseAuthException(
        code: 'too-many-requests',
      );

      for (var i = 0; i < 3; i++) {
        await provider.sendPasswordResetEmail('user@test.com');
      }

      expect(provider.isPasswordResetLockedOut, isTrue);
      expect(
        provider.error,
        'Too many reset attempts. Please wait 30 minutes before trying again.',
      );
    });

    test('deleteAccount maps requires-recent-login error', () async {
      authRepository.deleteError = FirebaseAuthException(
        code: 'requires-recent-login',
      );

      final success = await provider.deleteAccount();

      expect(success, isFalse);
      expect(
        provider.error,
        'Please sign in again before deleting your account.',
      );
    });

    test('signOut resets lockout state', () async {
      authRepository.signInError = FirebaseAuthException(
        code: 'wrong-password',
      );
      for (var i = 0; i < 5; i++) {
        await provider.signInWithEmail('user@test.com', 'bad');
      }

      await provider.signOut();

      expect(provider.isLockedOut, isFalse);
      expect(authRepository.signOutCalls, 1);
    });
  });
}
