import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/daily_tracker.dart';

class DailyTrackerRepository {
  final _db = FirebaseFirestore.instance;
  final String _collection = 'daily_tracker';

  // Get today's tracker data for a user
  Future<DailyTrackerData?> getTodayTracker(String userId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // Use only userId filter to avoid composite index requirement
      final snapshot = await _db
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .get();

      // Filter by date in memory
      for (final doc in snapshot.docs) {
        final docDate = DateTime.parse(doc.data()['date']);
        if (docDate.isAfter(startOfDay) && docDate.isBefore(endOfDay)) {
          return DailyTrackerData.fromJson({...doc.data(), 'id': doc.id});
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get tracker data for a specific date
  Future<DailyTrackerData?> getTrackerByDate(String userId, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await _db
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
          .where('date', isLessThan: endOfDay.toIso8601String())
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        return DailyTrackerData.fromJson({...doc.data(), 'id': doc.id});
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get tracker history for a user (last 30 days)
  Future<List<DailyTrackerData>> getTrackerHistory(String userId, {int days = 30}) async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days));

      // Use only userId filter to avoid composite index requirement
      final snapshot = await _db
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .get();

      // Filter and sort in memory
      final List<DailyTrackerData> filteredData = [];
      
      for (final doc in snapshot.docs) {
        final docDate = DateTime.parse(doc.data()['date']);
        if (docDate.isAfter(startDate) || docDate.isAtSameMomentAs(startDate)) {
          filteredData.add(DailyTrackerData.fromJson({...doc.data(), 'id': doc.id}));
        }
      }
      
      // Sort by date in descending order
      filteredData.sort((a, b) => b.date.compareTo(a.date));
      
      return filteredData;
    } catch (e) {
      return [];
    }
  }

  // Create or update today's tracker
  Future<void> saveTodayTracker(DailyTrackerData tracker) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // Check if today's tracker already exists
      final existingSnapshot = await _db
          .collection(_collection)
          .where('userId', isEqualTo: tracker.userId)
          .get();

      // Find today's tracker in memory
      String? docId;
      
      for (final doc in existingSnapshot.docs) {
        final docDate = DateTime.parse(doc.data()['date']);
        if (docDate.isAfter(startOfDay) && docDate.isBefore(endOfDay)) {
          docId = doc.id;
          break;
        }
      }

      if (docId != null) {
        // Update existing tracker
        final updateData = tracker.toJson();
        updateData['updatedAt'] = DateTime.now().toIso8601String();
        await _db.collection(_collection).doc(docId).update(updateData);
      } else {
        // Create new tracker
        final createData = tracker.toJson();
        createData['createdAt'] = DateTime.now().toIso8601String();
        createData['updatedAt'] = DateTime.now().toIso8601String();
        await _db.collection(_collection).add(createData);
      }
    } catch (e) {
      rethrow;
    }
  }

  // Update specific prayer completion
  Future<void> updatePrayerCompletion(String userId, String prayer, bool completed) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // Use only userId filter to avoid composite index requirement
      final existingSnapshot = await _db
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .get();

      // Find today's tracker in memory
      String? docId;
      Map<String, dynamic>? docData;
      
      for (final doc in existingSnapshot.docs) {
        final docDate = DateTime.parse(doc.data()['date']);
        if (docDate.isAfter(startOfDay) && docDate.isBefore(endOfDay)) {
          docId = doc.id;
          docData = doc.data();
          break;
        }
      }

      if (docId != null && docData != null) {
        // Update existing tracker
        final prayersCompleted = Map<String, bool>.from(docData['prayersCompleted'] ?? {});
        prayersCompleted[prayer] = completed;

        await _db.collection(_collection).doc(docId).update({
          'prayersCompleted': prayersCompleted,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      } else {
        // Create new tracker with just this prayer
        final prayersCompleted = {
          'Fajr': false,
          'Dhuhr': false,
          'Asr': false,
          'Maghrib': false,
          'Isha': false,
        };
        prayersCompleted[prayer] = completed;

        await _db.collection(_collection).add({
          'userId': userId,
          'prayersCompleted': prayersCompleted,
          'quranRecited': false,
          'date': startOfDay.toIso8601String(),
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      rethrow;
    }
  }

  // Update Quran recitation status
  Future<void> updateQuranRecitation(String userId, bool recited) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // Use only userId filter to avoid composite index requirement
      final existingSnapshot = await _db
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .get();

      // Find today's tracker in memory
      String? docId;
      
      for (final doc in existingSnapshot.docs) {
        final docDate = DateTime.parse(doc.data()['date']);
        if (docDate.isAfter(startOfDay) && docDate.isBefore(endOfDay)) {
          docId = doc.id;
          break;
        }
      }

      if (docId != null) {
        // Update existing tracker
        await _db.collection(_collection).doc(docId).update({
          'quranRecited': recited,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      } else {
        // Create new tracker with default prayer values
        final prayersCompleted = {
          'Fajr': false,
          'Dhuhr': false,
          'Asr': false,
          'Maghrib': false,
          'Isha': false,
        };

        await _db.collection(_collection).add({
          'userId': userId,
          'prayersCompleted': prayersCompleted,
          'quranRecited': recited,
          'date': startOfDay.toIso8601String(),
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get statistics for a user
  Future<Map<String, dynamic>> getUserStats(String userId, {int days = 30}) async {
    try {
      final history = await getTrackerHistory(userId, days: days);
      
      int totalDays = history.length;
      int daysWithAllPrayers = 0;
      int daysWithQuran = 0;
      Map<String, int> prayerCounts = {
        'Fajr': 0,
        'Dhuhr': 0,
        'Asr': 0,
        'Maghrib': 0,
        'Isha': 0,
      };

      for (final tracker in history) {
        // Count days with all prayers completed
        if (tracker.prayersCompleted.values.every((completed) => completed)) {
          daysWithAllPrayers++;
        }

        // Count days with Quran recited
        if (tracker.quranRecited) {
          daysWithQuran++;
        }

        // Count individual prayers
        for (final entry in tracker.prayersCompleted.entries) {
          if (entry.value) {
            prayerCounts[entry.key] = (prayerCounts[entry.key] ?? 0) + 1;
          }
        }
      }

      return {
        'totalDays': totalDays,
        'daysWithAllPrayers': daysWithAllPrayers,
        'daysWithQuran': daysWithQuran,
        'prayerCounts': prayerCounts,
        'prayerCompletionRate': totalDays > 0 ? (daysWithAllPrayers / totalDays) * 100.0 : 0.0,
        'quranCompletionRate': totalDays > 0 ? (daysWithQuran / totalDays) * 100.0 : 0.0,
      };
    } catch (e) {
      return {};
    }
  }
}
