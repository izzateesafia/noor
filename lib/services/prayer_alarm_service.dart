import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import '../models/prayer_times.dart';
import '../repository/prayer_times_repository.dart';
import 'adhan_audio_service.dart';

class PrayerAlarmService {
  static const String _taskName = "prayerAlarmTask";
  static const String _channelName = "prayer_alarm_channel";
  static const String _alarmEnabledKey = "prayer_alarm_enabled";
  static const String _alarmVolumeKey = "prayer_alarm_volume";
  static const String _alarmPrayersKey = "prayer_alarm_prayers";
  
  static final PrayerAlarmService _instance = PrayerAlarmService._internal();
  factory PrayerAlarmService() => _instance;
  PrayerAlarmService._internal();

  final AdhanAudioService _adhanAudioService = AdhanAudioService();
  final PrayerTimesRepository _prayerTimesRepository = PrayerTimesRepository();
  Timer? _prayerCheckTimer;
  bool _isInitialized = false;
  bool _alarmEnabled = true;
  double _alarmVolume = 1.0;
  Set<String> _enabledPrayers = {'Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'};
  String? _lastPlayedPrayer;
  DateTime? _lastPlayedTime;

  /// Initialize the prayer alarm service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Initialize WorkManager for background tasks
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: kDebugMode,
      );
      
      // Load user preferences
      await _loadPreferences();
      
      // Start the prayer monitoring timer
      _startPrayerMonitoring();
      
      _isInitialized = true;
      
      if (kDebugMode) {
        print('PrayerAlarmService initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing PrayerAlarmService: $e');
      }
    }
  }

  /// Load user preferences from SharedPreferences
  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _alarmEnabled = prefs.getBool(_alarmEnabledKey) ?? true;
      _alarmVolume = prefs.getDouble(_alarmVolumeKey) ?? 1.0;
      
      final enabledPrayersList = prefs.getStringList(_alarmPrayersKey);
      if (enabledPrayersList != null) {
        _enabledPrayers = enabledPrayersList.toSet();
      }
      
      if (kDebugMode) {
        print('Loaded preferences - Enabled: $_alarmEnabled, Volume: $_alarmVolume, Prayers: $_enabledPrayers');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading preferences: $e');
      }
    }
  }

  /// Save user preferences to SharedPreferences
  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_alarmEnabledKey, _alarmEnabled);
      await prefs.setDouble(_alarmVolumeKey, _alarmVolume);
      await prefs.setStringList(_alarmPrayersKey, _enabledPrayers.toList());
      
      if (kDebugMode) {
        print('Preferences saved successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving preferences: $e');
      }
    }
  }

  /// Start monitoring prayer times
  void _startPrayerMonitoring() {
    // Check every 30 seconds for more accurate prayer time detection
    _prayerCheckTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkPrayerTimes();
    });
    
    // Also check immediately
    _checkPrayerTimes();
    
    if (kDebugMode) {
      final timestamp = DateTime.now().toIso8601String();
      print('[$timestamp] PrayerAlarmService: Prayer monitoring started (checks every 30 seconds)');
    }
  }

  /// Check if it's time for any prayer
  Future<void> _checkPrayerTimes() async {
    if (!_alarmEnabled) {
      if (kDebugMode) {
        final timestamp = DateTime.now().toIso8601String();
        print('[$timestamp] PrayerAlarmService: Alarm is disabled, skipping check');
      }
      return;
    }
    
    try {
      final timestamp = DateTime.now().toIso8601String();
      if (kDebugMode) {
        print('[$timestamp] PrayerAlarmService: Checking prayer times...');
      }
      
      // Get current prayer times
      final prayerTimesData = await _prayerTimesRepository.getCurrentPrayerTimes('Kuala Lumpur', 'Kuala Lumpur');
      final prayerTimes = prayerTimesData.prayerTimes;
      
      final now = DateTime.now();
      final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      
      if (kDebugMode) {
        print('[$timestamp] PrayerAlarmService: Current time: $currentTime');
        print('[$timestamp] PrayerAlarmService: Prayer times - Fajr: ${prayerTimes.fajr}, Dhuhr: ${prayerTimes.dhuhr}, Asr: ${prayerTimes.asr}, Maghrib: ${prayerTimes.maghrib}, Isha: ${prayerTimes.isha}');
      }
      
      // Check each prayer time
      final prayers = [
        {'name': 'Fajr', 'time': prayerTimes.fajr},
        {'name': 'Dhuhr', 'time': prayerTimes.dhuhr},
        {'name': 'Asr', 'time': prayerTimes.asr},
        {'name': 'Maghrib', 'time': prayerTimes.maghrib},
        {'name': 'Isha', 'time': prayerTimes.isha},
      ];
      
      for (var prayer in prayers) {
        final prayerName = prayer['name']!;
        final prayerTime = prayer['time']!;
        
        // Check if this prayer is enabled and it's time for it
        if (_enabledPrayers.contains(prayerName) && _isPrayerTime(currentTime, prayerTime)) {
          if (kDebugMode) {
            print('[$timestamp] PrayerAlarmService: 🕌 It is time for $prayerName ($prayerTime), playing azan...');
          }
          await _playAdhanForPrayer(prayerName);
        }
      }
    } catch (e, stackTrace) {
      final errorTimestamp = DateTime.now().toIso8601String();
      if (kDebugMode) {
        print('[$errorTimestamp] PrayerAlarmService: ❌ Error checking prayer times: $e');
        print('[$errorTimestamp] PrayerAlarmService: Stack trace: $stackTrace');
      }
    }
  }

  /// Check if current time matches prayer time (within 1 minute tolerance)
  bool _isPrayerTime(String currentTime, String prayerTime) {
    try {
      final current = _parseTime(currentTime);
      final prayer = _parseTime(prayerTime);
      
      // Check if we're within 1 minute of prayer time
      final difference = (current.hour * 60 + current.minute) - (prayer.hour * 60 + prayer.minute);
      
      // Play adhan if we're at prayer time (within 1 minute) and haven't played it recently
      if (difference >= 0 && difference <= 1) {
        final now = DateTime.now();
        final prayerDateTime = DateTime(now.year, now.month, now.day, prayer.hour, prayer.minute);
        
        // Don't play the same prayer multiple times in the same day
        if (_lastPlayedPrayer != prayerTime || 
            _lastPlayedTime == null || 
            !_isSameDay(_lastPlayedTime!, now)) {
          return true;
        }
      }
      
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing time: $e');
      }
      return false;
    }
  }

  /// Parse time string to DateTime
  DateTime _parseTime(String timeString) {
    final parts = timeString.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return DateTime(2024, 1, 1, hour, minute); // Use dummy date
  }

  /// Check if two dates are on the same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && 
           date1.month == date2.month && 
           date1.day == date2.day;
  }

  /// Play adhan for specific prayer
  Future<void> _playAdhanForPrayer(String prayerName) async {
    try {
      final timestamp = DateTime.now().toIso8601String();
      
      // Check if we already played for this prayer today
      final now = DateTime.now();
      final todayKey = '${prayerName}_${now.year}_${now.month}_${now.day}';
      
      // Update last played info
      if (_lastPlayedPrayer != prayerName || 
          _lastPlayedTime == null || 
          !_isSameDay(_lastPlayedTime!, now)) {
        
        _lastPlayedPrayer = prayerName;
        _lastPlayedTime = now;
        
        if (kDebugMode) {
          print('[$timestamp] PrayerAlarmService: 🕌 Playing azan for $prayerName');
        }
        
        // Play the adhan
        await _adhanAudioService.playAdhanForPrayer(prayerName);
        
        if (kDebugMode) {
          print('[$timestamp] PrayerAlarmService: ✅ Adhan played for $prayerName at ${now.toString()}');
        }
        
        // Show notification (optional)
        await _showPrayerNotification(prayerName);
      } else {
        if (kDebugMode) {
          print('[$timestamp] PrayerAlarmService: ⏭️ Skipping azan for $prayerName (already played today)');
        }
      }
      
    } catch (e, stackTrace) {
      final errorTimestamp = DateTime.now().toIso8601String();
      if (kDebugMode) {
        print('[$errorTimestamp] PrayerAlarmService: ❌ Error playing adhan for $prayerName: $e');
        print('[$errorTimestamp] PrayerAlarmService: Stack trace: $stackTrace');
      }
    }
  }

  /// Show prayer notification
  Future<void> _showPrayerNotification(String prayerName) async {
    try {
      // This would typically use flutter_local_notifications
      // For now, just log it
      if (kDebugMode) {
        print('Prayer notification: $prayerName time has arrived');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error showing prayer notification: $e');
      }
    }
  }

  /// Enable/disable prayer alarm
  Future<void> setAlarmEnabled(bool enabled) async {
    _alarmEnabled = enabled;
    await _savePreferences();
    
    if (kDebugMode) {
      print('Prayer alarm ${enabled ? 'enabled' : 'disabled'}');
    }
  }

  /// Set alarm volume
  Future<void> setAlarmVolume(double volume) async {
    _alarmVolume = volume.clamp(0.0, 1.0);
    await _savePreferences();
    
    if (kDebugMode) {
      print('Prayer alarm volume set to $_alarmVolume');
    }
  }

  /// Enable/disable specific prayers
  Future<void> setPrayerEnabled(String prayerName, bool enabled) async {
    if (enabled) {
      _enabledPrayers.add(prayerName);
    } else {
      _enabledPrayers.remove(prayerName);
    }
    await _savePreferences();
    
    if (kDebugMode) {
      print('Prayer $prayerName ${enabled ? 'enabled' : 'disabled'}');
    }
  }

  /// Test adhan for specific prayer
  Future<void> testAdhan(String prayerName) async {
    await _adhanAudioService.playAdhanForPrayer(prayerName);
  }

  /// Get current settings
  bool get isAlarmEnabled => _alarmEnabled;
  double get alarmVolume => _alarmVolume;
  Set<String> get enabledPrayers => Set.from(_enabledPrayers);

  /// Dispose resources
  void dispose() {
    _prayerCheckTimer?.cancel();
    _adhanAudioService.dispose();
    _isInitialized = false;
  }
}

/// Background task callback for WorkManager
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      if (task == PrayerAlarmService._taskName) {
        // This would run in the background
        // For now, we'll rely on the timer-based approach
        return Future.value(true);
      }
      return Future.value(false);
    } catch (e) {
      if (kDebugMode) {
        print('Background task error: $e');
      }
      return Future.value(false);
    }
  });
}
