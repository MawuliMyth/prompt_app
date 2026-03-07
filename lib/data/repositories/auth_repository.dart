import 'dart:io' show Platform;
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart'
    show
        SignInWithApple,
        AppleIDAuthorizationScopes,
        AuthorizationCredentialAppleID,
        SignInWithAppleAuthorizationException,
        AuthorizationErrorCode;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../../core/config/api_config.dart';
import '../../firebase_options.dart';

abstract class AuthRepositoryBase {
  User? get currentUser;
  Stream<User?> get authStateChanges;

  Future<UserCredential> signInWithEmail(String email, String password);
  Future<UserCredential> signUpWithEmail(
    String name,
    String email,
    String password,
  );
  Future<Map<String, dynamic>?> signInWithGoogle();
  Future<Map<String, dynamic>?> signInWithApple();
  Future<void> signOut();
  Future<void> sendPasswordResetEmail(String email);
  Future<void> deleteAccount();
}

class AuthRepository implements AuthRepositoryBase {
  AuthRepository() {
    _googleSignIn = GoogleSignIn(
      serverClientId: _googleWebClientId,
      clientId: _iosClientId,
    );
  }
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Web OAuth client ID from google-services.json (client_type: 3)
  // This is required for Google Sign-In on Android
  static const String _googleWebClientId =
      '436678880838-goq9ki04q9mvq0vm7svoagt8lvaek6bo.apps.googleusercontent.com';
  static final String? _iosClientId = DefaultFirebaseOptions.ios.iosClientId;

  late final GoogleSignIn _googleSignIn;

  @override
  User? get currentUser => _auth.currentUser;

  @override
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Create or update Firestore user document
  Future<void> _createOrUpdateUserDocument(
    User user, {
    String? displayName,
  }) async {
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

  @override
  Future<UserCredential> signInWithEmail(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  @override
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

  @override
  Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled the sign-in
        return {'credential': null, 'cancelled': true};
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final result = await _auth.signInWithCredential(credential);
      // Create Firestore user document if new user
      if (result.user != null) {
        await _createOrUpdateUserDocument(result.user!);
      }
      return {'credential': result, 'cancelled': false};
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>?> signInWithApple() async {
    // Check platform - Apple Sign-In only works on iOS/macOS (not web)
    if (kIsWeb || (!Platform.isIOS && !Platform.isMacOS)) {
      throw Exception(
        'Apple Sign-In is only supported on iOS and macOS devices.',
      );
    }

    try {
      final AuthorizationCredentialAppleID appleCredential =
          await SignInWithApple.getAppleIDCredential(
            scopes: [
              AppleIDAuthorizationScopes.email,
              AppleIDAuthorizationScopes.fullName,
            ],
          );

      final OAuthCredential credential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final result = await _auth.signInWithCredential(credential);
      // Create Firestore user document if new user
      if (result.user != null) {
        // Apple may provide name on first sign-in
        final givenName = appleCredential.givenName;
        final familyName = appleCredential.familyName;
        final displayName = (givenName != null && familyName != null)
            ? '$givenName $familyName'
            : null;
        await _createOrUpdateUserDocument(
          result.user!,
          displayName: displayName,
        );
      }
      return {'credential': result, 'cancelled': false};
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        return {'credential': null, 'cancelled': true};
      }
      rethrow;
    } catch (e) {
      debugPrint('Apple Sign-In error: $e');
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  @override
  Future<void> deleteAccount() async {
    final user = currentUser;
    if (user != null) {
      final token = await user.getIdToken(true);
      final response = await http.delete(
        Uri.parse(ApiConfig.deleteAccountEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final code = data['code'] as String?;
        if (code == 'requires-recent-login') {
          throw FirebaseAuthException(
            code: 'requires-recent-login',
            message: data['error'] as String?,
          );
        }

        throw Exception(data['error'] ?? 'Failed to delete account');
      }

      await _googleSignIn.signOut();
      await _auth.signOut();
    }
  }
}
