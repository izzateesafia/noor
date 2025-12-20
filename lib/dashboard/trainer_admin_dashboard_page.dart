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
import '../admin/manage_news_page.dart';
import '../main.dart';
import '../theme_constants.dart';

class TrainerAdminDashboardPage extends StatefulWidget {
  const TrainerAdminDashboardPage({super.key});

  @override
  State<TrainerAdminDashboardPage> createState() => _TrainerAdminDashboardPageState();
}

class _TrainerAdminDashboardPageState extends State<TrainerAdminDashboardPage> {
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
          appBar: AppBar(
            title: Text(isMasterTrainer ? 'Master Trainer Dashboard' : 'Jurulatih Dashboard'),
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
            foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
            actions: [
              ValueListenableBuilder<ThemeMode>(
                valueListenable: themeModeNotifier,
                builder: (context, mode, _) => IconButton(
                  icon: Icon(mode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode),
                  onPressed: () {
                    themeModeNotifier.value = mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
                  },
                ),
              ),
            ],
          ),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                context.read<ClassCubit>().fetchClasses();
                context.read<DuaCubit>().fetchDuas();
                context.read<HadithCubit>().fetchHadiths();
                context.read<UserCubit>().fetchCurrentUser();
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Header Card
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primary,
                              AppColors.primary.withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.all(24),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Selamat Datang,',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    user.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      isMasterTrainer ? 'Master Trainer' : 'Jurulatih',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isMasterTrainer ? Icons.star : Icons.school,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Statistics Section
                    Text(
                      'Statistik',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Row(
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

                    const SizedBox(height: 32),

                    // Management Actions Section
                    Text(
                      'Urus Bahan',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    _AdminActionButton(
                      icon: Icons.class_,
                      label: 'Urus Kelas',
                      description: 'Tambah, edit atau padam kelas',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const ManageClassesPage(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _AdminActionButton(
                      icon: Icons.menu_book,
                      label: 'Urus Doa',
                      description: 'Tambah, edit atau padam doa',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const ManageDuasPage(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _AdminActionButton(
                      icon: Icons.book,
                      label: 'Urus Hadis',
                      description: 'Tambah, edit atau padam hadis',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const ManageHadithsPage(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _AdminActionButton(
                      icon: Icons.article,
                      label: 'Urus Berita (Terkini)',
                      description: 'Tambah, edit atau padam berita terkini',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const ManageNewsPage(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 32),
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

class _AdminActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;

  const _AdminActionButton({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    
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
                  color: primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: primary, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
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

