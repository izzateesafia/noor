import 'package:equatable/equatable.dart';
import '../models/mushaf_model.dart';

enum MushafStatus {
  initial,
  loading,
  loaded,
  error,
}

class MushafState extends Equatable {
  final MushafStatus status;
  final List<MushafModel> mushafs;
  final List<String> riwayahs;
  final String? selectedRiwayah;
  final String? error;

  const MushafState({
    this.status = MushafStatus.initial,
    this.mushafs = const [],
    this.riwayahs = const [],
    this.selectedRiwayah,
    this.error,
  });

  MushafState copyWith({
    MushafStatus? status,
    List<MushafModel>? mushafs,
    List<String>? riwayahs,
    String? selectedRiwayah,
    String? error,
  }) {
    return MushafState(
      status: status ?? this.status,
      mushafs: mushafs ?? this.mushafs,
      riwayahs: riwayahs ?? this.riwayahs,
      selectedRiwayah: selectedRiwayah ?? this.selectedRiwayah,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [status, mushafs, riwayahs, selectedRiwayah, error];
}

