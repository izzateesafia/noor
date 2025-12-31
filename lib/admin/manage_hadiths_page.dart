import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/hadith_cubit.dart';
import '../cubit/hadith_states.dart';
import '../models/hadith.dart';
import '../theme_constants.dart';
import 'hadith_form_page.dart';

class ManageHadithsPage extends StatefulWidget {
  const ManageHadithsPage({super.key});

  @override
  State<ManageHadithsPage> createState() => _ManageHadithsPageState();
}

class _ManageHadithsPageState extends State<ManageHadithsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HadithCubit>().fetchHadiths();
    });
  }

  Future<void> _addHadith(BuildContext context) async {
    final newHadith = await Navigator.of(context).push<Hadith>(
      MaterialPageRoute(builder: (context) => const HadithFormPage()),
    );
    if (newHadith != null) {
      await context.read<HadithCubit>().addHadith(newHadith);
    }
  }

  Future<void> _editHadith(BuildContext context, Hadith hadith) async {
    final editedHadith = await Navigator.of(context).push<Hadith>(
      MaterialPageRoute(builder: (context) => HadithFormPage(initialHadith: hadith)),
    );
    if (editedHadith != null) {
      await context.read<HadithCubit>().updateHadith(editedHadith.copyWith(id: hadith.id));
    }
  }

  Future<void> _deleteHadith(BuildContext context, Hadith hadith) async {
    await context.read<HadithCubit>().deleteHadith(hadith.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Urus Hadis'),
        backgroundColor: AppColors.appBar,
        foregroundColor: AppColors.onAppBar,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Tambah Hadis',
            onPressed: () => _addHadith(context),
          ),
        ],
      ),
      body: BlocBuilder<HadithCubit, HadithState>(
        builder: (context, state) {
          if (state.status == HadithStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state.status == HadithStatus.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(state.error ?? 'Error loading hadiths'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<HadithCubit>().fetchHadiths(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          } else if (state.hadiths.isEmpty) {
            return Center(
              child: Text(
                'Tiada hadis yet',
                style: TextStyle(color: AppColors.disabled, fontSize: 18),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            itemCount: state.hadiths.length,
            itemBuilder: (context, i) {
              final hadith = state.hadiths[i];
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
                          child: hadith.image!.startsWith('assets/')
                              ? Image.asset(
                                  hadith.image!,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.book,
                                        color: AppColors.primary,
                                        size: 40,
                                      ),
                                    );
                                  },
                                )
                              : Image.file(
                                  File(hadith.image!),
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.book,
                                        color: AppColors.primary,
                                        size: 40,
                                      ),
                                    );
                                  },
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
                            onPressed: () => _editHadith(context, hadith),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            tooltip: 'Delete',
                            onPressed: () => _deleteHadith(context, hadith),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}