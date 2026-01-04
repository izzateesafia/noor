import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ad.dart';

class AdRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'ads';

  Future<List<Ad>> getAds() async {
    try {
      // Try query with orderBy first (requires composite index)
      try {
        final querySnapshot = await _firestore
            .collection(_collection)
            .where('isActive', isEqualTo: true)
            .orderBy('createdAt', descending: true)
            .get();
        
        final ads = querySnapshot.docs.map((doc) {
          return Ad.fromJson({
            'id': doc.id,
            ...doc.data(),
          });
        }).toList();
        
        return ads;
      } catch (e) {
        // If orderBy fails (likely missing composite index), try without orderBy
        final fallbackSnapshot = await _firestore
            .collection(_collection)
            .where('isActive', isEqualTo: true)
            .get();
        
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
        
        final ads = sortedDocs.map((doc) {
          return Ad.fromJson({
            'id': doc.id,
            ...doc.data(),
          });
        }).toList();
        
        return ads;
      }
    } catch (e) {
      return [];
    }
  }

  Future<List<Ad>> getAllAds() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        return Ad.fromJson({
          'id': doc.id,
          ...doc.data(),
        });
      }).toList();
    } catch (e) {
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
      return null;
    }
  }

  Future<void> addAd(Ad ad) async {
    try {
      final data = ad.toJson();
      data.remove('id');
      if (data['createdAt'] == null) {
        data['createdAt'] = DateTime.now().toIso8601String();
      }
      // Use the isActive value from the ad object
      if (data['isActive'] == null) {
        data['isActive'] = true;
      }
      
      await _firestore.collection(_collection).add(data);
    } catch (e) {
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
      rethrow;
    }
  }

  Future<void> deleteAd(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      rethrow;
    }
  }
} 