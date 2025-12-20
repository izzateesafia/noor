import 'dart:io' show Platform;
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import '../repository/user_repository.dart';
import '../main.dart';

class GoogleAuthService {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // Only specify clientId for iOS, Android uses google-services.json automatically
    clientId: Platform.isIOS 
        ? '134970392054-86d1gomong6gdbdtu6c62p4knpouqh02.apps.googleusercontent.com'
        : null,
    scopes: ['email', 'profile'],
  );
  final UserRepository _userRepository = UserRepository();

  // Sign in with Google
  Future<UserModel?> signInWithGoogle() async {
    try {
      print('GoogleAuthService: Starting Google Sign-In process...');
      print('GoogleAuthService: Client ID: 134970392054-86d1gomong6gdbdtu6c62p4knpouqh02.apps.googleusercontent.com');
      
      // Try silent sign-in first (faster if user already signed in)
      print('GoogleAuthService: Attempting silent sign-in...');
      GoogleSignInAccount? googleUser;
      try {
        googleUser = await _googleSignIn.signInSilently().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            print('GoogleAuthService: Silent sign-in timed out, proceeding with interactive sign-in');
            return null;
          },
        );
        if (googleUser != null) {
          print('GoogleAuthService: Silent sign-in successful for: ${googleUser.email}');
        }
      } catch (e) {
        print('GoogleAuthService: Silent sign-in failed: $e');
      }
      
      // If silent sign-in didn't work, trigger interactive sign-in
      if (googleUser == null) {
        print('GoogleAuthService: Starting interactive sign-in flow...');
        googleUser = await _googleSignIn.signIn().timeout(
          const Duration(seconds: 120), // Increased timeout for user interaction
          onTimeout: () {
            print('GoogleAuthService: Sign-in timed out after 120 seconds');
            throw Exception('Masa tamat - sila pastikan sambungan internet anda stabil dan cuba lagi');
          },
        );
      }
      
      if (googleUser == null) {
        print('GoogleAuthService: User cancelled the sign-in');
        // User cancelled the sign-in
        return null;
      }

      print('GoogleAuthService: Google Sign-In successful for: ${googleUser.email}');
      
      // Obtain the auth details from the request
      print('GoogleAuthService: Getting authentication details...');
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('GoogleAuthService: Getting auth details timed out');
          throw Exception('Masa tamat semasa mendapatkan maklumat pengesahan. Sila cuba lagi.');
        },
      );
      
      print('GoogleAuthService: Access token: ${googleAuth.accessToken != null ? 'Present' : 'Missing'}');
      print('GoogleAuthService: ID token: ${googleAuth.idToken != null ? 'Present' : 'Missing'}');

      // Create a new credential
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      print('GoogleAuthService: Signing in to Firebase...');
      // Sign in to Firebase with the credential
      final firebase_auth.UserCredential userCredential = await _auth.signInWithCredential(credential).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('GoogleAuthService: Firebase sign-in timed out');
          throw Exception('Masa tamat semasa log masuk ke Firebase. Sila cuba lagi.');
        },
      );
      final firebase_auth.User? firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        print('GoogleAuthService: Firebase authentication successful for UID: ${firebaseUser.uid}');
        
        // Check if user already exists in Firestore
        UserModel? existingUser = await _userRepository.getUserById(firebaseUser.uid);
        
        // Save user token for notifications
        print('GoogleAuthService: Saving user token...');
        try {
          await saveUserToken();
          print('GoogleAuthService: User token saved successfully');
        } catch (e) {
          print('GoogleAuthService: Error saving user token: $e');
          // Continue even if token save fails
        }

        if (existingUser != null) {
          print('GoogleAuthService: Returning existing user: ${existingUser.name}');
          // User exists, return the existing user
          return existingUser;
        } else {
          // Create new user in Firestore
          print('GoogleAuthService: Creating new user in Firestore with UID: ${firebaseUser.uid}');
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
          print('GoogleAuthService: Saving user to Firestore...');
          await _userRepository.addUser(newUser);
          print('GoogleAuthService: User saved successfully to Firestore');
          return newUser;
        }
      } else {
        print('GoogleAuthService: Firebase authentication failed - no user returned');
      }
      
      return null;
    } catch (e) {
      print('GoogleAuthService: Error signing in with Google: $e');
      print('GoogleAuthService: Error type: ${e.runtimeType}');
      print('GoogleAuthService: Error details: ${e.toString()}');
      
      // Check for specific Google Sign-In errors
      if (e.toString().contains('sign_in_failed')) {
        print('GoogleAuthService: Sign-in failed - check SHA-1 fingerprint and client ID');
      } else if (e.toString().contains('network_error')) {
        print('GoogleAuthService: Network error - check internet connection');
      } else if (e.toString().contains('invalid_client')) {
        print('GoogleAuthService: Invalid client - check client ID configuration');
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
      print('Error signing out: $e');
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
      print('Error getting current Google user: $e');
      return null;
    }
  }

  // Test Google Sign-In configuration
  Future<void> testGoogleSignInConfig() async {
    try {
      print('GoogleAuthService: Testing Google Sign-In configuration...');
      print('GoogleAuthService: Client ID: 134970392054-86d1gomong6gdbdtu6c62p4knpouqh02.apps.googleusercontent.com');
      
      // Test if we can initialize Google Sign-In
      final bool canSignIn = await _googleSignIn.isSignedIn();
      print('GoogleAuthService: Can sign in: $canSignIn');
      
      // Test silent sign-in
      final GoogleSignInAccount? silentUser = await _googleSignIn.signInSilently();
      print('GoogleAuthService: Silent sign-in result: ${silentUser?.email ?? 'No user'}');
      
      print('GoogleAuthService: Configuration test completed');
    } catch (e) {
      print('GoogleAuthService: Configuration test failed: $e');
    }
  }
}
