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
import '../cubit/news_cubit.dart';
import '../cubit/news_states.dart';
import '../repository/news_repository.dart';
import '../widgets/daily_verse_widget.dart';
import 'terkini_news_feed.dart';
import '../admin/manage_classes_page.dart';
import '../admin/manage_duas_page.dart';
import '../admin/manage_hadiths_page.dart';

class JurulatihDashboardPage extends StatefulWidget {
  const JurulatihDashboardPage({super.key});

  @override
  State<JurulatihDashboardPage> createState() => _JurulatihDashboardPageState();
}

class _JurulatihDashboardPageState extends State<JurulatihDashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClassCubit>().fetchClasses();
      context.read<LiveStreamCubit>().getCurrentLiveStream();
      context.read<DuaCubit>().fetchDuas();
      context.read<HadithCubit>().fetchHadiths();
      context.read<NewsCubit>().fetchNews();
      
      // Fetch prayer times using user's location if available
      final user = context.read<UserCubit>().state.currentUser;
      final prayerTimesCubit = context.read<PrayerTimesCubit>();
      prayerTimesCubit.fetchHijriDate();
      
      if (user?.latitude != null && user?.longitude != null) {
        // Use user's location coordinates
        prayerTimesCubit.fetchPrayerTimesByCoordinates(user!.latitude!, user.longitude!);
      } else {
        // Fallback to default location (Kuala Lumpur)
        prayerTimesCubit.fetchCurrentPrayerTimes('Kuala Lumpur', 'Kuala Lumpur');
      }
    });
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
        BlocProvider<AdCubit>(
          create: (context) => AdCubit(AdRepository())..fetchAds(),
        ),
        BlocProvider<WhatsNewCubit>(
          create: (context) => WhatsNewCubit(WhatsNewRepository())..fetchWhatsNew(),
        ),
        BlocProvider<NewsCubit>.value(
          value: context.read<NewsCubit>(),
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

          final user = userState.currentUser;
          if (user == null) {
            return const Scaffold(
              body: Center(
                child: Text('Tiada data pengguna'),
              ),
            );
          }

          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: RefreshIndicator(
              onRefresh: () async {
                context.read<ClassCubit>().fetchClasses();
                context.read<LiveStreamCubit>().getCurrentLiveStream();
                context.read<DuaCubit>().fetchDuas();
                context.read<HadithCubit>().fetchHadiths();
                context.read<NewsCubit>().fetchNews();
                context.read<UserCubit>().fetchCurrentUser();
                context.read<PrayerTimesCubit>().fetchHijriDate();
                context.read<PrayerTimesCubit>().fetchCurrentPrayerTimes('Kuala Lumpur', 'Kuala Lumpur');
              },
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('halo'),
                    // Jurulatih Badge Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.primary.withOpacity(0.7),
                          ],
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.school, color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Jurulatih',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          ValueListenableBuilder<ThemeMode>(
                            valueListenable: themeModeNotifier,
                            builder: (context, mode, _) => IconButton(
                              icon: Icon(
                                mode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                themeModeNotifier.value = mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    BlocProvider.value(
                      value: context.read<UserCubit>(),
                      child: HeaderSection(user: user),
                    ),
                    PrayerTimesCard(),
                    const DailyVerseWidget(),
                    BlocBuilder<NewsCubit, NewsState>(
                      builder: (context, newsState) {
                        // Debug logging
                        print('JurulatihDashboard - News count: ${newsState.news.length}, Loading: ${newsState.isLoading}, Error: ${newsState.error}');
                        
                        // Show loading state
                        if (newsState.isLoading) {
                          return const SizedBox.shrink(); // Hide during loading
                        }
                        
                        // Show error state
                        if (newsState.error != null) {
                          print('NewsState error: ${newsState.error}');
                          return const SizedBox.shrink();
                        }
                        
                        // Show news feed if there are news items
                        if (newsState.news.isNotEmpty) {
                          print('JurulatihDashboard - Showing ${newsState.news.length} news items');
                          return TerkiniNewsFeed(news: newsState.news);
                        }
                        
                        // Hide if no news items
                        print('JurulatihDashboard - No news items, hiding widget');
                        return const SizedBox.shrink();
                      },
                    ),
                    DailyTracker(user: user),
                    QuickAccessGrid(),
                    if (!user.isPremium) BlocBuilder<AdCubit, AdState>(
                      builder: (context, adState) {
                        if (adState.ads.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return AdCarousel(ads: adState.ads);
                      },
                    ),
                    const SizedBox(height: 16),
                    // Trainer Management Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Urus Bahan',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 16),
                          _TrainerActionCard(
                            icon: Icons.class_,
                            title: 'Urus Kelas',
                            subtitle: 'Tambah, edit atau padam kelas',
                            color: Colors.blue,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const ManageClassesPage(),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          _TrainerActionCard(
                            icon: Icons.menu_book,
                            title: 'Urus Doa',
                            subtitle: 'Tambah, edit atau padam doa',
                            color: Colors.green,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const ManageDuasPage(),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          _TrainerActionCard(
                            icon: Icons.book,
                            title: 'Urus Hadis',
                            subtitle: 'Tambah, edit atau padam hadis',
                            color: Colors.orange,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const ManageHadithsPage(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // WhatsNewCarousel(),
                    // FeaturedSection(user: user),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TrainerActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _TrainerActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

