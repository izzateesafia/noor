import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'services/simple_alarm_service.dart';
import 'theme_constants.dart';

class TestSimpleAlarmPage extends StatefulWidget {
  const TestSimpleAlarmPage({super.key});

  @override
  State<TestSimpleAlarmPage> createState() => _TestSimpleAlarmPageState();
}

class _TestSimpleAlarmPageState extends State<TestSimpleAlarmPage> {
  final SimpleAlarmService _alarmService = SimpleAlarmService();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeAlarm();
  }

  Future<void> _initializeAlarm() async {
    await _alarmService.initialize();
    setState(() {
      _isInitialized = true;
    });
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

  Future<void> _testSimpleNotification() async {
    try {
      final FlutterLocalNotificationsPlugin notifications = FlutterLocalNotificationsPlugin();
      
      // Initialize if not already done
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      
      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await notifications.initialize(initializationSettings);
      
      // Request permissions
      await notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      
      // Show simple notification
      await notifications.show(
        999,
        'Test Notification',
        'This is a simple test notification',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'test_channel',
            'Test Notifications',
            channelDescription: 'Test notifications',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Simple notification sent')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending simple notification: $e')),
      );
    }
  }

  Future<void> _toggleAlarm() async {
    await _alarmService.setAlarmEnabled(!_alarmService.isAlarmEnabled);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Test Simple Alarm'),
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
        title: const Text('Test Simple Alarm'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
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
                        Text('Enabled: '),
                        Switch(
                          value: _alarmService.isAlarmEnabled,
                          onChanged: (value) => _toggleAlarm(),
                          activeColor: AppColors.primary,
                        ),
                      ],
                    ),
                    Text('Enabled Prayers: ${_alarmService.enabledPrayers.join(", ")}'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Test Buttons
            Text(
              'Test Adhan',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () => _testSimpleNotification(),
                  child: const Text('Test Simple Notification'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                // ElevatedButton(
                //   onPressed: () => _testAdhan('Fajr'),
                //   child: const Text('Test Fajr'),
                // ),
                // ElevatedButton(
                //   onPressed: () => _testAdhan('Dhuhr'),
                //   child: const Text('Test Dhuhr'),
                // ),
                // ElevatedButton(
                //   onPressed: () => _testAdhan('Asr'),
                //   child: const Text('Test Asr'),
                // ),
                // ElevatedButton(
                //   onPressed: () => _testAdhan('Maghrib'),
                //   child: const Text('Test Maghrib'),
                // ),
                // ElevatedButton(
                //   onPressed: () => _testAdhan('Isha'),
                //   child: const Text('Test Isha'),
                // ),
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
                      'Instructions',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '1. FIRST: Tap "Test Simple Notification" to test basic notifications\n'
                      '2. If no notification appears, check device notification settings\n'
                      '3. Then test individual prayer buttons\n'
                      '4. Check console logs for debug information\n'
                      '5. The alarm checks every 30 seconds for prayer times',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Troubleshooting
            Card(
              color: Colors.orange[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Troubleshooting',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'If notifications don\'t appear:\n'
                      '• Check device notification settings for this app\n'
                      '• Ensure "Allow notifications" is enabled\n'
                      '• Check if "Do Not Disturb" is enabled\n'
                      '• Look at console logs for error messages\n'
                      '• Try restarting the app',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.orange[700],
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
