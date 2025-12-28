import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran/quran.dart' as quran;
import 'theme_constants.dart';
import 'widgets/surah_detail_page.dart';
import 'repository/mushaf_repository.dart';
import 'models/mushaf_model.dart';
import 'pages/pdf_mushaf_viewer_page.dart';

class QuranReaderPage extends StatefulWidget {
  const QuranReaderPage({super.key});

  @override
  State<QuranReaderPage> createState() => _QuranReaderPageState();
}

class _QuranReaderPageState extends State<QuranReaderPage> {
  List<int> _filteredSurahs = [];
  String _currentViewMode = 'surah'; // Track current view mode
  final MushafRepository _mushafRepository = MushafRepository();

  @override
  void initState() {
    super.initState();
    _initializeSurahs();
  }

  void _initializeSurahs() {
    _filteredSurahs = List.generate(quran.totalSurahCount, (index) => index + 1);
  }

  /// Fetch Madinah Old mushaf and navigate to PDF viewer
  Future<void> _navigateToMadinahOldMushaf() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Fetch all mushafs
      final mushafs = await _mushafRepository.getAllMushafs();
      
      // Find Madinah Old mushaf (case-insensitive search)
      MushafModel? madinahOldMushaf;
      for (var mushaf in mushafs) {
        final nameLower = mushaf.name.toLowerCase();
        if (nameLower.contains('madinah') && nameLower.contains('old')) {
          madinahOldMushaf = mushaf;
          break;
        }
      }

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (madinahOldMushaf != null) {
        // Navigate to PDF viewer with Madinah Old mushaf
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PDFMushafViewerPage(mushaf: madinahOldMushaf!),
            ),
          );
        }
      } else {
        // Show error if mushaf not found
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Madinah Old mushaf not found. Please try again.'),
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) {
        Navigator.of(context).pop();
      }
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading mushaf: $e'),
          ),
        );
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Surah-surah'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // View switcher
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _currentViewMode = value;
              });
              if (value == 'mushaf') {
                _navigateToMadinahOldMushaf();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'surah',
                child: Row(
                  children: [
                    Icon(
                      Icons.list, 
                      size: 16,
                      color: _currentViewMode == 'surah' ? AppColors.primary : Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Surah-surah',
                      style: TextStyle(
                        color: _currentViewMode == 'surah' ? AppColors.primary : Theme.of(context).textTheme.bodyLarge?.color,
                        fontWeight: _currentViewMode == 'surah' ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    const Spacer(),
                    if (_currentViewMode == 'surah')
                      Icon(
                        Icons.check,
                        size: 16,
                        color: AppColors.primary,
                      ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'mushaf',
                child: Row(
                  children: [
                    Icon(
                      Icons.book, 
                      size: 16,
                      color: _currentViewMode == 'mushaf' ? AppColors.primary : Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Mushaf',
                      style: TextStyle(
                        color: _currentViewMode == 'mushaf' ? AppColors.primary : Theme.of(context).textTheme.bodyLarge?.color,
                        fontWeight: _currentViewMode == 'mushaf' ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    const Spacer(),
                    if (_currentViewMode == 'mushaf')
                      Icon(
                        Icons.check,
                        size: 16,
                        color: AppColors.primary,
                      ),
                  ],
                ),
              ),
            ],
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(Icons.view_module),
            ),
            tooltip: 'Switch View',
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).pushNamed('/quran_search');
            },
            icon: const Icon(Icons.search),
            tooltip: 'Search Quran',
          ),
        ],
      ),
      body: Column(
        children: [
          // Header with Quran info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                Text(
                  'القرآن الكريم',
                  style: GoogleFonts.amiriQuran(
                    fontSize: 32,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'The Holy Quran',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildInfoChip('${quran.totalSurahCount}', 'Surahs'),
                    _buildInfoChip('${quran.totalVerseCount}', 'Verses'),
                    _buildInfoChip('${quran.totalJuzCount}', 'Juz'),
                    _buildInfoChip('${quran.totalPagesCount}', 'Pages'),
                  ],
                ),
              ],
            ),
          ),
          

          
          // Surah list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredSurahs.length,
              itemBuilder: (context, index) {
                final surahNumber = _filteredSurahs[index];
                return _buildSurahCard(surahNumber);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildSurahCard(int surahNumber) {
    final surahName = quran.getSurahName(surahNumber);
    final surahNameArabic = quran.getSurahNameArabic(surahNumber);
    final verseCount = quran.getVerseCount(surahNumber);
    final placeOfRevelation = quran.getPlaceOfRevelation(surahNumber);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Center(
            child: Text(
              surahNumber.toString(),
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              surahName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              surahNameArabic,
              style: GoogleFonts.amiriQuran(
                fontSize: 22,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.format_list_numbered,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  '$verseCount verses',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  placeOfRevelation,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey[400],
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => SurahDetailPage(
                surahNumber: surahNumber,
                surahName: surahName,
              ),
            ),
          );
        },
      ),
    );
  }




}
