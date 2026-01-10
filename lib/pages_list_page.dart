import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'theme_constants.dart';
import 'cubit/user_cubit.dart';
import 'cubit/user_states.dart';
import 'models/user_model.dart';
import 'dashboard/dashboard_page.dart';
import 'dashboard/jurulatih_dashboard_page.dart';
import 'dashboard/master_trainer_dashboard_page.dart';

class PagesListPage extends StatelessWidget {
  const PagesListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<PageItem> pages = [
      // Authentication & Onboarding
      PageItem(
        route: '/login',
        title: 'Login Page',
        description: 'User login page',
        icon: Icons.login,
        category: 'Authentication',
      ),
      PageItem(
        route: '/signup',
        title: 'Signup Page',
        description: 'User registration page',
        icon: Icons.person_add,
        category: 'Authentication',
      ),
      PageItem(
        route: '/role',
        title: 'Role Selection',
        description: 'Select user role',
        icon: Icons.assignment_ind,
        category: 'Authentication',
      ),
      PageItem(
        route: '/biodata',
        title: 'Biodata Page',
        description: 'Complete user profile',
        icon: Icons.person,
        category: 'Profile',
      ),
      PageItem(
        route: '/card-info',
        title: 'Card Info',
        description: 'Payment card information',
        icon: Icons.credit_card,
        category: 'Profile',
      ),
      
      // Dashboard Pages
      PageItem(
        route: null,
        title: 'dashboard_page',
        description: 'DashboardPage - Student dashboard',
        icon: Icons.dashboard,
        category: 'Main',
        widget: const DashboardPage(),
      ),
      PageItem(
        route: null,
        title: 'jurulatih_dashboard_page',
        description: 'JurulatihDashboardPage - Trainer dashboard',
        icon: Icons.school,
        category: 'Main',
        widget: const JurulatihDashboardPage(),
      ),
      PageItem(
        route: null,
        title: 'master_trainer_dashboard_page',
        description: 'MasterTrainerDashboardPage - Master trainer dashboard',
        icon: Icons.admin_panel_settings,
        category: 'Main',
        widget: const MasterTrainerDashboardPage(),
      ),
      PageItem(
        route: '/profile',
        title: 'User Profile',
        description: 'User profile page',
        icon: Icons.account_circle,
        category: 'Profile',
      ),
      
      // Quran & Reading
      PageItem(
        route: '/quran',
        title: 'Quran Reader',
        description: 'Read Al-Quran with translation',
        icon: Icons.menu_book,
        category: 'Quran',
      ),
      PageItem(
        route: '/mushaf',
        title: 'Mushaf Reader',
        description: 'Digital mushaf for reading',
        icon: Icons.book,
        category: 'Quran',
      ),
      PageItem(
        route: '/quran_search',
        title: 'Quran Search',
        description: 'Search verses in Al-Quran',
        icon: Icons.search,
        category: 'Quran',
      ),
      
      // Ibadah & Doa
      PageItem(
        route: '/duas',
        title: 'Duas Page',
        description: 'Daily duas collection',
        icon: Icons.favorite,
        category: 'Ibadah',
      ),
      PageItem(
        route: '/hadiths',
        title: 'Hadiths Page',
        description: 'Collection of authentic hadiths',
        icon: Icons.book,
        category: 'Ibadah',
      ),
      PageItem(
        route: '/rukun_solat',
        title: 'Rukun Solat',
        description: 'Prayer pillars guide',
        icon: Icons.check_circle,
        category: 'Ibadah',
      ),
      PageItem(
        route: '/qiblah',
        title: 'Qibla Compass',
        description: 'Find Qibla direction',
        icon: Icons.explore,
        category: 'Ibadah',
      ),
      
      // Learning
      PageItem(
        route: '/classes',
        title: 'Classes Page',
        description: 'Online learning classes',
        icon: Icons.school,
        category: 'Learning',
      ),
      PageItem(
        route: '/enroll_class',
        title: 'Class Enrollment',
        description: 'Enroll in a class',
        icon: Icons.add_circle,
        category: 'Learning',
      ),
      PageItem(
        route: '/videos',
        title: 'Videos Page',
        description: 'Watch learning videos',
        icon: Icons.video_library,
        category: 'Learning',
      ),
      
      // Settings & Utilities
      PageItem(
        route: '/prayer_alarm_settings',
        title: 'Prayer Alarm Settings',
        description: 'Configure prayer times',
        icon: Icons.alarm,
        category: 'Settings',
      ),
      PageItem(
        route: '/premium',
        title: 'Premium Page',
        description: 'Upgrade to premium',
        icon: Icons.star,
        category: 'Settings',
      ),
      PageItem(
        route: '/policy',
        title: 'Policy Page',
        description: 'Privacy policy and terms',
        icon: Icons.description,
        category: 'Settings',
      ),
      PageItem(
        route: '/ios_setup_guide',
        title: 'iOS Setup Guide',
        description: 'iOS setup instructions',
        icon: Icons.phone_iphone,
        category: 'Settings',
      ),
      
      // Admin
      PageItem(
        route: '/admin',
        title: 'Admin Page',
        description: 'Admin dashboard',
        icon: Icons.admin_panel_settings,
        category: 'Admin',
        requiresAdmin: true,
      ),
      
      // Testing & Development
      PageItem(
        route: '/deep_link_test',
        title: 'Deep Link Test',
        description: 'Test deep links',
        icon: Icons.link,
        category: 'Testing',
      ),
      PageItem(
        route: '/test_prayer_alarm',
        title: 'Test Prayer Alarm',
        description: 'Test prayer alarm functionality',
        icon: Icons.alarm_on,
        category: 'Testing',
      ),
      PageItem(
        route: '/test_simple_alarm',
        title: 'Test Simple Alarm',
        description: 'Test simple alarm',
        icon: Icons.timer,
        category: 'Testing',
      ),
      PageItem(
        route: '/test_scheduled_alarm',
        title: 'Test Scheduled Alarm',
        description: 'Test scheduled alarm',
        icon: Icons.schedule,
        category: 'Testing',
      ),
    ];

