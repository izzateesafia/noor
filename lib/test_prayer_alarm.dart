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
  String _status = 'Memulakan...';

  String _getPrayerDisplayName(String prayerName) {
    switch (prayerName) {
      case 'Fajr':
        return 'Subuh';
      case 'Dhuhr':
        return 'Zuhur';
      case 'Asr':
        return 'Asar';
      case 'Maghrib':
        return 'Maghrib';
      case 'Isha':
        return 'Isya';
      default:
        return prayerName;
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    try {
      await _prayerAlarmService.initialize();
      setState(() {
        _status = 'Perkhidmatan berjaya dimulakan!';
      });
    } catch (e) {
      setState(() {
        _status = 'Ralat memulakan perkhidmatan: $e';
      });
    }
  }

  // Future<void> _testAdhan(String prayerName) async {
  //   try {
  //     await _prayerAlarmService.testAdhan(prayerName);
  //     setState(() {
  //       _status = 'Menguji azan untuk $prayerName...';
  //     });
  //   } catch (e) {
  //     setState(() {
  //       _status = 'Ralat menguji azan: $e';
  //     });
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ujian Penggera Solat'),
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
                      'Status Perkhidmatan',
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
              'Uji Azan untuk Setiap Solat:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'].map((prayer) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                // child: SizedBox(
                //   width: double.infinity,
                //   child: ElevatedButton(
                //     onPressed: () => _testAdhan(prayer),
                //     child: Text('Uji Azan ${_getPrayerDisplayName(prayer)}'),
                //   ),
                // ),
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
