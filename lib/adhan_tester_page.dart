/*
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/adhan_audio_service.dart';
import '../services/alarm_service.dart';
import '../theme_constants.dart';

class AdhanTesterPage extends StatefulWidget {
  const AdhanTesterPage({super.key});

  @override
  State<AdhanTesterPage> createState() => _AdhanTesterPageState();
}

class _AdhanTesterPageState extends State<AdhanTesterPage> {
  final AdhanAudioService _adhanAudioService = AdhanAudioService();
  final AlarmService _alarmService = AlarmService();
  final TextEditingController _hourController = TextEditingController();
  final TextEditingController _minuteController = TextEditingController();
  final FocusNode _hourFocusNode = FocusNode();
  final FocusNode _minuteFocusNode = FocusNode();
  
  int _selectedHour = 12;
  int _selectedMinute = 0;
  String _selectedPrayer = 'Dhuhr';
  bool _isPlaying = false;
  bool _isWaiting = false;
  bool _isScheduled = false;
  String _status = 'Siap untuk ujian';
  Timer? _timer;

  final List<String> _prayers = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];

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
    _updateControllers();
    _checkScheduledAdhan();
  }

  Future<void> _checkScheduledAdhan() async {
    try {
      await _alarmService.initialize();
      final scheduledInfo = await _alarmService.getScheduledAlarmInfo();
      
      if (mounted && scheduledInfo != null) {
        setState(() {
          _isScheduled = true;
          _status = 'Azan dijadualkan untuk ${scheduledInfo['prayerDisplayName']} pada ${_formatDateTime(scheduledInfo['scheduledTime'])}';
        });
      }
    } catch (e) {
      print('Error checking scheduled adhan: $e');
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _hourController.dispose();
    _minuteController.dispose();
    _hourFocusNode.dispose();
    _minuteFocusNode.dispose();
    _adhanAudioService.dispose();
    super.dispose();
  }

  void _updateControllers() {
    _hourController.text = _selectedHour.toString().padLeft(2, '0');
    _minuteController.text = _selectedMinute.toString().padLeft(2, '0');
  }

  void _updateTime() {
    final hourText = _hourController.text;
    final minuteText = _minuteController.text;
    
    print('Hour text: "$hourText", Minute text: "$minuteText"');
    
    final hour = int.tryParse(hourText) ?? 0;
    final minute = int.tryParse(minuteText) ?? 0;
    
    print('Parsed hour: $hour, Parsed minute: $minute');
    
    setState(() {
      _selectedHour = hour.clamp(0, 23);
      _selectedMinute = minute.clamp(0, 59);
    });
    
    print('Updated _selectedHour: $_selectedHour, _selectedMinute: $_selectedMinute');
  }

  String _getTimeString() {
    return '${_selectedHour.toString().padLeft(2, '0')}:${_selectedMinute.toString().padLeft(2, '0')}';
  }

  Future<void> _testAdhan() async {
    if (_isPlaying) {
      await _stopAdhan();
      return;
    }

    if (_isWaiting) {
      _stopWaiting();
      return;
    }

    if (_isScheduled) {
      await _cancelScheduledAdhan();
      return;
    }

    // Check if it's time to play adhan
    final now = DateTime.now();
    final targetTime = DateTime(now.year, now.month, now.day, _selectedHour, _selectedMinute);
    
    if (now.hour == _selectedHour && now.minute == _selectedMinute) {
      // Play immediately
      await _playAdhanNow();
    } else {
      // Schedule background alarm
      await _scheduleAdhan(targetTime);
    }
  }

  void _startWaiting() {
    _timer?.cancel();
    
    setState(() {
      _isWaiting = true;
      _status = 'Menunggu waktu ${_getTimeString()} untuk ${_getPrayerDisplayName(_selectedPrayer)}...';
    });

    // Check every second if it's time
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      if (now.hour == _selectedHour && now.minute == _selectedMinute) {
        timer.cancel();
        _playAdhanNow();
      } else {
        // Update status with countdown
        final targetTime = DateTime(now.year, now.month, now.day, _selectedHour, _selectedMinute);
        final difference = targetTime.difference(now);
        
        if (mounted) {
          setState(() {
            _status = 'Menunggu waktu ${_getTimeString()} untuk ${_getPrayerDisplayName(_selectedPrayer)}...\n'
                     'Masa tinggal: ${difference.inMinutes} minit ${difference.inSeconds % 60} saat';
          });
        }
      }
    });
  }

  void _stopWaiting() {
    _timer?.cancel();
    setState(() {
      _isWaiting = false;
      _status = 'Berhenti menunggu';
    });
  }

  Future<void> _scheduleAdhan(DateTime targetTime) async {
    try {
      await _alarmService.initialize();
      
      await _alarmService.scheduleAlarm(
        scheduledTime: targetTime,
        prayerName: _selectedPrayer,
        prayerDisplayName: _getPrayerDisplayName(_selectedPrayer),
      );
      
      setState(() {
        _isScheduled = true;
        _status = 'Azan dijadualkan untuk ${_getPrayerDisplayName(_selectedPrayer)} pada ${_getTimeString()} (akan berbunyi walaupun app ditutup)';
      });
      
      print('Adhan alarm scheduled for ${_getPrayerDisplayName(_selectedPrayer)} at ${_getTimeString()}');
    } catch (e) {
      setState(() {
        _status = 'Ralat menjadualkan azan: $e';
      });
      print('Error scheduling adhan alarm: $e');
    }
  }

  Future<void> _cancelScheduledAdhan() async {
    try {
      await _alarmService.cancelAllAlarms();
      
      setState(() {
        _isScheduled = false;
        _status = 'Jadual azan dibatalkan';
      });
      
      print('Scheduled adhan alarm cancelled');
    } catch (e) {
      setState(() {
        _status = 'Ralat membatalkan jadual azan: $e';
      });
      print('Error cancelling scheduled adhan alarm: $e');
    }
  }

  Future<void> _quickTestAdhan() async {
    print('Quick test adhan started for ${_selectedPrayer}');
    setState(() {
      _isPlaying = true;
      _status = 'Menguji azan untuk ${_getPrayerDisplayName(_selectedPrayer)}...';
    });

    try {
      print('Calling playAdhanForPrayer with ${_selectedPrayer}');
      await _adhanAudioService.playAdhanForPrayer(_selectedPrayer);
      print('playAdhanForPrayer completed successfully');
      
      // Auto-stop after 15 seconds
      Future.delayed(const Duration(seconds: 15), () {
        if (mounted) {
          setState(() {
            _isPlaying = false;
            _status = 'Ujian azan selesai untuk ${_getPrayerDisplayName(_selectedPrayer)}';
          });
        }
      });
    } catch (e) {
      print('Error in quick test adhan: $e');
      setState(() {
        _isPlaying = false;
        _status = 'Ralat menguji azan: $e';
      });
    }
  }

  Future<void> _debugNotifications() async {
    try {
      final pendingNotifications = await _alarmService.getPendingNotifications();
      print('Pending notifications: ${pendingNotifications.length}');
      
      for (var notification in pendingNotifications) {
        print('Notification ID: ${notification.id}, Title: ${notification.title}');
      }
      
      final alarmInfo = await _alarmService.getScheduledAlarmInfo();
      if (alarmInfo != null) {
        print('Scheduled alarm: ${alarmInfo['prayerDisplayName']} at ${alarmInfo['scheduledTime']}');
        setState(() {
          _status = 'Debug: ${pendingNotifications.length} notifications pending. Alarm: ${alarmInfo['prayerDisplayName']} at ${alarmInfo['scheduledTime']}';
        });
      } else {
        setState(() {
          _status = 'Debug: ${pendingNotifications.length} notifications pending. No alarm scheduled.';
        });
      }
    } catch (e) {
      print('Error debugging notifications: $e');
      setState(() {
        _status = 'Debug error: $e';
      });
    }
  }

  Future<void> _test30Seconds() async {
    try {
      final now = DateTime.now();
      final targetTime = now.add(const Duration(seconds: 30));
      
      await _alarmService.scheduleAlarm(
        scheduledTime: targetTime,
        prayerName: _selectedPrayer,
        prayerDisplayName: _getPrayerDisplayName(_selectedPrayer),
      );
      
      setState(() {
        _isScheduled = true;
        _status = 'Azan dijadualkan untuk ${_getPrayerDisplayName(_selectedPrayer)} dalam 30 saat (tutup app untuk test)';
      });
      
      print('30-second test alarm scheduled for ${_getPrayerDisplayName(_selectedPrayer)} at $targetTime');
    } catch (e) {
      setState(() {
        _status = 'Ralat menjadualkan ujian 30 saat: $e';
      });
      print('Error scheduling 30-second test: $e');
    }
  }

  Future<void> _testNotification() async {
    try {
      await _alarmService.showTestNotification();
      setState(() {
        _status = 'Notifikasi ujian dihantar - periksa status bar';
      });
      print('Test notification sent');
    } catch (e) {
      setState(() {
        _status = 'Ralat menghantar notifikasi ujian: $e';
      });
      print('Error sending test notification: $e');
    }
  }

  Future<void> _playAdhanNow() async {
    setState(() {
      _isWaiting = false;
      _isPlaying = true;
      _status = 'Memainkan azan untuk ${_getPrayerDisplayName(_selectedPrayer)} pada ${_getTimeString()}...';
    });

    try {
      await _adhanAudioService.playAdhanForPrayer(_selectedPrayer);
      
      // Auto-stop after 15 seconds
      Future.delayed(const Duration(seconds: 15), () {
        if (mounted) {
          setState(() {
            _isPlaying = false;
            _status = 'Azan selesai untuk ${_getPrayerDisplayName(_selectedPrayer)}';
          });
        }
      });
    } catch (e) {
      setState(() {
        _isPlaying = false;
        _status = 'Ralat memainkan azan: $e';
      });
    }
  }

  Future<void> _stopAdhan() async {
    _timer?.cancel();
    try {
      await _adhanAudioService.stopAdhan();
      setState(() {
        _isPlaying = false;
        _isWaiting = false;
        _status = 'Azan dihentikan';
      });
    } catch (e) {
      setState(() {
        _status = 'Error stopping adhan: $e';
      });
    }
  }

  Future<void> _testAllPrayers() async {
    if (_isWaiting) {
      _stopWaiting();
    }
    
    setState(() {
      _isPlaying = true;
      _status = 'Menguji semua solat...';
    });

    for (int i = 0; i < _prayers.length; i++) {
      final prayer = _prayers[i];
      
      setState(() {
        _selectedPrayer = prayer;
        _status = 'Menguji azan ${_getPrayerDisplayName(prayer)}...';
      });

      try {
        await _adhanAudioService.playAdhanForPrayer(prayer);
        
        // Wait for adhan to complete (15 seconds)
        await Future.delayed(const Duration(seconds: 16));
        
        // Stop before playing next
        await _adhanAudioService.stopAdhan();
        
        // Small delay between prayers
        if (i < _prayers.length - 1) {
          await Future.delayed(const Duration(seconds: 2));
        }
      } catch (e) {
        setState(() {
          _status = 'Error testing $prayer: $e';
        });
        break;
      }
    }

    setState(() {
      _isPlaying = false;
      _status = 'Semua solat berjaya diuji!';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adhan Tester'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, '/prayer_alarm_settings');
            },
            icon: const Icon(Icons.settings),
            tooltip: 'Prayer Alarm Settings',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: _isPlaying ? Colors.green[50] : (_isWaiting ? Colors.orange[50] : (_isScheduled ? Colors.purple[50] : Colors.blue[50])),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      _isPlaying ? Icons.volume_up : (_isWaiting ? Icons.schedule : (_isScheduled ? Icons.notifications_active : Icons.info_outline)),
                      color: _isPlaying ? Colors.green[700] : (_isWaiting ? Colors.orange[700] : (_isScheduled ? Colors.purple[700] : Colors.blue[700])),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Status',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: _isPlaying ? Colors.green[700] : (_isWaiting ? Colors.orange[700] : (_isScheduled ? Colors.purple[700] : Colors.blue[700])),
                            ),
                          ),
                          Text(
                            _status,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: _isPlaying ? Colors.green[700] : (_isWaiting ? Colors.orange[700] : (_isScheduled ? Colors.purple[700] : Colors.blue[700])),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Time Selection Card
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
                        Icon(Icons.access_time, color: AppColors.primary, size: 24),
                        const SizedBox(width: 12),
                        Text(
                          'Test Time',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        // Hour Input
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Hour (0-23)'),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _hourController,
                                focusNode: _hourFocusNode,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(2),
                                ],
                                onChanged: (value) => _updateTime(),
                                decoration: InputDecoration(
                                  hintText: '00',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Minute Input
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Minute (0-59)'),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _minuteController,
                                focusNode: _minuteFocusNode,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(2),
                                ],
                                onChanged: (value) => _updateTime(),
                                decoration: InputDecoration(
                                  hintText: '00',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Quick Time Buttons
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildQuickTimeButton('05:30', 'Fajr'),
                        _buildQuickTimeButton('12:00', 'Dhuhr'),
                        _buildQuickTimeButton('15:30', 'Asr'),
                        _buildQuickTimeButton('18:30', 'Maghrib'),
                        _buildQuickTimeButton('20:00', 'Isha'),
                        _buildQuickTimeButton('Now', 'Current'),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Prayer Selection Card
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
                        Icon(Icons.mosque, color: AppColors.primary, size: 24),
                        const SizedBox(width: 12),
                        Text(
                          'Prayer Selection',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _prayers.map((prayer) {
                        final isSelected = _selectedPrayer == prayer;
                        return FilterChip(
                          label: Text(_getPrayerDisplayName(prayer)),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedPrayer = prayer;
                              });
                            }
                          },
                          selectedColor: AppColors.primary.withOpacity(0.3),
                          checkmarkColor: AppColors.primary,
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Test Buttons
            Column(
              children: [
                // Main Test Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _testAdhan,
                    icon: Icon(_isPlaying ? Icons.stop : (_isWaiting ? Icons.pause : (_isScheduled ? Icons.cancel : Icons.play_arrow))),
                    label: Text(_isPlaying ? 'Hentikan Azan' : (_isWaiting ? 'Berhenti Menunggu' : (_isScheduled ? 'Batal Jadual' : 'Uji Azan'))),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isPlaying ? Colors.red : (_isWaiting ? Colors.orange : (_isScheduled ? Colors.purple : AppColors.primary)),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Test All Prayers Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: (_isPlaying || _isWaiting || _isScheduled) ? null : _testAllPrayers,
                    icon: const Icon(Icons.queue_music),
                    label: const Text('Uji Semua Solat'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Quick Test Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: (_isPlaying || _isWaiting || _isScheduled) ? null : _quickTestAdhan,
                    icon: const Icon(Icons.play_circle),
                    label: const Text('Uji Azan Sekarang'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                      side: BorderSide(color: Colors.green),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Debug Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _debugNotifications,
                    icon: const Icon(Icons.bug_report),
                    label: const Text('Debug Notifications'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      side: BorderSide(color: Colors.orange),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // 30 Second Test Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: (_isPlaying || _isWaiting || _isScheduled) ? null : _test30Seconds,
                    icon: const Icon(Icons.timer),
                    label: const Text('Uji 30 Saat Lagi'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.purple,
                      side: BorderSide(color: Colors.purple),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Test Notification Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _testNotification,
                    icon: const Icon(Icons.notifications),
                    label: const Text('Uji Notifikasi'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.teal,
                      side: BorderSide(color: Colors.teal),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Information Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: Colors.orange[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline, color: Colors.orange[700], size: 24),
                        const SizedBox(width: 12),
                        Text(
                          'Testing Tips',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '• Masukkan masa untuk menjadualkan azan\n'
                      '• Azan akan dimainkan walaupun app ditutup\n'
                      '• Gunakan butang masa pantas untuk masa solat biasa\n'
                      '• Subuh menggunakan fail audio azan yang berbeza\n'
                      '• Setiap azan dimainkan selama 15 saat\n'
                      '• Uji semua solat untuk mengesahkan fail audio berfungsi\n'
                      '• Pastikan kelantangan peranti dihidupkan\n'
                      '• Notifikasi akan muncul pada masa yang dijadualkan',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.orange[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Current Time Display
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.schedule, color: AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Current Time: ${_getCurrentTime()}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Selected Time: ${_getTimeString()}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
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

  Widget _buildQuickTimeButton(String time, String label) {
    return ElevatedButton(
      onPressed: () {
        if (time == 'Now') {
          final now = DateTime.now();
          setState(() {
            _selectedHour = now.hour;
            _selectedMinute = now.minute;
          });
        } else {
          final parts = time.split(':');
          setState(() {
            _selectedHour = int.parse(parts[0]);
            _selectedMinute = int.parse(parts[1]);
            _selectedPrayer = label;
          });
        }
        _updateControllers();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary.withOpacity(0.1),
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text('$time\n$label'),
    );
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }
}
*/
