import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

class MushafBookmarkService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final fb_auth.FirebaseAuth _auth = fb_auth.FirebaseAuth.instance;
  final String _collection = 'users';

  /// Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  /// Save bookmark for a mushaf
  /// Saves the page number to user's mushafBookmarks map in Firestore
  Future<void> saveBookmark(String mushafId, int pageNumber) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Check if document exists, if not create it first
      final docRef = _firestore.collection(_collection).doc(userId);
      final doc = await docRef.get();
      
      if (!doc.exists) {
        // Create document with bookmark if it doesn't exist
        await docRef.set({
          'mushafBookmarks': {
            mushafId: pageNumber,
          },
        });
      } else {
        // Update existing document's bookmark map
        await docRef.update({
          'mushafBookmarks.$mushafId': pageNumber,
        });
      }

    } catch (e) {
      rethrow;
    }
  }

  /// Get saved page number for a specific mushaf
  /// Returns null if no bookmark exists
  Future<int?> getBookmark(String mushafId) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        return null;
      }

      final doc = await _firestore.collection(_collection).doc(userId).get();
      if (!doc.exists) {
        return null;
      }

      final data = doc.data();
      if (data == null) {
        return null;
      }

      final bookmarks = data['mushafBookmarks'] as Map<String, dynamic>?;
      if (bookmarks == null) {
        return null;
      }

      final pageNumber = bookmarks[mushafId];
      if (pageNumber == null) {
        return null;
      }

      return pageNumber as int;
    } catch (e) {
      return null;
    }
  }

  /// Delete bookmark for a specific mushaf
  Future<void> deleteBookmark(String mushafId) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Use FieldValue to remove the key from the map
      await _firestore.collection(_collection).doc(userId).update({
        'mushafBookmarks.$mushafId': FieldValue.delete(),
      });

    } catch (e) {
      rethrow;
    }
  }

  /// Get all bookmarks for the current user
  /// Returns a map of mushafId to pageNumber
  Future<Map<String, int>> getAllBookmarks() async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        return {};
      }

      final doc = await _firestore.collection(_collection).doc(userId).get();
      if (!doc.exists) {
        return {};
      }

      final data = doc.data();
      if (data == null) {
        return {};
      }

      final bookmarks = data['mushafBookmarks'] as Map<String, dynamic>?;
      if (bookmarks == null) {
        return {};
      }

      // Convert to Map<String, int>
      return bookmarks.map((key, value) => MapEntry(key, value as int));
    } catch (e) {
      return {};
    }
  }
}

