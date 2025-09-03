import 'package:equatable/equatable.dart';
import '../../models/prayer_times.dart';

enum PrayerTimesStatus {
  initial,
  loading,
  loaded,
  error,
}

class PrayerTimesState extends Equatable {
  final PrayerTimesStatus status;
  final PrayerTimes? prayerTimes;
  final HijriDate? hijriDate;
  final List<String> states;
  final List<String> districts;
  final PrayerTimesData? currentPrayerTimes;
  final double? qiblaDirection;
  final String? error;
  final String? selectedState;
  final String? selectedDistrict;

  const PrayerTimesState({
    this.status = PrayerTimesStatus.initial,
    this.prayerTimes,
    this.hijriDate,
    this.states = const [],
    this.districts = const [],
    this.currentPrayerTimes,
    this.qiblaDirection,
    this.error,
    this.selectedState,
    this.selectedDistrict,
  });

  PrayerTimesState copyWith({
    PrayerTimesStatus? status,
    PrayerTimes? prayerTimes,
    HijriDate? hijriDate,
    List<String>? states,
    List<String>? districts,
    PrayerTimesData? currentPrayerTimes,
    double? qiblaDirection,
    String? error,
    String? selectedState,
    String? selectedDistrict,
  }) {
    return PrayerTimesState(
      status: status ?? this.status,
      prayerTimes: prayerTimes ?? this.prayerTimes,
      hijriDate: hijriDate ?? this.hijriDate,
      states: states ?? this.states,
      districts: districts ?? this.districts,
      currentPrayerTimes: currentPrayerTimes ?? this.currentPrayerTimes,
      qiblaDirection: qiblaDirection ?? this.qiblaDirection,
      error: error ?? this.error,
      selectedState: selectedState ?? this.selectedState,
      selectedDistrict: selectedDistrict ?? this.selectedDistrict,
    );
  }

  @override
  List<Object?> get props => [
        status,
        prayerTimes,
        hijriDate,
        states,
        districts,
        currentPrayerTimes,
        qiblaDirection,
        error,
        selectedState,
        selectedDistrict,
      ];
} 