import '../models/user_model.dart';

enum UserStatus { initial, loading, loaded, error }

class UserState {
  final UserStatus status;
  final List<UserModel> users;
  final UserModel? currentUser;
  final String? error;

  const UserState({
    this.status = UserStatus.initial,
    this.users = const [],
    this.currentUser,
    this.error,
  });

  UserState copyWith({
    UserStatus? status,
    List<UserModel>? users,
    UserModel? currentUser,
    String? error,
  }) {
    return UserState(
      status: status ?? this.status,
      users: users ?? this.users,
      currentUser: currentUser ?? this.currentUser,
      error: error,
    );
  }
} 