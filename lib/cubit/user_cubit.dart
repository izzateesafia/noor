import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/user_model.dart';
import '../repository/user_repository.dart';
import '../services/google_auth_service.dart';
import '../services/apple_auth_service.dart';
import '../services/image_upload_service.dart';
import 'user_states.dart';

class UserCubit extends Cubit<UserState> {
  final UserRepository repository;
  final GoogleAuthService _googleAuthService = GoogleAuthService();
  final AppleAuthService _appleAuthService = AppleAuthService();
  final ImageUploadService _imageUploadService = ImageUploadService();
  
  UserCubit(this.repository) : super(const UserState());

  Future<void> fetchUsers() async {
    emit(state.copyWith(status: UserStatus.loading));
    try {
      final users = await repository.getUsers();
      emit(state.copyWith(status: UserStatus.loaded, users: users));
    } catch (e) {
      emit(state.copyWith(status: UserStatus.error, error: e.toString()));
    }
  }

  Future<void> addUser(UserModel user) async {
    try {
      await repository.addUser(user);
      fetchUsers();
    } catch (e) {
      emit(state.copyWith(status: UserStatus.error, error: e.toString()));
    }
  }

  Future<void> updateUser(UserModel user) async {
    try {
      await repository.updateUser(user);
      // Update currentUser in state if this is the current user
      if (state.currentUser?.id == user.id) {
        emit(state.copyWith(
          currentUser: user,
          status: UserStatus.loaded,
        ));
      }
      fetchUsers();
    } catch (e) {
      emit(state.copyWith(status: UserStatus.error, error: e.toString()));
    }
  }

  Future<void> deleteUser(String id) async {
    try {
      await repository.deleteUser(id);
      fetchUsers();
    } catch (e) {
      emit(state.copyWith(status: UserStatus.error, error: e.toString()));
    }
  }

  Future<void> updateUserType(UserType userType) async {
    try {
      emit(state.copyWith(status: UserStatus.loading));
      final current = state.currentUser;
      if (current == null) {
        emit(state.copyWith(status: UserStatus.error, error: 'Tiada pengguna untuk dikemaskini'));
        return;
      }
      // Update roles: set the new role as primary (first in array) and keep other roles
      // Remove the new role from its current position if it exists, then add it as first
      final updatedRoles = [
        userType,
        ...current.roles.where((r) => r != userType),
      ];
      final updated = current.copyWith(roles: updatedRoles);
      await repository.updateUser(updated);
      emit(state.copyWith(status: UserStatus.loaded, currentUser: updated));
    } catch (e) {
      emit(state.copyWith(status: UserStatus.error, error: e.toString()));
    }
  }

