class PrayerTimes {
  final String fajr;
  final String sunrise;
  final String dhuhr;
  final String asr;
  final String maghrib;
  final String isha;

  const PrayerTimes({
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
  });

  factory PrayerTimes.fromJson(Map<String, dynamic> json) {
    return PrayerTimes(
      fajr: json['fajr'] ?? '',
      sunrise: json['sunrise'] ?? '',
      dhuhr: json['dhuhr'] ?? '',
      asr: json['asr'] ?? '',
      maghrib: json['maghrib'] ?? '',
      isha: json['isha'] ?? '',
    );
  }

  factory PrayerTimes.fromMap(Map<String, String> map) {
    return PrayerTimes(
      fajr: map['Fajr'] ?? '',
      sunrise: map['Sunrise'] ?? '',
      dhuhr: map['Dhuhr'] ?? '',
      asr: map['Asr'] ?? '',
      maghrib: map['Maghrib'] ?? '',
      isha: map['Isha'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fajr': fajr,
      'sunrise': sunrise,
      'dhuhr': dhuhr,
      'asr': asr,
      'maghrib': maghrib,
      'isha': isha,
    };
  }

  Map<String, String> toMap() {
    return {
      'Fajr': fajr,
      'Sunrise': sunrise,
      'Dhuhr': dhuhr,
      'Asr': asr,
      'Maghrib': maghrib,
      'Isha': isha,
    };
  }

  @override
  String toString() {
    return 'PrayerTimes(fajr: $fajr, sunrise: $sunrise, dhuhr: $dhuhr, asr: $asr, maghrib: $maghrib, isha: $isha)';
  }
}

class HijriDate {
  final String hijriDate;
  final String hijriMonth;
  final String hijriYear;
  final String gregorianDate;

  const HijriDate({
    required this.hijriDate,
    required this.hijriMonth,
    required this.hijriYear,
    required this.gregorianDate,
  });

  factory HijriDate.fromJson(Map<String, dynamic> json) {
    return HijriDate(
      hijriDate: json['hijri_date'] ?? '',
      hijriMonth: json['hijri_month'] ?? '',
      hijriYear: json['hijri_year'] ?? '',
      gregorianDate: json['gregorian_date'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hijri_date': hijriDate,
      'hijri_month': hijriMonth,
      'hijri_year': hijriYear,
      'gregorian_date': gregorianDate,
    };
  }

  @override
  String toString() {
    return 'HijriDate(hijriDate: $hijriDate, hijriMonth: $hijriMonth, hijriYear: $hijriYear, gregorianDate: $gregorianDate)';
  }
}

class Location {
  final String state;
  final String district;
  final double? latitude;
  final double? longitude;

  const Location({
    required this.state,
    required this.district,
    this.latitude,
    this.longitude,
  });

  String get fullLocation => '$state, $district';

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      state: json['state'] ?? '',
      district: json['district'] ?? '',
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'state': state,
      'district': district,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  @override
  String toString() {
    return 'Location(state: $state, district: $district, latitude: $latitude, longitude: $longitude)';
  }
}

class PrayerTimesData {
  final PrayerTimes prayerTimes;
  final HijriDate hijriDate;
  final Location location;
  final double? qiblaDirection;

  const PrayerTimesData({
    required this.prayerTimes,
    required this.hijriDate,
    required this.location,
    this.qiblaDirection,
  });

  factory PrayerTimesData.fromJson(Map<String, dynamic> json) {
    return PrayerTimesData(
      prayerTimes: PrayerTimes.fromJson(json['prayer_times'] ?? {}),
      hijriDate: HijriDate.fromJson(json['hijri_date'] ?? {}),
      location: Location.fromJson(json['location'] ?? {}),
      qiblaDirection: json['qibla_direction']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'prayer_times': prayerTimes.toJson(),
      'hijri_date': hijriDate.toJson(),
      'location': location.toJson(),
      'qibla_direction': qiblaDirection,
    };
  }

  @override
  String toString() {
    return 'PrayerTimesData(prayerTimes: $prayerTimes, hijriDate: $hijriDate, location: $location, qiblaDirection: $qiblaDirection)';
  }
}

// New models for zone-based API
class ZoneInfo {
  final String zone;
  final String state;
  final String district;

  const ZoneInfo({
    required this.zone,
    required this.state,
    required this.district,
  });

  factory ZoneInfo.fromJson(Map<String, dynamic> json) {
    return ZoneInfo(
      zone: json['zone'] ?? '',
      state: json['state'] ?? '',
      district: json['district'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'zone': zone,
      'state': state,
      'district': district,
    };
  }

  @override
  String toString() {
    return 'ZoneInfo(zone: $zone, state: $state, district: $district)';
  }
}

class ZonePrayerTimes {
  final String hijri;
  final String date;
  final String day;
  final String fajr;
  final String syuruk;
  final String dhuhr;
  final String asr;
  final String maghrib;
  final String isha;
  final String status;
  final String serverTime;
  final String periodType;
  final String lang;
  final String zone;
  final String bearing;
  final String state;
  final String district;

