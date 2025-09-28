import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran/quran.dart' as quran;
import '../theme_constants.dart';

class MushafPage extends StatelessWidget {
  final int pageNumber;

  const MushafPage({
    super.key,
    required this.pageNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Theme.of(context).scaffoldBackgroundColor,
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
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).dividerColor.withOpacity(0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).shadowColor.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      versesText,
                      textAlign: TextAlign.justify, // Better text distribution for continuous flow
                      style: GoogleFonts.amiriQuran(
                        fontSize: 24,
                        height: 2.2,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Minimal footer
              _buildMinimalFooter(context, pageNumber),
            ],
          ),
        ),
        
        // Floating navigation buttons
        // _buildFloatingNavigation(pageNumber),
      ],
    );
  }

  Widget _buildMinimalFooter(BuildContext context, int pageNumber) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        'Juz ${_getJuzFromPage(pageNumber)} • Halaman $pageNumber daripada ${quran.totalPagesCount}',
        style: TextStyle(
          color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
          fontSize: 12,
        ),
        textAlign: TextAlign.center,
      ),
    );
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
