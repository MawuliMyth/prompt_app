import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  /// Create or update Firestore user document
  Future<void> _createOrUpdateUserDocument(User user, {String? displayName}) async {
    final userRef = _firestore.collection('users').doc(user.uid);
    final doc = await userRef.get();

    if (!doc.exists) {
      // Create new user document
      final userModel = UserModel(
        uid: user.uid,
        email: user.email ?? '',
        displayName: displayName ?? user.displayName ?? '',
        photoUrl: user.photoURL,
        createdAt: DateTime.now(),
      );
      await userRef.set(userModel.toMap());
    } else if (displayName != null) {
      // Update display name if provided
      await userRef.update({'displayName': displayName});
    }
  }

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
    // Create Firestore user document
    if (credential.user != null) {
      await _createOrUpdateUserDocument(credential.user!, displayName: name);
    }
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
      // Create Firestore user document if new user
      if (result.user != null) {
        await _createOrUpdateUserDocument(result.user!);
      }
      return result;
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      rethrow;
    }
  }

  Future<UserCredential?> signInWithApple() async {
    // Check platform - Apple Sign-In only works on iOS/macOS (not web)
    if (kIsWeb || (!Platform.isIOS && !Platform.isMacOS)) {
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
      // Create Firestore user document if new user
      if (result.user != null) {
        // Apple may provide name on first sign-in
        final givenName = appleCredential.givenName;
        final familyName = appleCredential.familyName;
        final displayName = (givenName != null && familyName != null)
            ? '$givenName $familyName'
            : null;
        await _createOrUpdateUserDocument(result.user!, displayName: displayName);
      }
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
      final uid = user.uid;
      // Delete Firestore user data first
      await _firestore.collection('users').doc(uid).delete();
      // Then delete Firebase Auth account
      await user.delete();
    }
  }
}
