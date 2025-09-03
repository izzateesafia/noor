import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran/quran.dart' as quran;
import '../theme_constants.dart';
import 'widgets/mushaf_page.dart';

class MushafReaderPage extends StatefulWidget {
  const MushafReaderPage({super.key});

  @override
  State<MushafReaderPage> createState() => _MushafReaderPageState();
}

class _MushafReaderPageState extends State<MushafReaderPage> {
  int _currentPage = 1;
  bool _showTranslation = false;
  String _selectedTranslation = 'indonesian';
  final PageController _pageController = PageController();

  final Map<String, String> _translations = {
    'indonesian': 'Bahasa Indonesia (Closest to Malay)',
    'enSaheeh': 'English (Saheeh International)',
    'enClearQuran': 'English (Clear Quran)',
    'urdu': 'Urdu',
    'french': 'French',
    'turkish': 'Turkish',
  };

  @override
  void initState() {
    super.initState();
    // Initialize page controller with current page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage - 1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mushaf Reader'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // View switcher
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'surah') {
                Navigator.of(context).pushNamed('/quran');
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'surah',
                child: Row(
                  children: [
                    Icon(Icons.list, size: 16),
                    SizedBox(width: 8),
                    Text('Surah View'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'mushaf',
                child: Row(
                  children: [
                    Icon(Icons.book, size: 16),
                    SizedBox(width: 8),
                    Text('Mushaf View'),
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
          // Translation toggle
          IconButton(
            onPressed: () {
              setState(() {
                _showTranslation = !_showTranslation;
              });
            },
            icon: Icon(
              _showTranslation ? Icons.translate : Icons.translate_outlined,
            ),
            tooltip: 'Toggle Translation',
          ),
          // Translation selection
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
          // Jump to page
          IconButton(
            onPressed: _showJumpToPageDialog,
            icon: const Icon(Icons.search),
            tooltip: 'Jump to Page',
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index + 1;
          });
        },
        itemCount: quran.totalPagesCount,
        itemBuilder: (context, index) {
          return MushafPage(
            pageNumber: index + 1,
            showTranslation: _showTranslation,
            selectedTranslation: _selectedTranslation,
          );
        },
      ),
    );
  }

  void _goToPage(int pageNumber) {
    setState(() {
      _currentPage = pageNumber;
    });
    _pageController.animateToPage(
      pageNumber - 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _goToPreviousPage() {
    if (_currentPage > 1) {
      _goToPage(_currentPage - 1);
    }
  }

  void _goToNextPage() {
    if (_currentPage < quran.totalPagesCount) {
      _goToPage(_currentPage + 1);
    }
  }

  void _goToFirstPage() {
    _goToPage(1);
  }

  void _goToLastPage() {
    _goToPage(quran.totalPagesCount);
  }

  void _showJumpToPageDialog() {
    final TextEditingController textController = TextEditingController(text: _currentPage.toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Jump to Page'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: textController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Page Number (1-${quran.totalPagesCount})',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Current page: $_currentPage',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final pageNumber = int.tryParse(textController.text);
              if (pageNumber != null && pageNumber >= 1 && pageNumber <= quran.totalPagesCount) {
                _goToPage(pageNumber);
                Navigator.of(context).pop();
              } else {
                // Show error message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please enter a valid page number between 1 and ${quran.totalPagesCount}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Go'),
          ),
        ],
      ),
    );
  }

  int _getJuzFromPage(int pageNumber) {
    // Approximate Juz calculation based on page number
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
