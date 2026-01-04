import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/video.dart';

class VideoRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'videos';

  Future<List<Video>> getVideos({String? category}) async {
    try {
      Query query = _firestore.collection(_collection);
      
      if (category != null && category.isNotEmpty) {
        query = query.where('category', isEqualTo: category);
      }
      
      QuerySnapshot snapshot;
      bool usedOrderBy = false;
      try {
        // Try with orderBy first
        snapshot = await query.orderBy('uploadedAt', descending: true).get();
        usedOrderBy = true;
      } catch (e) {
        // If orderBy fails (e.g., missing index), try without orderBy
        snapshot = await query.get();
        usedOrderBy = false;
      }

      final videos = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        
        // Convert Firestore Timestamp to Map for fromJson
        if (data['uploadedAt'] != null && data['uploadedAt'] is Timestamp) {
          final timestamp = data['uploadedAt'] as Timestamp;
          data['uploadedAt'] = {
            'seconds': timestamp.seconds,
            'nanoseconds': timestamp.nanoseconds,
          };
        }
        
        return Video.fromJson({
          'id': doc.id,
          ...data,
        });
      }).toList();
      
      // If we didn't use orderBy, sort manually
      if (!usedOrderBy) {
        videos.sort((a, b) {
          if (a.uploadedAt == null && b.uploadedAt == null) return 0;
          if (a.uploadedAt == null) return 1;
          if (b.uploadedAt == null) return -1;
          return b.uploadedAt!.compareTo(a.uploadedAt!);
        });
      }
      
      return videos;
    } catch (e) {
      rethrow; // Rethrow instead of returning empty list to surface errors
    }
  }

  Future<Video?> getVideoById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (!doc.exists) {
        return null;
      }
      
      final data = doc.data() as Map<String, dynamic>;
      
      // Convert Firestore Timestamp to Map for fromJson
      if (data['uploadedAt'] != null && data['uploadedAt'] is Timestamp) {
        final timestamp = data['uploadedAt'] as Timestamp;
        data['uploadedAt'] = {
          'seconds': timestamp.seconds,
          'nanoseconds': timestamp.nanoseconds,
        };
      }
      
      return Video.fromJson({
        'id': doc.id,
        ...data,
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<List<String>> getCategories() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();
      final categories = <String>{};
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['category'] != null) {
          categories.add(data['category'] as String);
        }
      }
      
      return categories.toList()..sort();
    } catch (e) {
      return [];
    }
  }

  Future<void> addVideo(Video video) async {
    try {
      final data = video.toJson();
      data.remove('id');
      data['uploadedAt'] = FieldValue.serverTimestamp();
      
      await _firestore.collection(_collection).add(data);
    } on FirebaseException catch (e) {
      String errorMessage = 'Failed to add video';
      if (e.code == 'permission-denied') {
        errorMessage = 'Permission denied. You must be an admin to add videos. Please check your user role.';
      } else if (e.code == 'unauthenticated') {
        errorMessage = 'Authentication required. Please log in and try again.';
      } else {
        errorMessage = 'Failed to add video: ${e.message ?? e.code}';
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Failed to add video: ${e.toString()}');
    }
  }

  Future<void> updateVideo(Video video) async {
    try {
      final data = video.toJson();
      data.remove('id');
      data['updatedAt'] = FieldValue.serverTimestamp();
      
      await _firestore.collection(_collection).doc(video.id).update(data);
    } on FirebaseException catch (e) {
      String errorMessage = 'Failed to update video';
      if (e.code == 'permission-denied') {
        errorMessage = 'Permission denied. You must be an admin to update videos. Please check your user role.';
      } else if (e.code == 'unauthenticated') {
        errorMessage = 'Authentication required. Please log in and try again.';
      } else if (e.code == 'not-found') {
        errorMessage = 'Video not found. It may have been deleted.';
      } else {
        errorMessage = 'Failed to update video: ${e.message ?? e.code}';
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Failed to update video: ${e.toString()}');
    }
  }

  Future<void> deleteVideo(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } on FirebaseException catch (e) {
      String errorMessage = 'Failed to delete video';
      if (e.code == 'permission-denied') {
        errorMessage = 'Permission denied. You must be an admin to delete videos. Please check your user role.';
      } else if (e.code == 'unauthenticated') {
        errorMessage = 'Authentication required. Please log in and try again.';
      } else if (e.code == 'not-found') {
        errorMessage = 'Video not found. It may have already been deleted.';
      } else {
        errorMessage = 'Failed to delete video: ${e.message ?? e.code}';
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Failed to delete video: ${e.toString()}');
    }
  }
}

