import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/ad_states.dart';
import '../cubit/user_cubit.dart';
import '../cubit/user_states.dart';
import '../cubit/whats_new_states.dart';
import '../repository/user_repository.dart';
import '../cubit/live_stream_cubit.dart';
import '../cubit/live_stream_states.dart';
import '../models/live_stream.dart';
import '../theme_constants.dart';
import 'header_section.dart';
import 'prayer_times_card.dart';
import 'daily_tracker.dart';
import 'quick_access_grid.dart';
import 'whats_new_carousel.dart';
import 'featured_section.dart';
import 'ad_panel.dart';
import 'ad_carousel.dart';
import '../models/user_model.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart';
import '../cubit/class_cubit.dart';
import '../cubit/dua_cubit.dart';
import '../cubit/hadith_cubit.dart';
import '../cubit/ad_cubit.dart';
import '../cubit/whats_new_cubit.dart';
import '../repository/ad_repository.dart';
import '../repository/whats_new_repository.dart';
import '../cubit/prayer_times_cubit.dart';
import '../cubit/prayer_times_states.dart';
import '../cubit/news_cubit.dart';
import '../cubit/news_states.dart';
import '../repository/news_repository.dart';
import '../widgets/daily_verse_widget.dart';
import 'terkini_news_feed.dart';
import '../services/location_service.dart';
import 'package:geolocator/geolocator.dart';
import '../cubit/video_cubit.dart';
import '../cubit/video_states.dart';
import '../repository/video_repository.dart';
import '../models/video.dart';
import '../videos_page.dart';
import '../all_videos_page.dart';
import '../user_profile_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with WidgetsBindingObserver {
  bool _hasUserBeenLoaded = false; // Track if user was successfully loaded at least once

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Fetch user data first before using it
      context.read<UserCubit>().fetchCurrentUser();
      
      // Fetch other data
      context.read<ClassCubit>().fetchClasses();
      context.read<LiveStreamCubit>().getCurrentLiveStream();
      context.read<DuaCubit>().fetchDuas();
      context.read<HadithCubit>().fetchHadiths();
      context.read<NewsCubit>().fetchNews();
      context.read<AdCubit>().fetchAds();
      context.read<WhatsNewCubit>().fetchWhatsNew();
      context.read<VideoCubit>().fetchVideos();
      
      // Fetch prayer times using user's location if available
      // Note: User might not be loaded yet, so we'll handle this in a listener or after user loads
      final prayerTimesCubit = context.read<PrayerTimesCubit>();
      prayerTimesCubit.fetchHijriDate();
      
      // Fetch prayer times will be handled after user is loaded
      // Request location permission and update user location if not available
      _requestAndUpdateLocation();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Add a delay to ensure settings have been saved and app is fully resumed
      Future.delayed(const Duration(seconds: 1), () async {
        if (!mounted) {
          return;
        }
        // When app resumes, check if location permission was granted
        // and location is still missing, then re-fetch
        await _requestAndUpdateLocation(forceRefresh: true);
      });
    }
  }

  /// Request location permission and update user location
  /// [forceRefresh] - If true, will fetch location even if user already has location data
  Future<void> _requestAndUpdateLocation({bool forceRefresh = false}) async {
    if (!mounted) return;
    try {
      final userCubit = context.read<UserCubit>();
      final user = userCubit.state.currentUser;
      
      // Skip if user already has location data (unless force refresh)
      if (!forceRefresh && user?.latitude != null && user?.longitude != null && user?.locationName != null) {
        return;
      }
      
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled || !mounted) {
        return;
      }
      
      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        // Request permission - this will show the iOS permission dialog if needed
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied || !mounted) {
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever || !mounted) {
        return;
      }
      
      // Only proceed if permission is granted
      if (permission != LocationPermission.always && permission != LocationPermission.whileInUse) {
        return;
      }
      
      // Get current location directly (bypass LocationService to avoid double permission check)
      Position position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );
      } catch (e) {
        return;
      }
      
      if (!mounted) return;
      
      // Get location name
      final locationService = LocationService();
      final locationName = await locationService.getLocationName(
        position.latitude,
        position.longitude,
      );
      
      // Check mounted before updating user
      if (!mounted) return;
      
      // Update user with location
      // IMPORTANT: Fetch latest user from Firestore first to ensure we have current roles
      // This prevents overwriting manually set roles when updating location
      await userCubit.fetchCurrentUser();
      
      if (!mounted) return;
      final latestUser = userCubit.state.currentUser;
      
      if (latestUser != null && mounted) {
        // Use latestUser (with current roles from Firestore) instead of stale user from state
        final updatedUser = latestUser.copyWith(
          latitude: position.latitude,
          longitude: position.longitude,
          locationName: locationName ??
              '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}',
        );
        
        await userCubit.updateUser(updatedUser);
        
        // Check mounted before accessing context
        if (!mounted) return;
        
        // Update prayer times with new location
        final prayerTimesCubit = context.read<PrayerTimesCubit>();
        prayerTimesCubit.fetchPrayerTimesByCoordinates(
          position.latitude,
          position.longitude,
        );
      }
    } catch (e, stackTrace) {
      // Don't block dashboard if location fails
    }
  }

  Widget _buildFeaturedVideosSection(BuildContext context, List<Video> videos) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
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
                    'Video',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const AllVideosPage(),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Lihat Semua',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: videos.length,
            itemBuilder: (context, index) {
              final video = videos[index];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: SizedBox(
                  width: 160,
                  child: VideoCard(video: video, isHorizontal: true),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildHijriDateDisplay() {
    return BlocBuilder<PrayerTimesCubit, PrayerTimesState>(
      builder: (context, state) {
        final hijriDate = state.hijriDate;
        
        if (hijriDate == null) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_today,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                '${hijriDate.hijriDate} ${hijriDate.hijriMonth} ${hijriDate.hijriYear}',
                style: TextStyle(
                    fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
                  overflow: TextOverflow.ellipsis,
              ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'JAKIM',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
            return MultiBlocProvider(
          providers: [
            // Use existing cubits from parent context if available, otherwise create new ones
            BlocProvider<UserCubit>.value(
              value: context.read<UserCubit>(),
            ),
            BlocProvider<ClassCubit>.value(
              value: context.read<ClassCubit>(),
            ),
            BlocProvider<DuaCubit>.value(
              value: context.read<DuaCubit>(),
            ),
            BlocProvider<HadithCubit>.value(
              value: context.read<HadithCubit>(),
            ),
            BlocProvider<LiveStreamCubit>.value(
              value: context.read<LiveStreamCubit>(),
            ),
            BlocProvider<PrayerTimesCubit>.value(
              value: context.read<PrayerTimesCubit>(),
            ),
            BlocProvider<AdCubit>.value(
              value: context.read<AdCubit>(),
            ),
            BlocProvider<WhatsNewCubit>.value(
              value: context.read<WhatsNewCubit>(),
            ),
            BlocProvider<NewsCubit>.value(
              value: context.read<NewsCubit>(),
            ),
            BlocProvider<VideoCubit>.value(
              value: context.read<VideoCubit>(),
            ),
          ],
          child: BlocConsumer<UserCubit, UserState>(
            listener: (context, userState) {
              if (userState.status == UserStatus.loaded && userState.currentUser != null) {
                // Mark that user was successfully loaded
                _hasUserBeenLoaded = true;
                
                // User loaded - fetch prayer times using user's location
                final user = userState.currentUser!;
                final prayerTimesCubit = context.read<PrayerTimesCubit>();
                
                if (user.latitude != null && user.longitude != null) {
                  // Use user's location coordinates
                  prayerTimesCubit.fetchPrayerTimesByCoordinates(user.latitude!, user.longitude!);
                } else {
                  // Fallback to default location (Kuala Lumpur)
                  prayerTimesCubit.fetchCurrentPrayerTimes('Kuala Lumpur', 'Kuala Lumpur');
                }
              } else if (userState.status == UserStatus.error && 
                  userState.error != null &&
                  _hasUserBeenLoaded) {
                // Only show error if user was previously loaded successfully
                // This prevents showing errors that occur during initial load or before login
                // Also filter out permission-denied errors (they're handled in UI cards)
                final error = userState.error!;
                if (!error.contains('No user data found') &&
                    !error.contains('Please try logging in again') &&
                    !error.contains('permission-denied') &&
                    !error.contains('cloud_firestore') &&
                    !error.contains('Kebenaran ditolak')) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(error),
                      backgroundColor: Theme.of(context).colorScheme.error,
                      duration: const Duration(seconds: 4),
                      action: SnackBarAction(
                        label: 'Cuba Lagi',
                        onPressed: () {
                          context.read<UserCubit>().fetchCurrentUser();
                        },
                      ),
                    ),
                  );
                }
              }
            },
            builder: (context, userState) {
              // Show loading state while fetching user data
              if (userState.status == UserStatus.loading) {
                return const Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Memuatkan data pengguna...'),
                      ],
                    ),
                  ),
                );
              }
              
              return BlocConsumer<LiveStreamCubit, LiveStreamState>(
            listener: (context, state) {
              if (state is LiveStreamSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.green, // Success color - keep as is
                  ),
                );
                context.read<LiveStreamCubit>().clearMessage();
              } else if (state is LiveStreamError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
                context.read<LiveStreamCubit>().clearMessage();
              }
            },
            builder: (context, liveStreamState) {
              // Wait for user to be loaded - don't show fallback user
              if (userState.status != UserStatus.loaded || userState.currentUser == null) {
                // Still loading or error - show loading or wait
                if (userState.status == UserStatus.loading) {
                  return const Scaffold(
                    body: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Memuatkan data pengguna...'),
                        ],
                      ),
                    ),
                  );
                }
                // If error, still try to show dashboard but user will be null
                // This should not happen if user is authenticated
              }

              // Use real user data - required at this point
              final user = userState.currentUser;
              if (user == null) {
                // This should not happen for authenticated users, but handle gracefully
                return Scaffold(
                  body: Center(
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
                          'Tiada data pengguna',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            context.read<UserCubit>().fetchCurrentUser();
                          },
                          child: const Text('Cuba Lagi'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Get current live stream
              LiveStream? currentLiveStream;
              if (liveStreamState is LiveStreamLoaded) {
                currentLiveStream = liveStreamState.currentLiveStream;
              }


              // Check if there's an active live stream
              final bool isLive = currentLiveStream != null && currentLiveStream.isActive;
              
              // Show loading state while fetching
              final bool isLoading = liveStreamState is LiveStreamLoading;

              void _showLiveSheet() {
                if (currentLiveStream == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tiada siaran langsung tersedia pada masa ini. Sila periksa semula kemudian atau hubungi admin.'),
                      backgroundColor: Colors.orange,
                      duration: Duration(seconds: 3),
                    ),
                  );
                  return;
                }

                if (!currentLiveStream!.isActive) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Siaran langsung ini tidak aktif pada masa ini'),
                      backgroundColor: Colors.orange,
                      duration: Duration(seconds: 3),
                    ),
                  );
                  return;
                }

                final liveStream = currentLiveStream!;

                showModalBottomSheet(
                  context: context,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                  ),
                  builder: (context) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 18),
                      Text(
                        liveStream.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        liveStream.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 18),
                      ListTile(
                        leading: Icon(
                          Icons.live_tv,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        title: const Text('Tonton di TikTok'),
                        subtitle: Text(liveStream.tiktokLiveLink),
                        onTap: () async {
                          Navigator.of(context).pop();
                          final url = Uri.parse(liveStream.tiktokLiveLink);
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url, mode: LaunchMode.externalApplication);
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Tidak dapat membuka pautan TikTok'),
                                  backgroundColor: Theme.of(context).colorScheme.error,
                                ),
                              );
                            }
                          }
                        },
                      ),
                      const SizedBox(height: 18),
                    ],
                  ),
                );
              }

              return Scaffold(
                body: SafeArea(
                  child: Stack(
                    children: [
                      RefreshIndicator(
                        onRefresh: () async {
                          // Store cubit references before async operations
                          if (!mounted) return;
                          final userCubit = context.read<UserCubit>();
                          final liveStreamCubit = context.read<LiveStreamCubit>();
                          final classCubit = context.read<ClassCubit>();
                          final newsCubit = context.read<NewsCubit>();
                          final prayerTimesCubit = context.read<PrayerTimesCubit>();
                          
                          // Perform async operations
                          await liveStreamCubit.getCurrentLiveStream();
                          await classCubit.fetchClasses();
                          await newsCubit.fetchNews();
                          
                          // Check mounted before accessing context-dependent operations
                          if (!mounted) return;
                          await _requestAndUpdateLocation(forceRefresh: true);
                          
                          // Use stored references instead of context.read
                          if (!mounted) return;
                          final user = userCubit.state.currentUser;
                          if (user?.latitude != null && user?.longitude != null) {
                            prayerTimesCubit.fetchPrayerTimesByCoordinates(user!.latitude!, user.longitude!);
                          } else {
                            prayerTimesCubit.fetchCurrentPrayerTimes('Kuala Lumpur', 'Kuala Lumpur');
                          }
                          
                          // Also refresh Hijri date
                          prayerTimesCubit.fetchHijriDate();
                          
                          if (mounted) {
                          await Future.delayed(const Duration(milliseconds: 500)); // Small delay for better UX
                          }
                        },
                        child: SingleChildScrollView(
                          child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(height: 200, child: Image.asset(fit: BoxFit.cover,'assets/images/banner.jpeg'),),
                            // Theme mode toggle and Watch Live button in a single row
                            Padding(
                              padding: const EdgeInsets.only(top: 10, left: 20, right: 20, bottom: 0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Watch Live button
                                  ElevatedButton.icon(
                                    onPressed: isLoading ? null : () async {
                                      // Refresh live stream data first and wait for it
                                      await context.read<LiveStreamCubit>().getCurrentLiveStream();
                                      
                                      // Wait a bit for state to update
                                      await Future.delayed(const Duration(milliseconds: 100));
                                      
                                      // Get updated state
                                      final updatedState = context.read<LiveStreamCubit>().state;
                                      LiveStream? currentLiveStream;
                                      if (updatedState is LiveStreamLoaded) {
                                        currentLiveStream = updatedState.currentLiveStream;
                                      }
                                      
                                      // Check if there's an active live stream
                                      if (currentLiveStream != null && currentLiveStream.isActive && currentLiveStream.tiktokLiveLink.isNotEmpty) {
                                        // Directly navigate to the live stream link
                                        final url = Uri.parse(currentLiveStream.tiktokLiveLink);
                                        if (await canLaunchUrl(url)) {
                                          await launchUrl(url, mode: LaunchMode.externalApplication);
                                        } else {
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: const Text('Tidak dapat membuka pautan siaran langsung'),
                                                backgroundColor: Theme.of(context).colorScheme.error,
                                              ),
                                            );
                                          }
                                        }
                                      } else {
                                        // No active live stream, show error message
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Tiada siaran langsung tersedia pada masa ini. Sila periksa semula kemudian atau hubungi kami.'),
                                              backgroundColor: Colors.orange,
                                              duration: Duration(seconds: 3),
                                            ),
                                          );
                                        }
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(context).colorScheme.primary,
                                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                    ),
                                    icon: isLoading 
                                        ? SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                Theme.of(context).colorScheme.onPrimary,
                                              ),
                                            ),
                                          )
                                        : const Icon(Icons.live_tv),
                                    label: Row(
                                      children: [
                                        Text(isLoading ? 'Memuatkan...' : 'Tonton Langsung'),
                                        if (isLive && !isLoading)
                                          Container(
                                            margin: const EdgeInsets.only(left: 10),
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).colorScheme.onPrimary,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              'LIVE',
                                              style: TextStyle(
                                                color: Theme.of(context).colorScheme.primary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                                letterSpacing: 1.2,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  // Test button for creating sample live stream (temporary)
                                  if (user.roles.contains(UserType.admin))
                                    // ElevatedButton.icon(
                                    //   onPressed: () {
                                    //     context.read<LiveStreamCubit>().addLiveStream(
                                    //       title: 'Test Live Stream',
                                    //       description: 'This is a test live stream for debugging',
                                    //       tiktokLiveLink: 'https://www.tiktok.com/@testuser/live/123456789',
                                    //     );
                                    //   },
                                    //   style: ElevatedButton.styleFrom(
                                    //     backgroundColor: Colors.orange,
                                    //     foregroundColor: Colors.white,
                                    //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    //     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    //   ),
                                    //   icon: const Icon(Icons.bug_report, size: 16),
                                    //   label: const Text('Ujian', style: TextStyle(fontSize: 12)),
                                    // ),
                                  // Theme mode switch
                                  ValueListenableBuilder<ThemeMode>(
                                    valueListenable: themeModeNotifier,
                                    builder: (context, mode, _) => Row(
                                      children: [
                                        Icon(
                                          mode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode,
                                          color: mode == ThemeMode.dark ? Colors.yellow : Theme.of(context).colorScheme.primary,
                                        ),
                                        Switch(
                                          value: mode == ThemeMode.dark,
                                          onChanged: (val) {
                                            themeModeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
                                          },
                                          activeColor: Colors.yellow,
                                          inactiveThumbColor: Theme.of(context).colorScheme.primary,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            BlocProvider.value(
                              value: context.read<UserCubit>(),
                              child: HeaderSection(user: user),
                            ),
                            // _buildHijriDateDisplay(),
                            PrayerTimesCard(),
                            QuickAccessGrid(),

                            const DailyVerseWidget(),
                            // Featured Videos Section
                            BlocBuilder<VideoCubit, VideoState>(
                              builder: (context, videoState) {
                                if (videoState.status == VideoStatus.loading) {
                                  return const SizedBox.shrink();
                                }
                                
                                final featuredVideos = videoState.videos
                                    .where((v) => v.isFeatured && !v.isHidden)
                                    .take(10)
                                    .toList();
                                
                                if (featuredVideos.isEmpty) {
                                  return const SizedBox.shrink();
                                }
                                
                                return _buildFeaturedVideosSection(context, featuredVideos);
                              },
                            ),
                            BlocBuilder<NewsCubit, NewsState>(
                              builder: (context, newsState) {
                                // Show loading state
                                if (newsState.isLoading) {
                                  return const SizedBox.shrink(); // Hide during loading
                                }
                                
                                // Show error state
                                if (newsState.error != null) {
                                  return const SizedBox.shrink();
                                }
                                
                                // Show news feed if there are news items
                                if (newsState.news.isNotEmpty) {
                                  return TerkiniNewsFeed(news: newsState.news);
                                }
                                
                                // Hide if no news items
                                return const SizedBox.shrink();
                              },
                            ),
                            // DailyTracker(user: user),
                            if (!user.isPremium) BlocBuilder<AdCubit, AdState>(
                              builder: (context, adState) {
                                if (adState.isLoading) {
                                  return const SizedBox.shrink(); // Hide during loading
                                }
                                if (adState.error != null) {
                                  return const SizedBox.shrink(); // Hide on error
                                }
                                if (adState.ads.isEmpty) {
                                  return const SizedBox.shrink(); // Hide if no ads
                                }
                                return AdCarousel(ads: adState.ads);
                              },
                            ),
                            // if (!user.isPremium) BlocBuilder<AdCubit, AdState>(
                            //   builder: (context, adState) {
                            //     if (adState.isLoading || adState.error != null || adState.ads.isEmpty) {
                            //       return const SizedBox.shrink();
                            //     }
                            //     return AdPanel(ad: adState.ads.first);
                            //   },
                            // ),
                            FeaturedSection(
                              user: user,
                              duas: context.read<DuaCubit>().state.duas,
                              hadiths: context.read<HadithCubit>().state.hadiths,
                            ),
                            BlocBuilder<WhatsNewCubit, WhatsNewState>(
                              builder: (context, whatsNewState) {
                                return WhatsNewCarousel(items: whatsNewState.items);
                              },
                            ),
                          ],
                        ),
                        ),
                      ),
                      // Floating Profile Icon - top right
                      Positioned(
                        top: 8,
                        right: 16,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const UserProfilePage()),
                            );
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Theme.of(context).colorScheme.surface,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context).colorScheme.shadow.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: user.profileImage != null && user.profileImage!.isNotEmpty
                                  ? Image.network(
                                      user.profileImage!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          color: Theme.of(context).colorScheme.primary,
                                          child: Icon(
                                            Icons.person,
                                            color: Theme.of(context).colorScheme.onPrimary,
                                            size: 24,
                                          ),
                                        );
                                      },
                                    )
                                  : Container(
                                      color: Theme.of(context).colorScheme.primary,
                                      child: Icon(
                                        Icons.person,
                                        color: Theme.of(context).colorScheme.onPrimary,
                                        size: 24,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                      // Admin button - only visible for admin users (below profile icon)
                      if (user.roles.contains(UserType.admin))
                        Positioned(
                          top: 56,
                          right: 16,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Theme.of(context).colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            ),
                            icon: const Icon(Icons.admin_panel_settings, size: 20),
                            label: const Text('Admin'),
                            onPressed: () {
                              Navigator.of(context).pushNamed('/admin');
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
} 