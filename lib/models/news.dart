class News {
  final String? id;
  final String title;
  final String? description;
  final String? image;
  final String? link;
  final DateTime? uploaded;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isActive;
  final int? order; // For ordering news items

  News({
    this.id,
    required this.title,
    this.description,
    this.image,
    this.link,
    this.uploaded,
    this.createdAt,
    this.updatedAt,
    this.isActive = true,
    this.order,
  });

  factory News.fromJson(Map<String, dynamic> json) {
    return News(
      id: json['id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      image: json['image'] as String?,
      link: json['link'] as String?,
      uploaded: json['uploaded'] != null ? DateTime.tryParse(json['uploaded']) : null,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
      isActive: json['isActive'] ?? true,
      order: json['order'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'description': description,
      'image': image,
      'link': link,
      'uploaded': uploaded?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isActive': isActive,
      if (order != null) 'order': order,
    };
  }
}

