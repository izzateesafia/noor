import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/mushaf_model.dart';
import '../repository/mushaf_repository.dart';
import '../cubit/mushaf_cubit.dart';
import '../cubit/mushaf_states.dart';
import '../services/mushaf_download_service.dart';
import '../theme_constants.dart';
import 'pdf_mushaf_viewer_page.dart';

class MushafSelectionPage extends StatelessWidget {
  const MushafSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final cubit = MushafCubit(MushafRepository());
        cubit.fetchMushafs();
        return cubit;
      },
      child: const _MushafSelectionPageContent(),
    );
  }
}

class _MushafSelectionPageContent extends StatefulWidget {
  const _MushafSelectionPageContent();

  @override
  State<_MushafSelectionPageContent> createState() => _MushafSelectionPageState();
}

class _MushafSelectionPageState extends State<_MushafSelectionPageContent> {
  final MushafDownloadService _downloadService = MushafDownloadService();
  List<MushafModel> _filteredMushafs = [];
  String _selectedRiwayah = 'All';
  final TextEditingController _searchController = TextEditingController();
  final Map<String, bool> _cachedStatus = {};

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkCachedStatus(List<MushafModel> mushafs) async {
    final Map<String, bool> status = {};
    for (var mushaf in mushafs) {
      status[mushaf.id] = await _downloadService.isPdfCached(mushaf.id);
    }
    if (mounted) {
      setState(() {
        _cachedStatus.addAll(status);
      });
    }
  }

  void _filterMushafs(List<MushafModel> mushafs) {
    setState(() {
      _filteredMushafs = mushafs.where((mushaf) {
        final matchesRiwayah = _selectedRiwayah == 'All' || mushaf.riwayah == _selectedRiwayah;
        final matchesSearch = _searchController.text.isEmpty ||
            mushaf.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
            mushaf.nameArabic.contains(_searchController.text) ||
            mushaf.description.toLowerCase().contains(_searchController.text.toLowerCase());
        return matchesRiwayah && matchesSearch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MushafCubit, MushafState>(
      builder: (context, state) {
        // Update filtered list when state changes
        if (state.mushafs.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _filterMushafs(state.mushafs);
            _checkCachedStatus(state.mushafs);
          });
        } else if (state.status == MushafStatus.loaded && state.mushafs.isEmpty) {
          // Explicitly handle empty state
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _filteredMushafs = [];
            });
          });
        }

        if (state.status == MushafStatus.loading) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Select Mushaf'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (state.status == MushafStatus.error) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Select Mushaf'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading mushafs',
                    style: TextStyle(color: Colors.red[300]),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.read<MushafCubit>().fetchMushafs(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        return _buildContent(context, state);
      },
    );
  }

  Widget _buildContent(BuildContext context, MushafState state) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Mushaf'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).cardColor,
            child: Column(
              children: [
                // Search Field
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search mushafs...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              final state = context.read<MushafCubit>().state;
                              _filterMushafs(state.mushafs);
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (_) {
                    final state = context.read<MushafCubit>().state;
                    _filterMushafs(state.mushafs);
                  },
                ),
                const SizedBox(height: 12),
                // Riwayah Filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildRiwayahChip(context, 'All'),
                      const SizedBox(width: 8),
                      ...state.riwayahs.map((riwayah) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _buildRiwayahChip(context, riwayah),
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Mushaf List
          Expanded(
            child: _filteredMushafs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          state.mushafs.isEmpty 
                              ? Icons.video_library_outlined 
                              : Icons.search_off, 
                          size: 64, 
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          state.mushafs.isEmpty
                              ? 'No mushafs available\nCheck Firestore connection'
                              : 'No mushafs found\nTry adjusting your search',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        if (state.mushafs.isEmpty) ...[
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () => context.read<MushafCubit>().fetchMushafs(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredMushafs.length,
                    itemBuilder: (context, index) {
                      final mushaf = _filteredMushafs[index];
                      return _buildMushafCard(mushaf);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiwayahChip(BuildContext context, String riwayah) {
    final isSelected = _selectedRiwayah == riwayah;
    return FilterChip(
      label: Text(riwayah),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedRiwayah = riwayah;
        });
        if (riwayah == 'All') {
          context.read<MushafCubit>().clearFilter();
        } else {
          context.read<MushafCubit>().fetchMushafsByRiwayah(riwayah);
        }
      },
      selectedColor: AppColors.primary.withOpacity(0.2),
      checkmarkColor: AppColors.primary,
    );
  }

  Widget _buildMushafCard(MushafModel mushaf) {
    final isCached = _cachedStatus[mushaf.id] ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PDFMushafViewerPage(mushaf: mushaf),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon/Thumbnail
              Container(
                width: 60,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.book,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mushaf.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mushaf.nameArabic,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      mushaf.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Chip(
                          label: Text(
                            mushaf.riwayah,
                            style: const TextStyle(fontSize: 11),
                          ),
                          padding: EdgeInsets.zero,
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          labelStyle: TextStyle(color: AppColors.primary),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${mushaf.totalPages} pages',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (isCached) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Cached',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Arrow Icon
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

