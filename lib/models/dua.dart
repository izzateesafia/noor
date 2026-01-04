class Dua {
  final String id;
  final String title;
  final String content;
  final String? image;
  final String? link;
  final String? notes;
  final DateTime? uploaded;
  final bool isHidden;

  Dua({
    required this.id,
    required this.title,
    required this.content,
    this.image,
    this.link,
    this.notes,
    this.uploaded,
    this.isHidden = false,
  });

  factory Dua.fromJson(Map<String, dynamic> json) {
    DateTime? parseUploaded(dynamic uploaded) {
      if (uploaded == null) return null;
      
      // Handle Firestore Timestamp
      if (uploaded is Map && uploaded.containsKey('_seconds')) {
        final seconds = uploaded['_seconds'] as int;
        return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
      }
      
      // Handle Firestore Timestamp (alternative format)
      if (uploaded is Map && uploaded.containsKey('seconds')) {
        final seconds = uploaded['seconds'] as int;
        final nanoseconds = (uploaded['nanoseconds'] as int?) ?? 0;
        return DateTime.fromMillisecondsSinceEpoch(
          seconds * 1000 + (nanoseconds ~/ 1000000),
        );
      }
      
      // Handle ISO string
      if (uploaded is String) {
        return DateTime.tryParse(uploaded);
      }
      
      return null;
    }
    
    return Dua(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      image: json['image'] as String?,
      link: json['link'] as String?,
      notes: json['notes'] as String?,
      uploaded: parseUploaded(json['uploaded']),
      isHidden: json['isHidden'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'image': image,
      'link': link,
      'notes': notes,
      'uploaded': uploaded?.toIso8601String(),
      'isHidden': isHidden,
    };
  }

  Dua copyWith({
    String? id,
    String? title,
    String? content,
    String? image,
    String? link,
    String? notes,
    DateTime? uploaded,
    bool? isHidden,
  }) {
    return Dua(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      image: image ?? this.image,
      link: link ?? this.link,
      notes: notes ?? this.notes,
      uploaded: uploaded ?? this.uploaded,
      isHidden: isHidden ?? this.isHidden,
    );
  }
} 