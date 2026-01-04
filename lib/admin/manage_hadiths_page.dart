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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Padam Hadis'),
        content: Text('Adakah anda pasti mahu memadam "${hadith.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Padam'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await context.read<HadithCubit>().deleteHadith(hadith.id);
    }
  }

  void _duplicateHadith(BuildContext context, Hadith hadith) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Salin Hadis'),
        content: Text('Adakah anda pasti mahu menyalin "${hadith.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
            child: const Text('Salin'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      final duplicatedHadith = Hadith(
        id: '', // Empty ID - Firestore will generate a new one
        title: '${hadith.title} (Copy)',
        content: hadith.content,
        image: hadith.image,
        source: hadith.source,
        book: hadith.book,
        narrator: hadith.narrator,
        link: hadith.link,
        notes: hadith.notes,
        uploaded: DateTime.now(),
        isHidden: hadith.isHidden,
      );
      
      try {
        await context.read<HadithCubit>().addHadith(duplicatedHadith);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Hadis "${hadith.title}" telah disalin'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ralat menyalin hadis: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      }
    }
  }

  void _toggleHideHadith(BuildContext context, Hadith hadith) async {
    try {
      await context.read<HadithCubit>().updateHadith(
        hadith.copyWith(isHidden: !hadith.isHidden),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(hadith.isHidden 
              ? 'Hadis telah ditunjukkan kepada pengguna'
              : 'Hadis telah disembunyikan daripada pengguna'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ralat mengemas kini hadis: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  Widget _buildHadithImage(String imageUrl) {
    // Check if it's a network URL (Firebase Storage)
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return Image.network(
        imageUrl,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
                color: AppColors.primary,
              ),
            ),
          );
        },
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
      );
    }
    // Check if it's an asset
    else if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
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
      );
    }
    // Otherwise, treat as local file
    else {
      return Image.file(
        File(imageUrl),
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
      );
    }
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
                  Icon(
                    Icons.error,
                    color: Theme.of(context).colorScheme.error,
                    size: 48,
                  ),
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
              return Opacity(
                opacity: hadith.isHidden ? 0.6 : 1.0,
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  color: Theme.of(context).cardColor,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (hadith.image != null && hadith.image!.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: _buildHadithImage(hadith.image!),
                          ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      hadith.title,
                                      style: TextStyle(
                                        color: Theme.of(context).textTheme.bodyLarge?.color,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  if (hadith.isHidden)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.grey,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        'Disembunyikan',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                hadith.content,
                                style: TextStyle(
                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                  fontSize: 14,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
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
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: Icon(
                            Icons.more_vert,
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
                          ),
                          onSelected: (value) {
                            switch (value) {
                              case 'edit':
                                _editHadith(context, hadith);
                                break;
                              case 'duplicate':
                                _duplicateHadith(context, hadith);
                                break;
                              case 'hide':
                                _toggleHideHadith(context, hadith);
                                break;
                              case 'delete':
                                _deleteHadith(context, hadith);
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  const Icon(Icons.edit, color: Colors.orange, size: 20),
                                  const SizedBox(width: 12),
                                  const Text('Edit'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'duplicate',
                              child: Row(
                                children: [
                                  const Icon(Icons.copy, color: Colors.blue, size: 20),
                                  const SizedBox(width: 12),
                                  const Text('Duplicate'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'hide',
                              child: Row(
                                children: [
                                  Icon(
                                    hadith.isHidden ? Icons.visibility : Icons.visibility_off,
                                    color: Colors.grey,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(hadith.isHidden ? 'Tunjukkan' : 'Sembunyikan'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete,
                                    color: Theme.of(context).colorScheme.error,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  const Text('Padam'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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