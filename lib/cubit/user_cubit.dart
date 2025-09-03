import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/user_model.dart';
import '../repository/user_repository.dart';
import '../services/google_auth_service.dart';
import 'user_states.dart';

class UserCubit extends Cubit<UserState> {
  final UserRepository repository;
  final GoogleAuthService _googleAuthService = GoogleAuthService();
  
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

  Future<void> fetchCurrentUser() async {
    emit(state.copyWith(status: UserStatus.loading));
    try {
      print('UserCubit: Fetching current user...');
      final currentUser = await repository.getCurrentUser();
      
      if (currentUser != null) {
        print('UserCubit: Successfully loaded user: ${currentUser.name}');
        emit(state.copyWith(
          status: UserStatus.loaded, 
          currentUser: currentUser,
        ));
      } else {
        print('UserCubit: No user data found');
        emit(state.copyWith(
          status: UserStatus.error, 
          error: 'No user data found. Please try logging in again.',
        ));
      }
    } catch (e) {
      print('UserCubit: Error fetching current user: $e');
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
      print('UserCubit: Signing in with Google...');
      final user = await _googleAuthService.signInWithGoogle();
      
      if (user != null) {
        print('UserCubit: Successfully signed in with Google: ${user.name}');
        emit(state.copyWith(
          status: UserStatus.loaded,
          currentUser: user,
        ));
      } else {
        print('UserCubit: Google sign-in cancelled or failed');
        emit(state.copyWith(
          status: UserStatus.error,
          error: 'Google sign-in was cancelled or failed.',
        ));
      }
    } catch (e) {
      print('UserCubit: Error signing in with Google: $e');
      emit(state.copyWith(
        status: UserStatus.error,
        error: 'Failed to sign in with Google: $e',
      ));
    }
  }

  // Sign out from Google
  Future<void> signOut() async {
    emit(state.copyWith(status: UserStatus.loading));
    try {
      print('UserCubit: Signing out...');
      await _googleAuthService.signOut();
      emit(state.copyWith(
        status: UserStatus.initial,
        currentUser: null,
        users: [],
      ));
    } catch (e) {
      print('UserCubit: Error signing out: $e');
      emit(state.copyWith(
        status: UserStatus.error,
        error: 'Failed to sign out: $e',
      ));
    }
  }
} 