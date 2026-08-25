import 'dart:io' show Platform;
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
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

/// Typed result of a social sign-in attempt, replacing a previously
/// untyped `Map<String, dynamic>` with string keys ('credential',
/// 'cancelled') that could silently mismatch between repository and caller
/// (e.g. a typo'd key would read back null and be misread as "cancelled").
class SocialSignInResult {
  const SocialSignInResult({this.credential, required this.cancelled});

  final UserCredential? credential;
  final bool cancelled;
}

abstract class AuthRepositoryBase {
  User? get currentUser;
  Stream<User?> get authStateChanges;

  Future<UserCredential> signInWithEmail(String email, String password);
  Future<UserCredential> signUpWithEmail(
    String name,
    String email,
    String password,
  );
  Future<SocialSignInResult> signInWithGoogle();
  Future<SocialSignInResult> signInWithApple();
  Future<void> signOut();
  Future<void> sendPasswordResetEmail(String email);
  Future<void> sendEmailVerification();
  Future<void> reloadCurrentUser();
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

  /// Generates a cryptographically-random nonce for the Apple Sign-In flow.
  /// Apple/Firebase's documented flow requires binding the identity token
  /// to this specific auth attempt via a nonce - without it, a captured
  /// Apple identity token could potentially be replayed to authenticate.
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  String _sha256OfString(String input) {
    return sha256.convert(utf8.encode(input)).toString();
  }

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

    // The Firebase Auth account now exists. If any of the follow-up steps
    // below fail (e.g. a transient network drop right after account
    // creation), we still want to report signup as successful rather than
    // throwing - a rethrow here would surface a confusing failure for an
    // account that actually got created, and a retry would then fail with
    // "email-already-in-use" with the user never having seen a success
    // state. We best-effort these steps and swallow their errors.
    try {
      await credential.user?.updateDisplayName(name);
      await credential.user?.sendEmailVerification();
      if (credential.user != null) {
        await _createOrUpdateUserDocument(credential.user!, displayName: name);
      }
    } catch (e) {
      debugPrint('Post-signup setup step failed (account was created): $e');
    }

    return credential;
  }

  @override
  Future<SocialSignInResult> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled the sign-in
        return const SocialSignInResult(cancelled: true);
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
      return SocialSignInResult(credential: result, cancelled: false);
    } catch (e) {
      // Log only the error code, not the full exception - a
      // FirebaseAuthException's message can include the user's email
      // address, which shouldn't end up in device logs.
      debugPrint('Google Sign-In error: ${e is FirebaseAuthException ? e.code : e.runtimeType}');
      rethrow;
    }
  }

  @override
  Future<SocialSignInResult> signInWithApple() async {
    // Check platform - Apple Sign-In only works on iOS/macOS (not web)
    if (kIsWeb || (!Platform.isIOS && !Platform.isMacOS)) {
      throw Exception(
        'Apple Sign-In is only supported on iOS and macOS devices.',
      );
    }

    try {
      final rawNonce = _generateNonce();
      final hashedNonce = _sha256OfString(rawNonce);

      final AuthorizationCredentialAppleID appleCredential =
          await SignInWithApple.getAppleIDCredential(
            scopes: [
              AppleIDAuthorizationScopes.email,
              AppleIDAuthorizationScopes.fullName,
            ],
            nonce: hashedNonce,
          );

      final OAuthCredential credential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
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
      return SocialSignInResult(credential: result, cancelled: false);
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        return const SocialSignInResult(cancelled: true);
      }
      rethrow;
    } catch (e) {
      debugPrint('Apple Sign-In error: ${e is FirebaseAuthException ? e.code : e.runtimeType}');
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
  Future<void> sendEmailVerification() async {
    final user = currentUser;
    if (user == null) {
      throw Exception('Please sign in first.');
    }

    await user.sendEmailVerification();
  }

  @override
  Future<void> reloadCurrentUser() async {
    await currentUser?.reload();
  }

  @override
  Future<void> deleteAccount() async {
    final user = currentUser;
    if (user == null) {
      // Previously this silently returned as if deletion succeeded, which
      // let AuthProvider report success=true to the UI (e.g. after a token
      // expired or the user signed out elsewhere right before tapping
      // "Delete account") even though nothing was deleted.
      throw Exception('No signed-in account to delete. Please sign in and try again.');
    }

    final token = await user.getIdToken(true);
    final response = await http.delete(
      Uri.parse(ApiConfig.deleteAccountEndpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      String? code;
      String? errorMessage;
      try {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        code = data['code'] as String?;
        errorMessage = data['error'] as String?;
      } catch (_) {
        // Non-JSON error body (e.g. a proxy/outage HTML page) - fall back
        // to a generic message instead of letting a raw FormatException
        // bubble up as the user-facing error text.
      }

      if (code == 'requires-recent-login') {
        throw FirebaseAuthException(
          code: 'requires-recent-login',
          message: errorMessage,
        );
      }

      throw Exception(errorMessage ?? 'Failed to delete account. Please try again.');
    }

    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
