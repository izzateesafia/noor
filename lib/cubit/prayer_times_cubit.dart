import 'package:flutter_bloc/flutter_bloc.dart';
import '../repository/prayer_times_repository.dart';
import 'prayer_times_states.dart';

class PrayerTimesCubit extends Cubit<PrayerTimesState> {
  final PrayerTimesRepository _repository;

  PrayerTimesCubit(this._repository) : super(const PrayerTimesState());

  Future<void> fetchPrayerTimes(String stateName, String districtName) async {
    try {
      emit(state.copyWith(status: PrayerTimesStatus.loading));
      
      final prayerTimes = await _repository.getPrayerTimes(stateName, districtName);
      
      emit(state.copyWith(
        status: PrayerTimesStatus.loaded,
        prayerTimes: prayerTimes,
        selectedState: stateName,
        selectedDistrict: districtName,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: PrayerTimesStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> fetchQiblaDirection(double latitude, double longitude) async {
    try {
      emit(state.copyWith(status: PrayerTimesStatus.loading));
      
      final qiblaDirection = await _repository.getQiblaDirection(latitude, longitude);
      
      emit(state.copyWith(
        status: PrayerTimesStatus.loaded,
        qiblaDirection: qiblaDirection,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: PrayerTimesStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> fetchHijriDate() async {
    try {
      emit(state.copyWith(status: PrayerTimesStatus.loading));
      
      final hijriDate = await _repository.getHijriDate();
      
      emit(state.copyWith(
        status: PrayerTimesStatus.loaded,
        hijriDate: hijriDate,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: PrayerTimesStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> fetchStates() async {
    try {
      emit(state.copyWith(status: PrayerTimesStatus.loading));
      
      final states = await _repository.getStates();
      
      emit(state.copyWith(
        status: PrayerTimesStatus.loaded,
        states: states,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: PrayerTimesStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> fetchDistricts(String stateName) async {
    try {
      emit(state.copyWith(status: PrayerTimesStatus.loading));
      
      final districts = await _repository.getDistricts(stateName);
      
      emit(state.copyWith(
        status: PrayerTimesStatus.loaded,
        districts: districts,
        selectedState: stateName,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: PrayerTimesStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> fetchCurrentPrayerTimes(String stateName, String districtName) async {
    try {
      emit(state.copyWith(status: PrayerTimesStatus.loading));
      
      final prayerTimesData = await _repository.getCurrentPrayerTimes(stateName, districtName);
      
      // Since repository never throws exceptions, this should always succeed
      emit(state.copyWith(
        status: PrayerTimesStatus.loaded,
        currentPrayerTimes: prayerTimesData,
        prayerTimes: prayerTimesData.prayerTimes,
        hijriDate: prayerTimesData.hijriDate,
        qiblaDirection: prayerTimesData.qiblaDirection,
        selectedState: stateName,
        selectedDistrict: districtName,
        error: null, // Clear any previous errors
      ));
    } catch (e) {
      // This should never happen now, but just in case
      emit(state.copyWith(
        status: PrayerTimesStatus.error,
        error: e.toString(),
      ));
    }
  }

  // New method to fetch prayer times using coordinates
  Future<void> fetchPrayerTimesByCoordinates(double latitude, double longitude) async {
    try {
      emit(state.copyWith(status: PrayerTimesStatus.loading));
      
      final prayerTimesData = await _repository.getCurrentPrayerTimesByCoordinates(latitude, longitude);
      
      emit(state.copyWith(
        status: PrayerTimesStatus.loaded,
        currentPrayerTimes: prayerTimesData,
        prayerTimes: prayerTimesData.prayerTimes,
        hijriDate: prayerTimesData.hijriDate,
        qiblaDirection: prayerTimesData.qiblaDirection,
        selectedState: prayerTimesData.location.state,
        selectedDistrict: prayerTimesData.location.district,
        error: null, // Clear any previous errors
      ));
    } catch (e) {
      emit(state.copyWith(
        status: PrayerTimesStatus.error,
        error: e.toString(),
      ));
    }
  }

  // New method to get zone info from coordinates
  Future<void> fetchZoneInfo(double latitude, double longitude) async {
    try {
      emit(state.copyWith(status: PrayerTimesStatus.loading));
      
      final zoneInfo = await _repository.getZoneFromCoordinates(latitude, longitude);
      
      emit(state.copyWith(
        status: PrayerTimesStatus.loaded,
        selectedState: zoneInfo.state,
        selectedDistrict: zoneInfo.district,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: PrayerTimesStatus.error,
        error: e.toString(),
      ));
    }
  }

  void selectState(String selectedState) {
    emit(state.copyWith(
      selectedState: selectedState,
      selectedDistrict: null,
      districts: const [],
    ));
  }

  void selectDistrict(String selectedDistrict) {
    emit(state.copyWith(
      selectedDistrict: selectedDistrict,
    ));
  }

  void reset() {
    emit(const PrayerTimesState());
  }

  void clearError() {
    emit(state.copyWith(
      status: PrayerTimesStatus.initial,
      error: null,
    ));
  }
} 