import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../repository/prayer_times_repository.dart';
import 'adhan_audio_service.dart';

class ScheduledAlarmService {
  static final ScheduledAlarmService _instance = ScheduledAlarmService._internal();
  factory ScheduledAlarmService() => _instance;
  ScheduledAlarmService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final AdhanAudioService _adhanAudioService = AdhanAudioService();
  final PrayerTimesRepository _prayerTimesRepository = PrayerTimesRepository();
  bool _isInitialized = false;
  bool _alarmEnabled = true;
  Set<String> _enabledPrayers = {'Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'};
  Timer? _prayerCheckTimer;

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
        onDidReceiveBackgroundNotificationResponse: _onNotificationTapped,
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

      // Schedule all prayer notifications for today
      await _scheduleTodayPrayers();
      
      // Start timer to check prayer times and auto-play azan
      _startPrayerTimeChecker();

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

  // Schedule all prayer notifications for today
  Future<void> _scheduleTodayPrayers() async {
    if (!_alarmEnabled) return;

    try {
      // Cancel existing notifications
      await _notifications.cancelAll();

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Get real prayer times from API
      final timestamp = DateTime.now().toIso8601String();
      if (kDebugMode) {
      }
      
      final prayerTimesData = await _prayerTimesRepository.getCurrentPrayerTimes('Kuala Lumpur', 'Kuala Lumpur');
      final prayerTimes = prayerTimesData.prayerTimes;

      if (kDebugMode) {
      }

      // Convert prayer time strings to DateTime objects
      final prayerTimesMap = {
        'Fajr': _parsePrayerTime(prayerTimes.fajr, today),
        'Dhuhr': _parsePrayerTime(prayerTimes.dhuhr, today),
        'Asr': _parsePrayerTime(prayerTimes.asr, today),
        'Maghrib': _parsePrayerTime(prayerTimes.maghrib, today),
        'Isha': _parsePrayerTime(prayerTimes.isha, today),
      };

      for (String prayerName in _enabledPrayers) {
        final prayerTime = prayerTimesMap[prayerName];
        if (prayerTime != null && prayerTime.isAfter(now)) {
          await _schedulePrayerNotification(prayerName, prayerTime);
        }
      }

      // Schedule tomorrow's prayers at midnight
      final tomorrow = today.add(const Duration(days: 1));
      final midnight = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 0, 0);
      
      await _notifications.zonedSchedule(
        9999, // Special ID for rescheduling
        'Reschedule Prayers',
        'Scheduling tomorrow\'s prayers',
        tz.TZDateTime.from(midnight, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'adhan_channel',
            'Azan Notifications',
            channelDescription: 'Notifications for prayer times and adhan',
            importance: Importance.min,
            priority: Priority.min,
            silent: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'reschedule',
      );

      final endTimestamp = DateTime.now().toIso8601String();
      if (kDebugMode) {
      }
    } catch (e, stackTrace) {
      final errorTimestamp = DateTime.now().toIso8601String();
      if (kDebugMode) {
      }
    }
  }

  // Schedule individual prayer notification
  Future<void> _schedulePrayerNotification(String prayerName, DateTime prayerTime) async {
    try {
      final prayerDisplayName = _getPrayerDisplayName(prayerName);
      final notificationId = prayerName.hashCode;
      final timestamp = DateTime.now().toIso8601String();
      
      // Store prayer info in SharedPreferences for automatic playback
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('scheduled_prayer_$notificationId', prayerName);
      await prefs.setInt('scheduled_prayer_time_$notificationId', prayerTime.millisecondsSinceEpoch);
      
      if (kDebugMode) {
      }
      
      // Convert to timezone-aware datetime
      final scheduledTz = tz.TZDateTime.from(prayerTime, tz.local);
      
      await _notifications.zonedSchedule(
        notificationId,
        'Waktu $prayerDisplayName',
        'Azan akan dimainkan sekarang',
        scheduledTz,
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
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'adhan_$prayerName',
      );

      if (kDebugMode) {
      }
    } catch (e) {
      final errorTimestamp = DateTime.now().toIso8601String();
      if (kDebugMode) {
      }
    }
  }

