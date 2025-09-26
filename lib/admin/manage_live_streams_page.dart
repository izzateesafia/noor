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
        return Card(
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
            title: Text(
              liveStream.title,
              style: TextStyle(
                fontWeight: liveStream.isActive ? FontWeight.bold : FontWeight.normal,
              ),
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
              onSelected: (value) => _handleMenuAction(context, value, liveStream),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                if (!liveStream.isActive)
                  const PopupMenuItem(
                    value: 'activate',
                    child: Row(
                      children: [
                        Icon(Icons.play_arrow, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Activate'),
                      ],
                    ),
                  ),
                if (liveStream.isActive)
                  const PopupMenuItem(
                    value: 'deactivate',
                    child: Row(
                      children: [
                        Icon(Icons.stop, color: Colors.orange),
                        SizedBox(width: 8),
                        Text('Deactivate'),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete'),
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
        );
      },
    );
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