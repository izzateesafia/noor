import 'package:flutter/material.dart';
import '../theme_constants.dart';
import 'hadith_form_page.dart';

class ManageHadithsPage extends StatefulWidget {
  const ManageHadithsPage({super.key});

  @override
  State<ManageHadithsPage> createState() => _ManageHadithsPageState();
}

class _ManageHadithsPageState extends State<ManageHadithsPage> {
  List<Hadith> hadiths = [
    Hadith(
      title: 'Hadith on Intentions',
      content: 'Actions are judged by intentions...',
      image: 'assets/images/hadith_intentions.png',
      link: 'https://hadiths.com/intentions',
      notes: 'First hadith in Sahih Bukhari',
    ),
  ];

  Future<void> _addHadith() async {
    final newHadith = await Navigator.of(context).push<Hadith>(
      MaterialPageRoute(builder: (context) => const HadithFormPage()),
    );
    if (newHadith != null) {
      setState(() {
        hadiths.add(newHadith);
      });
    }
  }

  Future<void> _editHadith(int index) async {
    final editedHadith = await Navigator.of(context).push<Hadith>(
      MaterialPageRoute(builder: (context) => HadithFormPage(initialHadith: hadiths[index])),
    );
    if (editedHadith != null) {
      setState(() {
        hadiths[index] = editedHadith;
      });
    }
  }

  void _deleteHadith(int index) {
    setState(() {
      hadiths.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Hadiths'),
        backgroundColor: AppColors.appBar,
        foregroundColor: AppColors.onAppBar,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Hadith',
            onPressed: _addHadith,
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        itemCount: hadiths.length,
        itemBuilder: (context, i) {
          final hadith = hadiths[i];
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
                  if (hadith.image != null && hadith.image!.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        hadith.image!,
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
                          hadith.title,
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.text,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          hadith.content,
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.text,
                            fontSize: 14,
                          ),
                        ),
                        if (hadith.link != null && hadith.link!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            hadith.link!,
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 13,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                        if (hadith.notes != null && hadith.notes!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Notes: ${hadith.notes!}',
                            style: TextStyle(
                              color: AppColors.disabled,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.orange),
                        tooltip: 'Edit',
                        onPressed: () => _editHadith(i),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Delete',
                        onPressed: () => _deleteHadith(i),
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

class Hadith {
  final String title;
  final String content;
  final String? image;
  final String? link;
  final String? notes;
  const Hadith({required this.title, required this.content, this.image, this.link, this.notes});
} 