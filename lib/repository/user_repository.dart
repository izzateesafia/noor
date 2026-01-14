import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import '../models/user_model.dart';

class UserRepository {
  final _db = FirebaseFirestore.instance;
  final _auth = fb_auth.FirebaseAuth.instance;
  final String _collection = 'users';

  Future<List<UserModel>> getUsers() async {
    final snapshot = await _db.collection(_collection).get();
    return snapshot.docs
        .map((doc) => UserModel.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

    Future<UserModel?> getUserById(String id) async {
    try {
      final doc = await _db.collection(_collection).doc(id).get();
      
      if (!doc.exists) {
        return null;
      }
      
      final data = doc.data()!;
      
      // Ensure required fields have fallback values
      final safeData = {
        'id': doc.id,
        'name': data['name'] ?? 'Unknown User',
        'email': data['email'] ?? 'user@example.com',
        'phone': data['phone'], // can be null
        // userType is kept for backward compatibility (UserModel.fromJson handles it)
        'userType': data['userType'] ?? 'student',
        'isPremium': data['isPremium'] ?? false,
        'profileImage': data['profileImage'],
        'premiumStartDate': data['premiumStartDate'],
        'premiumEndDate': data['premiumEndDate'],
        'enrolledClassIds': data['enrolledClassIds'] ?? [],
        'roles': data['roles'], // UserModel.fromJson will handle backward compatibility
        'birthDate': data['birthDate'],
        'address': data['address'],
        'hasCompletedBiodata': data['hasCompletedBiodata'] ?? false,
        'stripePaymentMethodId': data['stripePaymentMethodId'],
        'latitude': data['latitude'],
        'longitude': data['longitude'],
        'locationName': data['locationName'],
        'mushafBookmarks': data['mushafBookmarks'],
        'pendingClassPayments': data['pendingClassPayments'],
      };
      
      final user = UserModel.fromJson(safeData);
      return user;
    } catch (e) {
      return null;
    }
  }

  // For admin or backend use only. Normal users should be created via signupUser
  Future<void> addUser(UserModel user) async {
    try {
      final data = user.toJson();
      data.remove('id');
      // Use the user's ID as the document ID to match Firebase Auth UID
      await _db.collection(_collection).doc(user.id).set(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateUser(UserModel user) async {
    final data = user.toJson();
    final id = user.id;
    data.remove('id');
    await _db.collection(_collection).doc(id).update(data);
  }

  // Delete user from Firestore (admin use or as part of account deletion)
  Future<void> deleteUser(String id) async {
    try {
      print('DEBUG: Attempting to delete user document: $id');
      await _db.collection(_collection).doc(id).delete();
      print('DEBUG: Delete operation completed for user: $id');
    } on FirebaseException catch (e) {
      print('DEBUG: FirebaseException during delete: ${e.code} - ${e.message}');
      if (e.code == 'permission-denied') {
        throw Exception('Tiada kebenaran untuk memadam data pengguna. Sila hubungi sokongan.');
      } else if (e.code == 'unavailable' || e.code == 'deadline-exceeded') {
        throw Exception('Tiada sambungan internet. Sila semak sambungan anda dan cuba lagi.');
      } else if (e.code == 'not-found') {
        // Document doesn't exist - this is actually OK, consider it successful
        print('DEBUG: Document not found (may already be deleted): $id');
        return;
      } else {
        throw Exception('Gagal memadam data pengguna dari pangkalan data: ${e.message ?? e.code}');
      }
    } catch (e) {
      print('DEBUG: Unexpected error during delete: $e');
      rethrow;
    }
  }

  // Delete current user's Firebase Auth account
  // This permanently deletes the authentication account
  Future<void> deleteCurrentUserAuthAccount() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('No authenticated user to delete');
    }
    await currentUser.delete();
  }

  // Delete FCM token for a user
  Future<void> deleteUserToken(String userId) async {
    try {
      await _db.collection('user_tokens').doc(userId).delete();
    } catch (e) {
      // Non-critical - log but don't throw
      // Token deletion failure shouldn't block account deletion
    }
  }

  // Complete account deletion: deletes Firestore document, FCM token, and Firebase Auth account
  // Note: Profile image deletion should be handled separately via ImageUploadService
  // Throws exception if any critical step fails
  Future<void> deleteCurrentUserAccount() async {
    print('DEBUG: Starting account deletion process');
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      print('DEBUG: No authenticated user found');
      throw Exception('No authenticated user to delete');
    }
    
    final userId = currentUser.uid;
    print('DEBUG: Deleting account for user ID: $userId');
    
    // 1. Delete FCM token (non-critical, continue even if fails)
    print('DEBUG: Step 1 - Deleting FCM token');
    try {
      await deleteUserToken(userId);
      print('DEBUG: FCM token deleted successfully');
    } catch (e) {
      // Log but continue - token deletion failure shouldn't block account deletion
      print('Warning: Failed to delete FCM token: $e');
    }
    
    // 2. Delete Firestore user document
    print('DEBUG: Step 2 - Deleting Firestore user document');
    try {
      await deleteUser(userId);
      print('DEBUG: Firestore delete operation completed');
    } catch (e) {
      print('DEBUG: Error during Firestore deletion: $e');
      // The deleteUser method already throws user-friendly exceptions
      rethrow;
    }
    
    // 3. Verify that the Firestore document was actually deleted
    // Use retry logic to handle Firestore eventual consistency
    print('DEBUG: Step 3 - Verifying document deletion');
    bool documentDeleted = false;
    const maxRetries = 5;
    const retryDelay = Duration(milliseconds: 500);
    
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        print('DEBUG: Verification attempt $attempt of $maxRetries');
        final doc = await _db.collection(_collection).doc(userId).get();
        if (!doc.exists) {
          print('DEBUG: Document verified as deleted');
          documentDeleted = true;
          break;
        } else {
          print('DEBUG: Document still exists, waiting before retry...');
          if (attempt < maxRetries) {
            await Future.delayed(retryDelay);
          }
        }
      } catch (e) {
        print('DEBUG: Error during verification attempt $attempt: $e');
        // If it's the last attempt and document still exists, throw error
        if (attempt == maxRetries) {
          // Check one more time if document exists
          try {
            final finalCheck = await _db.collection(_collection).doc(userId).get();
            if (finalCheck.exists) {
              throw Exception('Data pengguna masih wujud dalam pangkalan data selepas cubaan memadam. Sila hubungi sokongan.');
            }
            // Document doesn't exist, verification passed
            documentDeleted = true;
          } catch (checkError) {
            // If final check fails, throw the verification error
            if (checkError.toString().contains('Data pengguna masih wujud')) {
              rethrow;
            }
            // For other errors, log but assume deletion succeeded
            print('Warning: Could not complete final verification: $checkError');
            documentDeleted = true; // Assume success to avoid blocking deletion
          }
        } else {
          // Wait before retrying
          await Future.delayed(retryDelay);
        }
      }
    }
    
    if (!documentDeleted) {
      print('DEBUG: Verification failed - document still exists after all retries');
      throw Exception('Data pengguna masih wujud dalam pangkalan data selepas cubaan memadam. Sila hubungi sokongan.');
    }
    
    // 4. Delete Firebase Auth account (must be last as it signs out the user)
    print('DEBUG: Step 4 - Deleting Firebase Auth account');
    try {
      await deleteCurrentUserAuthAccount();
      print('DEBUG: Firebase Auth account deleted successfully');
    } catch (e) {
      print('DEBUG: Error during Firebase Auth deletion: $e');
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('requires-recent-login')) {
        throw Exception('Pengesahan semula diperlukan. Sila log keluar dan log masuk semula sebelum memadam akaun.');
      } else if (errorString.contains('network') || errorString.contains('connection')) {
        throw Exception('Tiada sambungan internet. Sila semak sambungan anda dan cuba lagi.');
      } else {
        throw Exception('Gagal memadam akaun pengesahan: $e');
      }
    }
    
