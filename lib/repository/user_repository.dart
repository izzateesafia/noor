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
      print('UserRepository: Getting user by ID: $id');
      final doc = await _db.collection(_collection).doc(id).get();
      print('UserRepository: Document exists: ${doc.exists}');
      
      if (!doc.exists) {
        print('UserRepository: Document does not exist for ID: $id');
        return null;
      }
      
      final data = doc.data()!;
      print('UserRepository: Document data keys: ${data.keys.join(', ')}');
      
      // Ensure required fields have fallback values
      final safeData = {
        'id': doc.id,
        'name': data['name'] ?? 'Unknown User',
        'email': data['email'] ?? 'user@example.com',
        'phone': data['phone'] ?? 'N/A',
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
      };
      
      print('UserRepository: Safe data prepared, creating UserModel...');
      final user = UserModel.fromJson(safeData);
      print('UserRepository: UserModel created successfully: ${user.name}');
      return user;
    } catch (e) {
      print('UserRepository: Error getting user by ID: $e');
      return null;
    }
  }

  // For admin or backend use only. Normal users should be created via signupUser
  Future<void> addUser(UserModel user) async {
    try {
      print('UserRepository: Adding user with ID: ${user.id}');
      final data = user.toJson();
      data.remove('id');
      print('UserRepository: User data prepared: ${data.keys.join(', ')}');
      // Use the user's ID as the document ID to match Firebase Auth UID
      await _db.collection(_collection).doc(user.id).set(data);
      print('UserRepository: User added successfully to Firestore');
    } catch (e) {
      print('UserRepository: Error adding user: $e');
      rethrow;
    }
  }

  Future<void> updateUser(UserModel user) async {
    final data = user.toJson();
    final id = user.id;
    data.remove('id');
    await _db.collection(_collection).doc(id).update(data);
  }

  Future<void> deleteUser(String id) async {
    await _db.collection(_collection).doc(id).delete();
  }

  // SIGNUP: Create user with email/password and add profile to Firestore
  Future<UserModel> signupUser({
    required String name,
    required String email,
    required String password,
    required String phone,
    List<UserType> roles = const [UserType.student],
    bool isPremium = false,
    DateTime? birthDate,
    String? address,
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
        print('No authenticated user found');
        return null;
      }
      
      print('Fetching user data for UID: ${currentAuthUser.uid}');
      final user = await getUserById(currentAuthUser.uid);
      
      if (user != null) {
        print('Successfully loaded user: ${user.name} (${user.email})');
      } else {
        print('Failed to load user data from Firestore');
      }
      
      return user;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  // Sign out from Firebase Auth
  Future<void> signOut() async {
    try {
      print('UserRepository: Signing out from Firebase Auth...');
      await _auth.signOut();
      print('UserRepository: Successfully signed out from Firebase Auth');
    } catch (e) {
      print('UserRepository: Error signing out from Firebase Auth: $e');
      rethrow;
    }
  }
} 