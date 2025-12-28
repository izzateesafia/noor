import 'package:flutter_bloc/flutter_bloc.dart';
import '../repository/mushaf_repository.dart';
import '../models/mushaf_model.dart';
import 'mushaf_states.dart';

class MushafCubit extends Cubit<MushafState> {
  final MushafRepository _repository;

  MushafCubit(this._repository) : super(const MushafState());

  /// Fetch all mushafs from Firestore
  Future<void> fetchMushafs() async {
    emit(state.copyWith(status: MushafStatus.loading));
    try {
      print('MushafCubit: Fetching mushafs...');
      final mushafs = await _repository.getAllMushafs();
      print('MushafCubit: Fetched ${mushafs.length} mushafs');
      
      final riwayahs = await _repository.getAllRiwayahs();
      print('MushafCubit: Found ${riwayahs.length} unique riwayahs');
      
      if (mushafs.isEmpty) {
        print('MushafCubit: Warning - No mushafs found in Firestore');
      }
      
      emit(state.copyWith(
        status: MushafStatus.loaded,
        mushafs: mushafs,
        riwayahs: riwayahs,
        error: null,
      ));
    } catch (e, stackTrace) {
      print('MushafCubit: Error fetching mushafs: $e');
      print('MushafCubit: Stack trace: $stackTrace');
      emit(state.copyWith(
        status: MushafStatus.error,
        error: e.toString(),
      ));
    }
  }

  /// Fetch mushafs filtered by riwayah
  Future<void> fetchMushafsByRiwayah(String riwayah) async {
    emit(state.copyWith(
      status: MushafStatus.loading,
      selectedRiwayah: riwayah,
    ));
    try {
      final mushafs = await _repository.getMushafsByRiwayah(riwayah);
      
      emit(state.copyWith(
        status: MushafStatus.loaded,
        mushafs: mushafs,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: MushafStatus.error,
        error: e.toString(),
      ));
    }
  }

  /// Clear riwayah filter and show all mushafs
  Future<void> clearFilter() async {
    await fetchMushafs();
  }

  /// Get a specific mushaf by ID
  Future<MushafModel?> getMushafById(String id) async {
    try {
      return await _repository.getMushafById(id);
    } catch (e) {
      print('Error getting mushaf by ID: $e');
      return null;
    }
  }
}

