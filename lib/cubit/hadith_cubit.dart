import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/hadith.dart';
import '../repository/hadith_repository.dart';
import 'hadith_states.dart';

class HadithCubit extends Cubit<HadithState> {
  final HadithRepository repository;
  HadithCubit(this.repository) : super(const HadithState());

  Future<void> fetchHadiths() async {
    emit(state.copyWith(status: HadithStatus.loading));
    try {
      final hadiths = await repository.getHadiths();
      emit(state.copyWith(status: HadithStatus.loaded, hadiths: hadiths));
    } catch (e) {
      emit(state.copyWith(status: HadithStatus.error, error: e.toString()));
    }
  }

  Future<void> addHadith(Hadith hadith) async {
    try {
      await repository.addHadith(hadith);
      fetchHadiths();
    } catch (e) {
      emit(state.copyWith(status: HadithStatus.error, error: e.toString()));
    }
  }

  Future<void> updateHadith(Hadith hadith) async {
    try {
      await repository.updateHadith(hadith);
      fetchHadiths();
    } catch (e) {
      emit(state.copyWith(status: HadithStatus.error, error: e.toString()));
    }
  }

  Future<void> deleteHadith(String id) async {
    try {
      await repository.deleteHadith(id);
      fetchHadiths();
    } catch (e) {
      emit(state.copyWith(status: HadithStatus.error, error: e.toString()));
    }
  }
} 