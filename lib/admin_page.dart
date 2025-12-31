import 'package:flutter/material.dart';
import 'admin/manage_ads_page.dart';
import 'admin/manage_duas_page.dart';
import 'admin/manage_hadiths_page.dart';
import 'admin/manage_classes_page.dart';
import 'admin/manage_users_page.dart';
import 'admin/manage_live_streams_page.dart';
import 'admin/manage_news_page.dart';
import 'admin/manage_videos_page.dart';
import 'admin/notification_editor_page.dart';
import 'deep_link_test_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'repository/app_settings_repository.dart';

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
    final TextEditingController messageController = TextEditingController();
    bool isLoading = true;
    String? errorMessage;

    // Load current message
    try {
      final currentMessage = await appSettingsRepo.getWelcomeMessage();
      messageController.text = currentMessage;
    } catch (e) {
      errorMessage = 'Failed to load current message: $e';
    } finally {
      isLoading = false;
    }

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Manage Welcome Message'),
          content: isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          errorMessage!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    TextField(
                      controller: messageController,
                      decoration: const InputDecoration(
                        labelText: 'Welcome Message',
                        hintText: 'Enter the welcome message to display',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      maxLength: 200,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This message will be displayed on the dashboard for all users.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                    ),
                  ],
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (messageController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a welcome message'),
                          ),
                        );
                        return;
                      }

                      setState(() {
                        isLoading = true;
                        errorMessage = null;
                      });

                      try {
                        await appSettingsRepo.updateWelcomeMessage(
                          messageController.text.trim(),
                        );
                        if (context.mounted) {
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Welcome message updated successfully!'),
                              backgroundColor: Colors.green, // Success color - keep as is
                            ),
                          );
                        }
                      } catch (e) {
                        setState(() {
                          isLoading = false;
                          errorMessage = 'Failed to update message: $e';
                        });
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showScheduleLiveDialog(BuildContext context) async {
    final TextEditingController messageController = TextEditingController();
    DateTime? scheduledTime;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Schedule Live Notification'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                labelText: 'Notification Message',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.calendar_today),
              label: Text(scheduledTime == null
                  ? 'Pick Date & Time'
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
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (messageController.text.trim().isEmpty || scheduledTime == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a message and pick a date/time.')),
                );
                return;
              }
              await FirebaseFirestore.instance.collection('scheduled_notifications').add({
                'message': messageController.text.trim(),
                'scheduledTime': scheduledTime!.toUtc().toIso8601String(),
                'createdAt': DateTime.now().toUtc().toIso8601String(),
              });
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notification scheduled for all users!')),
              );
            },
            child: const Text('Schedule'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Go Live button
                Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: ElevatedButton.icon(
                    onPressed: () => _showGoLiveSheet(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    icon: const Icon(Icons.live_tv),
                    label: const Text('Go Live'),
                  ),
                ),
                // Schedule Live button
                Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: ElevatedButton.icon(
                    onPressed: () => _showScheduleLiveDialog(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    icon: const Icon(Icons.alarm),
                    label: const Text('Schedule Live'),
                  ),
                ),
                Text(
                  'What would you manage today?',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                _AdminActionButton(
                  icon: Icons.campaign,
                  label: 'Manage Advertisement',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const ManageAdsPage()),
                    );
                  },
                ),
                const SizedBox(height: 18),
                _AdminActionButton(
                  icon: Icons.menu_book,
                  label: 'Manage Dua',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const ManageDuasPage()),
                    );
                  },
                ),
                const SizedBox(height: 18),
                _AdminActionButton(
                  icon: Icons.book,
                  label: 'Manage Hadith',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const ManageHadithsPage()),
                    );
                  },
                ),
                const SizedBox(height: 18),
                _AdminActionButton(
                  icon: Icons.class_,
                  label: 'Manage Class',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const ManageClassesPage()),
                    );
                  },
                ),
                const SizedBox(height: 18),
                _AdminActionButton(
                  icon: Icons.people,
                  label: 'Manage Users',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const ManageUsersPage()),
                    );
                  },
                ),
                const SizedBox(height: 18),
                _AdminActionButton(
                  icon: Icons.live_tv,
                  label: 'Manage Live Streams',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const ManageLiveStreamsPage()),
                    );
                  },
                ),
                const SizedBox(height: 18),
                _AdminActionButton(
                  icon: Icons.article,
                  label: 'Manage News (Terkini)',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const ManageNewsPage()),
                    );
                  },
                ),
                const SizedBox(height: 18),
                _AdminActionButton(
                  icon: Icons.video_library,
                  label: 'Manage Videos',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const ManageVideosPage()),
                    );
                  },
                ),
                const SizedBox(height: 18),
                _AdminActionButton(
                  icon: Icons.message,
                  label: 'Manage Welcome Message',
                  onTap: () => _showWelcomeMessageDialog(context),
                ),
                const SizedBox(height: 18),
                _AdminActionButton(
                  icon: Icons.notifications_active,
                  label: 'Send Notifications',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const NotificationEditorPage(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 18),
                _AdminActionButton(
                  icon: Icons.link,
                  label: 'Deep Link Test',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const DeepLinkTestPage()),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _AdminActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    final cardColor = Theme.of(context).cardColor;
    final borderColor = primary;
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        backgroundColor: cardColor,
        foregroundColor: primary,
        side: BorderSide(color: borderColor, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
        textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      icon: Icon(icon, size: 22, color: primary),
      label: Text(label, style: TextStyle(color: primary)),
      onPressed: onTap,
    );
  }
} 