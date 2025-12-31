import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'cubit/video_cubit.dart';
import 'cubit/video_states.dart';
import 'repository/video_repository.dart';
import 'models/video.dart';
import 'theme_constants.dart';
import 'cubit/user_cubit.dart';
import 'cubit/user_states.dart';
import 'all_videos_page.dart';
import 'pages/video_player_page.dart';

class VideosPage extends StatelessWidget {
  const VideosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final cubit = VideoCubit(VideoRepository());
        cubit.fetchVideos();
        cubit.fetchCategories();
        return cubit;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Videos'),
          backgroundColor: AppColors.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          actions: [
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AllVideosPage(),
                  ),
                );
              },
              icon: Icon(
                Icons.grid_view,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              label: Text(
                'All Videos',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        ),
        body: BlocBuilder<VideoCubit, VideoState>(
          builder: (context, state) {
            if (state.status == VideoStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.status == VideoStatus.error) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading videos',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 18,
                      ),
                    ),
                    if (state.error != null) ...[
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          state.error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error.withOpacity(0.8),
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        context.read<VideoCubit>().fetchVideos();
                        context.read<VideoCubit>().fetchCategories();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            // Organize videos into categories
            final featuredVideos = _getFeaturedVideos(state.videos);
            final popularVideos = _getPopularVideos(state.videos);
            final forYouVideos = _getForYouVideos(state.videos);

            return ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                // Featured Section - Large cards (1 per row)
                _buildFeaturedSection(
                  context,
                  videos: featuredVideos,
                  showPlaceholders: true,
                ),
                const SizedBox(height: 32),
                // Popular Section
                _buildVideoSection(
                  context,
                  title: 'Popular',
                  icon: Icons.trending_up,
                  videos: popularVideos,
                  showPlaceholders: true,
                ),
                const SizedBox(height: 24),
                // For You Section
                _buildVideoSection(
                  context,
                  title: 'For You',
                  icon: Icons.person,
                  videos: forYouVideos,
                  showPlaceholders: true,
                ),
                const SizedBox(height: 24),
              ],
            );
          },
        ),
      ),
    );
  }

  // Get featured videos (videos marked as featured, not hidden)
  List<Video> _getFeaturedVideos(List<Video> allVideos) {
    return allVideos
        .where((v) => v.isFeatured && !v.isHidden)
        .take(5)
        .toList();
  }

  // Get popular videos (videos marked as popular, not hidden, sorted by views)
  List<Video> _getPopularVideos(List<Video> allVideos) {
    final popular = allVideos
        .where((v) => v.isPopular && !v.isHidden)
        .toList();
    popular.sort((a, b) => (b.views ?? 0).compareTo(a.views ?? 0));
    return popular.take(5).toList();
  }

  // Get "For You" videos (videos marked as for you, not hidden)
  List<Video> _getForYouVideos(List<Video> allVideos) {
    return allVideos
        .where((v) => v.isForYou && !v.isHidden)
        .take(5)
        .toList();
  }

  Widget _buildFeaturedSection(
    BuildContext context, {
    required List<Video> videos,
    required bool showPlaceholders,
  }) {
    final hasVideos = videos.isNotEmpty;
    final displayVideos = hasVideos 
        ? videos 
        : (showPlaceholders ? _getPlaceholderVideos(5) : <Video>[]);

    if (displayVideos.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.star, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                'Featured',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Auto-scrolling banner with PageView
        SizedBox(
          height: 280, // Height for the large featured cards
          child: _AutoScrollFeaturedBanner(
            videos: displayVideos,
            hasVideos: hasVideos,
            showPlaceholders: showPlaceholders,
          ),
        ),
      ],
    );
  }

  Widget _buildVideoSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Video> videos,
    required bool showPlaceholders,
  }) {
    final hasVideos = videos.isNotEmpty;
    final displayVideos = hasVideos ? videos : (showPlaceholders ? _getPlaceholderVideos(5) : []);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Horizontal scrolling video list
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: displayVideos.length,
            itemBuilder: (context, index) {
              final video = displayVideos[index];
              final isPlaceholder = !hasVideos && showPlaceholders;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: SizedBox(
                  width: 160,
                  child: isPlaceholder
                      ? _PlaceholderVideoCard()
                      : VideoCard(video: video, isHorizontal: true),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Generate placeholder videos
  List<Video> _getPlaceholderVideos(int count) {
    return List.generate(count, (index) {
      return Video(
        id: 'placeholder_$index',
        title: 'Coming Soon',
        description: 'Video content will be available soon',
        thumbnailUrl: '',
        videoUrl: '',
        isPremium: false,
      );
    });
  }
}

// Auto-scrolling featured banner
class _AutoScrollFeaturedBanner extends StatefulWidget {
  final List<Video> videos;
  final bool hasVideos;
  final bool showPlaceholders;

  const _AutoScrollFeaturedBanner({
    required this.videos,
    required this.hasVideos,
    required this.showPlaceholders,
  });

  @override
  State<_AutoScrollFeaturedBanner> createState() => _AutoScrollFeaturedBannerState();
}

class _AutoScrollFeaturedBannerState extends State<_AutoScrollFeaturedBanner> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _startAutoScroll();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    if (widget.videos.isEmpty) return;
    
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_pageController.hasClients) {
        if (_currentPage < widget.videos.length - 1) {
          _currentPage++;
        } else {
          _currentPage = 0;
        }
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.videos.isEmpty) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentPage = index;
            });
          },
          itemCount: widget.videos.length,
          itemBuilder: (context, index) {
            final video = widget.videos[index];
            final isPlaceholder = !widget.hasVideos && widget.showPlaceholders;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: MediaQuery.of(context).size.width - 32,
                child: isPlaceholder
                    ? _PlaceholderFeaturedCard()
                    : _FeaturedVideoCard(video: video),
              ),
            );
          },
        ),
        // Page indicators
        if (widget.videos.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.videos.length,
                (index) => Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index
                        ? Theme.of(context).colorScheme.surface
                        : Theme.of(context).colorScheme.surface.withOpacity(0.4),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// Make VideoCard accessible from other files
class VideoCard extends StatelessWidget {
  final Video video;
  final bool isHorizontal;

  const VideoCard({required this.video, this.isHorizontal = false, super.key});

  String _formatDuration(Duration? duration) {
    if (duration == null) return '';
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatViews(int? views) {
    if (views == null) return '';
    if (views >= 1000000) {
      return '${(views / 1000000).toStringAsFixed(1)}M';
    } else if (views >= 1000) {
      return '${(views / 1000).toStringAsFixed(1)}K';
    }
    return views.toString();
  }

  bool _isYouTubeUrl(String url) {
    return url.contains('youtube.com') || 
           url.contains('youtu.be') || 
           url.contains('m.youtube.com');
  }

  bool _isFirebaseStorageUrl(String url) {
    return url.contains('firebasestorage.googleapis.com');
  }

  Future<void> _playVideo(BuildContext context) async {
    // Check if video is premium and user is not premium
    final userState = context.read<UserCubit>().state;
    final isPremium = userState.currentUser?.isPremium ?? false;

    if (video.isPremium && !isPremium) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This video is available for premium users only'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (video.videoUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video URL not available')),
      );
      return;
    }

    try {
      // Check if YouTube URL
      if (_isYouTubeUrl(video.videoUrl)) {
        final Uri url = Uri.parse(video.videoUrl);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cannot open YouTube video')),
          );
        }
        return;
      }

      // Check if Firebase Storage URL - play in-app
      if (_isFirebaseStorageUrl(video.videoUrl)) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => VideoPlayerPage(video: video),
          ),
        );
        return;
      }

      // Fallback: Open other URLs externally
      final Uri url = Uri.parse(video.videoUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot open video')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening video: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isHorizontal) {
      return _buildHorizontalCard(context);
    }
    return _buildGridCard(context);
  }

  Widget _buildHorizontalCard(BuildContext context) {
    return GestureDetector(
      onTap: () => _playVideo(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: video.thumbnailUrl.isNotEmpty
                      ? Image.network(
                          video.thumbnailUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildPlaceholderThumbnail();
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                        )
                      : _buildPlaceholderThumbnail(),
                ),
                // Play button overlay
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.shadow.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.play_arrow,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ),
                  ),
                ),
                // Duration badge
                if (video.duration != null)
                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.shadow.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _formatDuration(video.duration),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                // Premium badge
                if (video.isPremium)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'PREMIUM',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Video info
          Text(
            video.title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (video.views != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.visibility,
                  size: 12,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  _formatViews(video.views),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGridCard(BuildContext context) {
    return GestureDetector(
      onTap: () => _playVideo(context),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: video.thumbnailUrl.isNotEmpty
                        ? Image.network(
                            video.thumbnailUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildPlaceholderThumbnail();
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                          )
                        : _buildPlaceholderThumbnail(),
                  ),
                  // Play button overlay
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                    ),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.play_arrow,
                          color: AppColors.primary,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                  // Duration badge
                  if (video.duration != null)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _formatDuration(video.duration),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  // Premium badge
                  if (video.isPremium)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'PREMIUM',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Video info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      video.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (video.views != null)
                      Row(
                        children: [
                          Icon(
                            Icons.visibility,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatViews(video.views),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderThumbnail() {
    return Container(
      color: Colors.grey[300],
      child: Icon(
        Icons.video_library,
        color: Colors.grey[600],
        size: 48,
      ),
    );
  }
}

// Featured video card - large size (1 per row)
class _FeaturedVideoCard extends StatelessWidget {
  final Video video;

  const _FeaturedVideoCard({required this.video});

  String _formatDuration(Duration? duration) {
    if (duration == null) return '';
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatViews(int? views) {
    if (views == null) return '';
    if (views >= 1000000) {
      return '${(views / 1000000).toStringAsFixed(1)}M';
    } else if (views >= 1000) {
      return '${(views / 1000).toStringAsFixed(1)}K';
    }
    return views.toString();
  }

  bool _isYouTubeUrl(String url) {
    return url.contains('youtube.com') || 
           url.contains('youtu.be') || 
           url.contains('m.youtube.com');
  }

  bool _isFirebaseStorageUrl(String url) {
    return url.contains('firebasestorage.googleapis.com');
  }

  Future<void> _playVideo(BuildContext context) async {
    final userState = context.read<UserCubit>().state;
    final isPremium = userState.currentUser?.isPremium ?? false;

    if (video.isPremium && !isPremium) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This video is available for premium users only'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (video.videoUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video URL not available')),
      );
      return;
    }

    try {
      // Check if YouTube URL
      if (_isYouTubeUrl(video.videoUrl)) {
        final Uri url = Uri.parse(video.videoUrl);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cannot open YouTube video')),
          );
        }
        return;
      }

      // Check if Firebase Storage URL - play in-app
      if (_isFirebaseStorageUrl(video.videoUrl)) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => VideoPlayerPage(video: video),
          ),
        );
        return;
      }

      // Fallback: Open other URLs externally
      final Uri url = Uri.parse(video.videoUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot open video')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening video: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _playVideo(context),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Thumbnail
              AspectRatio(
                aspectRatio: 16 / 9,
                child: video.thumbnailUrl.isNotEmpty
                    ? Image.network(
                        video.thumbnailUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildPlaceholderThumbnail();
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                      )
                    : _buildPlaceholderThumbnail(),
              ),
              // Gradient overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
              ),
              // Play button overlay
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.play_arrow,
                    color: AppColors.primary,
                    size: 48,
                  ),
                ),
              ),
              // Video info overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Premium badge
                      if (video.isPremium)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'PREMIUM',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      if (video.isPremium) const SizedBox(height: 8),
                      // Title
                      Text(
                        video.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      // Meta info
                      Row(
                        children: [
                          if (video.duration != null) ...[
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDuration(video.duration),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 16),
                          ],
                          if (video.views != null) ...[
                            Icon(
                              Icons.visibility,
                              size: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatViews(video.views),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderThumbnail() {
    return Container(
      color: Colors.grey[300],
      child: Icon(
        Icons.video_library,
        color: Colors.grey[600],
        size: 64,
      ),
    );
  }
}

// Placeholder for featured card
class _PlaceholderFeaturedCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Icon(
          Icons.video_library_outlined,
          color: Colors.grey[500],
          size: 64,
        ),
      ),
    );
  }
}

// Placeholder video card for empty states
class _PlaceholderVideoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Placeholder thumbnail
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    Icons.video_library_outlined,
                    color: Colors.grey[500],
                    size: 48,
                  ),
                ),
                // Shimmer effect overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.1),
                        Colors.transparent,
                        Colors.white.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Placeholder title
        Container(
          height: 14,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 6),
        // Placeholder views
        Container(
          height: 12,
          width: 60,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }
}