  // Handle notification tap or background notification
  void _onNotificationTapped(NotificationResponse response) {
    final timestamp = DateTime.now().toIso8601String();
    final payload = response.payload ?? '';
    
    if (kDebugMode) {
    }
    
    if (payload == 'reschedule') {
      // Reschedule tomorrow's prayers
      if (kDebugMode) {
      }
      _scheduleTodayPrayers();
    } else if (payload.startsWith('adhan_')) {
      // Play adhan audio when notification is tapped or received
      final prayerName = payload.substring(6);
      if (kDebugMode) {
      }
      _adhanAudioService.playAdhanForPrayer(prayerName);
    } else if (payload.startsWith('test_adhan_')) {
      // Test notification
      final prayerName = payload.substring(11);
      if (kDebugMode) {
      }
      _adhanAudioService.playAdhanForPrayer(prayerName);
    } else if (payload.startsWith('test_scheduled_')) {
      // Test scheduled notification
      final prayerName = payload.substring(15);
      if (kDebugMode) {
      }
      _adhanAudioService.playAdhanForPrayer(prayerName);
    }
  }
  
  // Start timer to periodically check prayer times and auto-play azan
  void _startPrayerTimeChecker() {
    // Check every 30 seconds for prayer times
    _prayerCheckTimer?.cancel();
    _prayerCheckTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkAndPlayAzanForCurrentTime();
    });
    
    // Also check immediately
    _checkAndPlayAzanForCurrentTime();
    
    if (kDebugMode) {
      final timestamp = DateTime.now().toIso8601String();
    }
  }
  
  // Check and play azan for any prayer time that just passed
  Future<void> _checkAndPlayAzanForCurrentTime() async {
    if (!_alarmEnabled) return;
    
    try {
      final now = DateTime.now();
      final timestamp = now.toIso8601String();
      
      // Get all scheduled prayer notifications
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      
      for (String key in allKeys) {
        if (key.startsWith('scheduled_prayer_') && !key.endsWith('_time')) {
          final notificationIdStr = key.replaceFirst('scheduled_prayer_', '');
          final prayerName = prefs.getString(key);
          final prayerTimeMs = prefs.getInt('scheduled_prayer_time_$notificationIdStr');
          
          if (prayerName != null && prayerTimeMs != null) {
            final prayerTime = DateTime.fromMillisecondsSinceEpoch(prayerTimeMs);
            final timeDiff = now.difference(prayerTime).inMinutes;
            
            // If prayer time was 0-2 minutes ago, play azan
            if (timeDiff >= 0 && timeDiff <= 2) {
              // Check if we already played for this prayer today
              final lastPlayedKey = 'last_played_${prayerName}_${now.year}_${now.month}_${now.day}';
              final lastPlayed = prefs.getBool(lastPlayedKey) ?? false;
              
              if (!lastPlayed) {
                if (kDebugMode) {
                }
                await _adhanAudioService.playAdhanForPrayer(prayerName);
                await prefs.setBool(lastPlayedKey, true);
              }
            }
          }
        }
      }
    } catch (e) {
      final errorTimestamp = DateTime.now().toIso8601String();
      if (kDebugMode) {
      }
    }
  }

  // Parse prayer time string (HH:MM) to DateTime
  DateTime _parsePrayerTime(String timeString, DateTime baseDate) {
    try {
      final parts = timeString.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return DateTime(baseDate.year, baseDate.month, baseDate.day, hour, minute);
    } catch (e) {
      if (kDebugMode) {
      }
      // Fallback to a default time if parsing fails
      return DateTime(baseDate.year, baseDate.month, baseDate.day, 12, 0);
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

  // Enable/disable prayer alarm
  Future<void> setAlarmEnabled(bool enabled) async {
    _alarmEnabled = enabled;
    await _savePreferences();
    
    if (enabled) {
      await _scheduleTodayPrayers();
    } else {
      await _notifications.cancelAll();
    }
    
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
    
    // Reschedule all prayers
    await _scheduleTodayPrayers();
    
    if (kDebugMode) {
    }
  }

  // Test adhan for specific prayer
  Future<void> testAdhan(String prayerName) async {
    final prayerDisplayName = _getPrayerDisplayName(prayerName);
    final timestamp = DateTime.now().toIso8601String();
    
    if (kDebugMode) {
    }
    
    // Show notification first, then play audio
    try {
      await _notifications.show(
        prayerName.hashCode + 1000, // Different ID to avoid conflicts
        'Uji - Waktu $prayerDisplayName',
        'Azan sedang dimainkan sekarang',
        NotificationDetails(
          android: AndroidNotificationDetails(
            'adhan_channel',
            'Azan Notifications',
            channelDescription: 'Notifications for prayer times and adhan',
            importance: Importance.max,
            priority: Priority.high,
            playSound: false, // Don't play sound from notification since we're playing full azan
            enableVibration: true,
            showWhen: true,
            icon: '@mipmap/ic_launcher',
            fullScreenIntent: true,
            category: AndroidNotificationCategory.alarm,
            autoCancel: false, // Keep notification visible during test
            visibility: NotificationVisibility.public,
            ongoing: false,
            enableLights: true,
            ledColor: const Color(0xFF4CAF50), // Green for test
            ledOnMs: 1000,
            ledOffMs: 500,
            ticker: 'Uji Azan - $prayerDisplayName',
            largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: false, // Don't play sound from notification since we're playing full azan
            interruptionLevel: InterruptionLevel.active,
          ),
        ),
        payload: 'test_adhan_$prayerName',
      );
      
      if (kDebugMode) {
      }
    } catch (e) {
      if (kDebugMode) {
      }
    }
    
    // Small delay to ensure notification appears before audio
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Play the adhan audio
    await _adhanAudioService.playAdhanForPrayer(prayerName);
    
    if (kDebugMode) {
    }
  }

  // Schedule test notification for next minute
  Future<void> scheduleTestInNextMinute(String prayerName) async {
    try {
      final now = DateTime.now();
      final nextMinute = now.add(const Duration(minutes: 1));
      final prayerDisplayName = _getPrayerDisplayName(prayerName);
      
      // Use a special test ID
      final testId = 8888 + prayerName.hashCode;
      
      if (kDebugMode) {
      }
      
      // Convert to timezone-aware datetime
      final scheduledTz = tz.TZDateTime.from(nextMinute, tz.local);
      
      await _notifications.zonedSchedule(
        testId,
        'TEST - Waktu $prayerDisplayName',
        'Azan akan dimainkan sekarang (Test in 1 minute)',
        scheduledTz,
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
            ticker: 'Test Azan notification',
            largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: prayerName.toLowerCase() == 'fajr' ? 'azan_fajr.mp3' : 'azan.mp3',
            interruptionLevel: InterruptionLevel.critical,
            threadIdentifier: 'test_adhan_notifications',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'test_scheduled_$prayerName',
      );
      
      if (kDebugMode) {
      }
    } catch (e) {
      if (kDebugMode) {
      }
      rethrow;
    }
  }

  // Get current settings
  bool get isAlarmEnabled => _alarmEnabled;
  Set<String> get enabledPrayers => Set.from(_enabledPrayers);

  // Get scheduled notifications (for debugging)
  Future<List<PendingNotificationRequest>> getScheduledNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  // Dispose resources
  void dispose() {
    _prayerCheckTimer?.cancel();
    _prayerCheckTimer = null;
    _adhanAudioService.dispose();
    _isInitialized = false;
  }
}
