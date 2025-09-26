import 'package:flutter/material.dart';
import 'theme_constants.dart';

class PremiumPage extends StatelessWidget {
  const PremiumPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<String> benefits = [
      'Buka kunci semua video Rukun Solat',
      'Akses kandungan dan ciri eksklusif',
      'Pengalaman tanpa iklan',
      'Sokongan keutamaan',
    ];
    final List<_PremiumPlan> plans = [
      _PremiumPlan(name: 'Bulanan', price: 'RM 9.90', description: 'Ditagih bulanan, batal bila-bila masa'),
      _PremiumPlan(name: 'Tahunan', price: 'RM 99.00', description: 'Jimat 17% berbanding bulanan'),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pelan Premium'),
        backgroundColor: AppColors.appBar,
        foregroundColor: AppColors.onAppBar,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Icon(Icons.star_rounded, color: AppColors.primary, size: 64),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Jadi Premium',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 20),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Buka kunci semua ciri dan sokong Al-Quran Harian!',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Premium Benefits',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 15),
            ),
            const SizedBox(height: 12),
            ...benefits.map((b) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: AppColors.primary, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          b,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 32),
            Text(
              'Choose Your Plan',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 15),
            ),
            const SizedBox(height: 16),
            ...plans.map((plan) => _PremiumPlanCard(plan: plan)),
            const SizedBox(height: 32),
            Center(
              child: TextButton(
                onPressed: () {
                  // TODO: Implement restore purchase
                },
                child: const Text('Restore Purchase'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumPlan {
  final String name;
  final String price;
  final String description;
  const _PremiumPlan({required this.name, required this.price, required this.description});
}

class _PremiumPlanCard extends StatelessWidget {
  final _PremiumPlan plan;
  const _PremiumPlanCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Theme.of(context).cardColor,
      margin: const EdgeInsets.only(bottom: 18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        child: Row(
          children: [
            Icon(Icons.workspace_premium, color: AppColors.primary, size: 32),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    plan.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 18),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
              onPressed: () {
                // TODO: Implement purchase logic
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Purchase'),
                    content: Text('You selected the ${plan.name} plan.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
              child: Text('Buy'),
            ),
          ],
        ),
      ),
    );
  }
} 