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

      // Schedule all prayer notifications for today
      await _scheduleTodayPrayers();

      _isInitialized = true;

      if (kDebugMode) {
        print('ScheduledAlarmService initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing ScheduledAlarmService: $e');
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
        print('Loaded preferences - Enabled: $_alarmEnabled, Prayers: $_enabledPrayers');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading preferences: $e');
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
        print('Preferences saved successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving preferences: $e');
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
          print('Android notification permission granted: $granted');
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
          print('iOS notification permission granted: $granted');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error requesting permissions: $e');
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
      if (kDebugMode) {
        print('ScheduledAlarmService: Fetching prayer times from API...');
      }
      
      final prayerTimesData = await _prayerTimesRepository.getCurrentPrayerTimes('Kuala Lumpur', 'Kuala Lumpur');
      final prayerTimes = prayerTimesData.prayerTimes;

      if (kDebugMode) {
        print('ScheduledAlarmService: Got prayer times from API:');
        print('  Fajr: ${prayerTimes.fajr}');
        print('  Dhuhr: ${prayerTimes.dhuhr}');
        print('  Asr: ${prayerTimes.asr}');
        print('  Maghrib: ${prayerTimes.maghrib}');
        print('  Isha: ${prayerTimes.isha}');
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

      if (kDebugMode) {
        print('Scheduled ${_enabledPrayers.length} prayer notifications for today');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error scheduling prayers: $e');
      }
    }
  }

  // Schedule individual prayer notification
  Future<void> _schedulePrayerNotification(String prayerName, DateTime prayerTime) async {
    try {
      final prayerDisplayName = _getPrayerDisplayName(prayerName);
      final notificationId = prayerName.hashCode;
      
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
        print('Scheduled notification for $prayerDisplayName at ${prayerTime.toString()}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error scheduling notification for $prayerName: $e');
      }
    }
  }

  // Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload == 'reschedule') {
      // Reschedule tomorrow's prayers
      _scheduleTodayPrayers();
    } else if (response.payload?.startsWith('adhan_') == true) {
      // Play adhan audio when notification is tapped
      final prayerName = response.payload!.substring(6);
      _adhanAudioService.playAdhanForPrayer(prayerName);
    }
    
    if (kDebugMode) {
      print('Notification tapped: ${response.payload}');
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
        print('Error parsing prayer time "$timeString": $e');
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
      print('Prayer alarm ${enabled ? 'enabled' : 'disabled'}');
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
      print('Prayer $prayerName ${enabled ? 'enabled' : 'disabled'}');
    }
  }

  // Test adhan for specific prayer
  Future<void> testAdhan(String prayerName) async {
    await _adhanAudioService.playAdhanForPrayer(prayerName);
    
    // Also show immediate notification for testing
    await _notifications.show(
      prayerName.hashCode + 1000, // Different ID to avoid conflicts
      'Test - Waktu ${_getPrayerDisplayName(prayerName)}',
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
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: prayerName.toLowerCase() == 'fajr' ? 'azan_fajr.mp3' : 'azan.mp3',
          interruptionLevel: InterruptionLevel.critical,
        ),
      ),
      payload: 'test_adhan_$prayerName',
    );
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
        print('Scheduling test notification for $prayerDisplayName at ${nextMinute.toString()}');
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
        print('Test notification scheduled successfully for $prayerDisplayName');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error scheduling test notification: $e');
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
    _adhanAudioService.dispose();
    _isInitialized = false;
  }
}
