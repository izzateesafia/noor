import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/ad.dart';
import '../cubit/user_cubit.dart';
import '../cubit/user_states.dart';
import 'package:url_launcher/url_launcher.dart';

class AdCarousel extends StatelessWidget {
  final List<Ad>? ads;
  
  const AdCarousel({super.key, this.ads});

  bool _isValidLink(String? link) {
    if (link == null || link.isEmpty) return false;
    return link.startsWith('http://') || link.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    // Use dynamic ads if available, otherwise show loading or empty state
    if (ads == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0),
        child: Container(
          height: 140,
          color: Colors.transparent,
          child: Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      );
    }
    
    if (ads!.isEmpty) {
      return const SizedBox.shrink(); // Hide if no ads
    }

    return BlocBuilder<UserCubit, UserState>(
      builder: (context, userState) {
        final isPremium = userState.currentUser?.isPremium ?? false;
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0),
          child: Container(
            height: 140,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
            ),
            child: Stack(
              children: [
                PageView.builder(
                  itemCount: ads!.length,
                  controller: PageController(viewportFraction: 0.9),
                  itemBuilder: (context, index) {
                    final ad = ads![index];
                    final hasLink = _isValidLink(ad.link);
                    
                    return GestureDetector(
                      onTap: hasLink ? () async {
                        if (await canLaunchUrl(Uri.parse(ad.link!))) {
                          launchUrl(Uri.parse(ad.link!), mode: LaunchMode.externalApplication);
                        }
                      } : null,
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
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        child: Row(
                          children: [
                            // Image section
                            ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                bottomLeft: Radius.circular(16),
                              ),
                              child: ad.image != null && ad.image!.isNotEmpty
                                ? Image.network(
                                    ad.image!,
                                    width: 100,
                                    height: 140,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        width: 100,
                                        height: 140,
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
                                      width: 100,
                                      height: 140,
                                      color: Theme.of(context).colorScheme.surfaceVariant,
                                      child: Icon(
                                        Icons.campaign,
                                        color: Theme.of(context).colorScheme.primary,
                                        size: 40,
                                      ),
                                    ),
                                  )
                                : Container(
                                    width: 100,
                                    height: 140,
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
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Title and link indicator
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            ad.title,
                                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (hasLink) ...[
                                          const SizedBox(width: 8),
                                          Icon(
                                            Icons.open_in_new,
                                            size: 18,
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                        ],
                                      ],
                                    ),
                                    // Description
                                    if (ad.description != null && ad.description!.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        ad.description!,
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          fontSize: 12,
                                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                    // Link indicator at bottom
                                    if (hasLink)
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.link,
                                            size: 14,
                                            color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Klik untuk buka pautan',
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              fontSize: 11,
                                              color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                // Premium upgrade badge overlay
                // if (!isPremium)
                //   Positioned(
                //     top: 8,
                //     right: 8,
                //     child: GestureDetector(
                //       onTap: () {
                //         Navigator.of(context).pushNamed('/premium');
                //       },
                //       child: Container(
                //         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                //         decoration: BoxDecoration(
                //           gradient: LinearGradient(
                //             colors: [
                //               Colors.amber,
                //               Colors.orange,
                //             ],
                //             begin: Alignment.topLeft,
                //             end: Alignment.bottomRight,
                //           ),
                //           borderRadius: BorderRadius.circular(20),
                //           boxShadow: [
                //             BoxShadow(
                //               color: Colors.black.withOpacity(0.2),
                //               blurRadius: 4,
                //               offset: const Offset(0, 2),
                //             ),
                //           ],
                //         ),
                //         child: Row(
                //           mainAxisSize: MainAxisSize.min,
                //           children: [
                //             Icon(
                //               Icons.workspace_premium,
                //               size: 16,
                //               color: Colors.white,
                //             ),
                //             const SizedBox(width: 6),
                //             Text(
                //               'Tingkatkan ke Premium',
                //               style: TextStyle(
                //                 color: Colors.white,
                //                 fontSize: 11,
                //                 fontWeight: FontWeight.bold,
                //               ),
                //             ),
                //           ],
                //         ),
                //       ),
                //     ),
                //   ),
              ],
            ),
          ),
        );
      },
    );
  }
}

 