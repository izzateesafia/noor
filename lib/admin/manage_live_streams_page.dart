import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/live_stream_cubit.dart';
import '../cubit/live_stream_states.dart';
import '../models/live_stream.dart';
import '../repository/live_stream_repository.dart';
import 'live_stream_form_page.dart';

class ManageLiveStreamsPage extends StatelessWidget {
  const ManageLiveStreamsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LiveStreamCubit(
        context.read<LiveStreamRepository>(),
      )..getAllLiveStreams(),
      child: const _ManageLiveStreamsView(),
    );
  }
}

class _ManageLiveStreamsView extends StatelessWidget {
  const _ManageLiveStreamsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Urus Siaran Langsung'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const LiveStreamFormPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<LiveStreamCubit, LiveStreamState>(
        listener: (context, state) {
          if (state is LiveStreamSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
            context.read<LiveStreamCubit>().clearMessage();
          } else if (state is LiveStreamError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
            context.read<LiveStreamCubit>().clearMessage();
          }
        },
        builder: (context, state) {
          if (state is LiveStreamLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is LiveStreamLoaded) {
            return _buildLiveStreamsList(context, state.allLiveStreams);
          }

          return const Center(child: Text('Tiada siaran langsung dijumpai'));
        },
      ),
    );
  }

  Widget _buildLiveStreamsList(BuildContext context, List<LiveStream> liveStreams) {
    if (liveStreams.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.live_tv,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'Belum ada siaran langsung',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap the + button to add your first live stream',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: liveStreams.length,
      itemBuilder: (context, index) {
        final liveStream = liveStreams[index];
        return Opacity(
          opacity: !liveStream.isActive ? 0.6 : 1.0,
          child: Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: liveStream.isActive 
                    ? Colors.green.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                child: Icon(
                  liveStream.isActive ? Icons.live_tv : Icons.tv_off,
                  color: liveStream.isActive ? Colors.green : Colors.grey,
                ),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      liveStream.title,
                      style: TextStyle(
                        fontWeight: liveStream.isActive ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (!liveStream.isActive)
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
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(liveStream.description),
                const SizedBox(height: 4),
                Text(
                  liveStream.isActive ? '🟢 Active' : '⚫ Inactive',
                  style: TextStyle(
                    color: liveStream.isActive ? Colors.green : Colors.grey,
                    fontSize: 12,
                  ),
                ),
                Text(
                  'Created: ${_formatDate(liveStream.createdAt)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
              ),
              onSelected: (value) => _handleMenuAction(context, value, liveStream),
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
                  value: liveStream.isActive ? 'deactivate' : 'activate',
                  child: Row(
                    children: [
                      Icon(
                        liveStream.isActive ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(liveStream.isActive ? 'Sembunyikan' : 'Tunjukkan'),
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
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => LiveStreamFormPage(liveStream: liveStream),
                ),
              );
            },
          ),
        ));
      },
    );
  }

  void _duplicateLiveStream(BuildContext context, LiveStream liveStream) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Salin Siaran Langsung'),
        content: Text('Adakah anda pasti mahu menyalin "${liveStream.title}"?'),
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
      final duplicatedLiveStream = LiveStream(
        id: DateTime.now().millisecondsSinceEpoch.toString(), // New ID
        title: '${liveStream.title} (Copy)',
        description: liveStream.description,
        tiktokLiveLink: liveStream.tiktokLiveLink,
        isActive: false, // Start as inactive
        createdAt: DateTime.now(),
      );
      
      try {
        context.read<LiveStreamCubit>().addLiveStream(
          title: duplicatedLiveStream.title,
          description: duplicatedLiveStream.description,
          tiktokLiveLink: duplicatedLiveStream.tiktokLiveLink,
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Siaran langsung "${liveStream.title}" telah disalin'),
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
              content: Text('Ralat menyalin siaran langsung: $e'),
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

  void _handleMenuAction(BuildContext context, String action, LiveStream liveStream) {
    switch (action) {
      case 'edit':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => LiveStreamFormPage(liveStream: liveStream),
          ),
        );
        break;
      case 'duplicate':
        _duplicateLiveStream(context, liveStream);
        break;
      case 'activate':
        context.read<LiveStreamCubit>().activateLiveStream(liveStream.id);
        break;
      case 'deactivate':
        final updatedLiveStream = liveStream.copyWith(isActive: false);
        context.read<LiveStreamCubit>().updateLiveStream(updatedLiveStream);
        break;
      case 'delete':
        _showDeleteDialog(context, liveStream);
        break;
    }
  }

  void _showDeleteDialog(BuildContext context, LiveStream liveStream) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Live Stream'),
        content: Text('Are you sure you want to delete "${liveStream.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<LiveStreamCubit>().deleteLiveStream(liveStream.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
} 