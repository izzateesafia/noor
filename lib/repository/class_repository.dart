import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import '../models/class_model.dart';

class ClassRepository {
  final _db = FirebaseFirestore.instance;
  final _auth = fb_auth.FirebaseAuth.instance;
  final String _collection = 'classes';

  Future<List<ClassModel>> getClasses() async {
    try {
      // Check if user is authenticated before making the query
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Pengguna tidak didaftarkan masuk. Sila log masuk terlebih dahulu.');
      }

    final snapshot = await _db.collection(_collection).get();
    return snapshot.docs
        .map((doc) => ClassModel.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
    } on FirebaseException catch (e) {
      String errorMessage = 'Gagal memuatkan kelas';
      if (e.code == 'permission-denied') {
        errorMessage = 'Kebenaran ditolak. Sila pastikan anda telah log masuk dan cuba lagi.';
      } else if (e.code == 'unauthenticated') {
        errorMessage = 'Pengesahan diperlukan. Sila log masuk dan cuba lagi.';
      } else {
        errorMessage = 'Gagal memuatkan kelas: ${e.message ?? e.code}';
      }
      throw Exception(errorMessage);
    } catch (e) {
      // Re-throw if it's already a formatted Exception
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Gagal memuatkan kelas: ${e.toString()}');
    }
  }

  Future<ClassModel?> getClassById(String id) async {
    try {
      // Check if user is authenticated before making the query
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Pengguna tidak didaftarkan masuk. Sila log masuk terlebih dahulu.');
      }

    final doc = await _db.collection(_collection).doc(id).get();
    if (!doc.exists) return null;
    return ClassModel.fromJson({...doc.data()!, 'id': doc.id});
    } on FirebaseException catch (e) {
      String errorMessage = 'Gagal memuatkan kelas';
      if (e.code == 'permission-denied') {
        errorMessage = 'Kebenaran ditolak. Sila pastikan anda telah log masuk dan cuba lagi.';
      } else if (e.code == 'unauthenticated') {
        errorMessage = 'Pengesahan diperlukan. Sila log masuk dan cuba lagi.';
      } else {
        errorMessage = 'Gagal memuatkan kelas: ${e.message ?? e.code}';
      }
      throw Exception(errorMessage);
    } catch (e) {
      // Re-throw if it's already a formatted Exception
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Gagal memuatkan kelas: ${e.toString()}');
    }
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