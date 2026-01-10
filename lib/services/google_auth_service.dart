import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:flutter/material.dart' show TargetPlatform;
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import '../repository/user_repository.dart';
import '../main.dart';

class GoogleAuthService {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // For iOS: use iOS client ID
    // For Android: null (uses google-services.json automatically)
    // For Web: null (reads from meta tag in index.html)
    clientId: (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS)
        ? '134970392054-86d1gomong6gdbdtu6c62p4knpouqh02.apps.googleusercontent.com'
        : null,
    scopes: ['email', 'profile'],
  );
  final UserRepository _userRepository = UserRepository();

  // Sign in with Google
  Future<UserModel?> signInWithGoogle() async {
    try {
      
      // Try silent sign-in first (faster if user already signed in)
      GoogleSignInAccount? googleUser;
      try {
        googleUser = await _googleSignIn.signInSilently().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            return null;
          },
        );
        if (googleUser != null) {
        }
      } catch (e) {
      }
      
      // If silent sign-in didn't work, trigger interactive sign-in
      if (googleUser == null) {
        googleUser = await _googleSignIn.signIn().timeout(
          const Duration(seconds: 120), // Increased timeout for user interaction
          onTimeout: () {
            throw Exception('Masa tamat - sila pastikan sambungan internet anda stabil dan cuba lagi');
          },
        );
      }
      
      if (googleUser == null) {
        // User cancelled the sign-in
        return null;
      }

      
      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Masa tamat semasa mendapatkan maklumat pengesahan. Sila cuba lagi.');
        },
      );
      

      // Create a new credential
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the credential
      final firebase_auth.UserCredential userCredential = await _auth.signInWithCredential(credential).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Masa tamat semasa log masuk ke Firebase. Sila cuba lagi.');
        },
      );
      final firebase_auth.User? firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        
        // Check if user already exists in Firestore
        UserModel? existingUser = await _userRepository.getUserById(firebaseUser.uid);
        
        // Save user token for notifications
        try {
          await saveUserToken();
        } catch (e) {
          // Continue even if token save fails
        }

        if (existingUser != null) {
          // User exists, return the existing user
          return existingUser;
        } else {
          // Create new user in Firestore
          final newUser = UserModel(
            id: firebaseUser.uid,
            name: firebaseUser.displayName ?? 'Google User',
            email: firebaseUser.email ?? '',
            phone: firebaseUser.phoneNumber ?? 'N/A',
            roles: const [UserType.student],
            isPremium: false,
            profileImage: firebaseUser.photoURL,
            hasCompletedBiodata: false, // New users need to complete biodata
          );

          // Save to Firestore
          await _userRepository.addUser(newUser);
          return newUser;
        }
      } else {
      }
      
      return null;
    } catch (e) {
      
      // Check for specific Google Sign-In errors
      if (e.toString().contains('sign_in_failed')) {
      } else if (e.toString().contains('network_error')) {
      } else if (e.toString().contains('invalid_client')) {
      }
      
      rethrow;
    }
  }

  // Sign out from Google
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  // Check if user is signed in with Google
  bool isSignedInWithGoogle() {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      final providerData = currentUser.providerData;
      return providerData.any((provider) => provider.providerId == 'google.com');
    }
    return false;
  }

  // Get current Google user info
  Future<GoogleSignInAccount?> getCurrentGoogleUser() async {
    try {
      return await _googleSignIn.signInSilently();
    } catch (e) {
      return null;
    }
  }

  // Test Google Sign-In configuration
  Future<void> testGoogleSignInConfig() async {
    try {
      
      // Test if we can initialize Google Sign-In
      final bool canSignIn = await _googleSignIn.isSignedIn();
      
      // Test silent sign-in
      final GoogleSignInAccount? silentUser = await _googleSignIn.signInSilently();
      
    } catch (e) {
    }
  }
}
