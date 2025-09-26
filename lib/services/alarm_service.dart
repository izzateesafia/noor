import 'dart:async';
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
      print('AlarmService initialized successfully');
    } catch (e) {
      print('Error initializing AlarmService: $e');
    }
  }

  // Request notification permissions
  Future<void> _requestPermissions() async {
    try {
      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final granted = await androidPlugin.requestNotificationsPermission();
        print('Notification permission granted: $granted');
      }
    } catch (e) {
      print('Error requesting notification permissions: $e');
    }
  }

  // Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
    // You can add logic here to handle notification taps
  }

  // Schedule an alarm for a specific time
  Future<void> scheduleAlarm({
    required DateTime scheduledTime,
    required String prayerName,
    required String prayerDisplayName,
  }) async {
    print('AlarmService: scheduleAlarm called for $prayerDisplayName at $scheduledTime');
    
    if (!_isInitialized) {
      print('AlarmService: Initializing...');
      await initialize();
    }

    try {
      // Cancel any existing alarms
      print('AlarmService: Cancelling existing alarms...');
      await cancelAllAlarms();

      // Calculate alarm ID based on time
      final alarmId = scheduledTime.millisecondsSinceEpoch ~/ 1000;
      print('AlarmService: Using alarm ID: $alarmId');
      
      // Convert to timezone-aware datetime
      final scheduledTz = tz.TZDateTime.from(scheduledTime, tz.local);
      print('AlarmService: Scheduled time (TZ): $scheduledTz');

      // Schedule the notification
      print('AlarmService: Scheduling notification...');
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
            // Use default sound for now (custom sound might not be found)
            // sound: RawResourceAndroidNotificationSound('azan'),
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
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'azan.mp3',
            interruptionLevel: InterruptionLevel.critical,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'adhan_$prayerName',
      );

      print('AlarmService: Notification scheduled successfully');

      // Save alarm info to preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('scheduled_alarm_time', scheduledTime.millisecondsSinceEpoch);
      await prefs.setString('scheduled_prayer', prayerName);
      await prefs.setString('scheduled_prayer_display', prayerDisplayName);
      await prefs.setInt('alarm_id', alarmId);

      print('AlarmService: Alarm info saved to preferences');
      print('AlarmService: Alarm scheduled for $prayerDisplayName at ${scheduledTime.toString()}');
    } catch (e) {
      print('AlarmService: Error scheduling alarm: $e');
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

      print('All alarms cancelled');
    } catch (e) {
      print('Error cancelling alarms: $e');
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
      print('Error checking scheduled alarm: $e');
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
      print('Error getting scheduled alarm info: $e');
    }
    return null;
  }

  // Get pending notifications (for debugging)
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _notifications.pendingNotificationRequests();
    } catch (e) {
      print('Error getting pending notifications: $e');
      return [];
    }
  }

  // Test notification (for debugging)
  Future<void> showTestNotification() async {
    try {
      print('AlarmService: Showing test notification...');
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
      print('AlarmService: Test notification shown successfully');
    } catch (e) {
      print('AlarmService: Error showing test notification: $e');
    }
  }

  // Dispose resources
  void dispose() {
    // No resources to dispose for notifications
  }
}