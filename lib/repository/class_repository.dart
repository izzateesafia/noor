import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/class_model.dart';

class ClassRepository {
  final _db = FirebaseFirestore.instance;
  final String _collection = 'classes';

  Future<List<ClassModel>> getClasses() async {
    final snapshot = await _db.collection(_collection).get();
    return snapshot.docs
        .map((doc) => ClassModel.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  Future<ClassModel?> getClassById(String id) async {
    final doc = await _db.collection(_collection).doc(id).get();
    if (!doc.exists) return null;
    return ClassModel.fromJson({...doc.data()!, 'id': doc.id});
  }

  Future<void> addClass(ClassModel classModel) async {
    final data = classModel.toJson();
    data.remove('id'); // Firestore will generate the ID
    await _db.collection(_collection).add(data);
  }

  Future<void> updateClass(ClassModel classModel) async {
    final data = classModel.toJson();
    final id = classModel.id;
    data.remove('id');
    await _db.collection(_collection).doc(id).update(data);
  }

  Future<void> deleteClass(String id) async {
    await _db.collection(_collection).doc(id).delete();
  }
} 