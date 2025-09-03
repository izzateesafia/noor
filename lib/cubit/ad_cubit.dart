import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/ad.dart';
import '../repository/ad_repository.dart';
import 'ad_states.dart';

class AdCubit extends Cubit<AdState> {
  final AdRepository _repository;

  AdCubit(this._repository) : super(const AdInitial());

  Future<void> fetchAds() async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final ads = await _repository.getAds();
      emit(state.copyWith(ads: ads, isLoading: false));
    } catch (e) {
      emit(state.copyWith(error: 'Failed to fetch ads: $e', isLoading: false));
    }
  }

  Future<void> addAd(Ad ad) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      await _repository.addAd(ad);
      await fetchAds();
    } catch (e) {
      emit(state.copyWith(error: 'Failed to add ad: $e', isLoading: false));
    }
  }

  Future<void> updateAd(Ad ad) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      await _repository.updateAd(ad);
      await fetchAds();
    } catch (e) {
      emit(state.copyWith(error: 'Failed to update ad: $e', isLoading: false));
    }
  }

  Future<void> deleteAd(String id) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      await _repository.deleteAd(id);
      await fetchAds();
    } catch (e) {
      emit(state.copyWith(error: 'Failed to delete ad: $e', isLoading: false));
    }
  }
}
