import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../theme_constants.dart';
import '../cubit/user_cubit.dart';
import '../cubit/user_states.dart';
import '../models/user_model.dart';
import 'dashboard/dashboard_page.dart';
import 'dashboard/jurulatih_dashboard_page.dart';
import 'dashboard/master_trainer_dashboard_page.dart';
import 'menu_page.dart';
import 'user_profile_page.dart';
import 'quran_reader_page.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;
  bool _hasShownRoleWarning = false;

  List<Widget> _getPages(UserModel? user) {
    // Determine which dashboard to show based on user roles from Firestore
    Widget dashboardPage;
    
    if (user == null) {
      // No user, default to student dashboard
      dashboardPage = const DashboardPage();
      return [
        dashboardPage,
        const MenuPage(),
        const UserProfilePage(),
        const QuranReaderPage(),
      ];
    }
    
    // Get roles from Firestore - this is the single source of truth
    final roles = user.roles;
    final isAdmin = roles.contains(UserType.admin);
    print('MainNavigationPage: User roles from Firestore: ${roles.map((r) => r.toString()).join(', ')}');
    print('MainNavigationPage: User primary role (userType): ${user.userType}');
    print('MainNavigationPage: Is Admin: $isAdmin');
    
    // Determine effective dashboard STRICTLY from roles (highest priority)
    // Admins can access any dashboard if they have the role in their roles array
    UserType effectiveType;
    if (roles.contains(UserType.masterTrainer)) {
      effectiveType = UserType.masterTrainer;
    } else if (roles.contains(UserType.trainer)) {
      effectiveType = UserType.trainer;
    } else {
      effectiveType = UserType.student;
    }
    
    print('MainNavigationPage: Effective dashboard type: $effectiveType');

    // Route to dashboard based on effective type
    // Admins can access all dashboards based on their selected role
    if (effectiveType == UserType.masterTrainer) {
      dashboardPage = const MasterTrainerDashboardPage();
    } else if (effectiveType == UserType.trainer) {
      dashboardPage = const JurulatihDashboardPage();
    } else {
      dashboardPage = const DashboardPage(); // Student/default
    }

    return [
      dashboardPage,
      const MenuPage(),
      const UserProfilePage(),
      const QuranReaderPage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<UserCubit, UserState>(
      listener: (context, state) {
        // Redirect to login page when user is logged out
        if (state.status == UserStatus.initial && state.currentUser == null) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
        // Log role information for debugging
        if (mounted &&
            state.currentUser != null &&
            state.currentUser!.roles.isNotEmpty) {
          final user = state.currentUser!;
          final roles = user.roles;
          
          // Strict enforcement: If user tries to access trainer dashboard but doesn't have trainer role
          final hasTrainerAccess = roles.contains(UserType.trainer) || roles.contains(UserType.masterTrainer);
          final hasMasterAccess = roles.contains(UserType.masterTrainer);
          
          // This will be checked in _getPages, but we log it here for debugging
          print('MainNavigationPage: Has trainer access: $hasTrainerAccess, Has master access: $hasMasterAccess');
        }
      },
      child: BlocBuilder<UserCubit, UserState>(
        builder: (context, userState) {
          final user = userState.currentUser;
          final pages = _getPages(user);
          
          return Scaffold(
            body: IndexedStack(
              index: _currentIndex,
              children: pages,
            ),
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                type: BottomNavigationBarType.fixed,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                selectedItemColor: AppColors.primary,
                unselectedItemColor: Colors.grey[600],
                selectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home_outlined),
                    activeIcon: Icon(Icons.home),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.menu_outlined),
                    activeIcon: Icon(Icons.menu),
                    label: 'Menu',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person_outline),
                    activeIcon: Icon(Icons.person),
                    label: 'Profile',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.menu_book_outlined),
                    activeIcon: Icon(Icons.menu_book),
                    label: 'Quran',
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  String _getRoleName(UserType role) {
    switch (role) {
      case UserType.student:
        return 'Pelajar';
      case UserType.trainer:
        return 'Jurulatih';
      case UserType.masterTrainer:
        return 'Master Trainer';
      case UserType.admin:
        return 'Admin';
    }
  }
}

