import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'services/scheduled_alarm_service.dart';
import 'theme_constants.dart';

class TestScheduledAlarmPage extends StatefulWidget {
  const TestScheduledAlarmPage({super.key});

  @override
  State<TestScheduledAlarmPage> createState() => _TestScheduledAlarmPageState();
}

class _TestScheduledAlarmPageState extends State<TestScheduledAlarmPage> {
  final ScheduledAlarmService _alarmService = ScheduledAlarmService();
  bool _isInitialized = false;
  List<PendingNotificationRequest> _scheduledNotifications = [];

  @override
  void initState() {
    super.initState();
    _initializeAlarm();
  }

  Future<void> _initializeAlarm() async {
    await _alarmService.initialize();
    await _loadScheduledNotifications();
    setState(() {
      _isInitialized = true;
    });
  }

  Future<void> _loadScheduledNotifications() async {
    _scheduledNotifications = await _alarmService.getScheduledNotifications();
  }

  // Future<void> _testAdhan(String prayerName) async {
  //   try {
  //     await _alarmService.testAdhan(prayerName);
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Testing adhan for $prayerName')),
  //     );
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Error testing adhan: $e')),
  //     );
  //   }
  // }

  Future<void> _scheduleTestInNextMinute(String prayerName) async {
    try {
      await _alarmService.scheduleTestInNextMinute(prayerName);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Scheduled test notification for $prayerName in 1 minute'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
      // Refresh the scheduled notifications list
      await _loadScheduledNotifications();
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error scheduling test: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _toggleAlarm() async {
    await _alarmService.setAlarmEnabled(!_alarmService.isAlarmEnabled);
    await _loadScheduledNotifications();
    setState(() {});
  }

  Future<void> _refreshScheduled() async {
    await _loadScheduledNotifications();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Test Scheduled Alarm'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Scheduled Alarm'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _refreshScheduled,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Scheduled Notifications',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Alarm Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Alarm Status',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('Enabled: '),
                        Switch(
                          value: _alarmService.isAlarmEnabled,
                          onChanged: (value) => _toggleAlarm(),
                          activeColor: AppColors.primary,
                        ),
                      ],
                    ),
                    Text('Enabled Prayers: ${_alarmService.enabledPrayers.join(", ")}'),
                    const SizedBox(height: 8),
                    Text(
                      'Scheduled Notifications: ${_scheduledNotifications.length}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Scheduled Notifications List
            if (_scheduledNotifications.isNotEmpty) ...[
              Text(
                'Scheduled Notifications',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 200, // Fixed height instead of Expanded
                child: ListView.builder(
                  itemCount: _scheduledNotifications.length,
                  itemBuilder: (context, index) {
                    final notification = _scheduledNotifications[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.notifications),
                        title: Text(notification.title ?? 'No Title'),
                        subtitle: Text(notification.body ?? 'No Body'),
                        trailing: Text(
                          'ID: ${notification.id}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Test Buttons - Always visible
            Text(
              'Test Adhan (Immediate)',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            // Wrap(
            //   spacing: 8,
            //   runSpacing: 8,
            //   children: [
            //     ElevatedButton(
            //       onPressed: () => _testAdhan('Fajr'),
            //       child: const Text('Test Fajr'),
            //     ),
            //     ElevatedButton(
            //       onPressed: () => _testAdhan('Dhuhr'),
            //       child: const Text('Test Dhuhr'),
            //     ),
            //     ElevatedButton(
            //       onPressed: () => _testAdhan('Asr'),
            //       child: const Text('Test Asr'),
            //     ),
            //     ElevatedButton(
            //       onPressed: () => _testAdhan('Maghrib'),
            //       child: const Text('Test Maghrib'),
            //     ),
            //     ElevatedButton(
            //       onPressed: () => _testAdhan('Isha'),
            //       child: const Text('Test Isha'),
            //     ),
            //   ],
            // ),
            
            const SizedBox(height: 16),
            
            // Schedule Test Buttons - Always visible
            Text(
              'Schedule Test in 1 Minute',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Perfect for testing background notifications!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 8),
            
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () => _scheduleTestInNextMinute('Fajr'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Schedule Fajr Test'),
                ),
                ElevatedButton(
                  onPressed: () => _scheduleTestInNextMinute('Dhuhr'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Schedule Dhuhr Test'),
                ),
                ElevatedButton(
                  onPressed: () => _scheduleTestInNextMinute('Asr'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Schedule Asr Test'),
                ),
                ElevatedButton(
                  onPressed: () => _scheduleTestInNextMinute('Maghrib'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Schedule Maghrib Test'),
                ),
                ElevatedButton(
                  onPressed: () => _scheduleTestInNextMinute('Isha'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Schedule Isha Test'),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Instructions
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How to Test Background Notifications',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '1. Tap any "Schedule [Prayer] Test" button (green)\n'
                      '2. Wait for confirmation message\n'
                      '3. Close the app completely (swipe up and swipe away)\n'
                      '4. Wait 1 minute - notification should appear!\n'
                      '5. Check if adhan audio plays\n\n'
                      '✅ Works in background - notifications are scheduled with the system\n'
                      '✅ No timer needed - system handles the timing\n'
                      '✅ Battery efficient - no continuous monitoring\n'
                      '✅ Reliable - works even when app is closed',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.blue[700],
                      ),
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
}
