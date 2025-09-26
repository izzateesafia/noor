import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../cubit/daily_tracker_cubit.dart';
import '../models/daily_tracker.dart';
import '../models/user_model.dart';

class DailyTrackerHistoryPage extends StatefulWidget {
  final UserModel user;

  const DailyTrackerHistoryPage({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  State<DailyTrackerHistoryPage> createState() => _DailyTrackerHistoryPageState();
}

class _DailyTrackerHistoryPageState extends State<DailyTrackerHistoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedDays = 30;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Load data when page initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DailyTrackerCubit>().loadAllData(widget.user.id, days: _selectedDays);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Sejarah Penjejak Harian'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
        actions: [
          BlocBuilder<DailyTrackerCubit, DailyTrackerState>(
            builder: (context, state) {
              if (state is DailyTrackerLoading) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Days selector
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tunjukkan yang terakhir: ',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [7, 30, 90].map((days) => ChoiceChip(
                    label: Text('$days hari'),
                    selected: _selectedDays == days,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedDays = days);
                        context.read<DailyTrackerCubit>().loadAllData(widget.user.id, days: days);
                      }
                    },
                  )).toList(),
                ),
              ],
            ),
          ),

          // Tab bar
          Container(
            color: Theme.of(context).colorScheme.surface,
            child: TabBar(
              controller: _tabController,
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              indicatorColor: Theme.of(context).colorScheme.primary,
              tabs: const [
                Tab(text: 'Statistik'),
                Tab(text: 'Sejarah'),
                Tab(text: 'Kalendar'),
              ],
            ),
          ),

          // Tab content
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                context.read<DailyTrackerCubit>().loadAllData(widget.user.id, days: _selectedDays);
              },
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildStatisticsTab(),
                  _buildHistoryTab(),
                  _buildCalendarTab(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsTab() {
    return BlocBuilder<DailyTrackerCubit, DailyTrackerState>(
      builder: (context, state) {
        if (state is DailyTrackerLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is DailyTrackerLoaded && state.stats.isNotEmpty) {
          final stats = state.stats;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Overview cards
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Jumlah Hari',
                        '${stats['totalDays'] ?? 0}',
                        Icons.calendar_today,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'Perfect Days',
                        '${stats['daysWithAllPrayers'] ?? 0}',
                        Icons.star,
                        Colors.amber,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Quran Days',
                        '${stats['daysWithQuran'] ?? 0}',
                        Icons.menu_book,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'Prayer Rate',
                        '${(stats['prayerCompletionRate'] ?? 0).toStringAsFixed(1)}%',
                        Icons.handshake,
                        Colors.purple,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Prayer breakdown
                Text(
                  'Prayer Completion Breakdown',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                ...(['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'].map((prayer) {
                  final count = (stats['prayerCounts']?[prayer] ?? 0) as int;
                  final totalDays = (stats['totalDays'] ?? 0) as int;
                  final percentage = totalDays > 0
                      ? (count / totalDays) * 100.0
                      : 0.0;

                  return _buildPrayerProgressCard(prayer, count, percentage);
                })),

                const SizedBox(height: 24),

                // Quran progress
                Text(
                  'Quran Recitation Progress',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                _buildQuranProgressCard(
                  stats['daysWithQuran'] ?? 0,
                  stats['totalDays'] ?? 0,
                  stats['quranCompletionRate'] ?? 0,
                ),
              ],
            ),
          );
        }

        return const Center(
          child: Text('No statistics available'),
        );
      },
    );
  }

  Widget _buildHistoryTab() {
    return BlocBuilder<DailyTrackerCubit, DailyTrackerState>(
      builder: (context, state) {
        if (state is DailyTrackerLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is DailyTrackerError) {
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
                  'Error loading history',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  state.message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.read<DailyTrackerCubit>().loadAllData(widget.user.id, days: _selectedDays);
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (state is DailyTrackerLoaded) {
          if (state.history.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No history available',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start tracking your daily activities to build your history.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.history.length,
            itemBuilder: (context, index) {
              final tracker = state.history[index];
              return _buildHistoryCard(tracker);
            },
          );
        }

        return const Center(
          child: Text('No history available'),
        );
      },
    );
  }

  Widget _buildCalendarTab() {
    return BlocBuilder<DailyTrackerCubit, DailyTrackerState>(
      builder: (context, state) {
        if (state is DailyTrackerLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is DailyTrackerLoaded && state.history.isNotEmpty) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _buildCalendarView(state.history),
          );
        }

        return const Center(
          child: Text('No calendar data available'),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerProgressCard(String prayer, int count, double percentage) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  prayer,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${count}/${_selectedDays} (${percentage.toStringAsFixed(1)}%)',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuranProgressCard(int completedDays, int totalDays, double percentage) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.menu_book,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Quran Recitation',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Completed: $completedDays days',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(DailyTrackerData tracker) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final completedPrayers = tracker.prayersCompleted.values.where((completed) => completed).length;
    final totalPrayers = tracker.prayersCompleted.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateFormat.format(tracker.date),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: completedPrayers == totalPrayers
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$completedPrayers/$totalPrayers prayers',
                    style: TextStyle(
                      color: completedPrayers == totalPrayers
                          ? Colors.green
                          : Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Prayer status
            Wrap(
              spacing: 8,
              children: tracker.prayersCompleted.entries.map((entry) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: entry.value
                        ? Colors.green.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: entry.value ? Colors.green : Colors.grey,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        entry.value ? Icons.check_circle : Icons.circle_outlined,
                        color: entry.value ? Colors.green : Colors.grey,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        entry.key,
                        style: TextStyle(
                          color: entry.value ? Colors.green : Colors.grey,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 12),

            // Quran status
            Row(
              children: [
                Icon(
                  Icons.menu_book,
                  color: tracker.quranRecited ? Colors.green : Colors.grey,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Quran Recitation: ${tracker.quranRecited ? "Completed" : "Not completed"}',
                  style: TextStyle(
                    color: tracker.quranRecited ? Colors.green : Colors.grey,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarView(List<DailyTrackerData> history) {
    // Create a map of dates to tracker data
    final Map<DateTime, DailyTrackerData> dateMap = {};
    for (final tracker in history) {
      final date = DateTime(tracker.date.year, tracker.date.month, tracker.date.day);
      dateMap[date] = tracker;
    }

    // Get the date range
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: _selectedDays - 1));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Last $_selectedDays Days',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Calendar grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemCount: _selectedDays,
          itemBuilder: (context, index) {
            final date = startDate.add(Duration(days: index));
            final tracker = dateMap[date];
            final isToday = date.isAtSameMomentAs(DateTime(now.year, now.month, now.day));

            return _buildCalendarDay(date, tracker, isToday);
          },
        ),

        const SizedBox(height: 24),

        // Legend
        _buildCalendarLegend(),
      ],
    );
  }

  Widget _buildCalendarDay(DateTime date, DailyTrackerData? tracker, bool isToday) {
    final hasData = tracker != null;
    final allPrayersCompleted = hasData && tracker!.prayersCompleted.values.every((completed) => completed);
    final quranCompleted = hasData && tracker!.quranRecited;

    Color backgroundColor = Colors.transparent;
    Color borderColor = Colors.grey.withOpacity(0.3);

    if (isToday) {
      backgroundColor = Theme.of(context).colorScheme.primary.withOpacity(0.1);
      borderColor = Theme.of(context).colorScheme.primary;
    } else if (allPrayersCompleted && quranCompleted) {
      backgroundColor = Colors.green.withOpacity(0.2);
      borderColor = Colors.green;
    } else if (allPrayersCompleted) {
      backgroundColor = Colors.blue.withOpacity(0.2);
      borderColor = Colors.blue;
    } else if (hasData) {
      backgroundColor = Colors.orange.withOpacity(0.2);
      borderColor = Colors.orange;
    }

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${date.day}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                color: isToday
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
            if (hasData) ...[
              const SizedBox(height: 2),
              Icon(
                allPrayersCompleted ? Icons.check : Icons.circle,
                size: 8,
                color: allPrayersCompleted ? Colors.green : Colors.orange,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarLegend() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Legend',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            _buildLegendItem('Today', Theme.of(context).colorScheme.primary),
            const SizedBox(width: 16),
            _buildLegendItem('Perfect Day', Colors.green),
            const SizedBox(width: 16),
            _buildLegendItem('Prayers Only', Colors.blue),
          ],
        ),

        const SizedBox(height: 8),

        Row(
          children: [
            _buildLegendItem('Partial', Colors.orange),
            const SizedBox(width: 16),
            _buildLegendItem('No Data', Colors.grey),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            border: Border.all(color: color, width: 1),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
