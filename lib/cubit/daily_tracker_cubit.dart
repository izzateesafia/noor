import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/daily_tracker.dart';
import '../repository/daily_tracker_repository.dart';

// Events
abstract class DailyTrackerEvent {}

class LoadTodayTracker extends DailyTrackerEvent {
  final String userId;
  LoadTodayTracker(this.userId);
}

class UpdatePrayerCompletion extends DailyTrackerEvent {
  final String userId;
  final String prayer;
  final bool completed;
  UpdatePrayerCompletion(this.userId, this.prayer, this.completed);
}

class UpdateQuranRecitation extends DailyTrackerEvent {
  final String userId;
  final bool recited;
  UpdateQuranRecitation(this.userId, this.recited);
}

class LoadTrackerHistory extends DailyTrackerEvent {
  final String userId;
  final int days;
  LoadTrackerHistory(this.userId, {this.days = 30});
}

class LoadUserStats extends DailyTrackerEvent {
  final String userId;
  final int days;
  LoadUserStats(this.userId, {this.days = 30});
}

// States
abstract class DailyTrackerState {}

class DailyTrackerInitial extends DailyTrackerState {}

class DailyTrackerLoading extends DailyTrackerState {}

class DailyTrackerLoaded extends DailyTrackerState {
  final DailyTrackerData? todayTracker;
  final List<DailyTrackerData> history;
  final Map<String, dynamic> stats;
  
  DailyTrackerLoaded({
    this.todayTracker,
    this.history = const [],
    this.stats = const {},
  });
  
  DailyTrackerLoaded copyWith({
    DailyTrackerData? todayTracker,
    List<DailyTrackerData>? history,
    Map<String, dynamic>? stats,
  }) {
    return DailyTrackerLoaded(
      todayTracker: todayTracker ?? this.todayTracker,
      history: history ?? this.history,
      stats: stats ?? this.stats,
    );
  }
}

class DailyTrackerError extends DailyTrackerState {
  final String message;
  DailyTrackerError(this.message);
}

// Cubit
class DailyTrackerCubit extends Cubit<DailyTrackerState> {
  final DailyTrackerRepository _repository;
  
  DailyTrackerCubit(this._repository) : super(DailyTrackerInitial());

  Future<void> loadTodayTracker(String userId) async {
    try {
      emit(DailyTrackerLoading());
      final tracker = await _repository.getTodayTracker(userId);
      
      if (state is DailyTrackerLoaded) {
        final currentState = state as DailyTrackerLoaded;
        emit(currentState.copyWith(todayTracker: tracker));
      } else {
        emit(DailyTrackerLoaded(todayTracker: tracker));
      }
    } catch (e) {
      emit(DailyTrackerError('Failed to load today\'s tracker: $e'));
    }
  }

  Future<void> updatePrayerCompletion(String userId, String prayer, bool completed) async {
    try {
      emit(DailyTrackerLoading());
      await _repository.updatePrayerCompletion(userId, prayer, completed);
      
      // Reload today's tracker to get updated data
      await loadTodayTracker(userId);
    } catch (e) {
      emit(DailyTrackerError('Failed to update prayer completion: $e'));
    }
  }

  Future<void> updateQuranRecitation(String userId, bool recited) async {
    try {
      emit(DailyTrackerLoading());
      await _repository.updateQuranRecitation(userId, recited);
      
      // Reload today's tracker to get updated data
      await loadTodayTracker(userId);
    } catch (e) {
      emit(DailyTrackerError('Failed to update Quran recitation: $e'));
    }
  }

  Future<void> loadTrackerHistory(String userId, {int days = 30}) async {
    try {
      emit(DailyTrackerLoading());
      final history = await _repository.getTrackerHistory(userId, days: days);
      
      if (state is DailyTrackerLoaded) {
        final currentState = state as DailyTrackerLoaded;
        emit(currentState.copyWith(history: history));
      } else {
        emit(DailyTrackerLoaded(history: history));
      }
    } catch (e) {
      emit(DailyTrackerError('Failed to load tracker history: $e'));
    }
  }

  Future<void> loadUserStats(String userId, {int days = 30}) async {
    try {
      emit(DailyTrackerLoading());
      final stats = await _repository.getUserStats(userId, days: days);
      
      if (state is DailyTrackerLoaded) {
        final currentState = state as DailyTrackerLoaded;
        emit(currentState.copyWith(stats: stats));
      } else {
        emit(DailyTrackerLoaded(stats: stats));
      }
    } catch (e) {
      emit(DailyTrackerError('Failed to load user stats: $e'));
    }
  }

  Future<void> loadAllData(String userId, {int days = 30}) async {
    try {
      emit(DailyTrackerLoading());
      
      // Load all data concurrently
      final futures = await Future.wait([
        _repository.getTodayTracker(userId),
        _repository.getTrackerHistory(userId, days: days),
        _repository.getUserStats(userId, days: days),
      ]);
      
      final todayTracker = futures[0] as DailyTrackerData?;
      final history = futures[1] as List<DailyTrackerData>;
      final stats = futures[2] as Map<String, dynamic>;
      
      emit(DailyTrackerLoaded(
        todayTracker: todayTracker,
        history: history,
        stats: stats,
      ));
    } catch (e) {
      emit(DailyTrackerError('Failed to load data: $e'));
    }
  }
}
