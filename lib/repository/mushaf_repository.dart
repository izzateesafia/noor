import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/mushaf_model.dart';

class MushafRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'mushafs';

  /// Get all available mushafs from Firestore
  Future<List<MushafModel>> getAllMushafs() async {
    try {
      QuerySnapshot snapshot;
      
      // Try with orderBy first (requires composite index)
      try {
        snapshot = await _firestore
            .collection(_collection)
            .orderBy('riwayah')
            .orderBy('name')
            .get();
      } catch (e) {
        // If index is missing, try without orderBy
        snapshot = await _firestore
            .collection(_collection)
            .get();
      }

      final mushafs = snapshot.docs.map((doc) {
        try {
          final data = doc.data() as Map<String, dynamic>?;
          if (data == null) {
            return null;
          }
          return MushafModel.fromJson({
            'id': doc.id,
            ...data,
          });
        } catch (e) {
          return null;
        }
      }).whereType<MushafModel>().toList();

      // Sort manually if orderBy failed
      mushafs.sort((a, b) {
        final riwayahCompare = a.riwayah.compareTo(b.riwayah);
        if (riwayahCompare != 0) return riwayahCompare;
        return a.name.compareTo(b.name);
      });

      return mushafs;
    } catch (e) {
      return [];
    }
  }

  /// Get mushafs filtered by riwayah
  Future<List<MushafModel>> getMushafsByRiwayah(String riwayah) async {
    try {
      QuerySnapshot snapshot;
      
      // Try with orderBy first
      try {
        snapshot = await _firestore
            .collection(_collection)
            .where('riwayah', isEqualTo: riwayah)
            .orderBy('name')
            .get();
      } catch (e) {
        // If index is missing, try without orderBy
        snapshot = await _firestore
            .collection(_collection)
            .where('riwayah', isEqualTo: riwayah)
            .get();
      }

      final mushafs = snapshot.docs.map((doc) {
        try {
          final data = doc.data() as Map<String, dynamic>?;
          if (data == null) {
            return null;
          }
          return MushafModel.fromJson({
            'id': doc.id,
            ...data,
          });
        } catch (e) {
          return null;
        }
      }).whereType<MushafModel>().toList();

      // Sort manually if orderBy failed
      mushafs.sort((a, b) => a.name.compareTo(b.name));

      return mushafs;
    } catch (e) {
      return [];
    }
  }

  /// Get a specific mushaf by ID
  Future<MushafModel?> getMushafById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (!doc.exists) {
        return null;
      }

      final data = doc.data();
      if (data == null) {
        return null;
      }

      return MushafModel.fromJson({
        'id': doc.id,
        ...data,
      });
    } catch (e) {
      return null;
    }
  }

  /// Get all unique riwayahs
  Future<List<String>> getAllRiwayahs() async {
    try {
      final mushafs = await getAllMushafs();
      return mushafs
          .map((m) => m.riwayah)
          .toSet()
          .toList()
        ..sort();
    } catch (e) {
      return [];
    }
  }

  /// Add a new mushaf to Firestore (admin function)
  Future<void> addMushaf(MushafModel mushaf) async {
    try {
      final data = mushaf.toJson();
      data.remove('id'); // Firestore will generate the ID
      await _firestore.collection(_collection).add(data);
    } catch (e) {
      rethrow;
    }
  }

  /// Update an existing mushaf in Firestore (admin function)
  Future<void> updateMushaf(MushafModel mushaf) async {
    try {
      final data = mushaf.toJson();
      data.remove('id');
      await _firestore.collection(_collection).doc(mushaf.id).update(data);
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a mushaf from Firestore (admin function)
  Future<void> deleteMushaf(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      rethrow;
    }
  }
}

