import 'package:flutter/material.dart';
import '../services/scheduled_alarm_service.dart';
import '../theme_constants.dart';

class PrayerAlarmSettingsPage extends StatefulWidget {
  const PrayerAlarmSettingsPage({super.key});

  @override
  State<PrayerAlarmSettingsPage> createState() => _PrayerAlarmSettingsPageState();
}

class _PrayerAlarmSettingsPageState extends State<PrayerAlarmSettingsPage> {
  final ScheduledAlarmService _prayerAlarmService = ScheduledAlarmService();
  bool _alarmEnabled = true;
  Set<String> _enabledPrayers = {'Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'};

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
          SnackBar(content: Text('Ralat memuatkan tetapan: $e')),
        );
      }
    }
  }

  Future<void> _saveSettings() async {
    try {
      await _prayerAlarmService.setAlarmEnabled(_alarmEnabled);
      
      // Save individual prayer settings
      final allPrayers = {'Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'};
      for (String prayer in allPrayers) {
        await _prayerAlarmService.setPrayerEnabled(prayer, _enabledPrayers.contains(prayer));
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tetapan berjaya disimpan')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ralat menyimpan tetapan: $e')),
        );
      }
    }
  }

  Future<void> _testAdhan(String prayerName) async {
    try {
      await _prayerAlarmService.testAdhan(prayerName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Menguji azan untuk ${_getPrayerDisplayName(prayerName)}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ralat menguji azan: $e')),
        );
      }
    }
  }

  void _showQuickTestDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.play_circle, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text('Uji Azan Sekarang'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Pilih solat untuk menguji azan:',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              ...['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'].map((prayer) {
                return ListTile(
                  leading: Icon(
                    Icons.volume_up,
                    color: AppColors.primary,
                  ),
                  title: Text(_getPrayerDisplayName(prayer)),
                  onTap: () {
                    Navigator.of(context).pop();
                    _testAdhan(prayer);
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              }).toList(),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Batal'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Tetapan Penggera Solat'),
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
        title: const Text('Tetapan Penggera Solat'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _saveSettings,
            icon: const Icon(Icons.save),
            tooltip: 'Simpan Tetapan',
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
                                'Penggera Solat',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Mainkan azan secara automatik apabila waktu solat tiba',
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

            // Quick Test Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: Colors.green[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.play_circle, color: Colors.green[700], size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Uji Azan Sekarang',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[700],
                                ),
                              ),
                              Text(
                                'Uji azan untuk mana-mana solat tanpa menunggu waktu solat',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.green[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _showQuickTestDialog,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Pilih Solat untuk Uji'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

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
                            'Waktu Solat',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Pilih solat mana yang akan mencetuskan penggera azan:',
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
                                  _getPrayerDisplayName(prayer),
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
            // Card(
            //   elevation: 2,
            //   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            //   color: Colors.blue[50],
            //   child: Padding(
            //     padding: const EdgeInsets.all(16),
            //     child: Column(
            //       crossAxisAlignment: CrossAxisAlignment.start,
            //       children: [
            //         Row(
            //           children: [
            //             Icon(Icons.info_outline, color: Colors.blue[700], size: 24),
            //             const SizedBox(width: 12),
            //             Text(
            //               'Cara ia berfungsi',
            //               style: Theme.of(context).textTheme.titleMedium?.copyWith(
            //                 fontWeight: FontWeight.bold,
            //                 color: Colors.blue[700],
            //               ),
            //             ),
            //           ],
            //         ),
            //         const SizedBox(height: 12),
            //         Text(
            //           '• Aplikasi memeriksa waktu solat setiap minit\n'
            //           '• Azan akan dimainkan secara automatik apabila waktu solat tiba\n'
            //           '• Azan setiap solat dimainkan hanya sekali sehari\n'
            //           '• Pastikan kelantangan peranti anda dihidupkan\n'
            //           '• Aplikasi berfungsi di latar belakang apabila diminimumkan',
            //           style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            //             color: Colors.blue[700],
            //           ),
            //         ),
            //       ],
            //     ),
            //   ),
            // ),
            //
            // const SizedBox(height: 16),
            //
            // // iOS Setup Guide
            // Card(
            //   color: Colors.orange[50],
            //   child: Padding(
            //     padding: const EdgeInsets.all(16),
            //     child: Column(
            //       crossAxisAlignment: CrossAxisAlignment.start,
            //       children: [
            //         Row(
            //           children: [
            //             Icon(Icons.phone_iphone, color: Colors.orange[700], size: 24),
            //             const SizedBox(width: 8),
            //             Text(
            //               'iOS Users - Important!',
            //               style: Theme.of(context).textTheme.titleMedium?.copyWith(
            //                 fontWeight: FontWeight.bold,
            //                 color: Colors.orange[700],
            //               ),
            //             ),
            //           ],
            //         ),
            //         const SizedBox(height: 8),
            //         Text(
            //           'Apple limits background audio for third-party apps. For best results, please check the iOS setup guide.',
            //           style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            //             color: Colors.orange[700],
            //           ),
            //         ),
            //         const SizedBox(height: 8),
            //         SizedBox(
            //           width: double.infinity,
            //           child: ElevatedButton.icon(
            //             onPressed: () {
            //               Navigator.pushNamed(context, '/ios_setup_guide');
            //             },
            //             icon: const Icon(Icons.settings),
            //             label: const Text('iOS Setup Guide'),
            //             style: ElevatedButton.styleFrom(
            //               backgroundColor: Colors.orange[700],
            //               foregroundColor: Colors.white,
            //             ),
            //           ),
            //         ),
            //       ],
            //     ),
            //   ),
            // ),
            //
            // const SizedBox(height: 16),

            // // Test Buttons
            // Column(
            //   children: [
            //     Row(
            //       children: [
            //         Expanded(
            //           child: OutlinedButton.icon(
            //             onPressed: () {
            //               Navigator.pushNamed(context, '/test_scheduled_alarm');
            //             },
            //             icon: const Icon(Icons.schedule),
            //             label: const Text('Penguji Azan Terjadual'),
            //             style: OutlinedButton.styleFrom(
            //               foregroundColor: Colors.green,
            //               side: BorderSide(color: Colors.green),
            //               padding: const EdgeInsets.symmetric(vertical: 16),
            //               shape: RoundedRectangleBorder(
            //                 borderRadius: BorderRadius.circular(12),
            //               ),
            //             ),
            //           ),
            //         ),
            //         const SizedBox(width: 8),
            //         Expanded(
            //           child: OutlinedButton.icon(
            //             onPressed: () {
            //               Navigator.pushNamed(context, '/test_simple_alarm');
            //             },
            //             icon: const Icon(Icons.alarm),
            //             label: const Text('Penguji Azan Timer'),
            //             style: OutlinedButton.styleFrom(
            //               foregroundColor: AppColors.primary,
            //               side: BorderSide(color: AppColors.primary),
            //               padding: const EdgeInsets.symmetric(vertical: 16),
            //               shape: RoundedRectangleBorder(
            //                 borderRadius: BorderRadius.circular(12),
            //               ),
            //             ),
            //           ),
            //         ),
            //       ],
            //     ),
            //     const SizedBox(height: 8),
            //     // SizedBox(
            //     //   width: double.infinity,
            //     //   child: OutlinedButton.icon(
            //     //     onPressed: () {
            //     //       Navigator.pushNamed(context, '/adhan_tester');
            //     //     },
            //     //     icon: const Icon(Icons.play_arrow),
            //     //     label: const Text('Penguji Azan Lama'),
            //     //     style: OutlinedButton.styleFrom(
            //     //       foregroundColor: Colors.grey[600],
            //     //       side: BorderSide(color: Colors.grey[600]!),
            //     //       padding: const EdgeInsets.symmetric(vertical: 16),
            //     //       shape: RoundedRectangleBorder(
            //     //         borderRadius: BorderRadius.circular(12),
            //     //       ),
            //     //     ),
            //     //   ),
            //     // ),
            //   ],
            // ),
            //
            // const SizedBox(height: 16),

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
                  'Simpan Tetapan',
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
