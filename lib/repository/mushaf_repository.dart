import '../models/mushaf_model.dart';

class MushafRepository {
  static final MushafRepository _instance = MushafRepository._internal();
  factory MushafRepository() => _instance;
  MushafRepository._internal();

  // Hardcoded list of available mushafs
  // TODO: Move to Firestore later for dynamic management
  List<MushafModel> _mushafs = [];

  /// Initialize the repository with available mushafs
  void initialize() {
    _mushafs = [
      // Hafs Riwayah
      MushafModel(
        id: 'hafs_medina',
        name: 'Mushaf Madinah',
        nameArabic: 'مصحف المدينة',
        description: 'Hafs narration - King Fahd Complex',
        riwayah: 'Hafs',
        pdfUrl: '', // Will be set from Firebase Storage or remote server
        totalPages: 604,
        isPremium: false,
      ),
      MushafModel(
        id: 'hafs_tajweed',
        name: 'Mushaf Tajweed',
        nameArabic: 'مصحف التجويد',
        description: 'Hafs with Tajweed rules',
        riwayah: 'Hafs',
        pdfUrl: '', // Will be set from Firebase Storage or remote server
        totalPages: 604,
        isPremium: false,
      ),
      MushafModel(
        id: 'hafs_medina_old',
        name: 'Mushaf Madinah (Old)',
        nameArabic: 'مصحف المدينة القديم',
        description: 'Hafs narration - Old version',
        riwayah: 'Hafs',
        pdfUrl: '', // Will be set from Firebase Storage or remote server
        totalPages: 604,
        isPremium: false,
      ),

      // Warsh Riwayah
      MushafModel(
        id: 'warsh',
        name: 'Mushaf Warsh',
        nameArabic: 'مصحف ورش',
        description: 'Warsh narration from Nafi - King Fahd Complex',
        riwayah: 'Warsh',
        pdfUrl: '', // Will be set from Firebase Storage or remote server
        totalPages: 576,
        isPremium: false,
      ),
      MushafModel(
        id: 'warsh2',
        name: 'Mushaf Warsh 2',
        nameArabic: 'مصحف ورش 2',
        description: 'Warsh narration from Nafi - Asbahani route',
        riwayah: 'Warsh',
        pdfUrl: '', // Will be set from Firebase Storage or remote server
        totalPages: 610,
        isPremium: false,
      ),

      // Qaloon Riwayah
      MushafModel(
        id: 'qaloon',
        name: 'Mushaf Qaloon',
        nameArabic: 'مصحف قالون',
        description: 'Qaloon narration from Nafi - King Fahd Complex',
        riwayah: 'Qaloon',
        pdfUrl: '', // Will be set from Firebase Storage or remote server
        totalPages: 576,
        isPremium: false,
      ),

      // Douri Riwayah
      MushafModel(
        id: 'douri',
        name: 'Mushaf Douri',
        nameArabic: 'مصحف الدوري',
        description: 'Douri narration from Abu Amr al-Basri - King Fahd Complex',
        riwayah: 'Douri',
        pdfUrl: '', // Will be set from Firebase Storage or remote server
        totalPages: 544,
        isPremium: false,
      ),

      // Shubah Riwayah
      MushafModel(
        id: 'shubah',
        name: 'Mushaf Shubah',
        nameArabic: 'مصحف شعبة',
        description: 'Shubah narration from Asim - King Fahd Complex',
        riwayah: 'Shubah',
        pdfUrl: '', // Will be set from Firebase Storage or remote server
        totalPages: 624,
        isPremium: false,
      ),
    ];
  }

  /// Get all available mushafs
  List<MushafModel> getAllMushafs() {
    if (_mushafs.isEmpty) {
      initialize();
    }
    return List.unmodifiable(_mushafs);
  }

  /// Get mushafs filtered by riwayah
  List<MushafModel> getMushafsByRiwayah(String riwayah) {
    return getAllMushafs().where((m) => m.riwayah == riwayah).toList();
  }

  /// Get a specific mushaf by ID
  MushafModel? getMushafById(String id) {
    try {
      return getAllMushafs().firstWhere((m) => m.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get all unique riwayahs
  List<String> getAllRiwayahs() {
    return getAllMushafs()
        .map((m) => m.riwayah)
        .toSet()
        .toList()
      ..sort();
  }
}