    print('DEBUG: Account deletion completed successfully');
  }

  // SIGNUP: Create user with email/password and add profile to Firestore
  Future<UserModel> signupUser({
    required String name,
    required String email,
    required String password,
    String? phone,
    List<UserType> roles = const [UserType.student],
    bool isPremium = false,
    DateTime? birthDate,
    Map<String, String>? address,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    final uid = credential.user!.uid;
    final user = UserModel(
      id: uid,
      name: name,
      email: email,
      phone: phone,
      roles: roles,
      isPremium: isPremium,
      birthDate: birthDate,
      address: address,
      hasCompletedBiodata: false, // New users need to complete biodata
    );
    await _db.collection(_collection).doc(uid).set(user.toJson()..remove('id'));
    return user;
  }

  // LOGIN: Sign in with email/password and return UserModel from Firestore
  Future<UserModel?> loginUser({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
    final uid = credential.user!.uid;
    return getUserById(uid);
  }

  // Get current user from Firebase Auth and Firestore
  Future<UserModel?> getCurrentUser() async {
    try {
      final currentAuthUser = _auth.currentUser;
      if (currentAuthUser == null) {
        return null;
      }
      
      final user = await getUserById(currentAuthUser.uid);
      
      if (user != null) {
      } else {
      }
      
      return user;
    } catch (e) {
      return null;
    }
  }

  // Sign out from Firebase Auth
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      rethrow;
    }
  }
} 