import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/admin_notification_service.dart';
import '../theme_constants.dart';

class NotificationEditorPage extends StatefulWidget {
  const NotificationEditorPage({super.key});

  @override
  State<NotificationEditorPage> createState() => _NotificationEditorPageState();
}

class _NotificationEditorPageState extends State<NotificationEditorPage> {
  final AdminNotificationService _notificationService = AdminNotificationService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  
  bool _isScheduled = false;
  DateTime? _scheduledTime;
  bool _isLoading = false;
  bool _showHistory = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    
    // Pick date
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    
    if (pickedDate == null) return;
    
    // Pick time
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    
    if (pickedTime == null) return;
    
    setState(() {
      _scheduledTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _sendNotification() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a notification title'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_bodyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a notification message'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_isScheduled && _scheduledTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a date and time for scheduled notification'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_isScheduled && _scheduledTime!.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Scheduled time must be in the future'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isScheduled) {
        await _notificationService.scheduleNotification(
          title: _titleController.text.trim(),
          body: _bodyController.text.trim(),
          scheduledTime: _scheduledTime!,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Notification scheduled for ${_scheduledTime!.toLocal().toString().substring(0, 16)}',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        await _notificationService.sendNotificationToAllUsers(
          title: _titleController.text.trim(),
          body: _bodyController.text.trim(),
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notification sent to all users!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      // Clear form
      _titleController.clear();
      _bodyController.clear();
      setState(() {
        _scheduledTime = null;
        _isScheduled = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Editor'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_showHistory ? Icons.edit : Icons.history),
            onPressed: () {
              setState(() {
                _showHistory = !_showHistory;
              });
            },
            tooltip: _showHistory ? 'Show Editor' : 'Show History',
          ),
        ],
      ),
      body: _showHistory ? _buildHistoryView() : _buildEditorView(),
    );
  }

  Widget _buildEditorView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title field
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Notification Title',
              hintText: 'Enter notification title',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.title),
            ),
            maxLength: 100,
          ),
          const SizedBox(height: 16),
          
          // Body field
          TextField(
            controller: _bodyController,
            decoration: const InputDecoration(
              labelText: 'Notification Message',
              hintText: 'Enter notification message',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.message),
              alignLabelWithHint: true,
            ),
            maxLines: 5,
            maxLength: 500,
          ),
          const SizedBox(height: 16),
          
          // Schedule toggle
          Card(
            child: SwitchListTile(
              title: const Text('Schedule Notification'),
              subtitle: const Text('Send notification at a specific time'),
              value: _isScheduled,
              onChanged: (value) {
                setState(() {
                  _isScheduled = value;
                  if (!value) {
                    _scheduledTime = null;
                  }
                });
              },
              secondary: const Icon(Icons.schedule),
            ),
          ),
          
          // Date/Time picker (shown when scheduled)
          if (_isScheduled) ...[
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Scheduled Date & Time'),
                subtitle: Text(
                  _scheduledTime == null
                      ? 'Not selected'
                      : _scheduledTime!.toLocal().toString().substring(0, 16),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _pickDateTime,
              ),
            ),
          ],
          
          const SizedBox(height: 24),
          
          // Send button
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _sendNotification,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(_isScheduled ? Icons.schedule : Icons.send),
            label: Text(
              _isLoading
                  ? 'Sending...'
                  : _isScheduled
                      ? 'Schedule Notification'
                      : 'Send Notification Now',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Info card
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Notification Info',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isScheduled
                        ? 'This notification will be sent to all users at the scheduled time. Make sure Cloud Functions are set up to process scheduled notifications.'
                        : 'This notification will be sent immediately to all users who have the app installed.',
                    style: TextStyle(color: Colors.blue.shade900),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryView() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _notificationService.getNotificationHistory(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text('Error loading history: ${snapshot.error}'),
              ],
            ),
          );
        }

        final notifications = snapshot.data ?? [];

        if (notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_none, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No notifications sent yet',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notification = notifications[index];
            final createdAt = notification['createdAt'] as Timestamp?;
            final sentAt = notification['sentAt'] as Timestamp?;
            final isSent = notification['sent'] as bool? ?? false;
            final isScheduled = notification['type'] == 'scheduled';
            final scheduledTime = notification['scheduledTime'] as String?;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: Icon(
                  isSent ? Icons.check_circle : Icons.pending,
                  color: isSent ? Colors.green : Colors.orange,
                ),
                title: Text(
                  notification['title'] ?? 'No title',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(notification['body'] ?? 'No message'),
                    const SizedBox(height: 8),
                    if (isScheduled && scheduledTime != null)
                      Text(
                        'Scheduled: ${DateTime.parse(scheduledTime).toLocal().toString().substring(0, 16)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    if (createdAt != null)
                      Text(
                        'Created: ${createdAt.toDate().toLocal().toString().substring(0, 16)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    if (sentAt != null)
                      Text(
                        'Sent: ${sentAt.toDate().toLocal().toString().substring(0, 16)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[700],
                        ),
                      ),
                  ],
                ),
                trailing: !isSent
                    ? IconButton(
                        icon: const Icon(Icons.delete),
                        color: Colors.red,
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Notification'),
                              content: const Text(
                                'Are you sure you want to delete this notification?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true && mounted) {
                            try {
                              await _notificationService.deleteNotification(
                                notification['id'] as String,
                              );
                              setState(() {}); // Refresh list
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Notification deleted'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: ${e.toString()}'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                      )
                    : null,
              ),
            );
          },
        );
      },
    );
  }
}

