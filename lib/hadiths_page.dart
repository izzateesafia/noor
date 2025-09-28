import 'dart:io';
import 'package:flutter/material.dart';
import 'theme_constants.dart';

class HadithsPage extends StatelessWidget {
  const HadithsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample data - replace with real data later
    final List<Hadith> hadiths = [
      Hadith(
        title: 'Hadis Mengenai Niat',
        content: 'Amalan dinilai berdasarkan niat, dan setiap orang akan diberi ganjaran mengikut apa yang diniatkan. Maka sesiapa yang berhijrah kerana Allah dan Rasul-Nya, hijrahnya adalah untuk Allah dan Rasul-Nya. Dan sesiapa yang berhijrah untuk keuntungan duniawi atau untuk mengahwini seorang wanita, hijrahnya adalah untuk apa yang dia berhijrah.',
        narrator: 'Umar ibn Al-Khattab',
        source: 'Sahih Bukhari',
        book: 'Kitab 1, Hadis 1',
        image: 'assets/images/hadith_intentions.png',
        category: 'Aqidah',
      ),
      Hadith(
        title: 'Hadis Mengenai Akhlak Yang Baik',
        content: 'Yang paling sempurna iman di kalangan orang beriman adalah yang paling baik akhlaknya, dan yang terbaik di antara kamu adalah yang paling baik kepada wanita mereka.',
        narrator: 'Abu Huraira',
        source: 'Sahih Muslim',
        book: 'Kitab 1, Hadis 56',
        image: 'assets/images/hadith_character.png',
        category: 'Akhlak',
      ),
      Hadith(
        title: 'Hadis Mengenai Ilmu',
        content: 'Mencari ilmu adalah wajib ke atas setiap Muslim.',
        narrator: 'Anas ibn Malik',
        source: 'Ibn Majah',
        book: 'Book 1, Hadith 224',
        image: 'assets/images/hadith_knowledge.png',
        category: 'Ilm',
      ),
      Hadith(
        title: 'Hadith on Mercy',
        content: 'The merciful will be shown mercy by the Most Merciful. Be merciful to those on earth, and the One in heaven will be merciful to you.',
        narrator: 'Abdullah ibn Amr',
        source: 'Abu Dawud',
        book: 'Book 40, Hadith 4941',
        image: 'assets/images/hadith_mercy.png',
        category: 'Akhlak',
      ),
      Hadith(
        title: 'Hadith on Brotherhood',
        content: 'A Muslim is the brother of another Muslim. He does not wrong him, abandon him, or look down upon him. Piety is here (pointing to his chest). It is enough evil for a person to look down upon his Muslim brother.',
        narrator: 'Abu Huraira',
        source: 'Sahih Muslim',
        book: 'Book 32, Hadith 6219',
        image: 'assets/images/hadith_brotherhood.png',
        category: 'Muamalat',
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hadiths'),
        backgroundColor: AppColors.appBar,
        foregroundColor: AppColors.onAppBar,
      ),
      backgroundColor: AppColors.background,
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        itemCount: hadiths.length,
        itemBuilder: (context, index) {
          final hadith = hadiths[index];
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: Theme.of(context).cardColor,
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (hadith.image != null && hadith.image!.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: hadith.image!.startsWith('assets/')
                              ? Image.asset(
                                  hadith.image!,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.book,
                                        color: AppColors.primary,
                                        size: 40,
                                      ),
                                    );
                                  },
                                )
                              : Image.file(
                                  File(hadith.image!),
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.book,
                                        color: AppColors.primary,
                                        size: 40,
                                      ),
                                    );
                                  },
                                ),
                        ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hadith.title,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 15),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                hadith.category,
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    hadith.content,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.person, size: 16, color: AppColors.disabled),
                            const SizedBox(width: 8),
                            Text(
                              'Narrated by: ${hadith.narrator}',
                              style: TextStyle(
                                color: AppColors.disabled,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.source, size: 16, color: AppColors.disabled),
                            const SizedBox(width: 8),
                            Text(
                              '${hadith.source} - ${hadith.book}',
                              style: TextStyle(
                                color: AppColors.disabled,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class Hadith {
  final String title;
  final String content;
  final String narrator;
  final String source;
  final String book;
  final String? image;
  final String category;
  
  const Hadith({
    required this.title,
    required this.content,
    required this.narrator,
    required this.source,
    required this.book,
    this.image,
    required this.category,
  });
} 