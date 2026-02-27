import 'dart:io' show Platform;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter/foundation.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Web OAuth client ID from google-services.json (client_type: 3)
  // This is required for Google Sign-In on Android
  static const String _googleWebClientId =
      '436678880838-goq9ki04q9mvq0vm7svoagt8lvaek6bo.apps.googleusercontent.com';

  late final GoogleSignIn _googleSignIn;

  AuthRepository() {
    // Configure GoogleSignIn with serverClientId for Android
    _googleSignIn = GoogleSignIn(
      serverClientId: _googleWebClientId,
    );
  }

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signInWithEmail(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> signUpWithEmail(
    String name,
    String email,
    String password,
  ) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await credential.user?.updateDisplayName(name);
    return credential;
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      debugPrint('Starting Google Sign-In...');

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('Google Sign-In cancelled by user');
        return null; // Cancelled
      }

      debugPrint('Google user selected: ${googleUser.email}');

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      debugPrint('Got Google auth tokens - accessToken: ${googleAuth.accessToken != null}, idToken: ${googleAuth.idToken != null}');

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final result = await _auth.signInWithCredential(credential);
      debugPrint('Firebase sign-in successful: ${result.user?.email}');
      return result;
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      rethrow;
    }
  }

  Future<UserCredential?> signInWithApple() async {
    if (!Platform.isIOS && !Platform.isMacOS) {
      throw Exception('Apple Sign-In is only supported on iOS and macOS devices.');
    }

    try {
      debugPrint('Starting Apple Sign-In...');

      final AuthorizationCredentialAppleID appleCredential =
          await SignInWithApple.getAppleIDCredential(
            scopes: [
              AppleIDAuthorizationScopes.email,
              AppleIDAuthorizationScopes.fullName,
            ],
          );

      debugPrint('Got Apple credential - identityToken: ${appleCredential.identityToken != null}');

      final OAuthCredential credential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final result = await _auth.signInWithCredential(credential);
      debugPrint('Firebase Apple sign-in successful: ${result.user?.email}');
      return result;
    } catch (e) {
      debugPrint('Apple Sign-In error: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> deleteAccount() async {
    final user = currentUser;
    if (user != null) {
      await user.delete();
    }
  }
}
