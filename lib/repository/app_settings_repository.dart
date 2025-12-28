import 'package:cloud_firestore/cloud_firestore.dart';

class AppSettingsRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collection = 'app_settings';

  /// Get welcome message from Firestore
  /// Returns default message if not set
  Future<String> getWelcomeMessage() async {
    try {
      final doc = await _db.collection(_collection).doc('welcome_message').get();
      if (doc.exists && doc.data() != null) {
        return doc.data()!['message'] as String? ?? 
               'Ready to level up your Quran recitation?';
      }
      return 'Ready to level up your Quran recitation?';
    } catch (e) {
      print('Error fetching welcome message: $e');
      return 'Ready to level up your Quran recitation?';
    }
  }

  /// Update welcome message (admin only)
  Future<void> updateWelcomeMessage(String message) async {
    try {
      await _db.collection(_collection).doc('welcome_message').set({
        'message': message,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update welcome message: $e');
    }
  }
}

