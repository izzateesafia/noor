import 'package:cloud_firestore/cloud_firestore.dart';

class AdminStatsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, int>> getStats() async {
    try {
      final results = await Future.wait([
        _getCollectionCount('users'),
        _getCollectionCount('hadiths'),
        _getCollectionCount('duas'),
        _getCollectionCount('news'),
        _getCollectionCount('videos'),
        _getCollectionCount('classes'),
        _getCollectionCount('ads'),
        _getCollectionCount('live_streams'),
        _getActiveLiveStreamsCount(),
        _getHiddenItemsCount(),
      ]);

      return {
        'totalUsers': results[0],
        'totalHadiths': results[1],
        'totalDuas': results[2],
        'totalNews': results[3],
        'totalVideos': results[4],
        'totalClasses': results[5],
        'totalAds': results[6],
        'totalLiveStreams': results[7],
        'activeLiveStreams': results[8],
        'hiddenItems': results[9],
      };
    } catch (e) {
      rethrow;
    }
  }

  Future<int> _getCollectionCount(String collection) async {
    try {
      // Try count() first (available in newer versions)
      try {
        final snapshot = await _firestore.collection(collection).count().get();
        return snapshot.count ?? 0;
      } catch (_) {
        // Fallback: get all documents and count
        final snapshot = await _firestore.collection(collection).get();
        return snapshot.docs.length;
      }
    } catch (e) {
      return 0;
    }
  }

  Future<int> _getActiveLiveStreamsCount() async {
    try {
      // Try count() first (available in newer versions)
      try {
        final snapshot = await _firestore
            .collection('live_streams')
            .where('isActive', isEqualTo: true)
            .count()
            .get();
        return snapshot.count ?? 0;
      } catch (_) {
        // Fallback: get all documents and count
        final snapshot = await _firestore
            .collection('live_streams')
            .where('isActive', isEqualTo: true)
            .get();
        return snapshot.docs.length;
      }
    } catch (e) {
      return 0;
    }
  }

  Future<int> _getHiddenItemsCount() async {
    try {
      final results = await Future.wait([
        _getHiddenCountForCollection('hadiths'),
        _getHiddenCountForCollection('duas'),
        _getHiddenCountForCollection('classes'),
        _getHiddenCountForCollection('videos'),
      ]);

      int total = 0;
      for (final count in results) {
        total += count;
      }
      return total;
    } catch (e) {
      return 0;
    }
  }

  Future<int> _getHiddenCountForCollection(String collection) async {
    try {
      // Try count() first (available in newer versions)
      try {
        final snapshot = await _firestore
            .collection(collection)
            .where('isHidden', isEqualTo: true)
            .count()
            .get();
        return snapshot.count ?? 0;
      } catch (_) {
        // Fallback: get all documents and count
        final snapshot = await _firestore
            .collection(collection)
            .where('isHidden', isEqualTo: true)
            .get();
        return snapshot.docs.length;
      }
    } catch (e) {
      return 0;
    }
  }
}

