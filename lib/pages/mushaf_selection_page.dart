import 'package:flutter/material.dart';
import '../models/mushaf_model.dart';
import '../repository/mushaf_repository.dart';
import '../services/mushaf_download_service.dart';
import '../theme_constants.dart';
import 'pdf_mushaf_viewer_page.dart';

class MushafSelectionPage extends StatefulWidget {
  const MushafSelectionPage({super.key});

  @override
  State<MushafSelectionPage> createState() => _MushafSelectionPageState();
}

class _MushafSelectionPageState extends State<MushafSelectionPage> {
  final MushafRepository _repository = MushafRepository();
  final MushafDownloadService _downloadService = MushafDownloadService();
  List<MushafModel> _mushafs = [];
  List<MushafModel> _filteredMushafs = [];
  String _selectedRiwayah = 'All';
  final TextEditingController _searchController = TextEditingController();
  final Map<String, bool> _cachedStatus = {};

  @override
  void initState() {
    super.initState();
    _loadMushafs();
    _checkCachedStatus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadMushafs() {
    setState(() {
      _mushafs = _repository.getAllMushafs();
      _filteredMushafs = _mushafs;
    });
  }

  Future<void> _checkCachedStatus() async {
    final Map<String, bool> status = {};
    for (var mushaf in _mushafs) {
      status[mushaf.id] = await _downloadService.isPdfCached(mushaf.id);
    }
    setState(() {
      _cachedStatus.addAll(status);
    });
  }

  void _filterMushafs() {
    setState(() {
      _filteredMushafs = _mushafs.where((mushaf) {
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
                              _filterMushafs();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (_) => _filterMushafs(),
                ),
                const SizedBox(height: 12),
                // Riwayah Filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildRiwayahChip('All'),
                      const SizedBox(width: 8),
                      ..._repository.getAllRiwayahs().map((riwayah) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _buildRiwayahChip(riwayah),
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
                        Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No mushafs found',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
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

  Widget _buildRiwayahChip(String riwayah) {
    final isSelected = _selectedRiwayah == riwayah;
    return FilterChip(
      label: Text(riwayah),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedRiwayah = riwayah;
          _filterMushafs();
        });
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

