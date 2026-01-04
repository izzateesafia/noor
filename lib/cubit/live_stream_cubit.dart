import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/live_stream.dart';
import '../repository/live_stream_repository.dart';
import 'live_stream_states.dart';

class LiveStreamCubit extends Cubit<LiveStreamState> {
  final LiveStreamRepository _repository;

  LiveStreamCubit(this._repository) : super(LiveStreamInitial());

  // Get current live stream
  Future<void> getCurrentLiveStream() async {
    emit(LiveStreamLoading());
    try {
      final liveStream = await _repository.getCurrentLiveStream();
      emit(LiveStreamLoaded(currentLiveStream: liveStream));
    } catch (e) {
      emit(LiveStreamError('Failed to get current live stream: $e'));
    }
  }

  // Get all live streams
  Future<void> getAllLiveStreams() async {
    emit(LiveStreamLoading());
    try {
      final liveStreams = await _repository.getAllLiveStreams();
      final currentState = state;
      if (currentState is LiveStreamLoaded) {
        emit(currentState.copyWith(allLiveStreams: liveStreams));
      } else {
        emit(LiveStreamLoaded(allLiveStreams: liveStreams));
      }
    } catch (e) {
      emit(LiveStreamError('Failed to get live streams: $e'));
    }
  }

  // Add new live stream
  Future<void> addLiveStream({
    required String title,
    required String description,
    required String tiktokLiveLink,
  }) async {
    emit(LiveStreamLoading());
    try {
      final liveStream = LiveStream(
        id: '', // Will be set by Firestore
        title: title,
        description: description,
        tiktokLiveLink: tiktokLiveLink,
        isActive: true,
        createdAt: DateTime.now(),
      );

      final id = await _repository.addLiveStream(liveStream);
      if (id != null) {
        emit(LiveStreamSuccess('Live stream added successfully'));
        await getCurrentLiveStream();
        await getAllLiveStreams();
      } else {
        emit(LiveStreamError('Failed to add live stream'));
      }
    } catch (e) {
      emit(LiveStreamError('Failed to add live stream: $e'));
    }
  }

  // Update live stream
  Future<void> updateLiveStream(LiveStream liveStream) async {
    emit(LiveStreamLoading());
    try {
      
      final success = await _repository.updateLiveStream(liveStream);
      if (success) {
        emit(LiveStreamSuccess('Live stream updated successfully'));
        await getCurrentLiveStream();
        await getAllLiveStreams();
      } else {
        emit(LiveStreamError('Failed to update live stream'));
      }
    } catch (e) {
      emit(LiveStreamError('Failed to update live stream: $e'));
    }
  }

  // Delete live stream
  Future<void> deleteLiveStream(String id) async {
    emit(LiveStreamLoading());
    try {
      final success = await _repository.deleteLiveStream(id);
      if (success) {
        emit(LiveStreamSuccess('Live stream deleted successfully'));
        await getCurrentLiveStream();
        await getAllLiveStreams();
      } else {
        emit(LiveStreamError('Failed to delete live stream'));
      }
    } catch (e) {
      emit(LiveStreamError('Failed to delete live stream: $e'));
    }
  }

  // Activate live stream
  Future<void> activateLiveStream(String id) async {
    emit(LiveStreamLoading());
    try {
      final success = await _repository.activateLiveStream(id);
      if (success) {
        emit(LiveStreamSuccess('Live stream activated successfully'));
        await getCurrentLiveStream();
        await getAllLiveStreams();
      } else {
        emit(LiveStreamError('Failed to activate live stream'));
      }
    } catch (e) {
      emit(LiveStreamError('Failed to activate live stream: $e'));
    }
  }

  // Clear success/error messages
  void clearMessage() {
    final currentState = state;
    if (currentState is LiveStreamSuccess || currentState is LiveStreamError) {
      if (currentState is LiveStreamLoaded) {
        emit(currentState);
      } else {
        emit(LiveStreamInitial());
      }
    }
  }
} 