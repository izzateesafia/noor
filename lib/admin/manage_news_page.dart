import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
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

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<NewsCubit, NewsState>(
      listener: (context, state) {
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ralat: ${state.error}'),
              backgroundColor: Colors.red,
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
                        Theme.of(context).appBarTheme.foregroundColor ?? Colors.white,
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
        return Slidable(
          key: ValueKey(news.id),
          endActionPane: ActionPane(
            motion: const DrawerMotion(),
            children: [
              SlidableAction(
                onPressed: (context) => _addOrEditNews(news: news),
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                icon: Icons.edit,
                label: 'Edit',
              ),
              SlidableAction(
                onPressed: (context) => _deleteNews(news),
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                icon: Icons.delete,
                label: 'Padam',
              ),
            ],
          ),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: Theme.of(context).cardColor,
            margin: const EdgeInsets.only(bottom: 18),
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
              title: Text(
                news.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
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

