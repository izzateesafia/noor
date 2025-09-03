import '../models/whats_new.dart';

class WhatsNewState {
  final List<WhatsNew> items;
  final bool isLoading;
  final String? error;
  
  const WhatsNewState({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });
  
  WhatsNewState copyWith({
    List<WhatsNew>? items,
    bool? isLoading,
    String? error,
  }) {
    return WhatsNewState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class WhatsNewInitial extends WhatsNewState {
  const WhatsNewInitial() : super();
}

class WhatsNewLoading extends WhatsNewState {
  const WhatsNewLoading() : super(isLoading: true);
}

class WhatsNewLoaded extends WhatsNewState {
  const WhatsNewLoaded({required List<WhatsNew> items}) : super(items: items);
}

class WhatsNewError extends WhatsNewState {
  const WhatsNewError(String message) : super(error: message);
}
