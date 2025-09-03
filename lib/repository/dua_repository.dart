import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/dua.dart';

class DuaRepository {
  final _db = FirebaseFirestore.instance;
  final String _collection = 'duas';

  Future<List<Dua>> getDuas() async {
    final snapshot = await _db.collection(_collection).get();
    return snapshot.docs
        .map((doc) => Dua.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  Future<Dua?> getDuaById(String id) async {
    final doc = await _db.collection(_collection).doc(id).get();
    if (!doc.exists) return null;
    return Dua.fromJson({...doc.data()!, 'id': doc.id});
  }

  Future<void> addDua(Dua dua) async {
    final data = dua.toJson();
    data.remove('id');
    await _db.collection(_collection).add(data);
  }

  Future<void> updateDua(Dua dua) async {
    final data = dua.toJson();
    final id = dua.id;
    data.remove('id');
    await _db.collection(_collection).doc(id).update(data);
  }

  Future<void> deleteDua(String id) async {
    await _db.collection(_collection).doc(id).delete();
  }
} 