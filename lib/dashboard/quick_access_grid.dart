import 'package:flutter/material.dart';
import '../theme_constants.dart';

class QuickAccessGrid extends StatelessWidget {
  const QuickAccessGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final List<_QuickAccessItem> quickAccessItems = [
      _QuickAccessItem(
        icon: Icons.menu_book,
        label: 'Al-Quran',
        onTap: () {
          Navigator.of(context).pushNamed('/quran');
        },
      ),
      _QuickAccessItem(
        icon: Icons.book,
        label: 'Mushaf',
        onTap: () {
          Navigator.of(context).pushNamed('/mushaf');
        },
      ),
      _QuickAccessItem(
        icon: Icons.explore,
        label: 'Qiblah',
        onTap: () {
          Navigator.of(context).pushNamed('/qiblah');
        },
      ),
      _QuickAccessItem(
        icon: Icons.favorite,
        label: 'Doa',
        onTap: () {
          Navigator.of(context).pushNamed('/duas');
        },
      ),
      _QuickAccessItem(
        icon: Icons.school,
        label: 'Kelas',
        onTap: () {
          Navigator.of(context).pushNamed('/classes');
        },
      ),
      _QuickAccessItem(
        icon: Icons.book,
        label: 'Hadis',
        onTap: () {
          Navigator.of(context).pushNamed('/hadiths');
        },
      ),
      _QuickAccessItem(
        icon: Icons.check_circle,
        label: 'Rukun Solat',
        onTap: () {
          Navigator.of(context).pushNamed('/rukun_solat');
        },
      ),
      _QuickAccessItem(
        icon: Icons.video_library,
        label: 'Videos',
        onTap: () {
          Navigator.of(context).pushNamed('/videos');
        },
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            color: Theme.of(context).cardColor,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 12, top: 4),
                    child: Text(
                      'Akses Pantas',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  SizedBox(

                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: quickAccessItems.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: _QuickAccessButton(item: quickAccessItems[index]),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAccessItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAccessItem({required this.icon, required this.label, required this.onTap});
}

class _QuickAccessButton extends StatelessWidget {
  final _QuickAccessItem item;
  const _QuickAccessButton({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: item.onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.primary.withOpacity(0.13)
                  : AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(14),
            child: Icon(item.icon, color: AppColors.primary, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            item.label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
} 