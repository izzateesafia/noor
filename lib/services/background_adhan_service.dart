import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class BackgroundAdhanService {
  static final BackgroundAdhanService _instance = BackgroundAdhanService._internal();
  factory BackgroundAdhanService() => _instance;
  BackgroundAdhanService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  bool _isInitialized = false;
  Timer? _timer;

  // Initialize the background adhan service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize timezone data
      tz.initializeTimeZones();
      
      // Initialize local notifications
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

      // Create notification channel for adhan
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
      print('BackgroundAdhanService initialized successfully');
    } catch (e) {
      print('Error initializing BackgroundAdhanService: $e');
    }
  }

  // Schedule adhan for a specific time
  Future<void> scheduleAdhan({
    required DateTime scheduledTime,
    required String prayerName,
    required String prayerDisplayName,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Cancel any existing adhan notifications
      await cancelAllAdhanNotifications();

      // Calculate notification ID based on time to ensure uniqueness
      final notificationId = scheduledTime.millisecondsSinceEpoch ~/ 1000;

      // Convert to timezone-aware datetime
      final scheduledTz = tz.TZDateTime.from(scheduledTime, tz.local);
      
      // Schedule the notification
      await _notifications.zonedSchedule(
        notificationId,
        'Waktu $prayerDisplayName',
        'Azan akan dimainkan sekarang',
        scheduledTz,
        const NotificationDetails(
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
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );

      // Save the scheduled time to preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('scheduled_adhan_time', scheduledTime.millisecondsSinceEpoch);
      await prefs.setString('scheduled_prayer', prayerName);
      await prefs.setString('scheduled_prayer_display', prayerDisplayName);

      print('Adhan scheduled for $prayerDisplayName at ${scheduledTime.toString()}');
    } catch (e) {
      print('Error scheduling adhan: $e');
    }
  }

  // Play adhan audio in background
  Future<void> playAdhanAudio(String prayerName) async {
    try {
      // Stop any currently playing audio
      await _audioPlayer.stop();

      // Determine which azan file to play
      String audioFile = 'audio/azan.mp3';
      if (prayerName.toLowerCase() == 'fajr') {
        audioFile = 'audio/azan_fajr.mp3';
      }

      // Play the azan audio
      await _audioPlayer.play(AssetSource(audioFile));
      
      print('Playing adhan audio for $prayerName in background');
      
      // Auto-stop after 15 seconds
      Timer(const Duration(seconds: 15), () {
        _audioPlayer.stop();
      });
    } catch (e) {
      print('Error playing adhan audio in background: $e');
    }
  }

  // Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    print('Adhan notification tapped: ${response.payload}');
    
    // Get the scheduled prayer info
    _getScheduledPrayerInfo().then((info) {
      if (info != null && info['prayerName'] != null) {
        playAdhanAudio(info['prayerName']!);
      }
    });
  }

  // This method will be called when the notification fires (like an alarm)
  static Future<void> onNotificationReceived() async {
    print('Adhan notification received - playing audio automatically');
    
    try {
      final service = BackgroundAdhanService();
      final info = await service._getScheduledPrayerInfo();
      
      if (info != null && info['prayerName'] != null) {
        await service.playAdhanAudio(info['prayerName']!);
        print('Adhan audio started automatically for ${info['prayerDisplayName'] ?? 'Unknown'}');
      }
    } catch (e) {
      print('Error playing adhan audio automatically: $e');
    }
  }

  // Get scheduled prayer info from preferences
  Future<Map<String, String>?> _getScheduledPrayerInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final prayerName = prefs.getString('scheduled_prayer');
      final prayerDisplayName = prefs.getString('scheduled_prayer_display');
      
      if (prayerName != null && prayerDisplayName != null) {
        return {
          'prayerName': prayerName,
          'prayerDisplayName': prayerDisplayName,
        };
      }
    } catch (e) {
      print('Error getting scheduled prayer info: $e');
    }
    return null;
  }

  // Cancel all adhan notifications
  Future<void> cancelAllAdhanNotifications() async {
    try {
      await _notifications.cancelAll();
      
      // Clear scheduled prayer info
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('scheduled_adhan_time');
      await prefs.remove('scheduled_prayer');
      await prefs.remove('scheduled_prayer_display');
      
      print('All adhan notifications cancelled');
    } catch (e) {
      print('Error cancelling adhan notifications: $e');
    }
  }

  // Check if there's a scheduled adhan
  Future<bool> hasScheduledAdhan() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final scheduledTime = prefs.getInt('scheduled_adhan_time');
      
      if (scheduledTime != null) {
        final scheduledDateTime = DateTime.fromMillisecondsSinceEpoch(scheduledTime);
        final now = DateTime.now();
        
        // Check if the scheduled time is in the future
        return scheduledDateTime.isAfter(now);
      }
    } catch (e) {
      print('Error checking scheduled adhan: $e');
    }
    return false;
  }

  // Get scheduled adhan info
  Future<Map<String, dynamic>?> getScheduledAdhanInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final scheduledTime = prefs.getInt('scheduled_adhan_time');
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
      print('Error getting scheduled adhan info: $e');
    }
    return null;
  }

  // Dispose resources
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
  }
}
