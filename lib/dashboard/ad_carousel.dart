import 'package:flutter/material.dart';
import '../theme_constants.dart';
import '../models/ad.dart';
import 'package:url_launcher/url_launcher.dart';

class AdCarousel extends StatelessWidget {
  final List<Ad>? ads;
  
  const AdCarousel({super.key, this.ads});

  @override
  Widget build(BuildContext context) {
    // Use dynamic ads if available, otherwise show loading or empty state
    if (ads == null) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 0),
        child: Container(
          height: 120,
          color: Colors.transparent,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    
    if (ads!.isEmpty) {
      return const SizedBox.shrink(); // Hide if no ads
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Container(
        height: 120,
        color: AppColors.primary.withOpacity(0.13),
        child: PageView.builder(
          itemCount: ads!.length,
          controller: PageController(viewportFraction: 0.85),
          itemBuilder: (context, index) {
            final ad = ads![index];
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return GestureDetector(
              onTap: () async {
                if (ad.link != null && await canLaunchUrl(Uri.parse(ad.link!))) {
                  launchUrl(Uri.parse(ad.link!), mode: LaunchMode.externalApplication);
                }
              },
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(18),
                        bottomLeft: Radius.circular(18),
                      ),
                      child: ad.image != null 
                        ? Image.network(
                            ad.image!,
                            width: 80,
                            height: 120,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: 80,
                              height: 120,
                              color: AppColors.primary.withOpacity(0.1),
                              child: Icon(Icons.campaign, color: AppColors.primary, size: 36),
                            ),
                          )
                        : Container(
                            width: 80,
                            height: 120,
                            color: AppColors.primary.withOpacity(0.1),
                            child: Icon(Icons.campaign, color: AppColors.primary, size: 36),
                          ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        ad.title ?? 'Iklan',
                        style: TextStyle(
                          color: isDark ? AppColors.darkCard : AppColors.text,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

 