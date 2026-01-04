import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/live_stream.dart';

class LiveStreamRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'live_streams';

  // Get current live stream
  Future<LiveStream?> getCurrentLiveStream() async {
    try {
      // Try query with orderBy first (requires composite index)
      try {
        final querySnapshot = await _firestore
            .collection(_collection)
            .where('isActive', isEqualTo: true)
            .orderBy('createdAt', descending: true)
            .limit(1)
            .get();
        
        if (querySnapshot.docs.isNotEmpty) {
          final doc = querySnapshot.docs.first;
          return LiveStream.fromJson({
            'id': doc.id,
            ...doc.data(),
          });
        }
      } catch (e) {
        // If orderBy fails (likely missing composite index), try without orderBy
        final fallbackSnapshot = await _firestore
            .collection(_collection)
            .where('isActive', isEqualTo: true)
            .get();
        
        if (fallbackSnapshot.docs.isNotEmpty) {
          // Sort manually by createdAt and get the most recent
          final sortedDocs = fallbackSnapshot.docs.toList()
            ..sort((a, b) {
              final aCreated = a.data()['createdAt'] as String?;
              final bCreated = b.data()['createdAt'] as String?;
              if (aCreated == null && bCreated == null) return 0;
              if (aCreated == null) return 1;
              if (bCreated == null) return -1;
              return bCreated.compareTo(aCreated); // descending
            });
          
          final doc = sortedDocs.first;
          return LiveStream.fromJson({
            'id': doc.id,
            ...doc.data(),
          });
        }
      }
      
      return null;
    } catch (e) {
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
      return false;
    }
  }

  // Delete live stream
  Future<bool> deleteLiveStream(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
      return true;
    } catch (e) {
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
      // Ignore errors
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
      return false;
    }
  }
} 