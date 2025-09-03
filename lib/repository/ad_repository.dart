import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ad.dart';

class AdRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'ads';

  Future<List<Ad>> getAds() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        return Ad.fromJson({
          'id': doc.id,
          ...doc.data(),
        });
      }).toList();
    } catch (e) {
      print('Error getting ads: $e');
      return [];
    }
  }

  Future<Ad?> getAdById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (!doc.exists) return null;
      
      return Ad.fromJson({
        'id': doc.id,
        ...doc.data()!,
      });
    } catch (e) {
      print('Error getting ad by ID: $e');
      return null;
    }
  }

  Future<void> addAd(Ad ad) async {
    try {
      final data = ad.toJson();
      data.remove('id');
      data['createdAt'] = DateTime.now().toIso8601String();
      data['isActive'] = true;
      
      await _firestore.collection(_collection).add(data);
    } catch (e) {
      print('Error adding ad: $e');
      rethrow;
    }
  }

  Future<void> updateAd(Ad ad) async {
    try {
      final data = ad.toJson();
      data.remove('id');
      data['updatedAt'] = DateTime.now().toIso8601String();
      
      await _firestore
          .collection(_collection)
          .doc(ad.id)
          .update(data);
    } catch (e) {
      print('Error updating ad: $e');
      rethrow;
    }
  }

  Future<void> deleteAd(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      print('Error deleting ad: $e');
      rethrow;
    }
  }
} 