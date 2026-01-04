import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/prayer_times.dart';

class PrayerTimesRepository {
  static const String baseUrl = 'https://api.waktusolat.app';

  // Get zone information from coordinates
  Future<ZoneInfo> getZoneFromCoordinates(double latitude, double longitude) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/zones/$latitude/$longitude'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ZoneInfo.fromJson(data);
      } else {
        throw Exception('Failed to get zone info: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting zone info: $e');
    }
  }

  // Get prayer times for a specific zone and day
  Future<ZonePrayerTimes> getPrayerTimesByZone(String zone, int day) async {
    try {
      final now = DateTime.now();
      final year = now.year;
      final month = now.month;
      
      final response = await http.get(
        Uri.parse('$baseUrl/solat/$zone/$day?year=$year&month=$month'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Note: This will create ZonePrayerTimes without state/district
        // Use getTodayPrayerTimesByCoordinates instead for complete data
        return ZonePrayerTimes.fromJson(data);
      } else {
        throw Exception('Failed to get prayer times: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting prayer times: $e');
    }
  }

  // Get prayer times for today using coordinates
  Future<ZonePrayerTimes> getTodayPrayerTimesByCoordinates(double latitude, double longitude) async {
    try {
      // First get the zone from coordinates
      final zoneInfo = await getZoneFromCoordinates(latitude, longitude);
      
      // Then get today's prayer times for that zone
      final today = DateTime.now().day;
      final now = DateTime.now();
      final year = now.year;
      final month = now.month;
      
      final response = await http.get(
        Uri.parse('$baseUrl/solat/${zoneInfo.zone}/$today?year=$year&month=$month'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Create ZonePrayerTimes with state and district from zone info
        return ZonePrayerTimes.fromZoneAndPrayerTimes(zoneInfo, data);
      } else {
        throw Exception('Failed to get prayer times: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting today\'s prayer times: $e');
    }
  }

  // Get prayer times for a specific state and district using coordinates
  Future<PrayerTimes> getPrayerTimes(String state, String district) async {
    try {
      // Since the API doesn't support state/district directly, we need to use coordinates
      // For now, we'll use hardcoded coordinates for major cities
      // In the future, you could implement a geocoding service to convert state/district to coordinates
      
      final coordinates = _getCoordinatesForLocation(state, district);
      if (coordinates == null) {
        return _getFallbackPrayerTimes();
      }
      
      
      // First get the zone from coordinates
      final zoneInfo = await getZoneFromCoordinates(coordinates['lat']!, coordinates['lng']!);
      
      // Then get today's prayer times for that zone
      final today = DateTime.now().day;
      final now = DateTime.now();
      final year = now.year;
      final month = now.month;
      
      final response = await http.get(
        Uri.parse('$baseUrl/solat/${zoneInfo.zone}/$today?year=$year&month=$month'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Convert the API response to our PrayerTimes model
        return _convertApiResponseToPrayerTimes(data);
      } else {
        return _getFallbackPrayerTimes();
      }
    } catch (e) {
      return _getFallbackPrayerTimes();
    }
  }

  // Helper method to get coordinates for major Malaysian cities
  Map<String, double>? _getCoordinatesForLocation(String state, String district) {
    // Hardcoded coordinates for major Malaysian cities
    // You can expand this list or implement a proper geocoding service
    final coordinates = {
      'Kuala Lumpur': {'lat': 3.1390, 'lng': 101.6869},
      'Petaling Jaya': {'lat': 3.068498, 'lng': 101.630263},
      'Shah Alam': {'lat': 3.0738, 'lng': 101.5183},
      'Subang Jaya': {'lat': 3.0569, 'lng': 101.5855},
      'Klang': {'lat': 3.0449, 'lng': 101.4455},
      'Johor Bahru': {'lat': 1.4927, 'lng': 103.7414},
      'George Town': {'lat': 5.4164, 'lng': 100.3327},
      'Ipoh': {'lat': 4.5979, 'lng': 101.0901},
      'Seremban': {'lat': 2.7297, 'lng': 101.9421},
      'Melaka': {'lat': 2.1896, 'lng': 102.2501},
      'Kuantan': {'lat': 3.8167, 'lng': 103.3259},
      'Kuala Terengganu': {'lat': 5.3296, 'lng': 103.1370},
      'Kota Bharu': {'lat': 6.1355, 'lng': 102.2387},
      'Alor Setar': {'lat': 6.1185, 'lng': 100.3685},
      'Kangar': {'lat': 6.4414, 'lng': 100.1986},
      'Kota Kinabalu': {'lat': 5.9804, 'lng': 116.0735},
      'Kuching': {'lat': 1.5495, 'lng': 110.3594},
    };
    
    // Try to find exact match first
    if (coordinates.containsKey(district)) {
      return coordinates[district]!;
    }
    
    // If no exact match, try to find by state
    if (coordinates.containsKey(state)) {
      return coordinates[state]!;
    }
    
    // If still no match, return null to use fallback
    return null;
  }

  // Helper method to convert API response to PrayerTimes model
  PrayerTimes _convertApiResponseToPrayerTimes(Map<String, dynamic> data) {
    try {
      // The API response structure is:
      // {"prayerTime":{"hijri":"1446-07-01","date":"01-Jan-2025","day":"Wednesday","fajr":"06:07:00","syuruk":"07:18:00","dhuhr":"13:20:00","asr":"16:42:00","maghrib":"19:17:00","isha":"20:31:00"},"status":"OK!","serverTime":"2025-09-01 07:45:05","periodType":"day","lang":"","zone":"WLY01","bearing":""}
      
      final prayerTime = data['prayerTime'] as Map<String, dynamic>?;
      if (prayerTime == null) {
        return _getFallbackPrayerTimes();
      }
      
      // Extract prayer times from the prayerTime object
      // Note: API returns times with seconds (e.g., "06:07:00"), we need to remove seconds
      String formatTime(String timeWithSeconds) {
        if (timeWithSeconds.contains(':')) {
          final parts = timeWithSeconds.split(':');
          if (parts.length >= 2) {
            return '${parts[0]}:${parts[1]}';
          }
        }
        return timeWithSeconds;
      }
      
      return PrayerTimes(
        fajr: formatTime(prayerTime['fajr'] ?? '05:37'),
        sunrise: formatTime(prayerTime['syuruk'] ?? '06:42'),
        dhuhr: formatTime(prayerTime['dhuhr'] ?? '12:10'),
        asr: formatTime(prayerTime['asr'] ?? '15:16'),
        maghrib: formatTime(prayerTime['maghrib'] ?? '17:38'),
        isha: formatTime(prayerTime['isha'] ?? '18:43'),
      );
    } catch (e) {
      return _getFallbackPrayerTimes();
    }
  }

  PrayerTimes _getFallbackPrayerTimes() {
    // Return fallback prayer times for Kuala Lumpur
    return const PrayerTimes(
      fajr: '05:37',
      sunrise: '06:42',
      dhuhr: '12:10',
      asr: '15:16',
      maghrib: '17:38',
      isha: '18:43',
    );
  }

  Future<double> getQiblaDirection(double latitude, double longitude) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/v1/qibla?lat=$latitude&lng=$longitude'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['qibla_direction']?.toDouble() ?? 0.0;
      } else {
        return 0.0; // Return default direction if API fails
      }
    } catch (e) {
      return 0.0; // Return default direction if any error
    }
  }

  Future<HijriDate> getHijriDate() async {
    try {
      // Get Hijri date from prayer times API (it's included in the response)
      // Use default zone (WLY01 - Kuala Lumpur) to get today's date
      final now = DateTime.now();
      final today = now.day;
      final year = now.year;
      final month = now.month;
      
      // Use default zone for getting Hijri date
      final response = await http.get(
        Uri.parse('$baseUrl/solat/WLY01/$today?year=$year&month=$month'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final prayerTime = data['prayerTime'] ?? {};
        final hijriString = prayerTime['hijri'] ?? '';
        final gregorianDate = prayerTime['date'] ?? '';
        
        if (hijriString.isNotEmpty) {
          // Parse Hijri date from format "YYYY-MM-DD"
          final hijriParts = hijriString.split('-');
          final day = hijriParts.length > 2 ? hijriParts[2] : '';
          final monthNum = hijriParts.length > 1 ? hijriParts[1] : '';
          final year = hijriParts.isNotEmpty ? hijriParts[0] : '';
          
          // Convert month number to month name
          final monthNames = [
            'Muharram', 'Safar', 'Rabi\' Al-Awwal', 'Rabi\' Al-Thani',
            'Muharram', 'Safar', 'Rabiulawal', 'Rabiulakhir',
            'Jamadilawal', 'Jamadilakhir', 'Rejab', 'Syaaban',
            'Ramadan', 'Syawal', 'Zulkaedah', 'Zulhijjah'
          ];
          final monthIndex = int.tryParse(monthNum) ?? 1;
          final monthName = monthNames[monthIndex - 1];
          
          return HijriDate(
            hijriDate: day,
            hijriMonth: monthName,
            hijriYear: year,
            gregorianDate: gregorianDate,
          );
        }
      }
      
      // Return fallback Hijri date if API fails
      return _getFallbackHijriDate();
    } catch (e) {
      // Return fallback Hijri date if any error
      return _getFallbackHijriDate();
    }
  }

  HijriDate _getFallbackHijriDate() {
    final now = DateTime.now();
    return HijriDate(
      hijriDate: '15',
      hijriMonth: 'Jumada Al-Awwal',
      hijriYear: '1445',
      gregorianDate: '${now.day} ${_getMonthName(now.month)} ${now.year}',
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  Future<List<String>> getStates() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/v1/states'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<String>.from(data['states'] ?? []);
      } else {
        // Return fallback states
        return ['Kuala Lumpur', 'Selangor', 'Johor', 'Penang', 'Perak'];
      }
    } catch (e) {
      // Return fallback states if any error
      return ['Kuala Lumpur', 'Selangor', 'Johor', 'Penang', 'Perak'];
    }
  }

  Future<List<String>> getDistricts(String state) async {
    // Hardcoded districts for now - you can expand this
    switch (state) {
      case 'Kuala Lumpur':
        return ['Kuala Lumpur'];
      case 'Selangor':
        return ['Petaling', 'Shah Alam', 'Subang Jaya', 'Klang', 'Ampang'];
      case 'Johor':
        return ['Johor Bahru', 'Batu Pahat', 'Muar', 'Segamat'];
      case 'Penang':
        return ['George Town', 'Butterworth', 'Bayan Lepas'];
      case 'Perak':
        return ['Ipoh', 'Taiping', 'Teluk Intan'];
      default:
        return ['Main District'];
    }
  }

  Future<PrayerTimesData> getCurrentPrayerTimes(String state, String district) async {
    try {
      // Get prayer times - this method now uses the correct API endpoints
      final prayerTimes = await getPrayerTimes(state, district);
      
      // Create location
      final location = Location(state: state, district: district);
      
      // Try to get qibla direction, but don't fail if it doesn't work
      double? qiblaDirection;
      try {
        if (location.latitude != null && location.longitude != null) {
          qiblaDirection = await getQiblaDirection(location.latitude!, location.longitude!);
        }
      } catch (e) {
        // Ignore qibla direction errors
        qiblaDirection = 0.0;
      }

      // For now, we'll use the fallback Hijri date
      // In the future, we could extract it from the prayer times API response
      final hijriDate = _getFallbackHijriDate();

      return PrayerTimesData(
        prayerTimes: prayerTimes,
        hijriDate: hijriDate,
        location: location,
        qiblaDirection: qiblaDirection,
      );
    } catch (e) {
      // Ultimate fallback - return complete fallback data
      return PrayerTimesData(
        prayerTimes: _getFallbackPrayerTimes(),
        hijriDate: _getFallbackHijriDate(),
        location: Location(state: state, district: district),
        qiblaDirection: 0.0,
      );
    }
  }

  // New method to get prayer times using coordinates
  Future<PrayerTimesData> getCurrentPrayerTimesByCoordinates(double latitude, double longitude) async {
    try {
      // Get zone-based prayer times
      final zonePrayerTimes = await getTodayPrayerTimesByCoordinates(latitude, longitude);
      
      // Convert to existing format for compatibility
      final prayerTimes = zonePrayerTimes.toPrayerTimes();
      final hijriDate = zonePrayerTimes.toHijriDate();
      
      // Create location from zone info
      final location = Location(
        state: zonePrayerTimes.state,
        district: zonePrayerTimes.district,
        latitude: latitude,
        longitude: longitude,
      );
      
      // Try to get qibla direction
      double? qiblaDirection;
      try {
        qiblaDirection = await getQiblaDirection(latitude, longitude);
      } catch (e) {
        qiblaDirection = 0.0;
      }

      return PrayerTimesData(
        prayerTimes: prayerTimes,
        hijriDate: hijriDate,
        location: location,
        qiblaDirection: qiblaDirection,
      );
    } catch (e) {
      // Fallback to state/district method
      return getCurrentPrayerTimes('Kuala Lumpur', 'Kuala Lumpur');
    }
  }
} 