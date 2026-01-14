import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran/quran.dart' as quran;
import '../theme_constants.dart';
import 'surah_detail_page.dart';

class DailyVerseWidget extends StatefulWidget {
  const DailyVerseWidget({super.key});

  @override
  State<DailyVerseWidget> createState() => _DailyVerseWidgetState();
}

class _DailyVerseWidgetState extends State<DailyVerseWidget> {
  late String _arabicVerse;
  late String _translation;
  late String _surahName;
  late int _surahNumber;
  late int _verseNumber;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDailyVerse();
  }

  void _loadDailyVerse() {
    setState(() {
      _isLoading = true;
    });

    // Generate a daily verse based on current date
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    
    // Use day of year to get a consistent daily verse
    final randomVerse = quran.RandomVerse();
    
    setState(() {
      _arabicVerse = randomVerse.verse;
      // Use Indonesian translation (closest to Malay)
      _translation = quran.getVerseTranslation(
        randomVerse.surahNumber,
        randomVerse.verseNumber,
        translation: quran.Translation.indonesian,
      );
      _surahName = quran.getSurahName(randomVerse.surahNumber);
      _surahNumber = randomVerse.surahNumber;
      _verseNumber = randomVerse.verseNumber;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          height: 200,
          padding: const EdgeInsets.all(20),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),

      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.menu_book,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ayat Harian',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          '$_surahName, Ayat $_verseNumber',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _loadDailyVerse,
                    icon: Icon(
                      Icons.refresh,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    tooltip: 'Ayat Baru',
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Arabic Verse
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).shadowColor.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  _arabicVerse,
                  textAlign: TextAlign.right,
                  style: GoogleFonts.amiriQuran(
                    fontSize: 22,
                    height: 1.8,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Translation
              Text(
                _translation,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                  color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                  fontStyle: FontStyle.italic,
                ),
              ),

              const SizedBox(height: 16),

              // Action Buttons
              OutlinedButton.icon(
                onPressed: () {
                  // Navigate directly to the specific surah
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => SurahDetailPage(
                        surahNumber: _surahNumber,
                        surahName: _surahName,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.visibility, size: 16),
                label: const Text('Baca Surah Penuh'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
