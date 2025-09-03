import 'package:flutter/material.dart';
import 'services/prayer_alarm_service.dart';

/// Test page for prayer alarm functionality
/// This is a temporary test page to verify the alarm system works
class TestPrayerAlarmPage extends StatefulWidget {
  const TestPrayerAlarmPage({super.key});

  @override
  State<TestPrayerAlarmPage> createState() => _TestPrayerAlarmPageState();
}

class _TestPrayerAlarmPageState extends State<TestPrayerAlarmPage> {
  final PrayerAlarmService _prayerAlarmService = PrayerAlarmService();
  String _status = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    try {
      await _prayerAlarmService.initialize();
      setState(() {
        _status = 'Service initialized successfully!';
      });
    } catch (e) {
      setState(() {
        _status = 'Error initializing service: $e';
      });
    }
  }

  Future<void> _testAdhan(String prayerName) async {
    try {
      await _prayerAlarmService.testAdhan(prayerName);
      setState(() {
        _status = 'Testing adhan for $prayerName...';
      });
    } catch (e) {
      setState(() {
        _status = 'Error testing adhan: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Prayer Alarm'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Service Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(_status),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Test Adhan for Each Prayer:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'].map((prayer) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _testAdhan(prayer),
                    child: Text('Test $prayer Adhan'),
                  ),
                ),
              );
            }).toList(),
            const SizedBox(height: 16),
            const Text(
              'Settings:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text('Alarm Enabled: ${_prayerAlarmService.isAlarmEnabled}'),
            Text('Alarm Volume: ${(_prayerAlarmService.alarmVolume * 100).round()}%'),
            Text('Enabled Prayers: ${_prayerAlarmService.enabledPrayers.join(', ')}'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/prayer_alarm_settings');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Open Settings'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
