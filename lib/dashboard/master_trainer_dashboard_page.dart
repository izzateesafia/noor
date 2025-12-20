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
                          value: _getActiveUsersCount(context),
                          label: 'Active Users',
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
                      child: BlocBuilder<ClassCubit, ClassState>(
                        builder: (context, state) => _StatBox(
                          value: _getClassesCount(context),
                          label: 'Classes',
                          color: primaryColor.withOpacity(0.6),
                          isDark: isDark,
                        ),
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

  String _getActiveUsersCount(BuildContext context) {
    final state = context.read<UserCubit>().state;
    if (state.status == UserStatus.loading) return '...';
    return state.users.length.toString();
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
