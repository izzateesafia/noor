import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'cubit/hadith_cubit.dart';
import 'cubit/hadith_states.dart';
import 'pages/hadith_post_page.dart';

class HadithsPage extends StatefulWidget {
  const HadithsPage({super.key});

  @override
  State<HadithsPage> createState() => _HadithsPageState();
}

class _HadithsPageState extends State<HadithsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HadithCubit>().fetchHadiths();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Use existing HadithCubit from parent context if available, otherwise create new one
    return BlocProvider.value(
      value: context.read<HadithCubit>(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Hadis'),
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: BlocBuilder<HadithCubit, HadithState>(
          builder: (context, state) {
            if (state.status == HadithStatus.loading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (state.status == HadithStatus.error) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Gagal memuatkan hadis',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.error ?? 'Sila cuba lagi',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        context.read<HadithCubit>().fetchHadiths();
                      },
                      child: const Text('Cuba Lagi'),
                    ),
                  ],
                ),
              );
            }

            final visibleHadiths = state.hadiths.where((h) => !h.isHidden).toList();
            if (visibleHadiths.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.book_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Tiada hadis',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Belum ada hadis yang tersedia',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<HadithCubit>().fetchHadiths();
              },
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                itemCount: visibleHadiths.length,
                itemBuilder: (context, index) {
                  final hadith = visibleHadiths[index];
                  return InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => HadithPostPage(hadith: hadith),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    color: Theme.of(context).cardColor,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (hadith.image != null && hadith.image!.isNotEmpty)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: _buildHadithImage(context, hadith.image!),
                                ),
                              const SizedBox(width: 18),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      hadith.title,
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                    ),
                                    if (hadith.source != null || hadith.book != null) ...[
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          hadith.source != null && hadith.book != null
                                              ? '${hadith.source} - ${hadith.book}'
                                              : hadith.source ?? hadith.book ?? '',
                                          style: TextStyle(
                                            color: Theme.of(context).colorScheme.primary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            hadith.content,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5, fontSize: 13),
                          ),
                          if (hadith.narrator != null || hadith.source != null || hadith.book != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (hadith.narrator != null) ...[
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.person,
                                          size: 16,
                                          color: Theme.of(context).iconTheme.color?.withOpacity(0.6) ?? Colors.grey,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Diriwayatkan oleh: ${hadith.narrator}',
                                            style: TextStyle(
                                              color: Theme.of(context).iconTheme.color?.withOpacity(0.6) ?? Colors.grey,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (hadith.source != null || hadith.book != null) const SizedBox(height: 8),
                                  ],
                                  if (hadith.source != null || hadith.book != null)
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.source,
                                          size: 16,
                                          color: Theme.of(context).iconTheme.color?.withOpacity(0.6) ?? Colors.grey,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            hadith.source != null && hadith.book != null
                                                ? '${hadith.source} - ${hadith.book}'
                                                : hadith.source ?? hadith.book ?? '',
                                            style: TextStyle(
                                              color: Theme.of(context).iconTheme.color?.withOpacity(0.6) ?? Colors.grey,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHadithImage(BuildContext context, String imagePath) {
    if (imagePath.startsWith('assets/')) {
      return Image.asset(
        imagePath,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorImage(context);
        },
      );
    } else if (imagePath.startsWith('/data/') || imagePath.startsWith('file://')) {
      final file = File(imagePath.replaceFirst('file://', ''));
      if (file.existsSync()) {
        return Image.file(
          file,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildErrorImage(context);
          },
        );
      }
    } else {
      // Assume it's a network image
      return Image.network(
        imagePath,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorImage(context);
        },
      );
    }
    return _buildErrorImage(context);
  }

  Widget _buildErrorImage(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        Icons.book,
        color: Theme.of(context).colorScheme.primary,
        size: 40,
      ),
    );
  }
} 