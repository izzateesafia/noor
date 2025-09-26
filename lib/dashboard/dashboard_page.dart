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
import '../widgets/daily_verse_widget.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClassCubit>().fetchClasses();
      context.read<LiveStreamCubit>().getCurrentLiveStream();
      context.read<DuaCubit>().fetchDuas();
      context.read<HadithCubit>().fetchHadiths();
      
      // Automatically fetch prayer times for default location (Kuala Lumpur)
      context.read<PrayerTimesCubit>().fetchHijriDate();
      context.read<PrayerTimesCubit>().fetchCurrentPrayerTimes('Kuala Lumpur', 'Kuala Lumpur');
    });
  }

  @override
  Widget build(BuildContext context) {
            return MultiBlocProvider(
          providers: [
            BlocProvider<UserCubit>(
              create: (context) => UserCubit(UserRepository())..fetchCurrentUser(),
            ),
            BlocProvider<AdCubit>(
              create: (context) => AdCubit(AdRepository())..fetchAds(),
            ),
            BlocProvider<WhatsNewCubit>(
              create: (context) => WhatsNewCubit(WhatsNewRepository())..fetchWhatsNew(),
            ),
          ],
          child: BlocConsumer<UserCubit, UserState>(
            listener: (context, userState) {
              if (userState.status == UserStatus.error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(userState.error ?? 'Gagal memuatkan data pengguna'),
                    backgroundColor: Colors.red,
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
                    backgroundColor: Colors.green,
                  ),
                );
                context.read<LiveStreamCubit>().clearMessage();
              } else if (state is LiveStreamError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                  ),
                );
                context.read<LiveStreamCubit>().clearMessage();
              }
            },
            builder: (context, liveStreamState) {
              // Default user for fallback
              UserModel user = UserModel(
                id: 'default',
                name: 'User',
                email: 'user@example.com',
                phone: 'N/A',
                userType: UserType.nonAdmin,
                isPremium: false,
              );

              // Use real user data if available
              if (userState.status == UserStatus.loaded && userState.currentUser != null) {
                user = userState.currentUser!;
                print('Dashboard: Using real user data: ${user.name} (${user.email})');
              } else if (userState.status == UserStatus.error) {
                // Handle error state
                print('Dashboard: Error loading user: ${userState.error}');
                print('Dashboard: Using fallback user data');
              } else {
                print('Dashboard: Using fallback user data (status: ${userState.status})');
              }

              // Get current live stream
              LiveStream? currentLiveStream;
              if (liveStreamState is LiveStreamLoaded) {
                currentLiveStream = liveStreamState.currentLiveStream;
              }

              // Debug logging
              print('LiveStreamState: $liveStreamState');
              print('CurrentLiveStream: $currentLiveStream');
              if (currentLiveStream != null) {
                print('LiveStream isActive: ${currentLiveStream.isActive}');
                print('LiveStream title: ${currentLiveStream.title}');
                print('LiveStream link: ${currentLiveStream.tiktokLiveLink}');
              } else {
                print('No current live stream found - this could mean:');
                print('1. No live streams exist in the database');
                print('2. No live streams have isActive: true');
                print('3. There was an error fetching from Firestore');
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
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 18),
                      ListTile(
                        leading: const Icon(Icons.live_tv, color: Colors.red),
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
                                const SnackBar(
                                  content: Text('Tidak dapat membuka pautan TikTok'),
                                  backgroundColor: Colors.red,
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
                          context.read<LiveStreamCubit>().getCurrentLiveStream();
                          context.read<ClassCubit>().fetchClasses();
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
                                    onPressed: isLoading ? null : () {
                                      // Refresh live stream data first
                                      context.read<LiveStreamCubit>().getCurrentLiveStream();
                                      // Then show the sheet
                                      _showLiveSheet();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(context).colorScheme.primary,
                                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                    ),
                                    icon: isLoading 
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
                                  if (user.userType == UserType.admin)
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        context.read<LiveStreamCubit>().addLiveStream(
                                          title: 'Test Live Stream',
                                          description: 'This is a test live stream for debugging',
                                          tiktokLiveLink: 'https://www.tiktok.com/@testuser/live/123456789',
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      ),
                                      icon: const Icon(Icons.bug_report, size: 16),
                                      label: const Text('Ujian', style: TextStyle(fontSize: 12)),
                                    ),
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
                            PrayerTimesCard(),
                            const DailyVerseWidget(),
                            DailyTracker(user: user),
                            QuickAccessGrid(),
                            if (!user.isPremium) BlocBuilder<AdCubit, AdState>(
                              builder: (context, adState) {
                                return AdCarousel(ads: adState.ads);
                              },
                            ),
                            if (!user.isPremium) BlocBuilder<AdCubit, AdState>(
                              builder: (context, adState) {
                                return AdPanel(ad: adState.ads.isNotEmpty ? adState.ads.first : null);
                              },
                            ),
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
                      // Admin button - only visible for admin users
                      if (user.userType == UserType.admin)
                        Positioned(
                          top: 8,
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