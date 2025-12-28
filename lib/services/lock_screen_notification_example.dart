/// Example usage of LockScreenNotificationService
/// 
/// This file demonstrates how to use the lock screen notification service
/// to display Quran verses on the Android lock screen.

import 'package:quran/quran.dart' as quran;
import 'lock_screen_notification_service.dart';

/// Example: Show daily Quran verse on lock screen
Future<void> showDailyVerseOnLockScreen() async {
  final service = LockScreenNotificationService();
  
  // Get a daily verse (using day of year for consistency)
  final now = DateTime.now();
  final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
  final randomVerse = quran.RandomVerse();
  
  final arabicVerse = randomVerse.verse;
  final translation = quran.getVerseTranslation(
    randomVerse.surahNumber,
    randomVerse.verseNumber,
    translation: quran.Translation.indonesian,
  );
  final surahName = quran.getSurahName(randomVerse.surahNumber);
  
  // Show on lock screen
  await service.showLockScreenNotification(
    title: 'Quran Reminder - $surahName',
    body: translation,
    expandedText: '$arabicVerse\n\n$translation\n\n$surahName, Ayat ${randomVerse.verseNumber}',
  );
}

/// Example: Update lock screen notification with new verse
Future<void> updateLockScreenVerse() async {
  final service = LockScreenNotificationService();
  
  final randomVerse = quran.RandomVerse();
  final arabicVerse = randomVerse.verse;
  final translation = quran.getVerseTranslation(
    randomVerse.surahNumber,
    randomVerse.verseNumber,
    translation: quran.Translation.indonesian,
  );
  final surahName = quran.getSurahName(randomVerse.surahNumber);
  
  // Update existing notification
  await service.updateLockScreenNotification(
    title: 'Quran Reminder - $surahName',
    body: translation,
    expandedText: '$arabicVerse\n\n$translation',
  );
}

/// Example: Schedule daily verse updates
/// This can be integrated with WorkManager or a scheduling service
Future<void> scheduleDailyVerseUpdates() async {
  // This is a placeholder - integrate with your scheduling system
  // For example, use WorkManager to call showDailyVerseOnLockScreen()
  // at specific times (e.g., daily at Fajr time)
  
  // Example: Update every 6 hours
  // WorkManager().registerPeriodicTask(
  //   'update_lock_screen_verse',
  //   'updateLockScreenVerse',
  //   frequency: Duration(hours: 6),
  // );
}

/// Example: Dismiss lock screen notification
Future<void> dismissLockScreenNotification() async {
  final service = LockScreenNotificationService();
  await service.dismissLockScreenNotification();
}

