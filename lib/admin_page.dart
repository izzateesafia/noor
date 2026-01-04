import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'admin/manage_ads_page.dart';
import 'admin/manage_duas_page.dart';
import 'admin/manage_hadiths_page.dart';
import 'admin/manage_classes_page.dart';
import 'admin/manage_users_page.dart';
import 'admin/manage_live_streams_page.dart';
import 'admin/manage_news_page.dart';
import 'admin/manage_videos_page.dart';
import 'admin/notification_editor_page.dart';
import 'admin/widgets/admin_stats_card.dart';
import 'admin/widgets/admin_quick_actions.dart';
import 'admin/widgets/admin_category_grid.dart';
import 'deep_link_test_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'repository/app_settings_repository.dart';
import 'repository/admin_stats_repository.dart';
import 'cubit/admin_stats_cubit.dart';
import 'cubit/admin_stats_states.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  void _showGoLiveSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 18),
          const Text('Siaran Langsung sebagai Ustaz', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 18),
          ListTile(
            leading: Icon(
              Icons.ondemand_video,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('YouTube Live'),
            subtitle: const Text('Buka YouTube Studio untuk memulakan siaran langsung'),
            onTap: () async {
              Navigator.of(context).pop();
              final url = Uri.parse('https://studio.youtube.com/channel/UC/live_streaming');
              if (await canLaunchUrl(url)) {
                launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
          ),
          ListTile(
            leading: Icon(
              Icons.music_note,
              color: Theme.of(context).iconTheme.color,
            ),
            title: const Text('TikTok Live'),
            subtitle: const Text('Open TikTok to start a live stream'),
            onTap: () async {
              Navigator.of(context).pop();
              final url = Uri.parse('https://www.tiktok.com/live/');
              if (await canLaunchUrl(url)) {
                launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
          ),
          const SizedBox(height: 18),
        ],
      ),
    );
  }

  void _showWelcomeMessageDialog(BuildContext context) async {
    final appSettingsRepo = AppSettingsRepository();
    String? currentMessage;
    String? errorMessage;

    // Load current message
    try {
      currentMessage = await appSettingsRepo.getWelcomeMessage();
    } catch (e) {
      errorMessage = 'Failed to load current message: $e';
    }

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => _WelcomeMessageDialog(
        initialMessage: currentMessage ?? '',
        errorMessage: errorMessage,
      ),
    );
  }

  void _showScheduleLiveDialog(BuildContext context) async {
    final TextEditingController messageController = TextEditingController();
    DateTime? scheduledTime;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Jadual Notifikasi Siaran Langsung'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                labelText: 'Mesej Notifikasi',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.calendar_today),
              label: Text(scheduledTime == null
                  ? 'Pilih Tarikh & Masa'
                  : '${scheduledTime?.toLocal()}'),
              onPressed: () async {
                final now = DateTime.now();
                final pickedDate = await showDatePicker(
                  context: ctx,
                  initialDate: now,
                  firstDate: now,
                  lastDate: now.add(const Duration(days: 365)),
                );
                if (pickedDate != null) {
                  final pickedTime = await showTimePicker(
                    context: ctx,
                    initialTime: TimeOfDay.now(),
                  );
                  if (pickedTime != null) {
                    scheduledTime = DateTime(
                      pickedDate.year,
                      pickedDate.month,
                      pickedDate.day,
                      pickedTime.hour,
                      pickedTime.minute,
                    );
                  }
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (messageController.text.trim().isEmpty || scheduledTime == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sila masukkan mesej dan pilih tarikh/masa.')),
                );
                return;
              }
              await FirebaseFirestore.instance.collection('scheduled_notifications').add({
                'message': messageController.text.trim(),
                'scheduledTime': scheduledTime!.toUtc().toIso8601String(),
                'createdAt': DateTime.now().toUtc().toIso8601String(),
                'sent': false,
              });
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifikasi telah dijadualkan untuk semua pengguna!')),
              );
            },
            child: const Text('Jadual'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminStatsCubit(AdminStatsRepository())..fetchStats(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Panel Admin'),
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
          elevation: 0,
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Page Title
                Text(
                  'Dashboard Admin',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Urus kandungan dan tetapan aplikasi',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.color
                            ?.withOpacity(0.7),
                      ),
                ),
                const SizedBox(height: 32),

                // Statistics Section
                BlocBuilder<AdminStatsCubit, AdminStatsState>(
                  builder: (context, state) {
                    if (state.isLoading) {
                      return const SizedBox(
                        height: 200,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (state.error != null) {
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Error loading statistics: ${state.error}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      );
                    }

                    final stats = state.stats;
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
                        return GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.95,
                          children: [
                            AdminStatsCard(
                              icon: Icons.people,
                              title: 'Pengguna',
                              value: stats['totalUsers'] ?? 0,
                              color: Colors.blue,
                            ),
                            AdminStatsCard(
                              icon: Icons.article,
                              title: 'Kandungan',
                              value: (stats['totalHadiths'] ?? 0) +
                                  (stats['totalDuas'] ?? 0) +
                                  (stats['totalNews'] ?? 0) +
                                  (stats['totalVideos'] ?? 0),
                              color: Colors.green,
                            ),
                            AdminStatsCard(
                              icon: Icons.class_,
                              title: 'Kelas',
                              value: stats['totalClasses'] ?? 0,
                              color: Colors.orange,
                            ),
                            AdminStatsCard(
                              icon: Icons.live_tv,
                              title: 'Siaran Aktif',
                              value: stats['activeLiveStreams'] ?? 0,
                              color: Colors.red,
                              subtitle: '${stats['totalLiveStreams'] ?? 0} jumlah',
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),

                const SizedBox(height: 40),

                // Quick Actions Section
                AdminQuickActions(
                  onGoLive: () => _showGoLiveSheet(context),
                  onScheduleLive: () => _showScheduleLiveDialog(context),
                  onSendNotification: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const NotificationEditorPage(),
                      ),
                    );
                  },
                  onManageWelcomeMessage: () => _showWelcomeMessageDialog(context),
                ),

                const SizedBox(height: 40),

                // Management Categories
                BlocBuilder<AdminStatsCubit, AdminStatsState>(
                  builder: (context, state) {
                    final stats = state.stats;
                    return AdminCategoryGrid(
                      categories: [
                        AdminCategory(
                          title: 'Pengurusan Kandungan',
                          color: Colors.blue,
                          items: [
                            AdminCategoryItem(
                              icon: Icons.book,
                              label: 'Urus Hadis',
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const ManageHadithsPage(),
                                  ),
                                );
                              },
                              badgeCount: stats['totalHadiths'],
                              color: Colors.blue,
                            ),
                            AdminCategoryItem(
                              icon: Icons.menu_book,
                              label: 'Urus Doa',
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const ManageDuasPage(),
                                  ),
                                );
                              },
                              badgeCount: stats['totalDuas'],
                              color: Colors.blue,
                            ),
                            AdminCategoryItem(
                              icon: Icons.article,
                              label: 'Urus Berita',
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const ManageNewsPage(),
                                  ),
                                );
                              },
                              badgeCount: stats['totalNews'],
                              color: Colors.blue,
                            ),
                            AdminCategoryItem(
                              icon: Icons.video_library,
                              label: 'Urus Video',
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const ManageVideosPage(),
                                  ),
                                );
                              },
                              badgeCount: stats['totalVideos'],
                              color: Colors.blue,
                            ),
                          ],
                        ),
                        AdminCategory(
                          title: 'Sumber Pembelajaran',
                          color: Colors.green,
                          items: [
                            AdminCategoryItem(
                              icon: Icons.class_,
                              label: 'Urus Kelas',
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const ManageClassesPage(),
                                  ),
                                );
                              },
                              badgeCount: stats['totalClasses'],
                              color: Colors.green,
                            ),
                            AdminCategoryItem(
                              icon: Icons.live_tv,
                              label: 'Urus Siaran Langsung',
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const ManageLiveStreamsPage(),
                                  ),
                                );
                              },
                              badgeCount: stats['activeLiveStreams'],
                              color: Colors.green,
                            ),
                          ],
                        ),
                        AdminCategory(
                          title: 'Pemasaran',
                          color: Colors.purple,
                          items: [
                            AdminCategoryItem(
                              icon: Icons.campaign,
                              label: 'Urus Iklan',
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const ManageAdsPage(),
                                  ),
                                );
                              },
                              badgeCount: stats['totalAds'],
                              color: Colors.purple,
                            ),
                          ],
                        ),
                        AdminCategory(
                          title: 'Sistem',
                          color: Colors.grey,
                          items: [
                            AdminCategoryItem(
                              icon: Icons.people,
                              label: 'Urus Pengguna',
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const ManageUsersPage(),
                                  ),
                                );
                              },
                              badgeCount: stats['totalUsers'],
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ],
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
  }
}

