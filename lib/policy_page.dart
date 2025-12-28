import 'package:flutter/material.dart';

class PolicyPage extends StatelessWidget {
  const PolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dasar Privasi & Terma'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dasar Privasi',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              'Kami menghormati privasi anda dan komited untuk melindungi maklumat peribadi anda. Aplikasi Daily Quran mengumpul dan menggunakan maklumat berikut:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            const Text(
              '1. Maklumat Peribadi',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Nama, alamat emel, nombor telefon\n'
              '• Tarikh lahir dan alamat\n'
              '• Gambar profil (jika dimuat naik)',
            ),
            const SizedBox(height: 16),
            const Text(
              '2. Data Lokasi',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Lokasi GPS digunakan untuk memberikan waktu solat yang tepat\n'
              '• Arah Qiblah berdasarkan lokasi anda\n'
              '• Data lokasi disimpan secara tempatan dan tidak dikongsi dengan pihak ketiga',
            ),
            const SizedBox(height: 16),
            const Text(
              '3. Data Aplikasi',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Kemajuan pembelajaran Al-Quran\n'
              '• Kelas yang didaftar\n'
              '• Preferensi pengguna',
            ),
            const SizedBox(height: 32),
            Text(
              'Terma Penggunaan',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            const Text(
              '1. Penggunaan Aplikasi',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Dengan menggunakan aplikasi Daily Quran, anda bersetuju untuk:\n'
              '• Menggunakan aplikasi untuk tujuan pendidikan dan keagamaan sahaja\n'
              '• Tidak menyalahgunakan kandungan atau ciri aplikasi\n'
              '• Menghormati hak cipta dan kandungan yang disediakan',
            ),
            const SizedBox(height: 16),
            const Text(
              '2. Akaun Pengguna',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Anda bertanggungjawab untuk menjaga keselamatan akaun anda\n'
              '• Sila beritahu kami dengan segera jika terdapat aktiviti yang mencurigakan\n'
              '• Kami berhak menggantung atau menutup akaun yang melanggar terma',
            ),
            const SizedBox(height: 16),
            const Text(
              '3. Kandungan',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Semua kandungan Al-Quran dan terjemahan adalah berdasarkan sumber yang diiktiraf\n'
              '• Waktu solat menggunakan data dari JAKIM (Jabatan Kemajuan Islam Malaysia)\n'
              '• Kami tidak bertanggungjawab atas sebarang kesilapan dalam terjemahan atau waktu solat',
            ),
            const SizedBox(height: 32),
            Text(
              'Hubungi Kami',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Jika anda mempunyai sebarang soalan mengenai dasar privasi atau terma penggunaan, sila hubungi kami melalui emel atau melalui aplikasi.',
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

