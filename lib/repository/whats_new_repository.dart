import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/whats_new.dart';

class WhatsNewRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'whats_new';

  Future<List<WhatsNew>> getWhatsNew() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      return querySnapshot.docs.map((doc) {
        return WhatsNew.fromJson({
          'id': doc.id,
          ...doc.data(),
        });
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<WhatsNew?> getWhatsNewById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (!doc.exists) return null;
      
      return WhatsNew.fromJson({
        'id': doc.id,
        ...doc.data()!,
      });
    } catch (e) {
      return null;
    }
  }

  Future<void> addWhatsNew(WhatsNew item) async {
    try {
      final data = item.toJson();
      data.remove('id');
      data['createdAt'] = DateTime.now().toIso8601String();
      data['isActive'] = true;
      
      await _firestore.collection(_collection).add(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateWhatsNew(WhatsNew item) async {
    try {
      final data = item.toJson();
      data.remove('id');
      data['updatedAt'] = DateTime.now().toIso8601String();
      
      await _firestore
          .collection(_collection)
          .doc(item.id)
          .update(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteWhatsNew(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      rethrow;
    }
  }
}
