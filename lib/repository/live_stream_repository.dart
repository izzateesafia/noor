import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/live_stream.dart';

class LiveStreamRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'live_streams';

  // Get current live stream
  Future<LiveStream?> getCurrentLiveStream() async {
    try {
      print('Fetching current live stream from Firestore...');
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      print('Query result: ${querySnapshot.docs.length} documents found');
      
      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        print('Found live stream document: ${doc.id}');
        print('Document data: ${doc.data()}');
        return LiveStream.fromJson({
          'id': doc.id,
          ...doc.data(),
        });
      }
      
      print('No active live streams found');
      return null;
    } catch (e) {
      print('Error getting current live stream: $e');
      return null;
    }
  }

  // Get all live streams
  Future<List<LiveStream>> getAllLiveStreams() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        return LiveStream.fromJson({
          'id': doc.id,
          ...doc.data(),
        });
      }).toList();
    } catch (e) {
      print('Error getting all live streams: $e');
      return [];
    }
  }

  // Add new live stream
  Future<String?> addLiveStream(LiveStream liveStream) async {
    try {
      // Deactivate all existing live streams first
      await _deactivateAllLiveStreams();

      final docRef = await _firestore.collection(_collection).add(liveStream.toJson());
      return docRef.id;
    } catch (e) {
      print('Error adding live stream: $e');
      return null;
    }
  }

  // Update live stream
  Future<bool> updateLiveStream(LiveStream liveStream) async {
    try {
      final updateData = liveStream.toJson();
      updateData['updatedAt'] = DateTime.now().toIso8601String();
      
      await _firestore
          .collection(_collection)
          .doc(liveStream.id)
          .update(updateData);
      return true;
    } catch (e) {
      print('Error updating live stream: $e');
      return false;
    }
  }

  // Delete live stream
  Future<bool> deleteLiveStream(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
      return true;
    } catch (e) {
      print('Error deleting live stream: $e');
      return false;
    }
  }

  // Deactivate all live streams
  Future<void> _deactivateAllLiveStreams() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .get();

      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.update(doc.reference, {
          'isActive': false,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }
      await batch.commit();
    } catch (e) {
      print('Error deactivating live streams: $e');
    }
  }

  // Activate a specific live stream
  Future<bool> activateLiveStream(String id) async {
    try {
      // Deactivate all others first
      await _deactivateAllLiveStreams();

      // Activate the specified one
      await _firestore.collection(_collection).doc(id).update({
        'isActive': true,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      print('Error activating live stream: $e');
      return false;
    }
  }
} 