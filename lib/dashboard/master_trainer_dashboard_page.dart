import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/user_cubit.dart';
import '../cubit/user_states.dart';
import '../cubit/class_cubit.dart';
import '../cubit/class_states.dart';
import '../models/user_model.dart';
import '../models/class_model.dart';
import '../repository/user_repository.dart';
import '../theme_constants.dart';
import '../main.dart';
import '../admin_page.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;

class MasterTrainerDashboardPage extends StatefulWidget {
  const MasterTrainerDashboardPage({super.key});

  @override
  State<MasterTrainerDashboardPage> createState() => _MasterTrainerDashboardPageState();
}

class _MasterTrainerDashboardPageState extends State<MasterTrainerDashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClassCubit>().fetchClasses();
      if (context.read<UserCubit>().state.users.isEmpty) {
        context.read<UserCubit>().fetchUsers();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: RefreshIndicator(
              onRefresh: () async {
                context.read<ClassCubit>().fetchClasses();
          context.read<UserCubit>().fetchUsers();
              },
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
              // Header
                    Container(
                padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
                      decoration: BoxDecoration(
                  color: primaryColor,
                      ),
                      child: Row(
                        children: [
                    const Text(
                                  'Master Trainer',
                                  style: TextStyle(
                                    color: Colors.white,
                        fontSize: 18,
                                    fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          // Admin Panel Button
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (context) => const AdminPage()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.2),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            icon: const Icon(Icons.admin_panel_settings, size: 18),
                            label: const Text('Admin Panel', style: TextStyle(fontSize: 14)),
                          ),
                          const SizedBox(width: 8),
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
              
              // Three Stat Boxes
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: BlocBuilder<UserCubit, UserState>(
                        builder: (context, state) => _StatBox(
                          value: _getTotalUsersCount(context),
                          label: 'Total Users',
                          color: primaryColor,
                          isDark: isDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: BlocBuilder<UserCubit, UserState>(
                        builder: (context, state) => _StatBox(
                          value: _getStudentsCount(context),
                          label: 'Students',
                          color: primaryColor.withOpacity(0.8),
                          isDark: isDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: BlocBuilder<UserCubit, UserState>(
                        builder: (context, state) => _StatBox(
                          value: _getTrainersCount(context),
                          label: 'Trainers',
                          color: primaryColor.withOpacity(0.6),
                          isDark: isDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Real-time Analytics Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'REAL-TIME ANALYTICS',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                    ),
                    const SizedBox(height: 16),
                    
                    // New Registrations Chart
                    BlocBuilder<UserCubit, UserState>(
                      builder: (context, state) => _NewRegistrationsChart(
                        users: state.users,
                        primaryColor: primaryColor,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Active vs Inactive Statistics
                    BlocBuilder<UserCubit, UserState>(
                      builder: (context, state) => _ActiveInactiveStats(
                        users: state.users,
                        primaryColor: primaryColor,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
              ),

              // Main Content Area
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column - Stats and Charts
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Active Users Chart
                          Text(
                            'ACTIVE USERS',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                          ),
                          const SizedBox(height: 12),
                          _AreaChart(
                            data: _generateUserActivityData(),
                            primaryColor: primaryColor,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 24),
                          
                          // Stats Section
                          Text(
                            'STATS',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                          ),
                          const SizedBox(height: 12),
                          BlocBuilder<UserCubit, UserState>(
                            builder: (context, userState) {
                              return BlocBuilder<ClassCubit, ClassState>(
                                builder: (context, classState) {
                                  return _CircularProgressChart(
                                    value: _getEnrollmentRate(context),
                                    label: 'Enrollment',
                                    primaryColor: primaryColor,
                                    isDark: isDark,
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(width: 20),
                    
                    // Right Column - Maintenance and Top Classes
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Maintenance Section
                          Row(
                            children: [
                              Icon(
                                Icons.public,
                                color: primaryColor,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: primaryColor,
                                  shape: BoxShape.rectangle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.6),
                                  shape: BoxShape.rectangle,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'MAINTENANCE',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                          ),
                          const SizedBox(height: 12),
                          _CircularProgressChart(
                            value: _getSystemHealth(),
                            label: 'System Health',
                            primaryColor: primaryColor,
                            isDark: isDark,
                            showPercentage: true,
                          ),
                          const SizedBox(height: 24),
                          
                          // Top Classes
                          Text(
                            'TOP CLASSES',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                          ),
                          const SizedBox(height: 12),
                          BlocBuilder<ClassCubit, ClassState>(
                            builder: (context, classState) {
                              return BlocBuilder<UserCubit, UserState>(
                                builder: (context, userState) {
                                  return _TopClassesList(
                                    classes: _getTopEnrolledClasses(context),
                                    primaryColor: primaryColor,
                                    isDark: isDark,
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

                    const SizedBox(height: 24),

              // Network Activities Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NETWORK ACTIVITIES',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                    ),
                    const SizedBox(height: 12),
                    _AreaChart(
                      data: _generateNetworkActivityData(),
                      primaryColor: primaryColor,
                      isDark: isDark,
                      showDots: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
            ),
          );
  }

  String _getTotalUsersCount(BuildContext context) {
    final state = context.read<UserCubit>().state;
    if (state.status == UserStatus.loading) return '...';
    return state.users.length.toString();
  }

  String _getTrainersCount(BuildContext context) {
    final state = context.read<UserCubit>().state;
    if (state.status == UserStatus.loading) return '...';
    final trainers = state.users.where((u) => 
      u.roles.contains(UserType.trainer) || u.roles.contains(UserType.masterTrainer)
    ).length;
    return trainers.toString();
  }

  String _getStudentsCount(BuildContext context) {
    final state = context.read<UserCubit>().state;
    if (state.status == UserStatus.loading) return '...';
    final students = state.users.where((u) => 
      u.roles.contains(UserType.student)
    ).length;
    return students.toString();
  }

  String _getClassesCount(BuildContext context) {
    final state = context.read<ClassCubit>().state;
    if (state.status == ClassStatus.loading) return '...';
    return state.classes.length.toString();
  }

  double _getEnrollmentRate(BuildContext context) {
    final userState = context.read<UserCubit>().state;
    final classState = context.read<ClassCubit>().state;
    if (userState.users.isEmpty || classState.classes.isEmpty) return 0.0;
    final totalEnrollments = userState.users
        .fold<int>(0, (sum, user) => sum + user.enrolledClassIds.length);
    final maxPossible = userState.users.length * classState.classes.length;
    if (maxPossible == 0) return 0.0;
    return (totalEnrollments / maxPossible * 100).clamp(0.0, 100.0);
  }

  double _getSystemHealth() {
    // Mock system health - could be calculated from actual system metrics
    return 85.0;
  }

  List<double> _generateUserActivityData() {
    // Generate mock data for the last 7 days
    final random = math.Random(42); // Fixed seed for consistent data
    return List.generate(7, (index) => 20 + random.nextDouble() * 60);
  }

  List<double> _generateNetworkActivityData() {
    // Generate mock data for network activities
    final random = math.Random(24); // Different seed for variety
    return List.generate(7, (index) => 30 + random.nextDouble() * 50);
  }

  List<Map<String, dynamic>> _getTopEnrolledClasses(BuildContext context) {
    final classState = context.read<ClassCubit>().state;
    final userState = context.read<UserCubit>().state;
    
    if (classState.classes.isEmpty || userState.users.isEmpty) {
      return [];
    }
    
    // Count enrollments per class
    final enrollmentCounts = <String, int>{};
    for (final user in userState.users) {
      for (final classId in user.enrolledClassIds) {
        enrollmentCounts[classId] = (enrollmentCounts[classId] ?? 0) + 1;
      }
    }
    
    // Get top 3 classes
    final sortedClasses = classState.classes.map((cls) {
      return {
        'class': cls,
        'count': enrollmentCounts[cls.id] ?? 0,
      };
    }).toList()
      ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
    
    return sortedClasses.take(3).toList();
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final bool isDark;

  const _StatBox({
    required this.value,
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _AreaChart extends StatelessWidget {
  final List<double> data;
  final Color primaryColor;
  final bool isDark;
  final bool showDots;

  const _AreaChart({
    required this.data,
    required this.primaryColor,
    required this.isDark,
    this.showDots = false,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const SizedBox(height: 120);
    }

    final maxValue = data.reduce(math.max);
    final minValue = data.reduce(math.min);
    final range = maxValue - minValue;
    final normalizedData = data.map((v) => (v - minValue) / range).toList();

    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: CustomPaint(
        painter: _AreaChartPainter(
          data: normalizedData,
          primaryColor: primaryColor,
          showDots: showDots,
        ),
        child: Container(),
      ),
    );
  }
}

class _AreaChartPainter extends CustomPainter {
  final List<double> data;
  final Color primaryColor;
  final bool showDots;

  _AreaChartPainter({
    required this.data,
    required this.primaryColor,
    required this.showDots,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          primaryColor.withOpacity(0.3),
          primaryColor.withOpacity(0.1),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final strokePaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    final stepX = size.width / (data.length - 1);

    // Create area path
    path.moveTo(0, size.height);
    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = size.height - (data[i] * size.height * 0.8) - size.height * 0.1;
      if (i == 0) {
        path.lineTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, strokePaint);

    // Draw dots if needed
    if (showDots) {
      final dotPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      
      for (int i = 0; i < data.length; i++) {
        final x = i * stepX;
        final y = size.height - (data[i] * size.height * 0.8) - size.height * 0.1;
        canvas.drawCircle(Offset(x, y), 3, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _CircularProgressChart extends StatelessWidget {
  final double value;
  final String label;
  final Color primaryColor;
  final bool isDark;
  final bool showPercentage;

  const _CircularProgressChart({
    required this.value,
    required this.label,
    required this.primaryColor,
    required this.isDark,
    this.showPercentage = false,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = value.clamp(0.0, 100.0);
    final displayValue = showPercentage ? percentage : (percentage / 100 * 1000).round();

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: CircularProgressIndicator(
              value: percentage / 100,
              strokeWidth: 8,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                showPercentage 
                    ? '${percentage.toStringAsFixed(0)}%'
                    : '${(displayValue / 1000).toStringAsFixed(1)}K',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              if (!showPercentage && percentage > 0)
                Text(
                  '^${(percentage / 10).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TopClassesList extends StatelessWidget {
  final List<Map<String, dynamic>> classes;
  final Color primaryColor;
  final bool isDark;

  const _TopClassesList({
    required this.classes,
    required this.primaryColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (classes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'No classes yet',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    return Container(
                decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
      child: Column(
        children: classes.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final classModel = item['class'] as ClassModel;
          final count = item['count'] as int;
          
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(
                bottom: index < classes.length - 1
                    ? BorderSide(color: Colors.grey[300]!, width: 0.5)
                    : BorderSide.none,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ),
                const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        classModel.title,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                        '$count enrolled',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          );
        }).toList(),
      ),
    );
  }
}

// Chart Widgets for Real-time Analytics

class _NewRegistrationsChart extends StatelessWidget {
  final List<UserModel> users;
  final Color primaryColor;
  final bool isDark;

  const _NewRegistrationsChart({
    required this.users,
    required this.primaryColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // Since we don't have createdAt, we'll use a mock approach
    // In production, you'd need to add createdAt to UserModel
    final now = DateTime.now();
    final daily = <DateTime, int>{};
    final weekly = <int, int>{};
    final monthly = <String, int>{};

    // Mock data based on user count distribution
    // In real implementation, use user.createdAt
    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: 6 - i));
      daily[date] = (users.length / 7).round() + math.Random().nextInt(5);
    }

    for (int i = 0; i < 4; i++) {
      weekly[i] = (users.length / 4).round() + math.Random().nextInt(10);
    }

    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
    for (int i = 0; i < 6; i++) {
      monthly[months[i]] = (users.length / 6).round() + math.Random().nextInt(15);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'New Registrations',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          DefaultTabController(
            length: 3,
            child: Column(
              children: [
                TabBar(
                  tabs: const [
                    Tab(text: 'Daily'),
                    Tab(text: 'Weekly'),
                    Tab(text: 'Monthly'),
                  ],
                  labelColor: primaryColor,
                  unselectedLabelColor: Colors.grey[600],
                ),
                SizedBox(
                  height: 200,
                  child: TabBarView(
                    children: [
                      _buildDailyChart(daily, primaryColor),
                      _buildWeeklyChart(weekly, primaryColor),
                      _buildMonthlyChart(monthly, primaryColor),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyChart(Map<DateTime, int> data, Color color) {
    final sortedDates = data.keys.toList()..sort();
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= sortedDates.length) return const Text('');
                final date = sortedDates[value.toInt()];
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '${date.day}/${date.month}',
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: sortedDates.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), data[sortedDates[entry.key]]!.toDouble());
            }).toList(),
            isCurved: true,
            color: color,
            barWidth: 3,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(show: true, color: color.withOpacity(0.1)),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart(Map<int, int> data, Color color) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: data.values.isEmpty ? 1 : data.values.reduce(math.max).toDouble() * 1.2,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'W${value.toInt() + 1}',
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: data.entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value.toDouble(),
                color: color,
                width: 20,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMonthlyChart(Map<String, int> data, Color color) {
    final months = data.keys.toList();
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: data.values.isEmpty ? 1 : data.values.reduce(math.max).toDouble() * 1.2,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= months.length) return const Text('');
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    months[value.toInt()],
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: months.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: data[entry.value]!.toDouble(),
                color: color,
                width: 20,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _ActiveInactiveStats extends StatelessWidget {
  final List<UserModel> users;
  final Color primaryColor;
  final bool isDark;

  const _ActiveInactiveStats({
    required this.users,
    required this.primaryColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // Consider users with completed biodata as active
    final active = users.where((u) => u.hasCompletedBiodata).length;
    final inactive = users.length - active;
    final total = users.length;
    final activePercentage = total > 0 ? (active / total * 100) : 0.0;
    final inactivePercentage = total > 0 ? (inactive / total * 100) : 0.0;

    if (users.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: Text('No data')),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Active vs Inactive',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 24),
          // Active Statistics
          _buildStatCard(
            context: context,
            label: 'Active Users',
            value: active.toString(),
            percentage: activePercentage,
            color: Colors.green,
            icon: Icons.check_circle,
          ),
          const SizedBox(height: 16),
          // Inactive Statistics
          _buildStatCard(
            context: context,
            label: 'Inactive Users',
            value: inactive.toString(),
            percentage: inactivePercentage,
            color: Colors.orange,
            icon: Icons.cancel,
          ),
          const SizedBox(height: 16),
          // Total
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Users',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  total.toString(),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required String label,
    required String value,
    required double percentage,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[700],
                        fontSize: 12,
                      ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      value,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
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

class _EnrollmentChart extends StatelessWidget {
  final List<UserModel> users;
  final List<ClassModel> classes;
  final Color primaryColor;
  final bool isDark;

  const _EnrollmentChart({
    required this.users,
    required this.classes,
    required this.primaryColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // Count enrollments per class
    final enrollmentCounts = <String, int>{};
    for (final user in users) {
      for (final classId in user.enrolledClassIds) {
        enrollmentCounts[classId] = (enrollmentCounts[classId] ?? 0) + 1;
      }
    }

    // Get top 10 classes
    final sortedClasses = classes.map((cls) {
      return {
        'class': cls,
        'count': enrollmentCounts[cls.id] ?? 0,
      };
    }).toList()
      ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

    final topClasses = sortedClasses.take(10).toList();

    if (topClasses.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: Text('No enrollment data')),
      );
    }

    final maxEnrollment = topClasses.first['count'] as int;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Student-Teacher Enrollment',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxEnrollment > 0 ? maxEnrollment.toDouble() * 1.2 : 10,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => primaryColor,
                    tooltipRoundedRadius: 8,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= topClasses.length) return const Text('');
                        final classModel = topClasses[value.toInt()]['class'] as ClassModel;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: RotatedBox(
                            quarterTurns: 1,
                            child: Text(
                              classModel.title.length > 15
                                  ? '${classModel.title.substring(0, 15)}...'
                                  : classModel.title,
                              style: TextStyle(fontSize: 9, color: Colors.grey[600]),
                            ),
                          ),
                        );
                      },
                      reservedSize: 60,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey[300]!,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: topClasses.asMap().entries.map((entry) {
                  final count = entry.value['count'] as int;
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: count.toDouble(),
                        color: primaryColor,
                        width: 20,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
