import 'package:flutter/material.dart';
import '../theme_constants.dart';
import '../models/ad.dart';

class AdPanel extends StatelessWidget {
  final Ad? ad;
  
  const AdPanel({super.key, this.ad});

  @override
  Widget build(BuildContext context) {
    // Use dynamic ad if available, otherwise show default
    if (ad == null) {
      return const SizedBox.shrink(); // Hide if no ad
    }
    
    final String adImage = ad!.image ?? 'assets/images/ad_sample.png';
    final String adTitle = ad!.title ?? 'Tingkatkan ke Daily Quran Premium!';
    final String adDescription = ad!.description ?? 'Nikmati pengalaman tanpa iklan dan buka kunci semua ciri.';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: adImage.startsWith('http') 
                  ? Image.network(
                      adImage,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 70,
                        height: 70,
                        color: AppColors.primary.withOpacity(0.1),
                        child: Icon(Icons.campaign, color: AppColors.primary, size: 36),
                      ),
                    )
                  : Image.asset(
                      adImage,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 70,
                        height: 70,
                        color: AppColors.primary.withOpacity(0.1),
                        child: Icon(Icons.campaign, color: AppColors.primary, size: 36),
                      ),
                    ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      adTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      adDescription,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 36,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushNamed('/premium');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                        ),
                        child: const Text('Ketahui Lebih Lanjut'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 