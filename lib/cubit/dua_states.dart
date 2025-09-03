import '../models/dua.dart';

enum DuaStatus { initial, loading, loaded, error }

class DuaState {
  final DuaStatus status;
  final List<Dua> duas;
  final String? error;

  const DuaState({
    this.status = DuaStatus.initial,
    this.duas = const [],
    this.error,
  });

  DuaState copyWith({
    DuaStatus? status,
    List<Dua>? duas,
    String? error,
  }) {
    return DuaState(
      status: status ?? this.status,
      duas: duas ?? this.duas,
      error: error,
    );
  }
} 