class _WelcomeMessageDialog extends StatefulWidget {
  final String initialMessage;
  final String? errorMessage;

  const _WelcomeMessageDialog({
    required this.initialMessage,
    this.errorMessage,
  });

  @override
  State<_WelcomeMessageDialog> createState() => _WelcomeMessageDialogState();
}

class _WelcomeMessageDialogState extends State<_WelcomeMessageDialog> {
  late TextEditingController _messageController;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController(text: widget.initialMessage);
    _errorMessage = widget.errorMessage;
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _saveMessage() async {
    if (_messageController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sila masukkan mesej selamat datang'),
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final appSettingsRepo = AppSettingsRepository();
      await appSettingsRepo.updateWelcomeMessage(
        _messageController.text.trim(),
      );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mesej selamat datang berjaya dikemas kini!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Gagal mengemas kini mesej: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Urus Mesej Selamat Datang'),
      content: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    labelText: 'Mesej Selamat Datang',
                    hintText: 'Masukkan mesej selamat datang untuk dipaparkan',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  maxLength: 200,
                ),
                const SizedBox(height: 8),
                Text(
                  'Mesej ini akan dipaparkan di dashboard untuk semua pengguna.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                ),
              ],
            ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveMessage,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Simpan'),
        ),
      ],
    );
  }
}
