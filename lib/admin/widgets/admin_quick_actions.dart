import 'package:flutter/material.dart';

class AdminQuickActions extends StatelessWidget {
  final VoidCallback onGoLive;
  final VoidCallback onScheduleLive;
  final VoidCallback onSendNotification;
  final VoidCallback onManageWelcomeMessage;

  const AdminQuickActions({
    super.key,
    required this.onGoLive,
    required this.onScheduleLive,
    required this.onSendNotification,
    required this.onManageWelcomeMessage,
  });

  @override
  Widget build(BuildContext context) {
    // Use a default color for the quick actions section (red/orange theme)
    const sectionColor = Colors.deepOrange;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: sectionColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Tindakan Pantas',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.95,
          children: [
            _QuickActionCard(
              icon: Icons.live_tv,
              label: 'Go Live',
              color: Colors.red,
              onTap: onGoLive,
            ),
            _QuickActionCard(
              icon: Icons.alarm,
              label: 'Jadual Siaran',
              color: Colors.deepOrange,
              onTap: onScheduleLive,
            ),
            _QuickActionCard(
              icon: Icons.notifications_active,
              label: 'Hantar Notifikasi',
              color: Colors.blue,
              onTap: onSendNotification,
            ),
            _QuickActionCard(
              icon: Icons.message,
              label: 'Mesej Selamat Datang',
              color: Colors.purple,
              onTap: onManageWelcomeMessage,
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  textAlign: TextAlign.center,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

