import 'video_category.dart';

class Video {
  final String id;
  final String title;
  final String description;
  final String thumbnailUrl;
  final String videoUrl;
  final String? category;
  final Duration? duration;
  final DateTime? uploadedAt;
  final int? views;
  final bool isPremium;
  final bool isHidden;
  final bool isFeatured;
  final bool isPopular;
  final bool isForYou;

  Video({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    required this.videoUrl,
    this.category,
    this.duration,
    this.uploadedAt,
    this.views,
    this.isPremium = false,
    this.isHidden = false,
    this.isFeatured = false,
    this.isPopular = false,
    this.isForYou = false,
  });

  factory Video.fromJson(Map<String, dynamic> json) {
    DateTime? parseUploadedAt(dynamic uploadedAt) {
      if (uploadedAt == null) return null;
      
      // Handle Firestore Timestamp
      if (uploadedAt is Map && uploadedAt.containsKey('_seconds')) {
        final seconds = uploadedAt['_seconds'] as int;
        return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
      }
      
      // Handle Firestore Timestamp (alternative format)
      if (uploadedAt is Map && uploadedAt.containsKey('seconds')) {
        final seconds = uploadedAt['seconds'] as int;
        final nanoseconds = (uploadedAt['nanoseconds'] as int?) ?? 0;
        return DateTime.fromMillisecondsSinceEpoch(
          seconds * 1000 + (nanoseconds ~/ 1000000),
        );
      }
      
      // Handle ISO string
      if (uploadedAt is String) {
        return DateTime.tryParse(uploadedAt);
      }
      
      return null;
    }
    
    return Video(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      thumbnailUrl: json['thumbnailUrl'] as String,
      videoUrl: json['videoUrl'] as String,
      category: json['category'] as String?,
      duration: json['duration'] != null
          ? Duration(seconds: json['duration'] as int)
          : null,
      uploadedAt: parseUploadedAt(json['uploadedAt']),
      views: json['views'] as int?,
      isPremium: json['isPremium'] as bool? ?? false,
      isHidden: json['isHidden'] as bool? ?? false,
      isFeatured: json['isFeatured'] as bool? ?? false,
      isPopular: json['isPopular'] as bool? ?? false,
      isForYou: json['isForYou'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'thumbnailUrl': thumbnailUrl,
      'videoUrl': videoUrl,
      'category': category,
      'duration': duration?.inSeconds,
      'uploadedAt': uploadedAt?.toIso8601String(),
      'views': views,
      'isPremium': isPremium,
      'isHidden': isHidden,
      'isFeatured': isFeatured,
      'isPopular': isPopular,
      'isForYou': isForYou,
    };
  }

  Video copyWith({
    String? id,
    String? title,
    String? description,
    String? thumbnailUrl,
    String? videoUrl,
    String? category,
    Duration? duration,
    DateTime? uploadedAt,
    int? views,
    bool? isPremium,
    bool? isHidden,
    bool? isFeatured,
    bool? isPopular,
    bool? isForYou,
  }) {
    return Video(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      category: category ?? this.category,
      duration: duration ?? this.duration,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      views: views ?? this.views,
      isPremium: isPremium ?? this.isPremium,
      isHidden: isHidden ?? this.isHidden,
      isFeatured: isFeatured ?? this.isFeatured,
      isPopular: isPopular ?? this.isPopular,
      isForYou: isForYou ?? this.isForYou,
    );
  }

  /// Converts the category string to a VideoCategory enum if it matches a predefined category
  VideoCategory? getCategoryEnum() {
    return VideoCategory.fromString(category);
  }
}




