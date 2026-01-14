import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../models/user_model.dart';
import '../repository/user_repository.dart';
import '../main.dart';

class AppleAuthService {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final UserRepository _userRepository = UserRepository();

  /// Generates a cryptographically secure random nonce string.
  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  /// Returns the SHA-256 hash of the provided input string.
  String _sha256OfString(String input) {
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }

  /// Sign in with Apple and return the Firestore user record.
  Future<UserModel?> signInWithApple() async {
    try {
      final rawNonce = _generateNonce();
      final hashedNonce = _sha256OfString(rawNonce);
      print('DEBUG: Starting Apple Sign-In, nonce generated');

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );
      print('DEBUG: Apple credential received: ${appleCredential.identityToken != null ? "has token" : "no token"}');

      if (appleCredential.identityToken == null) {
        throw Exception('Apple identity token tidak tersedia.');
      }

      print('DEBUG: Creating Firebase credential');
      final credential = firebase_auth.OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
        rawNonce: rawNonce,
      );

      print('DEBUG: Signing in to Firebase');
      final userCredential = await _auth.signInWithCredential(credential);
      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        print('DEBUG: Firebase user is null after sign in');
        return null;
      }

      print('DEBUG: Firebase sign-in successful, user ID: ${firebaseUser.uid}');
      final existingUser = await _userRepository.getUserById(firebaseUser.uid);

      try {
        await saveUserToken();
      } catch (_) {
        // Continue even if token saving fails.
        print('DEBUG: Failed to save user token, continuing anyway');
      }

      if (existingUser != null) {
        print('DEBUG: Existing user found, returning user');
        return existingUser;
      }

      print('DEBUG: Creating new user in Firestore');
      final nameParts = [
        appleCredential.givenName,
        appleCredential.familyName,
      ].where((part) => part != null && part.trim().isNotEmpty).map((part) => part!.trim()).toList();
      final name = nameParts.isNotEmpty
          ? nameParts.join(' ')
          : firebaseUser.displayName?.trim().isNotEmpty == true
              ? firebaseUser.displayName!
              : 'Apple User';

      final newUser = UserModel(
        id: firebaseUser.uid,
        name: name,
        email: firebaseUser.email ?? appleCredential.email ?? '',
        phone: null, // optional, can be null
        roles: const [UserType.student],
        isPremium: false,
        profileImage: firebaseUser.photoURL,
        hasCompletedBiodata: false,
      );

      await _userRepository.addUser(newUser);
      print('DEBUG: New user created successfully');
      return newUser;
    } catch (e, stackTrace) {
      print('DEBUG: Apple Sign-In Error: $e');
      print('DEBUG: Stack trace: $stackTrace');
      rethrow;
    }
  }
}

