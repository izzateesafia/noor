import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import '../repository/user_repository.dart';

class GoogleAuthService {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: '134970392054-86d1gomong6gdbdtu6c62p4knpouqh02.apps.googleusercontent.com',
  );
  final UserRepository _userRepository = UserRepository();

  // Sign in with Google
  Future<UserModel?> signInWithGoogle() async {
    try {
      print('GoogleAuthService: Starting Google Sign-In process...');
      print('GoogleAuthService: Client ID: 134970392054-86d1gomong6gdbdtu6c62p4knpouqh02.apps.googleusercontent.com');
      
      // Check if Google Sign-In is available
      print('GoogleAuthService: Checking if Google Sign-In is available...');
      final bool isAvailable = await _googleSignIn.isSignedIn();
      print('GoogleAuthService: Google Sign-In available: $isAvailable');
      
      // Try to get current user first
      print('GoogleAuthService: Attempting to get current user...');
      final GoogleSignInAccount? currentUser = await _googleSignIn.signInSilently();
      if (currentUser != null) {
        print('GoogleAuthService: Found existing user: ${currentUser.email}');
        // Continue with existing user
      } else {
        print('GoogleAuthService: No existing user, starting sign-in flow...');
      }
      
      // Trigger the authentication flow with timeout
      print('GoogleAuthService: Calling _googleSignIn.signIn()...');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          print('GoogleAuthService: Sign-in timed out after 15 seconds');
          throw Exception('Google Sign-In timed out - no response from Google');
        },
      );
      
      if (googleUser == null) {
        print('GoogleAuthService: User cancelled the sign-in');
        // User cancelled the sign-in
        return null;
      }

      print('GoogleAuthService: Google Sign-In successful for: ${googleUser.email}');
      
      // Obtain the auth details from the request
      print('GoogleAuthService: Getting authentication details...');
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      print('GoogleAuthService: Access token: ${googleAuth.accessToken != null ? 'Present' : 'Missing'}');
      print('GoogleAuthService: ID token: ${googleAuth.idToken != null ? 'Present' : 'Missing'}');

      // Create a new credential
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      print('GoogleAuthService: Signing in to Firebase...');
      // Sign in to Firebase with the credential
      final firebase_auth.UserCredential userCredential = await _auth.signInWithCredential(credential);
      final firebase_auth.User? firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        print('GoogleAuthService: Firebase authentication successful for UID: ${firebaseUser.uid}');
        
        // Check if user already exists in Firestore
        UserModel? existingUser = await _userRepository.getUserById(firebaseUser.uid);
        
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
            userType: UserType.nonAdmin,
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
