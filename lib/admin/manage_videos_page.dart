import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../theme_constants.dart';
import '../models/video.dart';
import '../cubit/video_cubit.dart';
import '../cubit/video_states.dart';
import '../repository/video_repository.dart';
import '../utils/seed_dummy_videos.dart';
import 'video_form_page.dart';

class ManageVideosPage extends StatelessWidget {
  const ManageVideosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => VideoCubit(VideoRepository())..fetchVideos(),
      child: const _ManageVideosView(),
    );
  }
}

class _ManageVideosView extends StatelessWidget {
  const _ManageVideosView();

  Future<void> _addVideo(BuildContext context) async {
    final newVideo = await Navigator.of(context).push<Video>(
      MaterialPageRoute(builder: (context) => const VideoFormPage()),
    );
    if (newVideo != null) {
      context.read<VideoCubit>().addVideo(newVideo);
    }
  }

  Future<void> _editVideo(BuildContext context, Video video) async {
    final editedVideo = await Navigator.of(context).push<Video>(
      MaterialPageRoute(builder: (context) => VideoFormPage(initialVideo: video)),
    );
    if (editedVideo != null) {
      context.read<VideoCubit>().updateVideo(editedVideo);
    }
  }

  void _deleteVideo(BuildContext context, Video video) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Video'),
        content: Text('Are you sure you want to delete "${video.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<VideoCubit>().deleteVideo(video.id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Videos'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: BlocBuilder<VideoCubit, VideoState>(
        builder: (context, state) {
          if (state.status == VideoStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == VideoStatus.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text('Error: ${state.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<VideoCubit>().fetchVideos(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state.videos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.video_library_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text('No videos yet'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _addVideo(context),
                    child: const Text('Add First Video'),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await seedDummyVideos();
                      if (context.mounted) {
                        context.read<VideoCubit>().fetchVideos();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Dummy videos added successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Add Dummy Videos (for testing)'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.videos.length,
            itemBuilder: (context, index) {
              final video = state.videos[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: video.thumbnailUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            video.thumbnailUrl,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey[300],
                                child: const Icon(Icons.video_library),
                              );
                            },
                          ),
                        )
                      : Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey[300],
                          child: const Icon(Icons.video_library),
                        ),
                  title: Text(video.title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (video.category != null) Text('Category: ${video.category}'),
                      if (video.views != null) Text('Views: ${video.views}'),
                      if (video.isPremium)
                        const Text('Premium', style: TextStyle(color: Colors.amber)),
                    ],
                  ),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editVideo(context, video);
                      } else if (value == 'delete') {
                        _deleteVideo(context, video);
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addVideo(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

