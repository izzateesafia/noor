import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import '../cubit/daily_tracker_cubit.dart';
import '../models/user_model.dart';
import '../models/daily_tracker.dart';
import 'daily_tracker_history_page.dart';

class DailyTracker extends StatefulWidget {
  final UserModel user;
  final DailyTrackerData? initialData;

  const DailyTracker({
    super.key,
    required this.user,
    this.initialData,
  });

  @override
  State<DailyTracker> createState() => _DailyTrackerState();
}

class _DailyTrackerState extends State<DailyTracker> {
  late Map<String, bool> prayersCompleted;
  late bool quranRecited;
  bool showConfetti = false;

  @override
  void initState() {
    super.initState();
    // Use initial data if available, otherwise use defaults
    if (widget.initialData != null) {
      prayersCompleted = Map<String, bool>.from(widget.initialData!.prayersCompleted);
      quranRecited = widget.initialData!.quranRecited;
    } else {
      prayersCompleted = Map<String, bool>.from({
        'Fajr': false,
        'Dhuhr': false,
        'Asr': false,
        'Maghrib': false,
        'Isha': false,
      });
      quranRecited = false;
    }
    
    // Load today's tracker from Firebase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DailyTrackerCubit>().loadTodayTracker(widget.user.id);
    });
  }

  void _togglePrayer(String prayer) async {
    final newValue = !(prayersCompleted[prayer] ?? false);
    
    setState(() {
      prayersCompleted[prayer] = newValue;
      if (allPrayersCompleted) {
        showConfetti = true;
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => showConfetti = false);
        });
      }
    });

    // Update in Firebase
    try {
      await context.read<DailyTrackerCubit>().updatePrayerCompletion(
        widget.user.id,
        prayer,
        newValue,
      );
    } catch (e) {
      // Revert on error
      setState(() {
        prayersCompleted[prayer] = !newValue;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengemas kini solat: $e')),
      );
    }
  }

  void _toggleQuran() async {
    final newValue = !quranRecited;
    
    setState(() {
      final wasRecited = quranRecited;
      quranRecited = newValue;
      if (!wasRecited && quranRecited) {
        showConfetti = true;
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => showConfetti = false);
        });
      }
    });

    // Update in Firebase
    try {
      await context.read<DailyTrackerCubit>().updateQuranRecitation(
        widget.user.id,
        newValue,
      );
    } catch (e) {
      // Revert on error
      setState(() {
        quranRecited = !newValue;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengemas kini bacaan Al-Quran: $e')),
      );
    }
  }

  bool get allPrayersCompleted => prayersCompleted.values.every((v) => v);

  String _getPrayerDisplayName(String prayerName) {
    switch (prayerName) {
      case 'Fajr':
        return 'Subuh';
      case 'Dhuhr':
        return 'Zuhur';
      case 'Asr':
        return 'Asar';
      case 'Maghrib':
        return 'Maghrib';
      case 'Isha':
        return 'Isya';
      default:
        return prayerName;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DailyTrackerCubit, DailyTrackerState>(
      listener: (context, state) {
        if (state is DailyTrackerLoaded && state.todayTracker != null) {
          // Update local state with Firebase data
          setState(() {
            prayersCompleted = Map<String, bool>.from(state.todayTracker!.prayersCompleted);
            quranRecited = state.todayTracker!.quranRecited;
          });
        }
      },
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              color: Theme.of(context).cardColor,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row(
                    //   children: [
                    //     Icon(
                    //       Icons.check_circle_outline,
                    //       color: Theme.of(context).colorScheme.primary,
                    //       size: 22
                    //     ),
                    //     const SizedBox(width: 8),
                    //     Text(
                    //       'Penjejak Harian',
                    //       style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 15),
                    //     ),
                    //     const Spacer(),
                    //     // History button
                    //     IconButton(
                    //       onPressed: () {
                    //         Navigator.of(context).push(
                    //           MaterialPageRoute(
                    //             builder: (context) => BlocProvider.value(
                    //               value: context.read<DailyTrackerCubit>(),
                    //               child: DailyTrackerHistoryPage(user: widget.user),
                    //             ),
                    //           ),
                    //         );
                    //       },
                    //       icon: Icon(
                    //         Icons.history,
                    //         color: Theme.of(context).colorScheme.primary,
                    //         size: 20,
                    //       ),
                    //       tooltip: 'Lihat Sejarah',
                    //     ),
                    //   ],
                    // ),
                    // const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: prayersCompleted.entries.map((entry) {
                        return GestureDetector(
                          onTap: () => _togglePrayer(entry.key),
                          child: Column(
                            children: [
                              Icon(
                                entry.value ? Icons.check_circle : Icons.radio_button_unchecked,
                                color: entry.value 
                                    ? Theme.of(context).colorScheme.primary 
                                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                                size: 32,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _getPrayerDisplayName(entry.key),
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 22),
                    GestureDetector(
                      onTap: _toggleQuran,
                      child: Row(
                        children: [
                          Icon(
                            Icons.menu_book, 
                            color: Theme.of(context).colorScheme.primary, 
                            size: 22
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Bacaan Al-Quran',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const Spacer(),
                          quranRecited
                              ? Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle, 
                                      color: Theme.of(context).colorScheme.primary, 
                                      size: 22
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Selesai', 
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.primary, 
                                        fontWeight: FontWeight.w600
                                      )
                                    ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    Icon(
                                      Icons.radio_button_unchecked, 
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3), 
                                      size: 22
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Belum lagi', 
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3)
                                      )
                                    ),
                                  ],
                                ),
                        ],
                      ),
                    ),
                    
                    // Progress indicator
                    const SizedBox(height: 20),
                    _buildProgressIndicator(),
                  ],
                ),
              ),
            ),
          ),
          if (showConfetti)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => showConfetti = false),
                child: Container(
                  child: Center(
                    child: Lottie.asset(
                      'assets/lotties/confetti.json',
                      height: 500,
                      repeat: false,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final completedPrayers = prayersCompleted.values.where((completed) => completed).length;
    final totalPrayers = prayersCompleted.length;
    final prayerProgress = totalPrayers > 0 ? completedPrayers / totalPrayers : 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Daily Progress',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${(prayerProgress * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: prayerProgress,
          backgroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$completedPrayers daripada $totalPrayers waktu solat dilaksanakan',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
} 