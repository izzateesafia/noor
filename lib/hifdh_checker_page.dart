import 'package:flutter/material.dart';
import 'theme_constants.dart';

class HifdhCheckerPage extends StatefulWidget {
  const HifdhCheckerPage({super.key});

  @override
  State<HifdhCheckerPage> createState() => _HifdhCheckerPageState();
}

class _HifdhCheckerPageState extends State<HifdhCheckerPage> {
  bool isRecording = false;
  String aiFeedback = '';

  final List<HifdhCheck> recentChecks = [
    HifdhCheck(
      surah: 'Al-Fatihah',
      ayah: '1-7',
      result: 'Excellent! No mistakes detected.',
      date: DateTime(2025, 7, 6, 10, 0),
    ),
    HifdhCheck(
      surah: 'Al-Baqarah',
      ayah: '1-5',
      result: 'Minor tajweed mistakes. Practice more.',
      date: DateTime(2025, 7, 5, 15, 30),
    ),
  ];

  void _toggleRecording() {
    setState(() {
      isRecording = !isRecording;
      aiFeedback = isRecording ? '' : 'AI Feedback: (placeholder)';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hifz SmartChecker'),
        backgroundColor: AppColors.appBar,
        foregroundColor: AppColors.onAppBar,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Check Your Hifdh',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Center(
              child: GestureDetector(
                onTap: _toggleRecording,
                child: Container(
                  decoration: BoxDecoration(
                    color: isRecording ? AppColors.primary.withOpacity(0.15) : AppColors.primary.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(28),
                  child: Icon(
                    isRecording ? Icons.stop : Icons.mic,
                    color: AppColors.primary,
                    size: 48,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Center(
              child: Text(
                isRecording ? 'Listening...' : (aiFeedback.isNotEmpty ? aiFeedback : 'Tap the mic to start'),
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Recent Checks',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: recentChecks.length,
                itemBuilder: (context, i) {
                  final check = recentChecks[i];
                  return Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkCard : AppColors.lightCard,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Icon(Icons.check, color: AppColors.primary, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              check.result,
                              style: TextStyle(
                                color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.text,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HifdhCheck {
  final String surah;
  final String ayah;
  final String result;
  final DateTime date;
  const HifdhCheck({required this.surah, required this.ayah, required this.result, required this.date});
} 