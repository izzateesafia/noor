import 'package:flutter_bloc/flutter_bloc.dart';
import 'admin_stats_states.dart';
import '../repository/admin_stats_repository.dart';

class AdminStatsCubit extends Cubit<AdminStatsState> {
  final AdminStatsRepository _repository;

  AdminStatsCubit(this._repository) : super(const AdminStatsState());

  Future<void> fetchStats() async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final stats = await _repository.getStats();
      emit(state.copyWith(stats: stats, isLoading: false));
    } catch (e) {
      emit(state.copyWith(
        error: 'Failed to fetch stats: $e',
        isLoading: false,
      ));
    }
  }
}

