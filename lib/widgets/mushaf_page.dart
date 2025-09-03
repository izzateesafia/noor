import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran/quran.dart' as quran;
import '../theme_constants.dart';

class MushafPage extends StatelessWidget {
  final int pageNumber;
  final bool showTranslation;
  final String selectedTranslation;

  const MushafPage({
    super.key,
    required this.pageNumber,
    this.showTranslation = false,
    this.selectedTranslation = 'indonesian',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.white,
      child: _buildSinglePage(context, pageNumber, isLeftPage: true),
    );
  }

  Widget _buildSinglePage(BuildContext context, int pageNumber, {required bool isLeftPage}) {
    final pageData = quran.getPageData(pageNumber);
    final versesTextList = quran.getVersesTextByPage(
      pageNumber,
      verseEndSymbol: true,
    );
    // Join verses with spaces for continuous flow like traditional Mushaf
    final versesText = versesTextList.join(' ');

    return Stack(
      children: [
        // Full screen content
        Container(
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
        
              // Full screen Arabic text
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Text(
                      versesText,
                      textAlign: TextAlign.justify, // Better text distribution for continuous flow
                      style: GoogleFonts.amiriQuran(
                        fontSize: 24,
                        height: 2.2,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Translation (if enabled) - smaller to fit
              if (showTranslation) ...[
                Expanded(
                  flex: 1,
                  child: _buildCompactTranslation(pageNumber),
                ),
              ],
              
              // Minimal footer
              _buildMinimalFooter(pageNumber),
            ],
          ),
        ),
        
        // Floating navigation buttons
        // _buildFloatingNavigation(pageNumber),
      ],
    );
  }

  Widget _buildMinimalFooter(int pageNumber) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        'Juz ${_getJuzFromPage(pageNumber)} • Page $pageNumber of ${quran.totalPagesCount}',
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 12,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildCompactTranslation(int pageNumber) {
    final pageData = quran.getPageData(pageNumber);
    final translations = <String>[];
    
    for (final surahData in pageData) {
      final surahNumber = surahData['surahNumber'] as int;
      final startVerse = surahData['startVerse'] as int;
      final endVerse = surahData['endVerse'] as int;
      
      for (int verseNumber = startVerse; verseNumber <= endVerse; verseNumber++) {
        final translation = _getTranslation(surahNumber, verseNumber);
        translations.add('$verseNumber. $translation');
      }
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: translations.map((translation) => Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              translation,
              style: const TextStyle(
                fontSize: 12,
                height: 1.3,
                color: Colors.black87,
              ),
            ),
          )).toList(),
        ),
      ),
    );
  }

  String _getTranslation(int surahNumber, int verseNumber) {
    switch (selectedTranslation) {
      case 'indonesian':
        return quran.getVerseTranslation(
          surahNumber,
          verseNumber,
          translation: quran.Translation.indonesian,
        );
      case 'enSaheeh':
        return quran.getVerseTranslation(
          surahNumber,
          verseNumber,
          translation: quran.Translation.enSaheeh,
        );
      case 'enClearQuran':
        return quran.getVerseTranslation(
          surahNumber,
          verseNumber,
          translation: quran.Translation.enClearQuran,
        );
      case 'urdu':
        return quran.getVerseTranslation(
          surahNumber,
          verseNumber,
          translation: quran.Translation.urdu,
        );
      case 'french':
        return quran.getVerseTranslation(
          surahNumber,
          verseNumber,
          translation: quran.Translation.frHamidullah,
        );
      case 'turkish':
        return quran.getVerseTranslation(
          surahNumber,
          verseNumber,
          translation: quran.Translation.trSaheeh,
        );
      default:
        return quran.getVerseTranslation(
          surahNumber,
          verseNumber,
          translation: quran.Translation.indonesian,
        );
    }
  }

  int _getJuzFromPage(int pageNumber) {
    // Approximate Juz calculation based on page number
    // This is a simplified calculation - in reality, Juz boundaries vary
    if (pageNumber <= 20) return 1;
    if (pageNumber <= 40) return 2;
    if (pageNumber <= 60) return 3;
    if (pageNumber <= 80) return 4;
    if (pageNumber <= 100) return 5;
    if (pageNumber <= 120) return 6;
    if (pageNumber <= 140) return 7;
    if (pageNumber <= 160) return 8;
    if (pageNumber <= 180) return 9;
    if (pageNumber <= 200) return 10;
    if (pageNumber <= 220) return 11;
    if (pageNumber <= 240) return 12;
    if (pageNumber <= 260) return 13;
    if (pageNumber <= 280) return 14;
    if (pageNumber <= 300) return 15;
    if (pageNumber <= 320) return 16;
    if (pageNumber <= 340) return 17;
    if (pageNumber <= 360) return 18;
    if (pageNumber <= 380) return 19;
    if (pageNumber <= 400) return 20;
    if (pageNumber <= 420) return 21;
    if (pageNumber <= 440) return 22;
    if (pageNumber <= 460) return 23;
    if (pageNumber <= 480) return 24;
    if (pageNumber <= 500) return 25;
    if (pageNumber <= 520) return 26;
    if (pageNumber <= 540) return 27;
    if (pageNumber <= 560) return 28;
    if (pageNumber <= 580) return 29;
    return 30;
  }
}
