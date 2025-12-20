import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/user_cubit.dart';
import '../cubit/user_states.dart';
import '../cubit/class_cubit.dart';
import '../cubit/class_states.dart';
import '../cubit/dua_cubit.dart';
import '../cubit/dua_states.dart';
import '../cubit/hadith_cubit.dart';
import '../cubit/hadith_states.dart';
import '../models/user_model.dart';
import '../admin/manage_duas_page.dart';
import '../admin/manage_hadiths_page.dart';
import '../admin/manage_classes_page.dart';
import '../main.dart';

class TrainerDashboardPage extends StatefulWidget {
  const TrainerDashboardPage({super.key});

  @override
  State<TrainerDashboardPage> createState() => _TrainerDashboardPageState();
}

class _TrainerDashboardPageState extends State<TrainerDashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClassCubit>().fetchClasses();
      context.read<DuaCubit>().fetchDuas();
      context.read<HadithCubit>().fetchHadiths();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UserCubit, UserState>(
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

        // Default user for fallback
        UserModel user = UserModel(
          id: 'default',
          name: 'User',
          email: 'user@example.com',
          phone: 'N/A',
          roles: const [UserType.student],
          isPremium: false,
        );

        // Use real user data if available
        if (userState.status == UserStatus.loaded && userState.currentUser != null) {
          user = userState.currentUser!;
        }

        final bool isMasterTrainer = user.roles.contains(UserType.masterTrainer);

        return Scaffold(
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                context.read<ClassCubit>().fetchClasses();
                context.read<DuaCubit>().fetchDuas();
                context.read<HadithCubit>().fetchHadiths();
              },
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Section
                    Container(
                      padding: const EdgeInsets.all(24),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Selamat Datang,',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.9),
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    user.name,
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onPrimary,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      isMasterTrainer ? 'Master Trainer' : 'Trainer',
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onPrimary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              // Theme mode switch
                              ValueListenableBuilder<ThemeMode>(
                                valueListenable: themeModeNotifier,
                                builder: (context, mode, _) => Row(
                                  children: [
                                    Icon(
                                      mode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode,
                                      color: Theme.of(context).colorScheme.onPrimary,
                                    ),
                                    Switch(
                                      value: mode == ThemeMode.dark,
                                      onChanged: (val) {
                                        themeModeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
                                      },
                                      activeColor: Colors.yellow,
                                      inactiveThumbColor: Theme.of(context).colorScheme.onPrimary,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Statistics Cards
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Expanded(
                            child: BlocBuilder<ClassCubit, ClassState>(
                              builder: (context, state) => _StatCard(
                                icon: Icons.class_,
                                label: 'Kelas',
                                value: state.classes.length.toString(),
                                color: Colors.blue,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: BlocBuilder<DuaCubit, DuaState>(
                              builder: (context, state) => _StatCard(
                                icon: Icons.menu_book,
                                label: 'Doa',
                                value: state.duas.length.toString(),
                                color: Colors.green,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: BlocBuilder<HadithCubit, HadithState>(
                              builder: (context, state) => _StatCard(
                                icon: Icons.book,
                                label: 'Hadis',
                                value: state.hadiths.length.toString(),
                                color: Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Quick Actions Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Tindakan Pantas',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Material Management Cards
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
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
                          const SizedBox(height: 16),
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
                          const SizedBox(height: 16),
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

                    // Recent Activity Section (if needed in future)
                    // You can add monitoring features here

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
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

