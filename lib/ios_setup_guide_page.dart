import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'theme_constants.dart';

class IOSSetupGuidePage extends StatelessWidget {
  const IOSSetupGuidePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('iOS Setup Guide'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // iOS Limitations Warning
            Card(
              color: Colors.orange[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange[700], size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'iOS Limitations',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Apple doesn\'t allow third-party apps to play long audio (full azan) automatically in the background. However, you can still get prayer notifications with short sounds.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.orange[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Step 1: Enable Notifications
            _buildStepCard(
              context,
              '1',
              'Enable Notifications',
              'Allow the app to send you prayer notifications',
              [
                'Go to Settings → Notifications',
                'Find "Daily Quran" in the list',
                'Turn ON "Allow Notifications"',
                'Enable "Sounds", "Banners", and "Lock Screen"',
                'Set "Alert Style" to "Banners" or "Alerts"',
              ],
              Icons.notifications,
              Colors.blue,
            ),
            
            const SizedBox(height: 16),
            
            // Step 2: Location Access
            _buildStepCard(
              context,
              '2',
              'Allow Location Access',
              'Prayer times depend on your location',
              [
                'Go to Settings → Privacy & Security → Location Services',
                'Make sure Location Services is ON',
                'Find "Daily Quran" in the list',
                'Select "While Using App" or "Always"',
                'Turn ON "Precise Location"',
              ],
              Icons.location_on,
              Colors.green,
            ),
            
            const SizedBox(height: 16),
            
            // Step 3: Background App Refresh
            _buildStepCard(
              context,
              '3',
              'Enable Background App Refresh',
              'Allow the app to work in the background',
              [
                'Go to Settings → General → Background App Refresh',
                'Make sure Background App Refresh is ON',
                'Find "Daily Quran" in the list',
                'Turn ON Background App Refresh for this app',
              ],
              Icons.refresh,
              Colors.purple,
            ),
            
            const SizedBox(height: 16),
            
            // Step 4: Do Not Disturb
            _buildStepCard(
              context,
              '4',
              'Check Do Not Disturb Settings',
              'Make sure prayer notifications can break through',
              [
                'Go to Settings → Focus → Do Not Disturb',
                'Tap "Apps" under "Allow Notifications From"',
                'Add "Daily Quran" to allowed apps',
                'Or turn OFF Do Not Disturb during prayer times',
              ],
              Icons.do_not_disturb,
              Colors.red,
            ),
            
            const SizedBox(height: 16),
            
            // Alternative Solution
            Card(
              color: Colors.green[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb, color: Colors.green[700], size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'Alternative Solution',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'For full azan audio even when the app is closed, you can use the iPhone Clock app:',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.green[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '1. Download azan audio files to your iPhone\n'
                      '2. Go to Clock app → Alarms\n'
                      '3. Create alarms for each prayer time\n'
                      '4. Set custom ringtone to azan audio\n'
                      '5. This will play full azan even when locked',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Test Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/test_scheduled_alarm');
                },
                icon: const Icon(Icons.alarm),
                label: const Text('Test Notifications Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Additional Tips
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Additional Tips',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Keep the app updated for best performance\n'
                      '• Test notifications by scheduling a test in 1 minute\n'
                      '• If notifications don\'t work, restart your iPhone\n'
                      '• Make sure your iPhone isn\'t in Low Power Mode during prayer times\n'
                      '• Consider using the Clock app method for full azan audio',
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

  Widget _buildStepCard(
    BuildContext context,
    String stepNumber,
    String title,
    String description,
    List<String> instructions,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      stepNumber,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 12),
            ...instructions.map((instruction) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      instruction,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }
}
