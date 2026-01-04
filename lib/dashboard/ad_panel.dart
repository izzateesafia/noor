import 'package:flutter/material.dart';
import '../models/ad.dart';
import 'package:url_launcher/url_launcher.dart';

class AdPanel extends StatelessWidget {
  final Ad? ad;
  
  const AdPanel({super.key, this.ad});

  bool _isValidLink(String? link) {
    if (link == null || link.isEmpty) return false;
    return link.startsWith('http://') || link.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    // Use dynamic ad if available, otherwise show default
    if (ad == null) {
      return const SizedBox.shrink(); // Hide if no ad
    }
    
    final hasLink = _isValidLink(ad!.link);
    final adImage = ad!.image;
    final adTitle = ad!.title;
    final adDescription = ad!.description;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Card(
        elevation: hasLink ? 3 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: hasLink
            ? BorderSide(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                width: 1.5,
              )
            : BorderSide.none,
        ),
        color: Theme.of(context).cardColor,
        child: InkWell(
          onTap: hasLink ? () async {
            if (await canLaunchUrl(Uri.parse(ad!.link!))) {
              launchUrl(Uri.parse(ad!.link!), mode: LaunchMode.externalApplication);
            }
          } : null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image section
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: adImage != null && adImage.isNotEmpty
                    ? Image.network(
                        adImage,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: 80,
                            height: 80,
                            color: Theme.of(context).colorScheme.surfaceVariant,
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded / 
                                    loadingProgress.expectedTotalBytes!
                                  : null,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 80,
                          height: 80,
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          child: Icon(
                            Icons.campaign,
                            color: Theme.of(context).colorScheme.primary,
                            size: 40,
                          ),
                        ),
                      )
                    : Container(
                        width: 80,
                        height: 80,
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        child: Icon(
                          Icons.campaign,
                          color: Theme.of(context).colorScheme.primary,
                          size: 40,
                        ),
                      ),
                ),
                const SizedBox(width: 16),
                // Content section
                // Expanded(
                //   child: Column(
                //     crossAxisAlignment: CrossAxisAlignment.start,
                //     children: [
                //       // Title with link indicator
                //       Row(
                //         crossAxisAlignment: CrossAxisAlignment.start,
                //         children: [
                //           Expanded(
                //             child: Text(
                //               adTitle,
                //               style: Theme.of(context).textTheme.titleMedium?.copyWith(
                //                 color: Theme.of(context).colorScheme.primary,
                //                 fontWeight: FontWeight.bold,
                //                 fontSize: 16,
                //               ),
                //               maxLines: 2,
                //               overflow: TextOverflow.ellipsis,
                //             ),
                //           ),
                //           if (hasLink) ...[
                //             const SizedBox(width: 8),
                //             Icon(
                //               Icons.open_in_new,
                //               size: 18,
                //               color: Theme.of(context).colorScheme.primary,
                //             ),
                //           ],
                //         ],
                //       ),
                //       // Description
                //       if (adDescription != null && adDescription.isNotEmpty) ...[
                //         const SizedBox(height: 8),
                //         Text(
                //           adDescription,
                //           style: Theme.of(context).textTheme.bodySmall?.copyWith(
                //             fontSize: 13,
                //             color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                //           ),
                //           maxLines: 2,
                //           overflow: TextOverflow.ellipsis,
                //         ),
                //       ],
                //       const SizedBox(height: 12),
                //       // Action button or link indicator
                //       if (hasLink)
                //         Row(
                //           children: [
                //             Icon(
                //               Icons.link,
                //               size: 14,
                //               color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                //             ),
                //             const SizedBox(width: 4),
                //             Text(
                //               'Klik untuk buka pautan',
                //               style: Theme.of(context).textTheme.bodySmall?.copyWith(
                //                 fontSize: 12,
                //                 color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                //               ),
                //             ),
                //           ],
                //         )
                //       else
                //         SizedBox(
                //           height: 36,
                //           child: ElevatedButton(
                //             onPressed: () {
                //               Navigator.of(context).pushNamed('/premium');
                //             },
                //             style: ElevatedButton.styleFrom(
                //               backgroundColor: Theme.of(context).colorScheme.primary,
                //               foregroundColor: Theme.of(context).colorScheme.onPrimary,
                //               shape: RoundedRectangleBorder(
                //                 borderRadius: BorderRadius.circular(8),
                //               ),
                //               padding: const EdgeInsets.symmetric(horizontal: 18),
                //             ),
                //             child: const Text('Ketahui Lebih Lanjut'),
                //           ),
                //         ),
                //     ],
                //   ),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 