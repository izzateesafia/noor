import 'package:geolocator/geolocator.dart';
import '../repository/prayer_times_repository.dart';

class LocationService {
  final PrayerTimesRepository _prayerTimesRepository = PrayerTimesRepository();

  /// Request location permission and get current position
  Future<Position?> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return position;
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  /// Get location name from coordinates using prayer times repository
  Future<String?> getLocationName(double latitude, double longitude) async {
    try {
      final zoneInfo = await _prayerTimesRepository.getZoneFromCoordinates(latitude, longitude);
      return '${zoneInfo.district}, ${zoneInfo.state}';
    } catch (e) {
      print('Error getting location name: $e');
      return null;
    }
  }
}

