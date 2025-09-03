import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/prayer_alarm_service.dart';
import '../theme_constants.dart';

class PrayerAlarmSettingsPage extends StatefulWidget {
  const PrayerAlarmSettingsPage({super.key});

  @override
  State<PrayerAlarmSettingsPage> createState() => _PrayerAlarmSettingsPageState();
}

class _PrayerAlarmSettingsPageState extends State<PrayerAlarmSettingsPage> {
  final PrayerAlarmService _prayerAlarmService = PrayerAlarmService();
  bool _alarmEnabled = true;
  double _alarmVolume = 1.0;
  Set<String> _enabledPrayers = {'Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      // Load current settings
      _alarmEnabled = _prayerAlarmService.isAlarmEnabled;
      _alarmVolume = _prayerAlarmService.alarmVolume;
      _enabledPrayers = Set.from(_prayerAlarmService.enabledPrayers);
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading settings: $e')),
        );
      }
    }
  }

  Future<void> _saveSettings() async {
    try {
      await _prayerAlarmService.setAlarmEnabled(_alarmEnabled);
      await _prayerAlarmService.setAlarmVolume(_alarmVolume);
      
      // Save individual prayer settings
      final allPrayers = {'Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'};
      for (String prayer in allPrayers) {
        await _prayerAlarmService.setPrayerEnabled(prayer, _enabledPrayers.contains(prayer));
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving settings: $e')),
        );
      }
    }
  }

  Future<void> _testAdhan(String prayerName) async {
    try {
      await _prayerAlarmService.testAdhan(prayerName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Testing adhan for $prayerName')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error testing adhan: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Prayer Alarm Settings'),
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
        title: const Text('Prayer Alarm Settings'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _saveSettings,
            icon: const Icon(Icons.save),
            tooltip: 'Save Settings',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main Alarm Toggle
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.alarm, color: AppColors.primary, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Prayer Alarm',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Automatically play adhan when prayer time arrives',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _alarmEnabled,
                          onChanged: (value) {
                            setState(() {
                              _alarmEnabled = value;
                            });
                          },
                          activeColor: AppColors.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Volume Control
            if (_alarmEnabled) ...[
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.volume_up, color: AppColors.primary, size: 24),
                          const SizedBox(width: 12),
                          Text(
                            'Alarm Volume',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(Icons.volume_down, color: Colors.grey[600]),
                          Expanded(
                            child: Slider(
                              value: _alarmVolume,
                              min: 0.0,
                              max: 1.0,
                              divisions: 10,
                              label: '${(_alarmVolume * 100).round()}%',
                              onChanged: (value) {
                                setState(() {
                                  _alarmVolume = value;
                                });
                              },
                              activeColor: AppColors.primary,
                            ),
                          ),
                          Icon(Icons.volume_up, color: Colors.grey[600]),
                        ],
                      ),
                      Text(
                        '${(_alarmVolume * 100).round()}%',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Prayer Selection
            if (_alarmEnabled) ...[
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.schedule, color: AppColors.primary, size: 24),
                          const SizedBox(width: 12),
                          Text(
                            'Prayer Times',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Select which prayers should trigger the adhan alarm:',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'].map((prayer) {
                        final isEnabled = _enabledPrayers.contains(prayer);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  prayer,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ),
                              Switch(
                                value: isEnabled,
                                onChanged: (value) {
                                  setState(() {
                                    if (value) {
                                      _enabledPrayers.add(prayer);
                                    } else {
                                      _enabledPrayers.remove(prayer);
                                    }
                                  });
                                },
                                activeColor: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: () => _testAdhan(prayer),
                                icon: Icon(
                                  Icons.play_arrow,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                                tooltip: 'Test $prayer Adhan',
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Information Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700], size: 24),
                        const SizedBox(width: 12),
                        Text(
                          'How it works',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '• The app checks for prayer times every minute\n'
                      '• Adhan will play automatically when prayer time arrives\n'
                      '• Each prayer adhan plays only once per day\n'
                      '• Make sure your device volume is turned on\n'
                      '• The app works in the background when minimized',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Save Settings',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