  const ZonePrayerTimes({
    required this.hijri,
    required this.date,
    required this.day,
    required this.fajr,
    required this.syuruk,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.status,
    required this.serverTime,
    required this.periodType,
    required this.lang,
    required this.zone,
    required this.bearing,
    required this.state,
    required this.district,
  });

  factory ZonePrayerTimes.fromJson(Map<String, dynamic> json) {
    final prayerTime = json['prayerTime'] ?? {};
    return ZonePrayerTimes(
      hijri: prayerTime['hijri'] ?? '',
      date: prayerTime['date'] ?? '',
      day: prayerTime['day'] ?? '',
      fajr: prayerTime['fajr'] ?? '',
      syuruk: prayerTime['syuruk'] ?? '',
      dhuhr: prayerTime['dhuhr'] ?? '',
      asr: prayerTime['asr'] ?? '',
      maghrib: prayerTime['maghrib'] ?? '',
      isha: prayerTime['isha'] ?? '',
      status: json['status'] ?? '',
      serverTime: json['serverTime'] ?? '',
      periodType: json['periodType'] ?? '',
      lang: json['lang'] ?? '',
      zone: json['zone'] ?? '',
      bearing: json['bearing'] ?? '',
      state: '', // Will be set when creating from zone info
      district: '', // Will be set when creating from zone info
    );
  }

  // Create from zone info and prayer times
  factory ZonePrayerTimes.fromZoneAndPrayerTimes(ZoneInfo zoneInfo, Map<String, dynamic> prayerTimeJson) {
    final prayerTime = prayerTimeJson['prayerTime'] ?? {};
    return ZonePrayerTimes(
      hijri: prayerTime['hijri'] ?? '',
      date: prayerTime['date'] ?? '',
      day: prayerTime['day'] ?? '',
      fajr: prayerTime['fajr'] ?? '',
      syuruk: prayerTime['syuruk'] ?? '',
      dhuhr: prayerTime['dhuhr'] ?? '',
      asr: prayerTime['asr'] ?? '',
      maghrib: prayerTime['maghrib'] ?? '',
      isha: prayerTime['isha'] ?? '',
      status: prayerTimeJson['status'] ?? '',
      serverTime: prayerTimeJson['serverTime'] ?? '',
      periodType: prayerTimeJson['periodType'] ?? '',
      lang: prayerTimeJson['lang'] ?? '',
      zone: prayerTimeJson['zone'] ?? '',
      bearing: prayerTimeJson['bearing'] ?? '',
      state: zoneInfo.state,
      district: zoneInfo.district,
    );
  }

  // Convert to the existing PrayerTimes format for compatibility
  PrayerTimes toPrayerTimes() {
    return PrayerTimes(
      fajr: fajr,
      sunrise: syuruk,
      dhuhr: dhuhr,
      asr: asr,
      maghrib: maghrib,
      isha: isha,
    );
  }

  // Convert to HijriDate format for compatibility
  HijriDate toHijriDate() {
    final hijriParts = hijri.split('-');
    final day = hijriParts.length > 2 ? hijriParts[2] : '';
    final month = hijriParts.length > 1 ? hijriParts[1] : '';
    final year = hijriParts.isNotEmpty ? hijriParts[0] : '';
    
    return HijriDate(
      hijriDate: day,
      hijriMonth: _getHijriMonthName(month),
      hijriYear: year,
      gregorianDate: date,
    );
  }

  String _getHijriMonthName(String monthNumber) {
    const months = [
      'Muharram', 'Safar', 'Rabi al-Awwal', 'Rabi al-Thani',
      'Jumada al-Awwal', 'Jumada al-Thani', 'Rajab', 'Sha\'ban',
      'Ramadan', 'Shawwal', 'Dhu al-Qadah', 'Dhu al-Hijjah'
    ];
    
    final monthIndex = int.tryParse(monthNumber) ?? 1;
    return months[monthIndex - 1];
  }

  Map<String, dynamic> toJson() {
    return {
      'prayerTime': {
        'hijri': hijri,
        'date': date,
        'day': day,
        'fajr': fajr,
        'syuruk': syuruk,
        'dhuhr': dhuhr,
        'asr': asr,
        'maghrib': maghrib,
        'isha': isha,
      },
      'status': status,
      'serverTime': serverTime,
      'periodType': periodType,
      'lang': lang,
      'zone': zone,
      'bearing': bearing,
    };
  }

  @override
  String toString() {
    return 'ZonePrayerTimes(hijri: $hijri, date: $date, day: $day, fajr: $fajr, syuruk: $syuruk, dhuhr: $dhuhr, asr: $asr, maghrib: $maghrib, isha: $isha, zone: $zone, state: $state, district: $district)';
  }
} 