import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/hadith.dart';

class HadithRepository {
  final _db = FirebaseFirestore.instance;
  final String _collection = 'hadiths';

  Future<List<Hadith>> getHadiths() async {
    try {
      final snapshot = await _db
          .collection(_collection)
          .orderBy('uploaded', descending: true)
          .get();
      return snapshot.docs.map((doc) => Hadith.fromJson({
        ..._normalizeTimestamp(doc.data()),
        'id': doc.id,
      })).toList();
    } catch (_) {
      final snapshot = await _db.collection(_collection).get();
      return snapshot.docs.map((doc) => Hadith.fromJson({
        ..._normalizeTimestamp(doc.data()),
        'id': doc.id,
      })).toList();
    }
  }

  Future<Hadith?> getHadithById(String id) async {
    final doc = await _db.collection(_collection).doc(id).get();
    if (!doc.exists) return null;
    return Hadith.fromJson({...doc.data()!, 'id': doc.id});
  }

  Future<void> addHadith(Hadith hadith) async {
    final data = hadith.toJson();
    data.remove('id');
    await _db.collection(_collection).add(data);
  }

  Future<void> updateHadith(Hadith hadith) async {
    final data = hadith.toJson();
    final id = hadith.id;
    data.remove('id');
    await _db.collection(_collection).doc(id).update(data);
  }

  Future<void> deleteHadith(String id) async {
    await _db.collection(_collection).doc(id).delete();
  }

  Map<String, dynamic> _normalizeTimestamp(Map<String, dynamic> data) {
    final copy = {...data};
    final uploaded = copy['uploaded'];
    if (uploaded != null && uploaded is Timestamp) {
      copy['uploaded'] = uploaded.toDate().toIso8601String();
    }
    return copy;
  }
} 