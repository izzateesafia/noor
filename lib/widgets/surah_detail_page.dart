import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran/quran.dart' as quran;
import '../theme_constants.dart';

class SurahDetailPage extends StatefulWidget {
  final int surahNumber;
  final String surahName;

  const SurahDetailPage({
    super.key,
    required this.surahNumber,
    required this.surahName,
  });

  @override
  State<SurahDetailPage> createState() => _SurahDetailPageState();
}

class _SurahDetailPageState extends State<SurahDetailPage> {
  bool _showTranslation = false;
  bool _showArabic = true;
  String _selectedTranslation = 'indonesian';
  bool _isPlaying = false;

  final Map<String, String> _translations = {
    'indonesian': 'Bahasa Indonesia (Paling hampir dengan Bahasa Melayu)',
    'enSaheeh': 'Bahasa Inggeris (Saheeh International)',
  };

  @override
  Widget build(BuildContext context) {
    final surahNameArabic = quran.getSurahNameArabic(widget.surahNumber);
    final verseCount = quran.getVerseCount(widget.surahNumber);
    final placeOfRevelation = quran.getPlaceOfRevelation(widget.surahNumber);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.surahName),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _toggleAudio,
            icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _selectedTranslation = value;
              });
            },
            itemBuilder: (context) => _translations.entries.map((entry) {
              return PopupMenuItem(
                value: entry.key,
                child: Text(entry.value),
              );
            }).toList(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Surah header
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
                  surahNameArabic,
                  style: GoogleFonts.amiriQuran(
                    fontSize: 28,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.surahName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildInfoChip('$verseCount', 'Verses'),
                    _buildInfoChip(placeOfRevelation, 'Revelation'),
                    _buildInfoChip('${quran.getJuzNumber(widget.surahNumber, 1)}', 'Juz'),
                  ],
                ),
              ],
            ),
          ),
          
          // Controls
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).shadowColor.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.translate,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tunjukkan Terjemahan',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Switch(
                  value: _showTranslation,
                  onChanged: (value) {
                    setState(() {
                      _showTranslation = value;
                    });
                  },
                  activeColor: AppColors.primary,
                ),
              ],
            ),
          ),
          
          // Verses
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: verseCount,
              itemBuilder: (context, index) {
                final verseNumber = index + 1;
                return _buildVerseCard(verseNumber);
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
            fontSize: 16,
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

  Widget _buildVerseCard(int verseNumber) {
    final arabicVerse = quran.getVerse(widget.surahNumber, verseNumber, verseEndSymbol: true);
    final translation = _getTranslation(widget.surahNumber, verseNumber);
    final isSajdah = quran.isSajdahVerse(widget.surahNumber, verseNumber);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Verse number and controls
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    verseNumber.toString(),
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                if (isSajdah) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'سَجْدَةٌ',
                      style: GoogleFonts.amiriQuran(
                        color: Colors.orange[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                IconButton(
                  onPressed: () => _playVerseAudio(verseNumber),
                  icon: Icon(
                    Icons.play_arrow,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  tooltip: 'Play Audio',
                ),
                IconButton(
                  onPressed: () => _shareVerse(verseNumber),
                  icon: Icon(
                    Icons.share,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  tooltip: 'Share',
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Arabic verse
            if (_showArabic) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Text(
                  arabicVerse,
                  textAlign: TextAlign.right,
                  style: GoogleFonts.amiriQuran(
                    fontSize: 22,
                    height: 1.8,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            
            // Translation
            if (_showTranslation) ...[
              Text(
                translation,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getTranslation(int surahNumber, int verseNumber) {
    switch (_selectedTranslation) {
      case 'enSaheeh':
        return quran.getVerseTranslation(
          surahNumber,
          verseNumber,
          translation: quran.Translation.enSaheeh,
        );
      case 'indonesian':
      default:
        return quran.getVerseTranslation(
          surahNumber,
          verseNumber,
          translation: quran.Translation.indonesian,
        );
    }
  }

  void _toggleAudio() {
    setState(() {
      _isPlaying = !_isPlaying;
    });
    
    if (_isPlaying) {
      // Play full surah audio
      final audioUrl = quran.getAudioURLBySurah(
        widget.surahNumber,
        reciter: quran.Reciter.arAlafasy,
      );
      
      // TODO: Implement audio playback using audioplayers
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Playing ${widget.surahName} audio...'),
          action: SnackBarAction(
            label: 'Stop',
            onPressed: () {
              setState(() {
                _isPlaying = false;
              });
            },
          ),
        ),
      );
    }
  }

  void _playVerseAudio(int verseNumber) {
    final audioUrl = quran.getAudioURLByVerse(
      widget.surahNumber,
      verseNumber,
      reciter: quran.Reciter.arAlafasy,
    );
    
    // TODO: Implement audio playback using audioplayers
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Playing verse $verseNumber audio...'),
      ),
    );
  }

  void _shareVerse(int verseNumber) {
    final arabicVerse = quran.getVerse(widget.surahNumber, verseNumber);
    final translation = _getTranslation(widget.surahNumber, verseNumber);
    
    // TODO: Implement sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing verse $verseNumber...'),
      ),
    );
  }
}
