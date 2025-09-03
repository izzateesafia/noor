class Hadith {
  final String id;
  final String title;
  final String content;
  final String? image;
  final String? source;
  final String? book;
  final String? narrator;
  final DateTime? uploaded;

  Hadith({
    required this.id,
    required this.title,
    required this.content,
    this.image,
    this.source,
    this.book,
    this.narrator,
    this.uploaded,
  });

  factory Hadith.fromJson(Map<String, dynamic> json) {
    return Hadith(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      image: json['image'] as String?,
      source: json['source'] as String?,
      book: json['book'] as String?,
      narrator: json['narrator'] as String?,
      uploaded: json['uploaded'] != null ? DateTime.tryParse(json['uploaded']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'image': image,
      'source': source,
      'book': book,
      'narrator': narrator,
      'uploaded': uploaded?.toIso8601String(),
    };
  }
} 