import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

/// Lock Screen Notification Service
/// 
/// Why notifications instead of widgets?
/// - Classic Android lock-screen widgets were deprecated in Android 5.0+
/// - Modern Android (8+) uses notification-based lock screen content
/// - Notifications are the official, supported way to show content on lock screens
/// - Works consistently across all Android versions (8-14) and OEMs
/// - No special permissions or OEM-specific hacks required
/// 
/// This service creates a persistent, high-priority notification that:
/// - Appears on the lock screen even when device is locked
/// - Remains visible until manually dismissed or updated
/// - Supports Arabic text with proper RTL rendering
/// - Opens the app when tapped
class LockScreenNotificationService {
  static final LockScreenNotificationService _instance =
      LockScreenNotificationService._internal();
  factory LockScreenNotificationService() => _instance;
  LockScreenNotificationService._internal();

  static const String _channelId = 'lock_screen_quran_channel';
  static const String _channelName = 'Quran Lock Screen';
  static const String _channelDescription =
      'Shows Quran verses on lock screen. This notification is persistent and visible when device is locked.';
  static const int _notificationId = 9999; // Fixed ID for lock screen notification

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  /// Initialize the lock screen notification service
  /// Call this once during app startup (e.g., in main.dart)
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize notification plugin
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Request notification permissions (Android 13+)
      await _requestPermissions();

      // Create high-priority public notification channel for lock screen
      await _createLockScreenChannel();

      _isInitialized = true;
      print('LockScreenNotificationService initialized');
    } catch (e) {
      print('Error initializing LockScreenNotificationService: $e');
      rethrow;
    }
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    // Android 13+ requires explicit notification permission
    if (await Permission.notification.isDenied) {
      final status = await Permission.notification.request();
      if (status.isDenied) {
        print('Notification permission denied. Lock screen notification may not work.');
      }
    }

    // Also request via Android plugin (for compatibility)
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      print('Android notification permission: $granted');
    }
  }

  /// Create a high-priority public notification channel for lock screen
  /// 
  /// Channel properties:
  /// - Importance.max: Highest priority, appears on lock screen
  /// - Visibility.public: Content visible on lock screen (not hidden by privacy)
  /// - Category.service: Indicates this is a service notification
  Future<void> _createLockScreenChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.max, // Highest priority for lock screen
      playSound: false, // Silent for persistent display
      enableVibration: false, // No vibration for persistent display
      showBadge: true,
      // Visibility.public is set in AndroidNotificationDetails
    );

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(channel);
  }

  /// Show or update the lock screen notification
  /// 
  /// [title] - Notification title (e.g., "Quran Reminder")
  /// [body] - Main notification text (supports Arabic/RTL)
  /// [expandedText] - Optional expanded text for BigTextStyle (supports long Arabic text)
  /// [openAppOnTap] - Whether tapping notification should open the app (default: true)
  Future<void> showLockScreenNotification({
    required String title,
    required String body,
    String? expandedText,
    bool openAppOnTap = true,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Create intent to open app when notification is tapped
      final String? payload = openAppOnTap ? 'open_app' : null;

      // Android notification details with lock screen visibility
      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.max,
        priority: Priority.max,
        ongoing: true, // Persistent notification (cannot be swiped away)
        autoCancel: false, // Don't auto-cancel
        showWhen: false, // Hide timestamp for cleaner look
        styleInformation: expandedText != null
            ? BigTextStyleInformation(
                expandedText,
                contentTitle: title,
                summaryText: body,
                htmlFormatBigText: false, // Plain text (supports Arabic)
              )
            : BigTextStyleInformation(
                body,
                contentTitle: title,
                htmlFormatBigText: false,
              ),
        // Public visibility allows content on lock screen
        visibility: NotificationVisibility.public,
        category: AndroidNotificationCategory.service,
        // Enable full screen intent for lock screen (optional)
        fullScreenIntent: false, // Set to true if you want full-screen on lock screen
      );

      // iOS notification details
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: false,
      );

      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Show the notification
      await _notifications.show(
        _notificationId,
        title,
        body,
        notificationDetails,
        payload: payload,
      );

      print('Lock screen notification shown: $title');
    } catch (e) {
      print('Error showing lock screen notification: $e');
      rethrow;
    }
  }

  /// Update the lock screen notification content
  /// This is more efficient than showing a new notification
  Future<void> updateLockScreenNotification({
    required String title,
    required String body,
    String? expandedText,
  }) async {
    await showLockScreenNotification(
      title: title,
      body: body,
      expandedText: expandedText,
    );
  }

  /// Dismiss the lock screen notification
  Future<void> dismissLockScreenNotification() async {
    try {
      await _notifications.cancel(_notificationId);
      print('Lock screen notification dismissed');
    } catch (e) {
      print('Error dismissing lock screen notification: $e');
    }
  }

  /// Check if lock screen notification is currently showing
  Future<bool> isNotificationShowing() async {
    try {
      final activeNotifications = await _notifications.getActiveNotifications();
      return activeNotifications.any((n) => n.id == _notificationId);
    } catch (e) {
      print('Error checking notification status: $e');
      return false;
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    print('Lock screen notification tapped: ${response.payload}');
    
    if (response.payload == 'open_app') {
      // The app will automatically open when notification is tapped
      // You can add custom navigation logic here if needed
      print('Opening app from lock screen notification');
    }
  }
}

