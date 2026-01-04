import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Service for admins to send notifications to users
class AdminNotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Send notification immediately to all users
  /// 
  /// [title] - Notification title
  /// [body] - Notification body/message
  /// [data] - Optional additional data payload
  Future<void> sendNotificationToAllUsers({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Get all user FCM tokens from Firestore
      final tokensSnapshot = await _firestore.collection('user_tokens').get();
      final tokens = tokensSnapshot.docs
          .map((doc) => doc.data()['token'] as String?)
          .whereType<String>()
          .toList();

      if (tokens.isEmpty) {
        throw Exception('No user tokens found. Users need to have the app installed and opened.');
      }

      // Send notification via FCM
      // Note: For sending to multiple tokens, you would typically use Cloud Functions
      // or Firebase Admin SDK. Here we'll store it in Firestore and let Cloud Functions handle it.
      
      // Store notification in Firestore for Cloud Functions to process
      await _firestore.collection('admin_notifications').add({
        'title': title,
        'body': body,
        'data': data ?? {},
        'tokens': tokens,
        'sent': false,
        'createdAt': FieldValue.serverTimestamp(),
        'sentAt': null,
        'type': 'immediate',
      });

    } catch (e) {
      rethrow;
    }
  }

  /// Schedule a notification for a future date/time
  /// 
  /// [title] - Notification title
  /// [body] - Notification body/message
  /// [scheduledTime] - When to send the notification
  /// [data] - Optional additional data payload
  Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledTime,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Get all user FCM tokens
      final tokensSnapshot = await _firestore.collection('user_tokens').get();
      final tokens = tokensSnapshot.docs
          .map((doc) => doc.data()['token'] as String?)
          .whereType<String>()
          .toList();

      // Store scheduled notification in Firestore
      await _firestore.collection('admin_notifications').add({
        'title': title,
        'body': body,
        'data': data ?? {},
        'tokens': tokens,
        'scheduledTime': scheduledTime.toUtc().toIso8601String(),
        'sent': false,
        'createdAt': FieldValue.serverTimestamp(),
        'sentAt': null,
        'type': 'scheduled',
      });

    } catch (e) {
      rethrow;
    }
  }

  /// Get notification history
  Future<List<Map<String, dynamic>>> getNotificationHistory({int limit = 50}) async {
    try {
      final snapshot = await _firestore
          .collection('admin_notifications')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('admin_notifications').doc(notificationId).delete();
    } catch (e) {
      rethrow;
    }
  }
}

