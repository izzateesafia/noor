import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/news.dart';
import '../theme_constants.dart';
import '../cubit/news_cubit.dart';
import '../cubit/news_states.dart';
import '../repository/news_repository.dart';
import 'news_form_page.dart';
import 'dart:io';

class ManageNewsPage extends StatefulWidget {
  const ManageNewsPage({super.key});

  @override
  State<ManageNewsPage> createState() => _ManageNewsPageState();
}

class _ManageNewsPageState extends State<ManageNewsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NewsCubit>().fetchNews();
    });
  }

  void _addOrEditNews({News? news}) async {
    // Navigate to form page - it will handle saving via NewsCubit
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: context.read<NewsCubit>(),
          child: NewsFormPage(initialNews: news),
        ),
      ),
    );
    // Refresh news list after returning from form
    context.read<NewsCubit>().fetchNews();
  }

  void _duplicateNews(News news) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).dialogBackgroundColor,
        title: Text(
          'Salin Berita',
          style: TextStyle(color: Theme.of(context).textTheme.titleLarge?.color),
        ),
        content: Text(
          'Adakah anda pasti mahu menyalin "${news.title}"?',
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Batal',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
            child: const Text('Salin'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      // Create a duplicate news item with a new ID
      final duplicatedNews = News(
        title: '${news.title} (Copy)',
        description: news.description,
        image: news.image,
        link: news.link,
        isActive: news.isActive,
        order: news.order,
      );
      
      try {
        context.read<NewsCubit>().addNews(duplicatedNews);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Berita "${news.title}" telah disalin'),
              backgroundColor: Colors.green, // Success color - keep as is
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ralat menyalin berita: $e'),
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

  void _deleteNews(News news) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).dialogBackgroundColor,
        title: Text(
          'Padam Berita',
          style: TextStyle(color: Theme.of(context).textTheme.titleLarge?.color),
        ),
        content: Text(
          'Adakah anda pasti mahu memadam "${news.title}"?',
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Batal',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Padam'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      context.read<NewsCubit>().deleteNews(news.id!);
    }
  }

  void _toggleHideNews(News news) async {
    try {
      context.read<NewsCubit>().updateNews(
        news.copyWith(isActive: !news.isActive),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(news.isActive 
              ? 'Berita telah disembunyikan daripada pengguna'
              : 'Berita telah ditunjukkan kepada pengguna'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ralat mengemas kini berita: $e'),
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

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<NewsCubit, NewsState>(
      listener: (context, state) {
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ralat: ${state.error}'),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Urus Berita Terkini'),
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
            foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
            actions: [
              if (state.isLoading)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: _buildBody(state),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: state.isLoading ? null : () => _addOrEditNews(),
            icon: const Icon(Icons.add),
            label: const Text('Tambah Berita'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        );
      },
    );
  }

  Widget _buildBody(NewsState state) {
    if (state.isLoading && state.news.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Memuatkan berita...',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ],
        ),
      );
    }

    if (state.news.isEmpty) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.article,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Tiada berita',
              style: TextStyle(
                fontSize: 18,
                color: Theme.of(context).textTheme.titleLarge?.color?.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tambah berita pertama menggunakan butang +',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      itemCount: state.news.length,
      itemBuilder: (context, index) {
        final news = state.news[index];
        return Opacity(
          opacity: !news.isActive ? 0.6 : 1.0,
          child: Card(
            key: ValueKey(news.id),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: Theme.of(context).cardColor,
            margin: const EdgeInsets.only(bottom: 18),
            child: InkWell(
              onTap: () => _addOrEditNews(news: news),
              borderRadius: BorderRadius.circular(16),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: news.image != null && news.image!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _buildNewsImage(news.image!),
                      )
                    : Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.article,
                          color: Theme.of(context).colorScheme.primary,
                          size: 30,
                        ),
                      ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        news.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                      ),
                    ),
                    if (!news.isActive)
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
              subtitle: news.description != null
                  ? Text(
                      news.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8),
                            fontSize: 13,
                          ),
                    )
                  : null,
              trailing: PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
                ),
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _addOrEditNews(news: news);
                      break;
                    case 'duplicate':
                      _duplicateNews(news);
                      break;
                    case 'hide':
                      _toggleHideNews(news);
                      break;
                    case 'delete':
                      _deleteNews(news);
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
                        const Icon(
                          Icons.copy,
                          color: Colors.blue,
                          size: 20,
                        ),
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
                          news.isActive ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(news.isActive ? 'Sembunyikan' : 'Tunjukkan'),
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
            ),
          ),
        ),
        );
      },
    );
  }

  Widget _buildNewsImage(String imagePath) {
    if (imagePath.startsWith('assets/')) {
      return Image.asset(
        imagePath,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 60,
            height: 60,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            child: Icon(
              Icons.article,
              color: Theme.of(context).colorScheme.primary,
              size: 30,
            ),
          );
        },
      );
    } else if (File(imagePath).existsSync()) {
      return Image.file(
        File(imagePath),
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 60,
            height: 60,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            child: Icon(
              Icons.article,
              color: Theme.of(context).colorScheme.primary,
              size: 30,
            ),
          );
        },
      );
    } else {
      return Image.network(
        imagePath,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 60,
            height: 60,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            child: Icon(
              Icons.article,
              color: Theme.of(context).colorScheme.primary,
              size: 30,
            ),
          );
        },
      );
    }
  }
}

