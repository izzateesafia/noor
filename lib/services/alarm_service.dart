import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class AlarmService {
  static final AlarmService _instance = AlarmService._internal();
  factory AlarmService() => _instance;
  AlarmService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

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
      
      _isInitialized = true;
    } catch (e) {
    }
  }

  // Request notification permissions
  Future<void> _requestPermissions() async {
    try {
      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final granted = await androidPlugin.requestNotificationsPermission();
      }
    } catch (e) {
    }
  }

  // Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    // You can add logic here to handle notification taps
  }

  // Schedule an alarm for a specific time
  Future<void> scheduleAlarm({
    required DateTime scheduledTime,
    required String prayerName,
    required String prayerDisplayName,
  }) async {
    
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Cancel any existing alarms
      await cancelAllAlarms();

      // Calculate alarm ID based on time
      final alarmId = scheduledTime.millisecondsSinceEpoch ~/ 1000;
      
      // Convert to timezone-aware datetime
      final scheduledTz = tz.TZDateTime.from(scheduledTime, tz.local);

      // Schedule the notification
      await _notifications.zonedSchedule(
        alarmId,
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
            // Use the appropriate adhan sound based on prayer
            sound: RawResourceAndroidNotificationSound(
              prayerName.toLowerCase() == 'fajr' ? 'azan_fajr' : 'azan'
            ),
            // Make it a high priority notification
            fullScreenIntent: true,
            category: AndroidNotificationCategory.alarm,
            // Auto-dismiss after 30 seconds
            autoCancel: true,
            // Show on lock screen
            visibility: NotificationVisibility.public,
            // Additional settings for better reliability
            ongoing: false,
            silent: false,
            // Enable heads-up notification
            enableLights: true,
            ledColor: const Color(0xFFD32F2F), // Red color for alarm
            ledOnMs: 1000,
            ledOffMs: 500,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: prayerName.toLowerCase() == 'fajr' ? 'azan_fajr.mp3' : 'azan.mp3',
            interruptionLevel: InterruptionLevel.critical,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'adhan_$prayerName',
      );


      // Save alarm info to preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('scheduled_alarm_time', scheduledTime.millisecondsSinceEpoch);
      await prefs.setString('scheduled_prayer', prayerName);
      await prefs.setString('scheduled_prayer_display', prayerDisplayName);
      await prefs.setInt('alarm_id', alarmId);

    } catch (e) {
      rethrow;
    }
  }

  // Cancel all scheduled alarms
  Future<void> cancelAllAlarms() async {
    try {
      // Cancel all pending notifications
      await _notifications.cancelAll();

      // Clear alarm info from preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('scheduled_alarm_time');
      await prefs.remove('scheduled_prayer');
      await prefs.remove('scheduled_prayer_display');
      await prefs.remove('alarm_id');

    } catch (e) {
    }
  }

  // Check if there's a scheduled alarm
  Future<bool> hasScheduledAlarm() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final scheduledTime = prefs.getInt('scheduled_alarm_time');
      
      if (scheduledTime != null) {
        final scheduledDateTime = DateTime.fromMillisecondsSinceEpoch(scheduledTime);
        final now = DateTime.now();
        
        // Check if the scheduled time is in the future
        return scheduledDateTime.isAfter(now);
      }
    } catch (e) {
    }
    return false;
  }

  // Get scheduled alarm info
  Future<Map<String, dynamic>?> getScheduledAlarmInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final scheduledTime = prefs.getInt('scheduled_alarm_time');
      final prayerName = prefs.getString('scheduled_prayer');
      final prayerDisplayName = prefs.getString('scheduled_prayer_display');
      
      if (scheduledTime != null && prayerName != null && prayerDisplayName != null) {
        final scheduledDateTime = DateTime.fromMillisecondsSinceEpoch(scheduledTime);
        final now = DateTime.now();
        
        if (scheduledDateTime.isAfter(now)) {
          return {
            'scheduledTime': scheduledDateTime,
            'prayerName': prayerName,
            'prayerDisplayName': prayerDisplayName,
            'timeRemaining': scheduledDateTime.difference(now),
          };
        }
      }
    } catch (e) {
    }
    return null;
  }

  // Get pending notifications (for debugging)
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _notifications.pendingNotificationRequests();
    } catch (e) {
      return [];
    }
  }

  // Test notification (for debugging)
  Future<void> showTestNotification() async {
    try {
      await _notifications.show(
        999,
        'Test Notification',
        'This is a test notification to verify the system works',
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
            // Use default sound for test
            // sound: RawResourceAndroidNotificationSound('azan'),
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    } catch (e) {
    }
  }

  // Dispose resources
  void dispose() {
    // No resources to dispose for notifications
  }
}