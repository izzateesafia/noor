class MushafModel {
  final String id;
  final String name;
  final String nameArabic;
  final String description;
  final String riwayah;
  final String pdfUrl;
  final int totalPages;
  final String? thumbnailUrl;
  final bool isPremium;

  MushafModel({
    required this.id,
    required this.name,
    required this.nameArabic,
    required this.description,
    required this.riwayah,
    required this.pdfUrl,
    required this.totalPages,
    this.thumbnailUrl,
    this.isPremium = false,
  });

  factory MushafModel.fromJson(Map<String, dynamic> json) {
    return MushafModel(
      id: json['id'] as String,
      name: json['name'] as String,
      nameArabic: json['nameArabic'] as String? ?? json['name'] as String,
      description: json['description'] as String? ?? '',
      riwayah: json['riwayah'] as String,
      pdfUrl: json['pdfUrl'] as String,
      totalPages: json['totalPages'] as int? ?? 604,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      isPremium: json['isPremium'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nameArabic': nameArabic,
      'description': description,
      'riwayah': riwayah,
      'pdfUrl': pdfUrl,
      'totalPages': totalPages,
      'thumbnailUrl': thumbnailUrl,
      'isPremium': isPremium,
    };
  }
}

