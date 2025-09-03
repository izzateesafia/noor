import '../models/hadith.dart';

enum HadithStatus { initial, loading, loaded, error }

class HadithState {
  final HadithStatus status;
  final List<Hadith> hadiths;
  final String? error;

  const HadithState({
    this.status = HadithStatus.initial,
    this.hadiths = const [],
    this.error,
  });

  HadithState copyWith({
    HadithStatus? status,
    List<Hadith>? hadiths,
    String? error,
  }) {
    return HadithState(
      status: status ?? this.status,
      hadiths: hadiths ?? this.hadiths,
      error: error,
    );
  }
} 