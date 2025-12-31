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
            child: Text(
              'Delete',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _duplicateVideo(BuildContext context, Video video) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Duplicate Video'),
        content: Text('Are you sure you want to duplicate "${video.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
            child: const Text('Duplicate'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final duplicatedVideo = video.copyWith(
        id: '', // New ID will be generated
        title: '${video.title} (Copy)',
        isFeatured: false,
        isPopular: false,
        isForYou: false,
      );
      context.read<VideoCubit>().addVideo(duplicatedVideo);
    }
  }

  void _toggleHideVideo(BuildContext context, Video video) {
    final newVideo = video.copyWith(isHidden: !video.isHidden);
    context.read<VideoCubit>().updateVideo(newVideo);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          video.isHidden ? 'Video is now visible' : 'Video is now hidden',
        ),
        backgroundColor: Colors.green, // Success color - keep as is
      ),
    );
  }

  void _showSectionSelector(BuildContext context, Video video) {
    showDialog(
      context: context,
      builder: (ctx) => _SectionSelectorDialog(
        video: video,
        onSave: (isFeatured, isPopular, isForYou) async {
          final updatedVideo = video.copyWith(
            isFeatured: isFeatured,
            isPopular: isPopular,
            isForYou: isForYou,
          );
          
          await context.read<VideoCubit>().updateVideo(updatedVideo);
          if (ctx.mounted) {
            Navigator.of(ctx).pop();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Video sections updated successfully'),
                  backgroundColor: Colors.green, // Success color - keep as is
                ),
              );
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Videos'),
        backgroundColor: AppColors.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: Stack(
        children: [
          BlocBuilder<VideoCubit, VideoState>(
            builder: (context, state) {
              if (state.status == VideoStatus.loading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state.status == VideoStatus.error) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64,
                          color: Theme.of(context).colorScheme.error),
                      const SizedBox(height: 16),
                      Text('Error: ${state.error}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () =>
                            context.read<VideoCubit>().fetchVideos(),
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
                      Icon(Icons.video_library_outlined, size: 64,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
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
                                content: Text(
                                    'Dummy videos added successfully!'),
                                backgroundColor: Colors.green, // Success color - keep as is // Success color - keep as is
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
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
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
                      title: Row(
                        children: [
                          Expanded(child: Text(video.title)),
                          if (video.isHidden)
                            Icon(Icons.visibility_off, size: 16,
                                color: Colors.grey[600]),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (video.category != null) Text(
                              'Category: ${video.category}'),
                          if (video.views != null) Text(
                              'Views: ${video.views}'),
                          Wrap(
                            spacing: 8,
                            children: [
                              if (video.isPremium)
                                Chip(
                                  label: const Text('Premium',
                                      style: TextStyle(fontSize: 10)),
                                  backgroundColor: Colors.amber,
                                  padding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.compact,
                                ),
                              if (video.isFeatured)
                                Chip(
                                  label: const Text('Featured',
                                      style: TextStyle(fontSize: 10)),
                                  backgroundColor: Colors.blue[100],
                                  padding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.compact,
                                ),
                              if (video.isPopular)
                                Chip(
                                  label: const Text('Popular',
                                      style: TextStyle(fontSize: 10)),
                                  backgroundColor: Colors.green[100],
                                  padding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.compact,
                                ),
                              if (video.isForYou)
                                Chip(
                                  label: const Text('For You',
                                      style: TextStyle(fontSize: 10)),
                                  backgroundColor: Colors.purple[100],
                                  padding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.compact,
                                ),
                            ],
                          ),
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert,
                          color: Theme
                              .of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.6),
                        ),
                        onSelected: (value) {
                          switch (value) {
                            case 'edit':
                              _editVideo(context, video);
                              break;
                            case 'duplicate':
                              _duplicateVideo(context, video);
                              break;
                            case 'hide':
                              _toggleHideVideo(context, video);
                              break;
                            case 'sections':
                              _showSectionSelector(context, video);
                              break;
                            case 'delete':
                              _deleteVideo(context, video);
                              break;
                          }
                        },
                        itemBuilder: (context) =>
                        [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(
                                    Icons.edit, color: Colors.orange, size: 20),
                                const SizedBox(width: 12),
                                const Text('Edit'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'duplicate',
                            child: Row(
                              children: [
                                Icon(Icons.copy, color: Colors.blue, size: 20),
                                const SizedBox(width: 12),
                                const Text('Duplicate'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'sections',
                            child: Row(
                              children: [
                                Icon(Icons.category, color: Colors.purple,
                                    size: 20),
                                const SizedBox(width: 12),
                                const Text('Select Sections'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'hide',
                            child: Row(
                              children: [
                                Icon(
                                  video.isHidden ? Icons.visibility : Icons
                                      .visibility_off,
                                  color: Colors.grey,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Text(video.isHidden ? 'Show' : 'Hide'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red, size: 20),
                                const SizedBox(width: 12),
                                const Text('Delete',
                                    style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
              // Floating + button at top right
              Positioned(
                top: 8,
                right: 16,
                child: FloatingActionButton(
                  onPressed: () => _addVideo(context),
                  backgroundColor: AppColors.primary,
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              );
            }),
      ]),
    );
  }
}

class _SectionSelectorDialog extends StatefulWidget {
  final Video video;
  final Future<void> Function(bool isFeatured, bool isPopular, bool isForYou) onSave;

  const _SectionSelectorDialog({
    required this.video,
    required this.onSave,
  });

  @override
  State<_SectionSelectorDialog> createState() => _SectionSelectorDialogState();
}

class _SectionSelectorDialogState extends State<_SectionSelectorDialog> {
  late bool _isFeatured;
  late bool _isPopular;
  late bool _isForYou;

  @override
  void initState() {
    super.initState();
    _isFeatured = widget.video.isFeatured;
    _isPopular = widget.video.isPopular;
    _isForYou = widget.video.isForYou;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Select Sections for "${widget.video.title}"'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CheckboxListTile(
            title: const Text('Featured'),
            value: _isFeatured,
            onChanged: (value) {
              setState(() {
                _isFeatured = value ?? false;
              });
            },
          ),
          CheckboxListTile(
            title: const Text('Popular'),
            value: _isPopular,
            onChanged: (value) {
              setState(() {
                _isPopular = value ?? false;
              });
            },
          ),
          CheckboxListTile(
            title: const Text('For You'),
            value: _isForYou,
            onChanged: (value) {
              setState(() {
                _isForYou = value ?? false;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            await widget.onSave(_isFeatured, _isPopular, _isForYou);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

