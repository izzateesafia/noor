import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/news.dart';

class NewsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'news';

  Future<List<News>> getNews() async {
    try {
      
      // Try with orderBy first, fallback to without if index missing
      QuerySnapshot querySnapshot;
      try {
        querySnapshot = await _firestore
            .collection(_collection)
            .where('isActive', isEqualTo: true)
            .orderBy('createdAt', descending: true)
            .get();
      } catch (e) {
        // Fallback: get all active news without ordering
        querySnapshot = await _firestore
            .collection(_collection)
            .where('isActive', isEqualTo: true)
            .get();
      }

      final newsList = querySnapshot.docs.map((doc) {
        try {
          final data = doc.data() as Map<String, dynamic>?;
          return News.fromJson({
            'id': doc.id,
            if (data != null) ...data,
          });
        } catch (e) {
          return null;
        }
      }).whereType<News>().toList();

      return newsList;
    } catch (e) {
      return [];
    }
  }

  Future<News?> getNewsById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (!doc.exists) return null;
      
      return News.fromJson({
        'id': doc.id,
        ...doc.data()!,
      });
    } catch (e) {
      return null;
    }
  }

  Future<void> addNews(News news) async {
    try {
      final data = news.toJson();
      data.remove('id');
      data['createdAt'] = DateTime.now().toIso8601String();
      data['isActive'] = true;
      
      await _firestore.collection(_collection).add(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateNews(News news) async {
    try {
      final data = news.toJson();
      data.remove('id');
      data['updatedAt'] = DateTime.now().toIso8601String();
      
      await _firestore
          .collection(_collection)
          .doc(news.id)
          .update(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteNews(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      rethrow;
    }
  }
}