  Future<void> fetchCurrentUser() async {
    emit(state.copyWith(status: UserStatus.loading));
    try {
      final currentUser = await repository.getCurrentUser();
      
      if (currentUser != null) {
        emit(state.copyWith(
          status: UserStatus.loaded, 
          currentUser: currentUser,
        ));
      } else {
        emit(state.copyWith(
          status: UserStatus.error, 
          error: 'No user data found. Please try logging in again.',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: UserStatus.error, 
        error: 'Failed to load user data: $e'
      ));
    }
  }

  // Sign in with Google
  Future<void> signInWithGoogle() async {
    emit(state.copyWith(status: UserStatus.loading));
    try {
      final user = await _googleAuthService.signInWithGoogle().timeout(
        const Duration(seconds: 70),
        onTimeout: () {
          throw Exception('Google Sign-In timed out - sila pastikan sambungan internet anda stabil dan cuba lagi');
        },
      );
      
      if (user != null) {
        emit(state.copyWith(
          status: UserStatus.loaded,
          currentUser: user,
        ));
      } else {
        emit(state.copyWith(
          status: UserStatus.error,
          error: 'Google sign-in was cancelled or failed.',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: UserStatus.error,
        error: 'Failed to sign in with Google: $e',
      ));
    }
  }

  Future<void> signInWithApple() async {
    emit(state.copyWith(status: UserStatus.loading));
    try {
      final user = await _appleAuthService.signInWithApple().timeout(
        const Duration(seconds: 70),
        onTimeout: () {
          throw Exception('Apple Sign-In timed out - sila pastikan sambungan internet anda stabil dan cuba lagi');
        },
      );

      if (user != null) {
        emit(state.copyWith(
          status: UserStatus.loaded,
          currentUser: user,
        ));
      } else {
        print('DEBUG: Apple Sign-In returned null user');
        emit(state.copyWith(
          status: UserStatus.error,
          error: 'Apple sign-in was cancelled or failed.',
        ));
      }
    } catch (e, stackTrace) {
      print('DEBUG: UserCubit Apple Sign-In Error: $e');
      print('DEBUG: UserCubit Stack trace: $stackTrace');
      emit(state.copyWith(
        status: UserStatus.error,
        error: 'Failed to sign in with Apple: $e',
      ));
    }
  }

  // Reset state to initial
  void resetState() {
    emit(const UserState());
  }

  // Sign out from Firebase Auth and Google
  Future<void> signOut() async {
    emit(state.copyWith(status: UserStatus.loading));
    try {
      
      // Sign out from Firebase Auth
      await repository.signOut();
      
      // Sign out from Google if applicable
      await _googleAuthService.signOut();
      
      emit(state.copyWith(
        status: UserStatus.initial,
        currentUser: null,
        users: [],
      ));
      
    } catch (e) {
      emit(state.copyWith(
        status: UserStatus.error,
        error: 'Failed to sign out: $e',
      ));
    }
  }

  // Delete current user's account completely
  // This permanently deletes all user data including:
  // - Profile image from Storage
  // - FCM token from Firestore
  // - User document from Firestore
  // - Firebase Auth account
  // After deletion, user is automatically signed out
  // Throws exception if deletion fails so UI can catch and handle it
  Future<void> deleteCurrentUserAccount() async {
    emit(state.copyWith(status: UserStatus.loading));
    
    try {
      final currentUser = state.currentUser;
      if (currentUser == null) {
        final error = 'No user logged in to delete';
        emit(state.copyWith(
          status: UserStatus.error,
          error: error,
        ));
        throw Exception(error);
      }

      final userId = currentUser.id;

      // 1. Delete profile image if exists (non-critical, continue even if fails)
      if (currentUser.profileImage != null && currentUser.profileImage!.isNotEmpty) {
        try {
          await _imageUploadService.deleteProfilePicture(currentUser.profileImage!);
        } catch (e) {
          // Log but continue - profile image deletion failure shouldn't block account deletion
          print('Warning: Failed to delete profile image: $e');
        }
      }

      // 2. Delete account (handles FCM token, Firestore doc, and Firebase Auth account)
      // This will throw if deletion fails (includes verification that document was deleted)
      print('DEBUG: UserCubit - Calling repository.deleteCurrentUserAccount()');
      await repository.deleteCurrentUserAccount();
      print('DEBUG: UserCubit - Repository deletion completed successfully');

      // 3. Sign out from Google if applicable (user is already signed out from Firebase Auth)
      try {
        await _googleAuthService.signOut();
        print('DEBUG: UserCubit - Signed out from Google');
      } catch (e) {
        // Non-critical - user is already signed out from Firebase Auth
        print('Warning: Failed to sign out from Google: $e');
      }

      // 4. Explicitly sign out from Firebase Auth to ensure all auth state is cleared
      try {
        await repository.signOut();
        print('DEBUG: UserCubit - Signed out from Firebase Auth');
      } catch (e) {
        // Non-critical - account is already deleted, but try to clear any remaining state
        print('Warning: Failed to sign out from Firebase Auth: $e');
      }

      // 5. Reset state - user is now deleted and signed out
      emit(state.copyWith(
        status: UserStatus.initial,
        currentUser: null,
        users: [],
      ));
      
      print('DEBUG: UserCubit - Account deletion completed, user signed out and state reset');
      
    } catch (e) {
      print('DEBUG: UserCubit - Error during account deletion: $e');
      
      // Extract error message from exception
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }
      
      // If the error message is already user-friendly (from repository), use it
      // Otherwise, format a generic error message
      if (!errorMessage.contains('Tiada') && 
          !errorMessage.contains('Gagal') && 
          !errorMessage.contains('Sila')) {
        // Not a user-friendly message, format it
        final errorString = errorMessage.toLowerCase();
        if (errorString.contains('firestore') || errorString.contains('document') || errorString.contains('pangkalan data')) {
          errorMessage = 'Gagal memadam data pengguna dari pangkalan data. Sila cuba lagi atau hubungi sokongan.';
        } else if (errorString.contains('auth') || errorString.contains('authentication') || errorString.contains('pengesahan')) {
          errorMessage = 'Gagal memadam akaun pengesahan. Sila cuba lagi atau hubungi sokongan.';
        } else if (errorString.contains('network') || errorString.contains('connection') || errorString.contains('sambungan')) {
          errorMessage = 'Tiada sambungan internet. Sila semak sambungan anda dan cuba lagi.';
        } else if (errorString.contains('permission') || errorString.contains('denied') || errorString.contains('kebenaran')) {
          errorMessage = 'Tiada kebenaran untuk memadam akaun. Sila hubungi sokongan.';
        } else if (errorString.contains('no user logged in') || errorString.contains('tiada pengguna')) {
          errorMessage = 'Tiada pengguna yang log masuk. Sila log masuk semula.';
        } else {
          errorMessage = 'Gagal memadam akaun. Sila cuba lagi.';
        }
      }
      
      print('DEBUG: UserCubit - Formatted error message: $errorMessage');
      
      // Emit error state for UI updates
      // Keep the user logged in so they can try again
      emit(state.copyWith(
        status: UserStatus.error,
        error: errorMessage,
        // Don't clear currentUser - keep user logged in on deletion failure
      ));
      
      // Re-throw the exception with user-friendly message so the UI's try-catch can handle it
      throw Exception(errorMessage);
    }
  }
} 