import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../models/mushaf_model.dart';
import '../services/mushaf_download_service.dart';
import '../theme_constants.dart';

class PDFMushafViewerPage extends StatefulWidget {
  final MushafModel mushaf;

  const PDFMushafViewerPage({required this.mushaf, super.key});

  @override
  State<PDFMushafViewerPage> createState() => _PDFMushafViewerPageState();
}

class _PDFMushafViewerPageState extends State<PDFMushafViewerPage> {
  final PdfViewerController _pdfViewerController = PdfViewerController();
  final MushafDownloadService _downloadService = MushafDownloadService();
  
  int _currentPage = 1;
  int _totalPages = 0;
  bool _isLoading = true;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String? _errorMessage;
  String? _pdfPath;
  bool _isPdfCached = false;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Check if PDF is cached
      _isPdfCached = await _downloadService.isPdfCached(widget.mushaf.id);
      
      if (_isPdfCached) {
        // Load from cache
        _pdfPath = await _downloadService.getLocalPdfPath(widget.mushaf.id);
        setState(() {
          _isLoading = false;
        });
      } else {
        // Download PDF
        if (widget.mushaf.pdfUrl.isEmpty) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'PDF URL not configured. Please contact support.';
          });
          return;
        }

        setState(() {
          _isDownloading = true;
          _downloadProgress = 0.0;
        });

        try {
          _pdfPath = await _downloadService.downloadPdf(
            widget.mushaf.id,
            widget.mushaf.pdfUrl,
            onProgress: (received, total) {
              setState(() {
                _downloadProgress = received / total;
              });
            },
          );

          setState(() {
            _isDownloading = false;
            _isLoading = false;
            _isPdfCached = true;
          });
        } catch (e) {
          setState(() {
            _isDownloading = false;
            _isLoading = false;
            _errorMessage = 'Failed to download PDF: ${e.toString()}';
          });
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading PDF: ${e.toString()}';
      });
    }
  }

  Future<void> _retryDownload() async {
    await _loadPdf();
  }

  void _showJumpToPageDialog() {
    if (_totalPages == 0) return;

    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Jump to Page'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Enter page number (1-$_totalPages)',
            labelText: 'Page Number',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final page = int.tryParse(controller.text);
              if (page != null && page >= 1 && page <= _totalPages) {
                _pdfViewerController.jumpToPage(page);
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please enter a valid page number between 1 and $_totalPages'),
                  ),
                );
              }
            },
            child: const Text('Go'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.mushaf.name),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_isPdfCached)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                // TODO: Implement search functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Search feature coming soon')),
                );
              },
              tooltip: 'Search',
            ),
          if (_pdfPath != null)
            IconButton(
              icon: const Icon(Icons.bookmark_border),
              onPressed: () {
                // TODO: Implement bookmark functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Bookmark feature coming soon')),
                );
              },
              tooltip: 'Bookmark',
            ),
          if (_pdfPath != null)
            PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: const Row(
                    children: [
                      Icon(Icons.pageview),
                      SizedBox(width: 8),
                      Text('Jump to Page'),
                    ],
                  ),
                  onTap: () {
                    Future.delayed(Duration.zero, () => _showJumpToPageDialog());
                  },
                ),
              ],
            ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _pdfPath != null ? _buildBottomBar() : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading || _isDownloading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isDownloading) ...[
              CircularProgressIndicator(value: _downloadProgress),
              const SizedBox(height: 16),
              Text(
                'Downloading PDF... ${(_downloadProgress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(fontSize: 16),
              ),
            ] else ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Loading PDF...'),
            ],
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                'Error',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _retryDownload,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_pdfPath == null) {
      return const Center(
        child: Text('PDF not available'),
      );
    }

    final file = File(_pdfPath!);
    if (!file.existsSync()) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            const Text('PDF file not found'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _retryDownload,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return SfPdfViewer.file(
      file,
      controller: _pdfViewerController,
      onDocumentLoaded: (PdfDocumentLoadedDetails details) {
        setState(() {
          _totalPages = details.document.pages.count;
        });
      },
      onPageChanged: (PdfPageChangedDetails details) {
        setState(() {
          _currentPage = details.newPageNumber;
        });
      },
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Page $_currentPage of $_totalPages',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _currentPage > 1
                    ? () => _pdfViewerController.previousPage()
                    : null,
                tooltip: 'Previous Page',
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: _currentPage < _totalPages
                    ? () => _pdfViewerController.nextPage()
                    : null,
                tooltip: 'Next Page',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

