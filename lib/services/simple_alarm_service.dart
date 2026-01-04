import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'adhan_audio_service.dart';

class SimpleAlarmService {
  static final SimpleAlarmService _instance = SimpleAlarmService._internal();
  factory SimpleAlarmService() => _instance;
  SimpleAlarmService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final AdhanAudioService _adhanAudioService = AdhanAudioService();
  Timer? _prayerCheckTimer;
  bool _isInitialized = false;
  bool _alarmEnabled = true;
  Set<String> _enabledPrayers = {'Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'};
  String? _lastPlayedPrayer;
  DateTime? _lastPlayedTime;

  // Initialize the alarm service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize timezone data
      tz.initializeTimeZones();
      
      // Initialize notifications
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      
      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _notifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Request notification permissions
      await _requestPermissions();

      // Create adhan notification channel
      const AndroidNotificationChannel adhanChannel = AndroidNotificationChannel(
        'adhan_channel',
        'Azan Notifications',
        description: 'Notifications for prayer times and adhan',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );

      await _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(adhanChannel);

      // Load user preferences
      await _loadPreferences();

      // Start the prayer monitoring timer
      _startPrayerMonitoring();

      _isInitialized = true;

      if (kDebugMode) {
      }
    } catch (e) {
      if (kDebugMode) {
      }
    }
  }

  // Load user preferences
  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _alarmEnabled = prefs.getBool('prayer_alarm_enabled') ?? true;
      
      final enabledPrayersList = prefs.getStringList('prayer_alarm_prayers');
      if (enabledPrayersList != null) {
        _enabledPrayers = enabledPrayersList.toSet();
      }
      
      if (kDebugMode) {
      }
    } catch (e) {
      if (kDebugMode) {
      }
    }
  }

  // Save user preferences
  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('prayer_alarm_enabled', _alarmEnabled);
      await prefs.setStringList('prayer_alarm_prayers', _enabledPrayers.toList());
      
      if (kDebugMode) {
      }
    } catch (e) {
      if (kDebugMode) {
      }
    }
  }

  // Request notification permissions
  Future<void> _requestPermissions() async {
    try {
      // Request Android permissions
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin != null) {
        final granted = await androidPlugin.requestNotificationsPermission();
        if (kDebugMode) {
        }
      }
      
      // Request iOS permissions
      final iosPlugin = _notifications
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      
      if (iosPlugin != null) {
        final granted = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        if (kDebugMode) {
        }
      }
    } catch (e) {
      if (kDebugMode) {
      }
    }
  }

  // Start monitoring prayer times
  void _startPrayerMonitoring() {
    // Check every 30 seconds for prayer times (more frequent for testing)
    _prayerCheckTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkPrayerTimes();
    });
    
    // Also check immediately
    _checkPrayerTimes();
    
    if (kDebugMode) {
    }
  }

  // Check if it's time for any prayer
  Future<void> _checkPrayerTimes() async {
    if (!_alarmEnabled) return;
    
    try {
      final now = DateTime.now();
      final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      
      // For testing, let's use hardcoded prayer times
      final prayers = [
        {'name': 'Fajr', 'time': '05:30'},
        {'name': 'Dhuhr', 'time': '12:30'},
        {'name': 'Asr', 'time': '15:45'},
        {'name': 'Maghrib', 'time': '18:30'},
        {'name': 'Isha', 'time': '20:00'},
      ];
      
      for (var prayer in prayers) {
        final prayerName = prayer['name']!;
        final prayerTime = prayer['time']!;
        
        // Check if this prayer is enabled and it's time for it
        if (_enabledPrayers.contains(prayerName) && _isPrayerTime(currentTime, prayerTime)) {
          await _playAdhanForPrayer(prayerName);
        }
      }
    } catch (e) {
      if (kDebugMode) {
      }
    }
  }

  // Check if current time matches prayer time (within 1 minute tolerance)
  bool _isPrayerTime(String currentTime, String prayerTime) {
    try {
      final current = _parseTime(currentTime);
      final prayer = _parseTime(prayerTime);
      
      // Check if we're within 1 minute of prayer time
      final difference = (current.hour * 60 + current.minute) - (prayer.hour * 60 + prayer.minute);
      
      // Play adhan if we're at prayer time (within 1 minute) and haven't played it recently
      if (difference >= 0 && difference <= 1) {
        final now = DateTime.now();
        
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
      }
      return false;
    }
  }

  // Parse time string to DateTime
  DateTime _parseTime(String timeString) {
    final parts = timeString.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return DateTime(2024, 1, 1, hour, minute); // Use dummy date
  }

  // Check if two dates are on the same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && 
           date1.month == date2.month && 
           date1.day == date2.day;
  }

  // Play adhan for specific prayer
  Future<void> _playAdhanForPrayer(String prayerName) async {
    try {
      // Update last played info
      _lastPlayedPrayer = prayerName;
      _lastPlayedTime = DateTime.now();
      
      // Play the adhan
      await _adhanAudioService.playAdhanForPrayer(prayerName);
      
      // Show notification
      await _showPrayerNotification(prayerName);
      
      if (kDebugMode) {
      }
      
    } catch (e) {
      if (kDebugMode) {
      }
    }
  }

  // Show prayer notification
  Future<void> _showPrayerNotification(String prayerName) async {
    try {
      final prayerDisplayName = _getPrayerDisplayName(prayerName);
      
      // Create notification ID based on current time to ensure uniqueness
      final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      if (kDebugMode) {
      }
      
      await _notifications.show(
        notificationId,
        'Waktu $prayerDisplayName',
        'Azan akan dimainkan sekarang',
        NotificationDetails(
          android: AndroidNotificationDetails(
            'adhan_channel',
            'Azan Notifications',
            channelDescription: 'Notifications for prayer times and adhan',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            showWhen: true,
            icon: '@mipmap/ic_launcher',
            sound: RawResourceAndroidNotificationSound(
              prayerName.toLowerCase() == 'fajr' ? 'azan_fajr' : 'azan'
            ),
            fullScreenIntent: true,
            category: AndroidNotificationCategory.alarm,
            autoCancel: true,
            visibility: NotificationVisibility.public,
            ongoing: false,
            silent: false,
            enableLights: true,
            ledColor: const Color(0xFFD32F2F),
            ledOnMs: 1000,
            ledOffMs: 500,
            // Additional settings for better visibility
            ticker: 'Azan notification',
            largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: prayerName.toLowerCase() == 'fajr' ? 'azan_fajr.mp3' : 'azan.mp3',
            interruptionLevel: InterruptionLevel.critical,
            threadIdentifier: 'adhan_notifications',
          ),
        ),
        payload: 'adhan_$prayerName',
      );
      
      if (kDebugMode) {
      }
    } catch (e) {
      if (kDebugMode) {
      }
    }
  }

  // Get prayer display name
  String _getPrayerDisplayName(String prayerName) {
    switch (prayerName) {
      case 'Fajr':
        return 'Subuh';
      case 'Dhuhr':
        return 'Zuhur';
      case 'Asr':
        return 'Asar';
      case 'Maghrib':
        return 'Maghrib';
      case 'Isha':
        return 'Isya';
      default:
        return prayerName;
    }
  }

  // Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    if (kDebugMode) {
    }
  }

  // Enable/disable prayer alarm
  Future<void> setAlarmEnabled(bool enabled) async {
    _alarmEnabled = enabled;
    await _savePreferences();
    
    if (kDebugMode) {
    }
  }

  // Enable/disable specific prayers
  Future<void> setPrayerEnabled(String prayerName, bool enabled) async {
    if (enabled) {
      _enabledPrayers.add(prayerName);
    } else {
      _enabledPrayers.remove(prayerName);
    }
    await _savePreferences();
    
    if (kDebugMode) {
    }
  }

  // Test adhan for specific prayer
  Future<void> testAdhan(String prayerName) async {
    await _adhanAudioService.playAdhanForPrayer(prayerName);
    await _showPrayerNotification(prayerName);
  }

  // Get current settings
  bool get isAlarmEnabled => _alarmEnabled;
  Set<String> get enabledPrayers => Set.from(_enabledPrayers);

  // Dispose resources
  void dispose() {
    _prayerCheckTimer?.cancel();
    _adhanAudioService.dispose();
    _isInitialized = false;
  }
}
