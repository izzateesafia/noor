import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran/quran.dart' as quran;
import '../theme_constants.dart';
import 'widgets/surah_detail_page.dart';

class QuranSearchPage extends StatefulWidget {
  const QuranSearchPage({super.key});

  @override
  State<QuranSearchPage> createState() => _QuranSearchPageState();
}

class _QuranSearchPageState extends State<QuranSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  String _selectedTranslation = 'indonesian';

  final Map<String, String> _translations = {
    'indonesian': 'Bahasa Indonesia (Paling hampir dengan Bahasa Melayu)',
    'enSaheeh': 'Bahasa Inggeris (Saheeh International)',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cari Al-Quran'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _selectedTranslation = value;
              });
              if (_searchController.text.isNotEmpty) {
                _performSearch(_searchController.text);
              }
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
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search in Quran...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchResults.clear();
                          });
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (query) {
                if (query.length >= 2) {
                  _performSearch(query);
                } else {
                  setState(() {
                    _searchResults.clear();
                  });
                }
              },
            ),
          ),
          
          // Translation info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.translate, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Searching in: ${_translations[_selectedTranslation]}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Search results
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty
                    ? _buildEmptyState()
                    : _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Search the Quran',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter at least 2 characters to search',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final result = _searchResults[index];
        return _buildSearchResultCard(result);
      },
    );
  }

  Widget _buildSearchResultCard(Map<String, dynamic> result) {
    final surahNumber = result['surahNumber'] as int;
    final verseNumber = result['verseNumber'] as int;
    final arabicVerse = result['arabicVerse'] as String;
    final translation = result['translation'] as String;
    final surahName = quran.getSurahName(surahNumber);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
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
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$surahName $verseNumber',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Arabic verse
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Text(
                  arabicVerse,
                  textAlign: TextAlign.right,
                  style: GoogleFonts.amiriQuran(
                    fontSize: 20,
                    height: 1.6,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Translation
              Text(
                translation,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.4,
                  color: Colors.grey[700],
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _performSearch(String query) {
    setState(() {
      _isSearching = true;
    });

    // Perform search in a separate isolate to avoid blocking UI
    Future.delayed(const Duration(milliseconds: 300), () {
      final results = <Map<String, dynamic>>[];
      
      try {
        // Search through all surahs and verses
        for (int surahNumber = 1; surahNumber <= quran.totalSurahCount; surahNumber++) {
          final verseCount = quran.getVerseCount(surahNumber);
          
          for (int verseNumber = 1; verseNumber <= verseCount; verseNumber++) {
            // Get translation based on selected language
            final translation = _getTranslation(surahNumber, verseNumber);
            
            // Check if query matches translation
            if (translation.toLowerCase().contains(query.toLowerCase())) {
              final arabicVerse = quran.getVerse(surahNumber, verseNumber, verseEndSymbol: true);
              
              results.add({
                'surahNumber': surahNumber,
                'verseNumber': verseNumber,
                'arabicVerse': arabicVerse,
                'translation': translation,
              });
              
              // Limit results to avoid performance issues
              if (results.length >= 50) break;
            }
          }
          
          if (results.length >= 50) break;
        }
      } catch (e) {
        // Handle any errors
        print('Search error: $e');
      }
      
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    });
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
