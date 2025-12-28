import 'package:flutter/material.dart';
import '../theme_constants.dart';

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<MenuSection> menuSections = [
      MenuSection(
        title: 'Al-Quran & Bacaan',
        items: [
          MenuItem(
            icon: Icons.menu_book,
            label: 'Al-Quran',
            description: 'Baca Al-Quran dengan terjemahan',
            onTap: () => Navigator.of(context).pushNamed('/quran'),
          ),
          MenuItem(
            icon: Icons.book,
            label: 'Mushaf',
            description: 'Mushaf digital untuk bacaan',
            onTap: () => Navigator.of(context).pushNamed('/mushaf'),
          ),
          MenuItem(
            icon: Icons.picture_as_pdf,
            label: 'Mushaf PDF',
            description: 'Pilih mushaf dengan berbagai riwayah',
            onTap: () => Navigator.of(context).pushNamed('/mushaf_pdf_selection'),
          ),
          MenuItem(
            icon: Icons.search,
            label: 'Cari Ayat',
            description: 'Cari ayat dalam Al-Quran',
            onTap: () => Navigator.of(context).pushNamed('/quran_search'),
          ),
        ],
      ),
      MenuSection(
        title: 'Ibadah & Doa',
        items: [
          MenuItem(
            icon: Icons.favorite,
            label: 'Doa Harian',
            description: 'Koleksi doa-doa harian',
            onTap: () => Navigator.of(context).pushNamed('/duas'),
          ),
          MenuItem(
            icon: Icons.check_circle,
            label: 'Rukun Solat',
            description: 'Panduan rukun solat',
            onTap: () => Navigator.of(context).pushNamed('/rukun_solat'),
          ),
        ],
      ),
      MenuSection(
        title: 'Pembelajaran',
        items: [
          MenuItem(
            icon: Icons.school,
            label: 'Kelas Online',
            description: 'Ikuti kelas pembelajaran',
            onTap: () => Navigator.of(context).pushNamed('/classes'),
          ),
          MenuItem(
            icon: Icons.book,
            label: 'Hadis',
            description: 'Koleksi hadis-hadis sahih',
            onTap: () => Navigator.of(context).pushNamed('/hadiths'),
          ),
          MenuItem(
            icon: Icons.video_library,
            label: 'Videos',
            description: 'Tonton video pembelajaran',
            onTap: () => Navigator.of(context).pushNamed('/videos'),
          ),
        ],
      ),
      MenuSection(
        title: 'Alat & Utiliti',
        items: [
          // MenuItem(
          //   icon: Icons.volume_up,
          //   label: 'Penguji Azan',
          //   description: 'Uji kualiti azan',
          //   onTap: () => Navigator.of(context).pushNamed('/adhan_tester'),
          // ),
          MenuItem(
            icon: Icons.alarm,
            label: 'Tetapan Azan',
            description: 'Konfigurasi waktu solat',
            onTap: () => Navigator.of(context).pushNamed('/prayer_alarm_settings'),
          ),
          MenuItem(
            icon: Icons.money,
            label: 'Premium',
            description: 'Upgrade ke versi premium',
            onTap: () => Navigator.of(context).pushNamed('/premium'),
          ),
        ],
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: menuSections.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: _MenuSectionWidget(section: menuSections[index]),
          );
        },
      ),
    );
  }
}

class MenuSection {
  final String title;
  final List<MenuItem> items;

  const MenuSection({
    required this.title,
    required this.items,
  });
}

class MenuItem {
  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;

  const MenuItem({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
  });
}

class _MenuSectionWidget extends StatelessWidget {
  final MenuSection section;

  const _MenuSectionWidget({required this.section});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            section.title,
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
            children: section.items.map((item) => _MenuItemWidget(item: item)).toList(),
          ),
        ),
      ],
    );
  }
}

class _MenuItemWidget extends StatelessWidget {
  final MenuItem item;

  const _MenuItemWidget({required this.item});

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
          item.icon,
          color: AppColors.primary,
          size: 24,
        ),
      ),
      title: Text(
        item.label,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        item.description,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Colors.grey[600],
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey,
      ),
      onTap: item.onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

