import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'deep_link_handler.dart';

class DeepLinkTestPage extends StatefulWidget {
  const DeepLinkTestPage({super.key});

  @override
  State<DeepLinkTestPage> createState() => _DeepLinkTestPageState();
}

class _DeepLinkTestPageState extends State<DeepLinkTestPage> {
  String? fcmToken;
  bool isLoadingToken = true;

  @override
  void initState() {
    super.initState();
    _getFCMToken();
  }

  Future<void> _getFCMToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      setState(() {
        fcmToken = token;
        isLoadingToken = false;
      });
    } catch (e) {
      setState(() {
        fcmToken = 'Error getting token: $e';
        isLoadingToken = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ujian Pautan Dalam'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Uji Pautan Dalam',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ketik mana-mana butang di bawah untuk navigasi ke halaman tertentu dalam aplikasi:',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            
            // Direct Navigation Buttons
            _buildNavigationButton(
              context,
              'Halaman Premium',
              '/premium',
              Icons.star,
              Colors.amber,
            ),
            _buildNavigationButton(
              context,
              'Profil Pengguna',
              '/profile',
              Icons.person,
              Colors.blue,
            ),
            _buildNavigationButton(
              context,
              'Kelas',
              '/classes',
              Icons.school,
              Colors.green,
            ),
            _buildNavigationButton(
              context,
              'Duas',
              '/duas',
              Icons.waving_hand_outlined,
              Colors.purple,
            ),
            _buildNavigationButton(
              context,
              'Hadiths',
              '/hadiths',
              Icons.menu_book,
              Colors.orange,
            ),
            _buildNavigationButton(
              context,
              'Qiblah',
              '/qiblah',
              Icons.explore,
              Colors.red,
            ),
            _buildNavigationButton(
              context,
              'Hifdh Checker',
              '/hifdh_checker',
              Icons.psychology,
              Colors.teal,
            ),
            _buildNavigationButton(
              context,
              'Prayer Steps',
              '/rukun_solat',
              Icons.directions_walk,
              Colors.indigo,
            ),
            _buildNavigationButton(
              context,
              'Dashboard',
              '/dashboard',
              Icons.dashboard,
              Colors.grey,
            ),
            _buildNavigationButton(
              context,
              'Admin Panel',
              '/admin',
              Icons.admin_panel_settings,
              Colors.deepOrange,
            ),
            
            const SizedBox(height: 32),
            
            // Deep Link URLs Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Deep Link URLs:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'These URLs can be used from external apps, messages, or websites:',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    _buildShareableLink('Premium: ${DeepLinkRoutes.premium}'),
                    _buildShareableLink('Profile: ${DeepLinkRoutes.profile}'),
                    _buildShareableLink('Classes: ${DeepLinkRoutes.classes}'),
                    _buildShareableLink('Duas: ${DeepLinkRoutes.duas}'),
                    _buildShareableLink('Hadiths: ${DeepLinkRoutes.hadiths}'),
                    _buildShareableLink('Qiblah: ${DeepLinkRoutes.qiblah}'),
                    _buildShareableLink('Hifdh: ${DeepLinkRoutes.hifdh}'),
                    _buildShareableLink('Prayer Steps: ${DeepLinkRoutes.rukun}'),
                    _buildShareableLink('Dashboard: ${DeepLinkRoutes.dashboard}'),
                    _buildShareableLink('Admin: ${DeepLinkRoutes.admin}'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // FCM Token Section for Testing
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'FCM Token (for Firebase Console testing):',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Copy this token to test push notifications in Firebase Console:',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    _buildFCMTokenDisplay(),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Instructions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'How to Use:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Tap buttons above to navigate within the app\n'
                      '• Copy URLs below to share with others\n'
                      '• Use these URLs in messages, emails, or websites\n'
                      '• External apps can open your app using these URLs',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButton(
    BuildContext context,
    String title,
    String route,
    IconData icon,
    Color color,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        subtitle: Text('Route: $route'),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          // Navigate directly using Navigator
          Navigator.of(context).pushNamed(route);
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Navigating to: $title'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 1),
            ),
          );
        },
      ),
    );
  }

  Widget _buildShareableLink(String link) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SelectableText(
        link,
        style: const TextStyle(
          fontSize: 12,
          fontFamily: 'monospace',
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildFCMTokenDisplay() {
    return SelectableText(
      isLoadingToken ? 'Loading FCM Token...' : fcmToken ?? 'No FCM Token available',
      style: const TextStyle(
        fontSize: 12,
        fontFamily: 'monospace',
        color: Colors.purple,
      ),
    );
  }
} 