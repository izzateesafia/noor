import 'package:flutter/material.dart';
import '../theme_constants.dart';
import 'ad_form_page.dart';
import '../models/ad.dart';

class ManageAdsPage extends StatefulWidget {
  const ManageAdsPage({super.key});

  @override
  State<ManageAdsPage> createState() => _ManageAdsPageState();
}

class _ManageAdsPageState extends State<ManageAdsPage> {
  List<Ad> ads = [
    Ad(
      title: 'Special Ramadan Sale!',
      image: 'assets/images/ad_ramadan.png',
      link: 'https://ramadansale.com',
    ),
    Ad(
      title: 'Quran App Premium',
      image: 'assets/images/ad_premium.png',
      link: 'https://quranapp.com/premium',
    ),
  ];

  Future<void> _addAd() async {
    final newAd = await Navigator.of(context).push<Ad>(
      MaterialPageRoute(builder: (context) => const AdFormPage()),
    );
    if (newAd != null) {
      setState(() {
        ads.add(newAd);
      });
    }
  }

  Future<void> _editAd(int index) async {
    final editedAd = await Navigator.of(context).push<Ad>(
      MaterialPageRoute(builder: (context) => AdFormPage(initialAd: ads[index])),
    );
    if (editedAd != null) {
      setState(() {
        ads[index] = editedAd;
      });
    }
  }

  void _deleteAd(int index) {
    setState(() {
      ads.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Advertisements'),
        backgroundColor: AppColors.appBar,
        foregroundColor: AppColors.onAppBar,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Advertisement',
            onPressed: _addAd,
          ),
        ],
      ),
      backgroundColor: AppColors.background,
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        itemCount: ads.length,
        itemBuilder: (context, i) {
          final ad = ads[i];
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkCard : AppColors.lightCard,
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      // todo add a dummy-photo
                      ad.image ?? 'assets/images/dummy-photo.png',
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ad.title,
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.text,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          //todo adddummy link if link is broken
                          ad.link ?? 'http dummy',

                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.orange),
                        tooltip: 'Edit',
                        onPressed: () => _editAd(i),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Delete',
                        onPressed: () => _deleteAd(i),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
} 