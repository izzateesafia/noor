class Dua {
  final String id;
  final String title;
  final String content;
  final String? image;
  final String? link;
  final String? notes;
  final DateTime? uploaded;

  Dua({
    required this.id,
    required this.title,
    required this.content,
    this.image,
    this.link,
    this.notes,
    this.uploaded,
  });

  factory Dua.fromJson(Map<String, dynamic> json) {
    return Dua(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      image: json['image'] as String?,
      link: json['link'] as String?,
      notes: json['notes'] as String?,
      uploaded: json['uploaded'] != null ? DateTime.tryParse(json['uploaded']) : null,
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
    };
  }
} 