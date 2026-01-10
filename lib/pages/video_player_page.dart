import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/video.dart';
import '../theme_constants.dart';

class VideoPlayerPage extends StatefulWidget {
  final Video video;

  const VideoPlayerPage({super.key, required this.video});

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  String? _errorMessage;
  bool _isPlaying = false;
  bool _showControls = true;
  bool _isFullscreen = false;

  bool _isValidVideoUrl(String? url) {
    if (url == null || url.trim().isEmpty) return false;
    return url.startsWith('http://') || url.startsWith('https://');
  }

  /// Checks if URL is from Firebase Storage
  bool _isFirebaseStorageUrl(String url) {
    return url.contains('firebasestorage.googleapis.com') ||
           url.contains('firebasestorage.app');
  }

  /// Checks if URL is a Firebase Storage path (not full URL)
  bool _isFirebaseStoragePath(String url) {
    // Paths typically start with 'videos/' or 'gs://' or don't have http/https
    return url.startsWith('videos/') ||
           url.startsWith('gs://') ||
           (!url.startsWith('http://') && !url.startsWith('https://'));
  }

  /// Extracts Storage path from Firebase Storage URL
  String? _extractStoragePathFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      // Firebase Storage URLs can have different formats:
      // 1. https://firebasestorage.googleapis.com/v0/b/bucket/o/videos%2Ffile.mp4?alt=media&token=...
      // 2. https://bucket.firebasestorage.app/videos/file.mp4?token=...
      
      final pathSegments = uri.pathSegments;
      
      // Try to find 'videos' in path segments
      final videosIndex = pathSegments.indexOf('videos');
      if (videosIndex >= 0 && videosIndex < pathSegments.length - 1) {
        // Reconstruct path: videos/filename
        final filename = pathSegments.sublist(videosIndex + 1).join('/');
        return 'videos/$filename';
      }
      
      // Alternative format: path might be URL-encoded in 'o' parameter
      // Format: /v0/b/bucket/o/videos%2Ffile.mp4
      if (pathSegments.contains('o') && pathSegments.length > pathSegments.indexOf('o') + 1) {
        final encodedPath = pathSegments[pathSegments.indexOf('o') + 1];
        try {
          final decodedPath = Uri.decodeComponent(encodedPath);
          if (decodedPath.startsWith('videos/')) {
            return decodedPath;
          }
        } catch (e) {
          print('DEBUG: Error decoding path: $e');
        }
      }
      
