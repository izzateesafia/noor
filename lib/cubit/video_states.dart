import 'package:equatable/equatable.dart';
import '../models/video.dart';

enum VideoStatus {
  initial,
  loading,
  loaded,
  error,
}

class VideoState extends Equatable {
  final VideoStatus status;
  final List<Video> videos;
  final List<String> categories;
  final String? selectedCategory;
  final String? error;

  const VideoState({
    this.status = VideoStatus.initial,
    this.videos = const [],
    this.categories = const [],
    this.selectedCategory,
    this.error,
  });

  VideoState copyWith({
    VideoStatus? status,
    List<Video>? videos,
    List<String>? categories,
    String? selectedCategory,
    String? error,
  }) {
    return VideoState(
      status: status ?? this.status,
      videos: videos ?? this.videos,
      categories: categories ?? this.categories,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, videos, categories, selectedCategory, error];
}

class VideoInitial extends VideoState {
  const VideoInitial() : super(status: VideoStatus.initial);
}

class VideoLoading extends VideoState {
  const VideoLoading() : super(status: VideoStatus.loading);
}

class VideoLoaded extends VideoState {
  const VideoLoaded({required List<Video> videos})
      : super(status: VideoStatus.loaded, videos: videos);
}

class VideoError extends VideoState {
  const VideoError({required String error})
      : super(status: VideoStatus.error, error: error);
}

