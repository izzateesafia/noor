import 'package:equatable/equatable.dart';
import '../models/live_stream.dart';

abstract class LiveStreamState extends Equatable {
  const LiveStreamState();

  @override
  List<Object?> get props => [];
}

class LiveStreamInitial extends LiveStreamState {
  const LiveStreamInitial();
}

class LiveStreamLoading extends LiveStreamState {
  const LiveStreamLoading();
}

class LiveStreamLoaded extends LiveStreamState {
  final LiveStream? currentLiveStream;
  final List<LiveStream> allLiveStreams;

  const LiveStreamLoaded({
    this.currentLiveStream,
    this.allLiveStreams = const [],
  });

  @override
  List<Object?> get props => [currentLiveStream, allLiveStreams];

  LiveStreamLoaded copyWith({
    LiveStream? currentLiveStream,
    List<LiveStream>? allLiveStreams,
  }) {
    return LiveStreamLoaded(
      currentLiveStream: currentLiveStream ?? this.currentLiveStream,
      allLiveStreams: allLiveStreams ?? this.allLiveStreams,
    );
  }
}

class LiveStreamError extends LiveStreamState {
  final String message;

  const LiveStreamError(this.message);

  @override
  List<Object?> get props => [message];
}

class LiveStreamSuccess extends LiveStreamState {
  final String message;

  const LiveStreamSuccess(this.message);

  @override
  List<Object?> get props => [message];
} 