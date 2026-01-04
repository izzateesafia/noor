import 'package:flutter/services.dart';
import 'dart:io' show Platform;
import '../models/prayer_times.dart';

class WidgetDataService {
  static const MethodChannel _channel = MethodChannel('com.hexahelix.dq/widget');
  
  /// Updates prayer times data for lock screen widgets
  /// This will update both iOS and Android widgets
  static Future<void> updatePrayerTimes({
    required PrayerTimes prayerTimes,
    required String nextPrayer,
    String? location,
  }) async {
    try {
      // Format times for display (remove seconds if present)
      String formatTime(String time) {
        if (time.contains(':')) {
          final parts = time.split(':');
          if (parts.length >= 2) {
            return '${parts[0]}:${parts[1]}';
          }
        }
        return time;
      }

      await _channel.invokeMethod('updatePrayerTimes', {
        'fajr': formatTime(prayerTimes.fajr),
        'dhuhr': formatTime(prayerTimes.dhuhr),
        'asr': formatTime(prayerTimes.asr),
        'maghrib': formatTime(prayerTimes.maghrib),
        'isha': formatTime(prayerTimes.isha),
        'nextPrayer': nextPrayer,
        'location': location ?? '',
      });
    } catch (e) {
      // Don't throw - widget updates are non-critical
    }
  }

  /// Gets the next prayer name based on current time
  static String getNextPrayer(PrayerTimes prayerTimes) {
    final now = DateTime.now();
    final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    
    final prayers = [
      {'name': 'Fajr', 'time': prayerTimes.fajr, 'displayName': 'Subuh'},
      {'name': 'Dhuhr', 'time': prayerTimes.dhuhr, 'displayName': 'Zuhur'},
      {'name': 'Asr', 'time': prayerTimes.asr, 'displayName': 'Asar'},
      {'name': 'Maghrib', 'time': prayerTimes.maghrib, 'displayName': 'Maghrib'},
      {'name': 'Isha', 'time': prayerTimes.isha, 'displayName': 'Isya'},
    ];

    for (var prayer in prayers) {
      if (prayer['time']!.compareTo(currentTime) > 0) {
        return prayer['displayName']!;
      }
    }
    return 'Subuh'; // Default to Subuh if all prayers have passed
  }
}


