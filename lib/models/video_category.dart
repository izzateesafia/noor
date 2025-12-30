enum VideoCategory {
  tajweed,
  tafsir,
  hadith,
  seerah,
  dua,
  fiqh,
  aqidah,
  quranRecitation,
  lecture,
  other;

  String get displayName {
    switch (this) {
      case VideoCategory.tajweed:
        return 'Tajweed';
      case VideoCategory.tafsir:
        return 'Tafsir';
      case VideoCategory.hadith:
        return 'Hadith';
      case VideoCategory.seerah:
        return 'Seerah';
      case VideoCategory.dua:
        return 'Dua';
      case VideoCategory.fiqh:
        return 'Fiqh';
      case VideoCategory.aqidah:
        return 'Aqidah';
      case VideoCategory.quranRecitation:
        return 'Quran Recitation';
      case VideoCategory.lecture:
        return 'Lecture';
      case VideoCategory.other:
        return 'Other';
    }
  }

  static VideoCategory? fromString(String? categoryString) {
    if (categoryString == null || categoryString.isEmpty) {
      return null;
    }

    for (var category in VideoCategory.values) {
      if (category.displayName.toLowerCase() == categoryString.toLowerCase()) {
        return category;
      }
    }

    return null;
  }

  static List<VideoCategory> get allCategories => VideoCategory.values;

  static List<VideoCategory> get predefinedCategories {
    return VideoCategory.values.where((c) => c != VideoCategory.other).toList();
  }
}

