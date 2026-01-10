import '../repository/video_repository.dart';
import '../models/video.dart';

/// Helper function to seed dummy videos for testing
/// Call this from admin page or directly to add sample videos
Future<void> seedDummyVideos() async {
  final repository = VideoRepository();
  
  final dummyVideos = [
    Video(
      id: '',
      title: 'Introduction to Quran Recitation',
      description: 'Learn the basics of proper Quran recitation with tajweed rules',
      thumbnailUrl: 'https://images.unsplash.com/photo-1604147706283-d7119b5b822c?w=400',
      videoUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      category: 'Tajweed',
      duration: const Duration(minutes: 15),
      uploadedAt: DateTime.now().subtract(const Duration(days: 2)),
      views: 1250,
      isPremium: false,
    ),
    Video(
      id: '',
      title: 'Understanding Tafsir: Surah Al-Fatiha',
      description: 'Deep dive into the meaning and interpretation of the opening chapter',
      thumbnailUrl: 'https://images.unsplash.com/photo-1519074069444-1ba4fff66e16?w=400',
      videoUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      category: 'Tafsir',
      duration: const Duration(minutes: 30),
      uploadedAt: DateTime.now().subtract(const Duration(days: 5)),
      views: 3200,
      isPremium: false,
    ),
    Video(
      id: '',
      title: 'Hadith of the Day: Kindness to Parents',
      description: 'Exploring authentic hadiths about respecting and honoring parents',
      thumbnailUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400',
      videoUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      category: 'Hadith',
      duration: const Duration(minutes: 20),
      uploadedAt: DateTime.now().subtract(const Duration(days: 1)),
      views: 890,
      isPremium: false,
    ),
    Video(
      id: '',
      title: 'Seerah: Life of Prophet Muhammad (PBUH)',
      description: 'Comprehensive series on the biography of the Prophet',
      thumbnailUrl: 'https://images.unsplash.com/photo-1502082553048-f009c37129b9?w=400',
      videoUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      category: 'Seerah',
      duration: const Duration(minutes: 45),
      uploadedAt: DateTime.now().subtract(const Duration(days: 7)),
      views: 5600,
      isPremium: true,
    ),
    Video(
      id: '',
      title: 'Advanced Tajweed: Rules of Noon and Meem',
      description: 'Master the complex rules of noon sakinah and meem sakinah',
      thumbnailUrl: 'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=400',
      videoUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      category: 'Tajweed',
      duration: const Duration(minutes: 25),
      uploadedAt: DateTime.now().subtract(const Duration(days: 3)),
      views: 2100,
      isPremium: true,
    ),
    Video(
      id: '',
      title: 'Daily Dua: Morning and Evening Supplications',
      description: 'Essential duas to recite in the morning and evening',
      thumbnailUrl: 'https://images.unsplash.com/photo-1519681393784-d120267933ba?w=400',
      videoUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      category: 'Dua',
      duration: const Duration(minutes: 12),
      uploadedAt: DateTime.now().subtract(const Duration(days: 4)),
      views: 1800,
      isPremium: false,
    ),
  ];

  for (final video in dummyVideos) {
    try {
      await repository.addVideo(video);
    } catch (e) {
    }
  }
  
}












