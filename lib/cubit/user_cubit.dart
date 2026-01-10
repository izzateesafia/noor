import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/user_model.dart';
import '../repository/user_repository.dart';
import '../services/google_auth_service.dart';
import '../services/apple_auth_service.dart';
import 'user_states.dart';

class UserCubit extends Cubit<UserState> {
  final UserRepository repository;
  final GoogleAuthService _googleAuthService = GoogleAuthService();
  final AppleAuthService _appleAuthService = AppleAuthService();
  
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
} 