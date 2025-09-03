import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/whats_new.dart';
import '../repository/whats_new_repository.dart';
import 'whats_new_states.dart';

class WhatsNewCubit extends Cubit<WhatsNewState> {
  final WhatsNewRepository _repository;

  WhatsNewCubit(this._repository) : super(const WhatsNewInitial());

  Future<void> fetchWhatsNew() async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final items = await _repository.getWhatsNew();
      emit(state.copyWith(items: items, isLoading: false));
    } catch (e) {
      emit(state.copyWith(error: 'Failed to fetch what\'s new: $e', isLoading: false));
    }
  }

  Future<void> addWhatsNew(WhatsNew item) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      await _repository.addWhatsNew(item);
      await fetchWhatsNew();
    } catch (e) {
      emit(state.copyWith(error: 'Failed to add what\'s new: $e', isLoading: false));
    }
  }

  Future<void> updateWhatsNew(WhatsNew item) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      await _repository.updateWhatsNew(item);
      await fetchWhatsNew();
    } catch (e) {
      emit(state.copyWith(error: 'Failed to update what\'s new: $e', isLoading: false));
    }
  }

  Future<void> deleteWhatsNew(String id) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      await _repository.deleteWhatsNew(id);
      await fetchWhatsNew();
    } catch (e) {
      emit(state.copyWith(error: 'Failed to delete what\'s new: $e', isLoading: false));
    }
  }
}
