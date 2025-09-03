import '../models/ad.dart';

class AdState {
  final List<Ad> ads;
  final bool isLoading;
  final String? error;
  
  const AdState({
    this.ads = const [],
    this.isLoading = false,
    this.error,
  });
  
  AdState copyWith({
    List<Ad>? ads,
    bool? isLoading,
    String? error,
  }) {
    return AdState(
      ads: ads ?? this.ads,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class AdInitial extends AdState {
  const AdInitial() : super();
}

class AdLoading extends AdState {
  const AdLoading() : super(isLoading: true);
}

class AdLoaded extends AdState {
  const AdLoaded({required List<Ad> ads}) : super(ads: ads);
}

class AdError extends AdState {
  const AdError(String message) : super(error: message);
}