    // Group pages by category
    final Map<String, List<PageItem>> groupedPages = {};
    for (var page in pages) {
      if (!groupedPages.containsKey(page.category)) {
        groupedPages[page.category] = [];
      }
      groupedPages[page.category]!.add(page);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Pages'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: BlocBuilder<UserCubit, UserState>(
        builder: (context, state) {
          final user = state.currentUser;
          final isAdmin = user?.roles.contains(UserType.admin) ?? false;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: groupedPages.length,
            itemBuilder: (context, index) {
              final category = groupedPages.keys.elementAt(index);
              final categoryPages = groupedPages[category]!;

              // Filter out admin pages if user is not admin
              final visiblePages = categoryPages.where((page) {
                if (page.requiresAdmin && !isAdmin) {
                  return false;
                }
                return true;
              }).toList();

              if (visiblePages.isEmpty) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: _PageCategoryWidget(
                  category: category,
                  pages: visiblePages,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class PageItem {
  final String? route;
  final String title;
  final String description;
  final IconData icon;
  final String category;
  final bool requiresAdmin;
  final Widget? widget;

  const PageItem({
    this.route,
    required this.title,
    required this.description,
    required this.icon,
    required this.category,
    this.requiresAdmin = false,
    this.widget,
  });
}

class _PageCategoryWidget extends StatelessWidget {
  final String category;
  final List<PageItem> pages;

  const _PageCategoryWidget({
    required this.category,
    required this.pages,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            category,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
              fontSize: 20,
            ),
          ),
        ),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: pages.map((page) => _PageItemWidget(page: page)).toList(),
          ),
        ),
      ],
    );
  }
}

class _PageItemWidget extends StatelessWidget {
  final PageItem page;

  const _PageItemWidget({required this.page});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(12),
        child: Icon(
          page.icon,
          color: AppColors.primary,
          size: 24,
        ),
      ),
      title: Text(
        page.title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            page.description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            page.route != null ? 'Route: ${page.route}' : 'Widget: ${page.title}.dart',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[500],
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey,
      ),
      onTap: () {
        try {
          if (page.route != null) {
            Navigator.of(context).pushNamed(page.route!);
          } else if (page.widget != null) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => page.widget!),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No navigation method available for this page'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error navigating: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

