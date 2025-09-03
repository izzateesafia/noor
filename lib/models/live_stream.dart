class LiveStream {
  final String id;
  final String title;
  final String description;
  final String tiktokLiveLink;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  LiveStream({
    required this.id,
    required this.title,
    required this.description,
    required this.tiktokLiveLink,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
  });

  factory LiveStream.fromJson(Map<String, dynamic> json) {
    return LiveStream(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      tiktokLiveLink: json['tiktokLiveLink'] ?? '',
      isActive: json['isActive'] ?? false,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'tiktokLiveLink': tiktokLiveLink,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  LiveStream copyWith({
    String? id,
    String? title,
    String? description,
    String? tiktokLiveLink,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LiveStream(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      tiktokLiveLink: tiktokLiveLink ?? this.tiktokLiveLink,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 