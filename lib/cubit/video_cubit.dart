import 'package:flutter_bloc/flutter_bloc.dart';
import '../repository/video_repository.dart';
import '../models/video.dart';
import 'video_states.dart';

class VideoCubit extends Cubit<VideoState> {
  final VideoRepository _repository;

  VideoCubit(this._repository) : super(VideoInitial());

  Future<void> fetchVideos({String? category}) async {
    emit(VideoLoading());
    try {
      final videos = await _repository.getVideos(category: category);
      emit(VideoLoaded(videos: videos));
    } catch (e) {
      emit(VideoError(error: e.toString()));
    }
  }

  Future<void> fetchCategories() async {
    try {
      final categories = await _repository.getCategories();
      emit(state.copyWith(categories: categories));
    } catch (e) {
      emit(VideoError(error: e.toString()));
    }
  }

  void filterByCategory(String? category) {
    emit(state.copyWith(selectedCategory: category));
    fetchVideos(category: category);
  }

  void clearFilter() {
    filterByCategory(null);
  }

  Future<void> addVideo(Video video) async {
    try {
      await _repository.addVideo(video);
      fetchVideos(category: state.selectedCategory);
    } catch (e) {
      emit(VideoError(error: e.toString()));
    }
  }

  Future<void> updateVideo(Video video) async {
    try {
      await _repository.updateVideo(video);
      fetchVideos(category: state.selectedCategory);
    } catch (e) {
      emit(VideoError(error: e.toString()));
    }
  }

  Future<void> deleteVideo(String id) async {
    try {
      await _repository.deleteVideo(id);
      fetchVideos(category: state.selectedCategory);
    } catch (e) {
      emit(VideoError(error: e.toString()));
    }
  }
}