      // Check if path contains 'videos' anywhere
      final fullPath = uri.path;
      final videosMatch = RegExp(r'videos[/%2F]([^?]+)').firstMatch(fullPath);
      if (videosMatch != null) {
        final filename = videosMatch.group(1);
        if (filename != null) {
          return 'videos/${Uri.decodeComponent(filename)}';
        }
      }
    } catch (e) {
      print('DEBUG: Error extracting path from URL: $e');
    }
    return null;
  }

  /// Regenerates download URL from Firebase Storage
  Future<String?> _refreshFirebaseStorageUrl(String url) async {
    try {
      print('DEBUG: Attempting to refresh Firebase Storage URL');
      print('DEBUG: Original URL: $url');

      String? storagePath;

      // Check if it's already a path
      if (_isFirebaseStoragePath(url)) {
        storagePath = url;
      } else if (_isFirebaseStorageUrl(url)) {
        // Extract path from full URL
        storagePath = _extractStoragePathFromUrl(url);
      }

      if (storagePath == null) {
        print('DEBUG: Could not extract storage path, using original URL');
        return url;
      }

      print('DEBUG: Storage path: $storagePath');

      // Get fresh download URL from Firebase Storage
      final storageRef = FirebaseStorage.instance.ref(storagePath);
      final freshUrl = await storageRef.getDownloadURL();
      
      print('DEBUG: Fresh download URL obtained: $freshUrl');
      return freshUrl;
    } catch (e, stackTrace) {
      print('DEBUG: Error refreshing Firebase Storage URL: $e');
      print('DEBUG: Stack trace: $stackTrace');
      // Return original URL if refresh fails
      return url;
    }
  }

  /// Normalizes Firebase Storage URLs for iOS compatibility
  String _normalizeVideoUrlForIOS(String url) {
    // Check if it's a Firebase Storage URL
    if (_isFirebaseStorageUrl(url)) {
      final uri = Uri.tryParse(url);
      if (uri != null) {
        // Ensure we have the proper query parameters for iOS
        final queryParams = Map<String, String>.from(uri.queryParameters);
        
        // Add alt=media if not present (required for Firebase Storage downloads)
        if (!queryParams.containsKey('alt')) {
          queryParams['alt'] = 'media';
        }
        
        // Rebuild URI with normalized parameters
        final normalizedUri = uri.replace(queryParameters: queryParams);
        return normalizedUri.toString();
      }
    }
    return url;
  }

  /// Checks if we're running on iOS
  bool get _isIOS {
    if (kIsWeb) return false;
    return Platform.isIOS;
  }

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    print('DEBUG: Initializing video player');
    print('DEBUG: Video URL from model: ${widget.video.videoUrl}');
    
    // Check if it's a Firebase Storage path (not full URL)
    String videoUrl = widget.video.videoUrl;
    
    // If it's a Firebase Storage URL or path, try to refresh it
    if (_isFirebaseStorageUrl(videoUrl) || _isFirebaseStoragePath(videoUrl)) {
      print('DEBUG: Detected Firebase Storage URL/path, refreshing...');
      final refreshedUrl = await _refreshFirebaseStorageUrl(videoUrl);
      if (refreshedUrl != null) {
        videoUrl = refreshedUrl;
        print('DEBUG: Using refreshed URL: $videoUrl');
      } else {
        print('DEBUG: URL refresh failed, using original URL');
      }
    }

    if (!_isValidVideoUrl(videoUrl)) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'URL video tidak sah. Sila cuba buka secara luaran.';
        });
      }
      return;
    }

    try {
      // Normalize URL for iOS if needed
      if (_isIOS) {
        final normalizedUrl = _normalizeVideoUrlForIOS(videoUrl);
        if (normalizedUrl != videoUrl) {
          print('DEBUG: Normalized URL for iOS: $normalizedUrl');
          videoUrl = normalizedUrl;
        }
      }

      print('DEBUG: Final video URL: $videoUrl');
      final uri = Uri.tryParse(videoUrl);
      if (uri == null) {
        throw Exception('URL video tidak sah.');
      }

      // Create video player controller with retry logic for iOS
      VideoPlayerController? controller;
      int retryCount = 0;
      const maxRetries = 2;

      while (retryCount <= maxRetries) {
        try {
          print('DEBUG: Attempt ${retryCount + 1} to initialize video player');
          controller = VideoPlayerController.networkUrl(uri);
          
          // Add timeout for initialization (iOS sometimes hangs)
          await controller.initialize().timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              print('DEBUG: Video initialization timeout');
              throw Exception('Video initialization timeout. Sila cuba lagi atau buka dalam Safari.');
            },
          );

          print('DEBUG: Video player initialized successfully');
          // Success - break out of retry loop
          break;
        } catch (e, stackTrace) {
          print('DEBUG: Video initialization error (attempt ${retryCount + 1}): $e');
          print('DEBUG: Stack trace: $stackTrace');
          retryCount++;
          if (controller != null) {
            await controller.dispose();
            controller = null;
          }

          // If this was the last retry, throw the error
          if (retryCount > maxRetries) {
            print('DEBUG: Max retries reached, giving up');
            // Provide iOS-specific error message
            if (_isIOS && e.toString().contains('cannot open')) {
              throw Exception(
                'Video tidak dapat dimainkan pada peranti iOS. '
                'Ini mungkin disebabkan oleh format video yang tidak disokong. '
                'Sila cuba buka video dalam Safari atau gunakan format H.264/H.265.'
              );
            }
            rethrow;
          }

          // Wait before retrying (exponential backoff)
          print('DEBUG: Waiting before retry...');
          await Future.delayed(Duration(milliseconds: 500 * retryCount));
        }
      }

      if (controller == null) {
        throw Exception('Gagal memuatkan video selepas beberapa percubaan.');
      }

      if (mounted) {
        setState(() {
          _controller = controller;
          _isInitialized = true;
          _isPlaying = controller!.value.isPlaying;
        });
        controller!.play();
        controller!.addListener(_videoListener);
      } else {
        await controller!.dispose();
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = e.toString();
        
        // Provide user-friendly error messages
        if (errorMsg.contains('cannot open') || errorMsg.contains('videoError')) {
          errorMsg = _isIOS
              ? 'Video tidak dapat dimainkan pada iOS. Format video mungkin tidak disokong. Sila cuba buka dalam Safari.'
              : 'Video tidak dapat dimainkan. Sila cuba buka dalam pelayar.';
        } else if (errorMsg.contains('timeout')) {
          errorMsg = 'Masa tamat memuatkan video. Sila semak sambungan internet anda.';
        } else if (errorMsg.contains('network')) {
          errorMsg = 'Masalah sambungan internet. Sila semak sambungan anda.';
        }

        setState(() {
          _hasError = true;
          _errorMessage = errorMsg;
        });
      }
    }
  }

  void _videoListener() {
    if (mounted && _controller != null) {
      setState(() {
        _isPlaying = _controller!.value.isPlaying;
      });
    }
  }

  @override
  void dispose() {
    // Exit fullscreen if active
    if (_isFullscreen) {
      _exitFullscreen();
    }
    // Reset orientation to allow all orientations
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    if (_controller != null) {
      _controller!.removeListener(_videoListener);
      _controller!.dispose();
    }
    super.dispose();
  }

  void _enterFullscreen() {
    setState(() {
      _isFullscreen = true;
    });
    // Hide system UI but don't lock orientation
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _exitFullscreen() {
    setState(() {
      _isFullscreen = false;
    });
    // Show system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  void _rotateVideo() {
    // Toggle between portrait and landscape
    if (MediaQuery.of(context).orientation == Orientation.portrait) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
  }

  void _toggleFullscreen() {
    if (_isFullscreen) {
      _exitFullscreen();
    } else {
      _enterFullscreen();
    }
  }

  void _togglePlayPause() {
    if (_controller != null) {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
      } else {
        _controller!.play();
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isFullscreen) {
      return _buildFullscreenView();
    }
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _hasError
          ? _buildErrorView()
          : !_isInitialized
              ? _buildLoadingView()
              : _buildPlayerWithDetails(),
    );
  }

  Widget _buildFullscreenView() {
    if (_controller == null) {
      return _buildLoadingView();
    }
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _showControls = !_showControls;
        });
      },
      child: Container(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Video player - fullscreen
            Center(
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              ),
            ),
            // Controls overlay
            AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: _showControls ? _buildFullscreenControls() : const SizedBox.shrink(),
            ),
            // Center play button when paused
            if (!_isPlaying && _showControls)
              Center(
                child: GestureDetector(
                  onTap: _togglePlayPause,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),
            const SizedBox(height: 20),
            Text(
              'Loading video...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
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
              'Failed to load video',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 8),
            Text(
              _isIOS
                  ? 'Jika video gagal dimuat, cuba buka dalam Safari. Format video mungkin tidak disokong oleh pemain dalam aplikasi.'
                  : 'Jika video gagal dimuat, cuba buka semula pautan ini dalam pelayar untuk mengesahkan akses.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _hasError = false;
                  _isInitialized = false;
                });
                _initializePlayer();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Cuba Lagi'),
            ),
            if (_isValidVideoUrl(widget.video.videoUrl))
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: OutlinedButton.icon(
                  onPressed: _launchVideoExternally,
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Buka dalam Safari'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchVideoExternally() async {
    final uri = Uri.tryParse(widget.video.videoUrl);
    if (uri == null) return;
    if (!await canLaunchUrl(uri)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka URL video secara luaran.')),
        );
      }
      return;
    }

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Widget _buildPlayerWithDetails() {
    if (_controller == null) {
      return _buildLoadingView();
    }
    
    return Column(
      children: [
        // Video player section (top half)
        Expanded(
          flex: 1,
          child: Container(
            color: Colors.black,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _showControls = !_showControls;
                });
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Video player
                  Center(
                    child: AspectRatio(
                      aspectRatio: _controller!.value.aspectRatio,
                      child: VideoPlayer(_controller!),
                    ),
                  ),
                  // Controls overlay with fade animation
                  AnimatedOpacity(
                    opacity: _showControls ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: _showControls ? _buildVideoControls() : const SizedBox.shrink(),
                  ),
                  // Center play button when paused
                  if (!_isPlaying && _showControls)
                    Center(
                      child: GestureDetector(
                        onTap: _togglePlayPause,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 48,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        // Video details section (bottom half)
        Expanded(
          flex: 1,
          child: _buildVideoDetails(),
        ),
      ],
    );
  }

  Widget _buildVideoControls() {
    if (_controller == null) {
      return const SizedBox.shrink();
    }
    
    final duration = _controller!.value.duration;
    final position = _controller!.value.position;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.3, 0.7, 1.0],
          colors: [
            Colors.black.withOpacity(0.8),
            Colors.black.withOpacity(0.3),
            Colors.black.withOpacity(0.3),
            Colors.black.withOpacity(0.8),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox.shrink(), // Top spacer
          // Bottom section with controls
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
                // Progress bar with time
                Row(
                  children: [
                    Text(
                      _formatDuration(position),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: VideoProgressIndicator(
                        _controller!,
                        allowScrubbing: true,
                        colors: VideoProgressColors(
                          playedColor: Colors.white,
                          bufferedColor: Colors.white.withOpacity(0.25),
                          backgroundColor: Colors.white.withOpacity(0.15),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDuration(duration),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Control buttons row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left side - Play/Pause
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          _isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: _togglePlayPause,
                        iconSize: 32,
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                    // Right side - Exit Fullscreen
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                          color: Colors.white,
                          size: 24,
                        ),
                        onPressed: _toggleFullscreen,
                        iconSize: 24,
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoDetails() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            widget.video.title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 12),
          // Video metadata row
          Row(
            children: [
              // Views
              if (widget.video.views != null) ...[
                Row(
                  children: [
                    Icon(
                      Icons.visibility,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatViews(widget.video.views!),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
              ],
              // Upload date
              if (widget.video.uploadedAt != null) ...[
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(widget.video.uploadedAt!),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          // Category chip
          if (widget.video.category != null) ...[
            Wrap(
              spacing: 8,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    widget.video.category!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (widget.video.isPremium)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star,
                          size: 14,
                          color: Colors.amber[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Premium',
                          style: TextStyle(
                            color: Colors.amber[700],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          // Divider
          Divider(
            color: Theme.of(context).dividerColor,
            thickness: 1,
          ),
          const SizedBox(height: 16),
          // Description
          if (widget.video.description.isNotEmpty) ...[
            Text(
              'Description',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.video.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
          ],
          // Duration
          if (widget.video.duration != null) ...[
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
                const SizedBox(width: 8),
                Text(
                  'Duration: ${_formatDuration(widget.video.duration!)}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatViews(int views) {
    if (views >= 1000000) {
      return '${(views / 1000000).toStringAsFixed(1)}M views';
    } else if (views >= 1000) {
      return '${(views / 1000).toStringAsFixed(1)}K views';
    }
    return '$views views';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }

  Widget _buildFullscreenControls() {
    if (_controller == null) {
      return const SizedBox.shrink();
    }
    
    final duration = _controller!.value.duration;
    final position = _controller!.value.position;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.3, 0.7, 1.0],
          colors: [
            Colors.black.withOpacity(0.8),
            Colors.black.withOpacity(0.3),
            Colors.black.withOpacity(0.3),
            Colors.black.withOpacity(0.8),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top section - Back and Exit Fullscreen buttons
          SafeArea(
            bottom: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () {
                        _exitFullscreen();
                        Navigator.of(context).pop();
                      },
                      iconSize: 24,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.fullscreen_exit, color: Colors.white),
                      onPressed: _toggleFullscreen,
                      iconSize: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Bottom section with controls
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
                // Progress bar with time
                Row(
                  children: [
                    Text(
                      _formatDuration(position),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: VideoProgressIndicator(
                        _controller!,
                        allowScrubbing: true,
                        colors: VideoProgressColors(
                          playedColor: Colors.white,
                          bufferedColor: Colors.white.withOpacity(0.25),
                          backgroundColor: Colors.white.withOpacity(0.15),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDuration(duration),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Control buttons row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Play/Pause button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          _isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 32,
                        ),
                        onPressed: _togglePlayPause,
                        iconSize: 40,
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Rotate button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.screen_rotation,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: _rotateVideo,
                        iconSize: 32,
                        padding: const EdgeInsets.all(12),
                        tooltip: 'Rotate',
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Exit fullscreen button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.fullscreen_exit,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: _toggleFullscreen,
                        iconSize: 32,
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

