class Hadith {
  final String id;
  final String title;
  final String content;
  final String? image;
  final String? source;
  final String? book;
  final String? narrator;
  final String? link;
  final String? notes;
  final DateTime? uploaded;
  final bool isHidden;

  Hadith({
    required this.id,
    required this.title,
    required this.content,
    this.image,
    this.source,
    this.book,
    this.narrator,
    this.link,
    this.notes,
    this.uploaded,
    this.isHidden = false,
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
      link: json['link'] as String?,
      notes: json['notes'] as String?,
      uploaded: json['uploaded'] != null ? DateTime.tryParse(json['uploaded']) : null,
      isHidden: json['isHidden'] as bool? ?? false,
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
      'link': link,
      'notes': notes,
      'uploaded': uploaded?.toIso8601String(),
      'isHidden': isHidden,
    };
  }

  Hadith copyWith({
    String? id,
    String? title,
    String? content,
    String? image,
    String? source,
    String? book,
    String? narrator,
    String? link,
    String? notes,
    DateTime? uploaded,
    bool? isHidden,
  }) {
    return Hadith(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      image: image ?? this.image,
      source: source ?? this.source,
      book: book ?? this.book,
      narrator: narrator ?? this.narrator,
      link: link ?? this.link,
      notes: notes ?? this.notes,
      uploaded: uploaded ?? this.uploaded,
      isHidden: isHidden ?? this.isHidden,
    );
  }
} 