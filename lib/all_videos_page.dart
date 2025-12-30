import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'cubit/video_cubit.dart';
import 'cubit/video_states.dart';
import 'repository/video_repository.dart';
import 'models/video.dart';
import 'theme_constants.dart';
import 'cubit/user_cubit.dart';
import 'videos_page.dart'; // Reuse VideoCard

class AllVideosPage extends StatefulWidget {
  const AllVideosPage({super.key});

  @override
  State<AllVideosPage> createState() => _AllVideosPageState();
}

class _AllVideosPageState extends State<AllVideosPage> {
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final cubit = VideoCubit(VideoRepository());
        cubit.fetchVideos();
        cubit.fetchCategories();
        return cubit;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('All Videos'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: Column(
          children: [
            // Category tabs
            BlocBuilder<VideoCubit, VideoState>(
              builder: (context, state) {
                if (state.categories.isEmpty) {
                  return const SizedBox.shrink();
                }

                return Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: state.categories.length + 1, // +1 for "All" tab
                    itemBuilder: (context, index) {
                      final isAllTab = index == 0;
                      final category = isAllTab ? null : state.categories[index - 1];
                      final isSelected = _selectedCategory == category;

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(isAllTab ? 'All' : category!),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = isAllTab ? null : category;
                            });
                            context.read<VideoCubit>().filterByCategory(_selectedCategory);
                          },
                          selectedColor: AppColors.primary,
                          checkmarkColor: Colors.white,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            // Videos grid
            Expanded(
              child: BlocBuilder<VideoCubit, VideoState>(
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
                          Text(
                            'Error loading videos',
                            style: TextStyle(color: Colors.red[300], fontSize: 18),
                          ),
                          if (state.error != null) ...[
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                state.error!,
                                style: TextStyle(color: Colors.red[200], fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => context.read<VideoCubit>().fetchVideos(),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  // Filter out hidden videos
                  final visibleVideos = state.videos.where((v) => !v.isHidden).toList();

                  if (visibleVideos.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.video_library_outlined, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            _selectedCategory == null
                                ? 'No videos available'
                                : 'No videos in this category',
                            style: TextStyle(color: Colors.grey[600], fontSize: 18),
                          ),
                        ],
                      ),
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: visibleVideos.length,
                    itemBuilder: (context, index) {
                      final video = visibleVideos[index];
                      // Reuse the VideoCard from videos_page.dart
                      return VideoCard(video: video, isHorizontal: false);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

