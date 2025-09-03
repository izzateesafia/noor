import 'package:flutter/material.dart';
import 'theme_constants.dart';

class RukunSolatPage extends StatelessWidget {
  final bool isPremium;
  const RukunSolatPage({super.key, this.isPremium = false});

  @override
  Widget build(BuildContext context) {
    final List<RukunSolat> rukunList = [
      RukunSolat(
        title: 'Niat (Intention)',
        image: 'assets/images/niat.png',
        explanation: 'Making the intention in the heart to perform the specific prayer.',
        videoUrl: 'https://www.youtube.com/watch?v=niat_video',
      ),
      RukunSolat(
        title: 'Takbiratul Ihram',
        image: 'assets/images/takbir.png',
        explanation: 'Raising both hands and saying "Allahu Akbar" to begin the prayer.',
        videoUrl: 'https://www.youtube.com/watch?v=takbir_video',
      ),
      RukunSolat(
        title: 'Standing (Qiyam)',
        image: 'assets/images/qiyam.png',
        explanation: 'Standing upright while reciting Al-Fatihah and another surah.',
        videoUrl: 'https://www.youtube.com/watch?v=qiyam_video',
      ),
      RukunSolat(
        title: 'Ruku’ (Bowing)',
        image: 'assets/images/ruku.png',
        explanation: 'Bowing with hands on knees, back and head level, saying "Subhana Rabbiyal Adheem".',
        videoUrl: 'https://www.youtube.com/watch?v=ruku_video',
      ),
      RukunSolat(
        title: 'I’tidal (Standing after Ruku’)',
        image: 'assets/images/itidal.png',
        explanation: 'Standing up straight after ruku’, saying "Sami’ Allahu liman hamidah".',
        videoUrl: 'https://www.youtube.com/watch?v=itidal_video',
      ),
      RukunSolat(
        title: 'Sujud (Prostration)',
        image: 'assets/images/sujud.png',
        explanation: 'Prostrating with forehead, nose, palms, knees, and toes touching the ground.',
        videoUrl: 'https://www.youtube.com/watch?v=sujud_video',
      ),
      RukunSolat(
        title: 'Sitting between two Sujud',
        image: 'assets/images/duduk_antara_dua_sujud.png',
        explanation: 'Sitting calmly between the two prostrations.',
        videoUrl: 'https://www.youtube.com/watch?v=duduk_video',
      ),
      RukunSolat(
        title: 'Final Tashahhud',
        image: 'assets/images/tashahhud.png',
        explanation: 'Reciting the final testimony while sitting.',
        videoUrl: 'https://www.youtube.com/watch?v=tashahhud_video',
      ),
      RukunSolat(
        title: 'Salam',
        image: 'assets/images/salam.png',
        explanation: 'Ending the prayer by turning the head right and left, saying "Assalamu Alaikum wa Rahmatullah".',
        videoUrl: 'https://www.youtube.com/watch?v=salam_video',
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rukun Solat'),
        backgroundColor: AppColors.appBar,
        foregroundColor: AppColors.onAppBar,
      ),
      // Use theme background
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        itemCount: rukunList.length,
        itemBuilder: (context, index) {
          final rukun = rukunList[index];
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: Theme.of(context).cardColor,
            margin: const EdgeInsets.only(bottom: 18),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (rukun.image != null && rukun.image!.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset(
                            rukun.image!,
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.image,
                                  color: AppColors.primary,
                                  size: 36,
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
                              rukun.title,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 15),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              rukun.explanation,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  isPremium
                      ? AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.black12,
                            ),
                            child: Center(
                              child: Icon(Icons.play_circle_fill, color: AppColors.primary, size: 48),
                            ),
                          ),
                        )
                      : Stack(
                          children: [
                            AspectRatio(
                              aspectRatio: 16 / 9,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white12 : Colors.black12,
                                ),
                                child: Center(
                                  child: Icon(Icons.play_circle_fill, color: AppColors.primary.withOpacity(0.4), size: 48),
                                ),
                              ),
                            ),
                            Positioned.fill(
                              child: GestureDetector(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Premium Feature'),
                                      content: const Text('This video is for premium users. Would you like to view premium plans?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(),
                                          child: const Text('Cancel'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                            Navigator.of(context).pushNamed('/premium');
                                          },
                                          child: const Text('View Premium'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.45),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.lock, color: Colors.white, size: 32),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Premium Only',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
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

class RukunSolat {
  final String title;
  final String? image;
  final String explanation;
  final String? videoUrl;
  const RukunSolat({
    required this.title,
    this.image,
    required this.explanation,
    this.videoUrl,
  });
} 