import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import '../cubit/prayer_times_cubit.dart';
import '../cubit/prayer_times_states.dart';
import '../models/prayer_times.dart';
import '../theme_constants.dart';


class PrayerTimesCard extends StatefulWidget {
  const PrayerTimesCard({super.key});

  @override
  State<PrayerTimesCard> createState() => _PrayerTimesCardState();
}

class _PrayerTimesCardState extends State<PrayerTimesCard> {
  Timer? _autoRefreshTimer;
  Timer? _nextPrayerTimer;

  @override
  void initState() {
    super.initState();
    // Start auto-refresh functionality
    _startAutoRefresh();
    _startNextPrayerTimer();
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _nextPrayerTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    // Refresh prayer times every 30 minutes
    _autoRefreshTimer = Timer.periodic(const Duration(minutes: 30), (timer) {
      if (mounted) {
        context.read<PrayerTimesCubit>().fetchCurrentPrayerTimes('Kuala Lumpur', 'Kuala Lumpur');
      }
    });
  }

  void _startNextPrayerTimer() {
    // Check for next prayer every minute
    _nextPrayerTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        setState(() {
          // Trigger rebuild to update next prayer highlighting
        });
      }
    });
  }



  String _getNextPrayer(PrayerTimes prayerTimes) {
    final now = DateTime.now();
    final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    
    final prayers = [
      {'name': 'Fajr', 'time': prayerTimes.fajr, 'displayName': 'Subuh'},
      {'name': 'Dhuhr', 'time': prayerTimes.dhuhr, 'displayName': 'Zuhur'},
      {'name': 'Asr', 'time': prayerTimes.asr, 'displayName': 'Asar'},
      {'name': 'Maghrib', 'time': prayerTimes.maghrib, 'displayName': 'Maghrib'},
      {'name': 'Isha', 'time': prayerTimes.isha, 'displayName': 'Isya'},
    ];

    for (var prayer in prayers) {
      if (prayer['time']!.compareTo(currentTime) > 0) {
        return prayer['displayName']!;
      }
    }
    return 'Subuh'; // Default to Subuh if all prayers have passed
  }

  List<Map<String, String>> _getPrayersList(PrayerTimes prayerTimes) {
    return [
      {'name': 'Fajr', 'time': prayerTimes.fajr, 'displayName': 'Subuh'},
      {'name': 'Sunrise', 'time': prayerTimes.sunrise, 'displayName': 'Terbit'},
      {'name': 'Dhuhr', 'time': prayerTimes.dhuhr, 'displayName': 'Zuhur'},
      {'name': 'Asr', 'time': prayerTimes.asr, 'displayName': 'Asar'},
      {'name': 'Maghrib', 'time': prayerTimes.maghrib, 'displayName': 'Maghrib'},
      {'name': 'Isha', 'time': prayerTimes.isha, 'displayName': 'Isya'},
    ];
  }

  String _getMonthName(int month) {
    switch (month) {
      case 1:
        return 'Jan';
      case 2:
        return 'Feb';
      case 3:
        return 'Mar';
      case 4:
        return 'Apr';
      case 5:
        return 'May';
      case 6:
        return 'Jun';
      case 7:
        return 'Jul';
      case 8:
        return 'Aug';
      case 9:
        return 'Sep';
      case 10:
        return 'Oct';
      case 11:
        return 'Nov';
      case 12:
        return 'Dec';
      default:
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PrayerTimesCubit, PrayerTimesState>(
      builder: (context, state) {
        if (state.status == PrayerTimesStatus.loading) {
          return _buildLoadingCard();
        }

        if (state.status == PrayerTimesStatus.error) {
          return _buildErrorCard(state.error ?? 'Failed to load prayer times');
        }

        if (state.prayerTimes == null) {
          return _buildEmptyCard();
        }

        final prayerTimes = state.prayerTimes!;
        final hijriDate = state.hijriDate;
        final location = state.currentPrayerTimes?.location;
        final nextPrayer = _getNextPrayer(prayerTimes);
        final prayers = _getPrayersList(prayerTimes);

        // Note: Adhan is now handled by PrayerAlarmService automatically

        return RefreshIndicator(
          onRefresh: () async {
            // Refresh prayer times when user pulls to refresh
            context.read<PrayerTimesCubit>().fetchCurrentPrayerTimes('Kuala Lumpur', 'Kuala Lumpur');
            await Future.delayed(const Duration(milliseconds: 500)); // Small delay for better UX
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                color: Theme.of(context).cardColor,
                child: Column(
                  children: [
                    // Header with Hijri date and next prayer
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                                                     Expanded(
                             child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 Text(
                                   '${DateTime.now().day} ${_getMonthName(DateTime.now().month)} ${DateTime.now().year}',
                                   style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                     color: AppColors.primary,
                                     fontWeight: FontWeight.bold,
                                   ),
                                 ),
                                 Text(
                                   'Next: $nextPrayer',
                                   style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                     color: AppColors.primary.withOpacity(0.8),
                                   ),
                                 ),
                               ],
                             ),
                           ),
                           // Prayer alarm settings button
                           IconButton(
                             onPressed: () {
                               Navigator.pushNamed(context, '/prayer_alarm_settings');
                             },
                             icon: Icon(
                               Icons.settings,
                               color: AppColors.primary,
                               size: 20,
                             ),
                             tooltip: 'Prayer Alarm Settings',
                           ),
                        ],
                      ),
                    ),
                    
                    // Prayer times in rows
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Main prayers row (Fajr, Dhuhr, Asr, Maghrib, Isha)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: prayers.where((p) => p['name'] != 'Sunrise').map((prayer) {
                              final bool isNext = prayer['displayName'] == nextPrayer;
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    prayer['displayName']!,
                                    style: isNext
                                        ? Theme.of(context).textTheme.bodyLarge?.copyWith(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          )
                                        : Theme.of(context).textTheme.bodyLarge?.copyWith(
                                            color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.8),
                                            fontWeight: FontWeight.w500,
                                            fontSize: 13,
                                          ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    prayer['time']!,
                                    style: isNext
                                        ? Theme.of(context).textTheme.bodyLarge?.copyWith(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          )
                                        : Theme.of(context).textTheme.bodyLarge?.copyWith(
                                            color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.7),
                                            fontWeight: FontWeight.normal,
                                            fontSize: 13,
                                          ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Sunrise row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.wb_sunny_outlined, color: Colors.orange, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                'Sunrise: ${prayers.firstWhere((p) => p['name'] == 'Sunrise')['time']}',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    

                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: const Padding(
          padding: EdgeInsets.all(20),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading prayer times...'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard(String error) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                'Error loading prayer times',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.red.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  context.read<PrayerTimesCubit>().fetchCurrentPrayerTimes('Kuala Lumpur', 'Kuala Lumpur');
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: const Padding(
          padding: EdgeInsets.all(20),
          child: Center(
            child: Text('No prayer times available'),
          ),
        ),
      ),
    );
  }
} 