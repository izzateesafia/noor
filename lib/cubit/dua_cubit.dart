import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/dua.dart';
import '../repository/dua_repository.dart';
import 'dua_states.dart';

class DuaCubit extends Cubit<DuaState> {
  final DuaRepository repository;
  DuaCubit(this.repository) : super(const DuaState());

  Future<void> fetchDuas() async {
    emit(state.copyWith(status: DuaStatus.loading));
    try {
      final duas = await repository.getDuas();
      emit(state.copyWith(status: DuaStatus.loaded, duas: duas));
    } catch (e) {
      emit(state.copyWith(status: DuaStatus.error, error: e.toString()));
    }
  }

  Future<void> addDua(Dua dua) async {
    try {
      await repository.addDua(dua);
      fetchDuas();
    } catch (e) {
      emit(state.copyWith(status: DuaStatus.error, error: e.toString()));
    }
  }

  Future<void> updateDua(Dua dua) async {
    try {
      await repository.updateDua(dua);
      fetchDuas();
    } catch (e) {
      emit(state.copyWith(status: DuaStatus.error, error: e.toString()));
    }
  }

  Future<void> deleteDua(String id) async {
    try {
      await repository.deleteDua(id);
      fetchDuas();
    } catch (e) {
      emit(state.copyWith(status: DuaStatus.error, error: e.toString()));
    }
  }
} 