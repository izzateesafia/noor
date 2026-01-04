class Ad {
  final String? id;
  final String title;
  final String? description;
  final String? image;
  final String? link;
  final String? notes;
  final DateTime? uploaded;
  final DateTime? deadline;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isActive;

  Ad({
    this.id,
    required this.title,
    this.description,
    this.image,
    this.link,
    this.notes,
    this.uploaded,
    this.deadline,
    this.createdAt,
    this.updatedAt,
    this.isActive = true,
  });

  factory Ad.fromJson(Map<String, dynamic> json) {
    return Ad(
      id: json['id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      image: json['image'] as String?,
      link: json['link'] as String?,
      notes: json['notes'] as String?,
      uploaded: json['uploaded'] != null ? DateTime.tryParse(json['uploaded']) : null,
      deadline: json['deadline'] != null ? DateTime.tryParse(json['deadline']) : null,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'description': description,
      'image': image,
      'link': link,
      'notes': notes,
      'uploaded': uploaded?.toIso8601String(),
      'deadline': deadline?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isActive': isActive,
    };
  }

  Ad copyWith({
    String? id,
    String? title,
    String? description,
    String? image,
    String? link,
    String? notes,
    DateTime? uploaded,
    DateTime? deadline,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return Ad(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      image: image ?? this.image,
      link: link ?? this.link,
      notes: notes ?? this.notes,
      uploaded: uploaded ?? this.uploaded,
      deadline: deadline ?? this.deadline,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }
} 