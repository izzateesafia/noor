import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/dua.dart';

class DuaRepository {
  final _db = FirebaseFirestore.instance;
  final String _collection = 'duas';

  Future<List<Dua>> getDuas() async {
    try {
      // Try to fetch with orderBy, fallback to simple query if index is missing
      QuerySnapshot snapshot;
      bool usedOrderBy = false;
      try {
        snapshot = await _db.collection(_collection).orderBy('uploaded', descending: true).get();
        usedOrderBy = true;
      } catch (e) {
        // If orderBy fails (e.g., missing index), try without orderBy
        print('OrderBy failed, falling back to simple query: $e');
        snapshot = await _db.collection(_collection).get();
        usedOrderBy = false;
      }
      
      final duas = snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            // Convert Firestore Timestamp to Map for fromJson
            if (data['uploaded'] != null && data['uploaded'] is Timestamp) {
              final timestamp = data['uploaded'] as Timestamp;
              data['uploaded'] = {
                'seconds': timestamp.seconds,
                'nanoseconds': timestamp.nanoseconds,
              };
            }
            return Dua.fromJson({...data, 'id': doc.id});
          })
          .toList();
      
      // If we didn't use orderBy, sort manually
      if (!usedOrderBy) {
        duas.sort((a, b) {
          if (a.uploaded == null && b.uploaded == null) return 0;
          if (a.uploaded == null) return 1;
          if (b.uploaded == null) return -1;
          return b.uploaded!.compareTo(a.uploaded!);
        });
      }
      
      return duas;
    } catch (e) {
      print('Error fetching duas: $e');
      rethrow;
    }
  }

  Future<Dua?> getDuaById(String id) async {
    try {
      final doc = await _db.collection(_collection).doc(id).get();
      if (!doc.exists) return null;
      final data = doc.data()!;
      // Convert Firestore Timestamp to Map for fromJson
      if (data['uploaded'] != null && data['uploaded'] is Timestamp) {
        final timestamp = data['uploaded'] as Timestamp;
        data['uploaded'] = {
          'seconds': timestamp.seconds,
          'nanoseconds': timestamp.nanoseconds,
        };
      }
      return Dua.fromJson({...data, 'id': doc.id});
    } catch (e) {
      print('Error getting dua by ID: $e');
      rethrow;
    }
  }

  Future<void> addDua(Dua dua) async {
    try {
      final data = dua.toJson();
      data.remove('id');
      await _db.collection(_collection).add(data);
      print('Dua added successfully');
    } catch (e) {
      print('Error adding dua: $e');
      rethrow;
    }
  }

  Future<void> updateDua(Dua dua) async {
    try {
      if (dua.id.isEmpty) {
        throw Exception('Cannot update dua with empty ID');
      }
      final data = dua.toJson();
      final id = dua.id;
      data.remove('id');
      await _db.collection(_collection).doc(id).update(data);
      print('Dua updated successfully');
    } catch (e) {
      print('Error updating dua: $e');
      rethrow;
    }
  }

  Future<void> deleteDua(String id) async {
    try {
      if (id.isEmpty) {
        throw Exception('Cannot delete dua with empty ID');
      }
      await _db.collection(_collection).doc(id).delete();
      print('Dua deleted successfully');
    } catch (e) {
      print('Error deleting dua: $e');
      rethrow;
    }
  }
} 