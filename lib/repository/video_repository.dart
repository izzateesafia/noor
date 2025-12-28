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
      
      final snapshot = await query
          .orderBy('uploadedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return Video.fromJson({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        });
      }).toList();
    } catch (e) {
      print('Error getting videos: $e');
      return [];
    }
  }

  Future<Video?> getVideoById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (!doc.exists) return null;
      
      return Video.fromJson({
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      });
    } catch (e) {
      print('Error getting video by ID: $e');
      return null;
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
      print('Error getting categories: $e');
      return [];
    }
  }

  Future<void> addVideo(Video video) async {
    try {
      final data = video.toJson();
      data.remove('id');
      data['uploadedAt'] = FieldValue.serverTimestamp();
      
      await _firestore.collection(_collection).add(data);
    } catch (e) {
      print('Error adding video: $e');
      rethrow;
    }
  }

  Future<void> updateVideo(Video video) async {
    try {
      final data = video.toJson();
      data.remove('id');
      data['updatedAt'] = FieldValue.serverTimestamp();
      
      await _firestore.collection(_collection).doc(video.id).update(data);
    } catch (e) {
      print('Error updating video: $e');
      rethrow;
    }
  }

  Future<void> deleteVideo(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      print('Error deleting video: $e');
      rethrow;
    }
  }
}

