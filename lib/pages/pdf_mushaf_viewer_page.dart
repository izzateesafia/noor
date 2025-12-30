import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../models/mushaf_model.dart';
import '../services/mushaf_download_service.dart';
import '../services/mushaf_bookmark_service.dart';
import '../cubit/user_cubit.dart';
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
  final MushafBookmarkService _bookmarkService = MushafBookmarkService();
  
  int _currentPage = 1;
  int _totalPages = 0;
  bool _isLoading = true;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String? _errorMessage;
  String? _pdfPath;
  bool _isPdfCached = false;
  bool _isBookmarked = false;
  int? _savedBookmarkPage;
  
  // Gesture detection for horizontal swipe
  double _dragStartX = 0.0;
  double _dragStartY = 0.0;

  @override
  void initState() {
    super.initState();
    _checkCacheFirst();
    _loadBookmark();
  }

  /// Load saved bookmark for this mushaf
  Future<void> _loadBookmark() async {
    try {
      final savedPage = await _bookmarkService.getBookmark(widget.mushaf.id);
      if (savedPage != null) {
        setState(() {
          _savedBookmarkPage = savedPage;
          _isBookmarked = true;
        });
      }
    } catch (e) {
      print('Error loading bookmark: $e');
    }
  }

  /// Check cache status immediately before showing loading state
  Future<void> _checkCacheFirst() async {
    _isPdfCached = await _downloadService.isPdfCached(widget.mushaf.id);
    if (_isPdfCached) {
      _pdfPath = await _downloadService.getLocalPdfPath(widget.mushaf.id);
      // Verify file exists and is readable
      final file = File(_pdfPath!);
      if (await file.exists()) {
        setState(() {
          _isLoading = false;
        });
        return; // Skip download, load immediately
      } else {
        // Cache file doesn't exist, mark as not cached
        _isPdfCached = false;
      }
    }
    // If not cached or invalid, proceed with download
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Check if PDF is cached (double check)
      if (!_isPdfCached) {
        _isPdfCached = await _downloadService.isPdfCached(widget.mushaf.id);
      }
      
      if (_isPdfCached && _pdfPath != null) {
        // Load from cache
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

  /// Save current page as bookmark
  /// If bookmark already exists, it updates to current page
  Future<void> _saveBookmark() async {
    try {
      await _bookmarkService.saveBookmark(widget.mushaf.id, _currentPage);
      setState(() {
        _isBookmarked = true;
        _savedBookmarkPage = _currentPage;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bookmark saved at page $_currentPage'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save bookmark: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Remove bookmark for this mushaf
  Future<void> _removeBookmark() async {
    try {
      await _bookmarkService.deleteBookmark(widget.mushaf.id);
      setState(() {
        _isBookmarked = false;
        _savedBookmarkPage = null;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bookmark removed'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove bookmark: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
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
                // Maintain zoom and scroll after explicit page jump
                Future.delayed(const Duration(milliseconds: 300), () {
                  _pdfViewerController.zoomLevel = 1.5;
                  // Only use jumpTo when explicitly jumping to a page, not on natural page changes
                  Future.delayed(const Duration(milliseconds: 100), () {
                    _pdfViewerController.jumpTo(xOffset: 50.0, yOffset: 200.0);
                  });
                });
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
              icon: Icon(_isBookmarked ? Icons.bookmark : Icons.bookmark_border),
              onPressed: _isBookmarked ? _removeBookmark : _saveBookmark,
              tooltip: _isBookmarked ? 'Remove Bookmark' : 'Save Bookmark',
            ),
          if (_pdfPath != null)
            PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: const Row(
                    children: [
                      Icon(Icons.pageview),
                      SizedBox(width: 8),
                      Text('Tukar Mushaf'),
                    ],
                  ),
                  onTap: () {
                    Future.delayed(Duration.zero, () {
                      Navigator.of(context).pushNamed('/mushaf_pdf_selection');
                    });
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

    // Wrap PDF viewer with GestureDetector for horizontal swipe navigation
    return GestureDetector(
      onHorizontalDragStart: (details) {
        _dragStartX = details.globalPosition.dx;
        _dragStartY = details.globalPosition.dy;
      },
      onHorizontalDragUpdate: (details) {
        // Track drag for swipe detection
      },
      onHorizontalDragEnd: (details) {
        final dragEndX = details.globalPosition.dx;
        final dragEndY = details.globalPosition.dy;
        final deltaX = dragEndX - _dragStartX;
        final deltaY = dragEndY - _dragStartY;
        
        // Only trigger swipe if horizontal movement is greater than vertical
        // and exceeds threshold (50 pixels)
        if (deltaX.abs() > deltaY.abs() && deltaX.abs() > 50) {
          if (deltaX > 0) {
            // Swipe right - go to previous page
            if (_currentPage > 1) {
              _pdfViewerController.previousPage();
              // Maintain zoom after page change (don't use jumpTo as it may reset page)
              Future.delayed(const Duration(milliseconds: 200), () {
                _pdfViewerController.zoomLevel = 1.1;
              });
            }
          } else {
            // Swipe left - go to next page
            if (_currentPage < _totalPages) {
              _pdfViewerController.nextPage();
              // Maintain zoom after page change (don't use jumpTo as it may reset page)
              Future.delayed(const Duration(milliseconds: 200), () {
                _pdfViewerController.zoomLevel = 1.1;
              });
            }
          }
        }
      },
      child: SfPdfViewer.file(
        file,
        controller: _pdfViewerController,
        // enableDoubleTapZoom: false,
        canShowScrollHead: false,
        canShowScrollStatus: false,
        scrollDirection: PdfScrollDirection.horizontal,
        pageLayoutMode: PdfPageLayoutMode.single,
        onDocumentLoaded: (PdfDocumentLoadedDetails details) {
          setState(() {
            _totalPages = details.document.pages.count;
          });
          
          // Set zoom level and scroll to verse area after document loads
          Future.delayed(const Duration(milliseconds: 500), () {
            _pdfViewerController.zoomLevel = 1.1; // Zoom in to focus on verse area
            // Scroll to verse area (yellow part) - centered on the text block
            _pdfViewerController.jumpTo(xOffset: 50.0, yOffset: 200.0);
          });
          
          // Jump to saved bookmark page if available
          if (_savedBookmarkPage != null && _savedBookmarkPage! >= 1 && _savedBookmarkPage! <= _totalPages) {
            Future.delayed(const Duration(milliseconds: 800), () {
              _pdfViewerController.jumpToPage(_savedBookmarkPage!);
              // Reapply zoom and scroll after page jump
              Future.delayed(const Duration(milliseconds: 300), () {
                _pdfViewerController.zoomLevel = 1.1;
                _pdfViewerController.jumpTo(xOffset: 20.0, yOffset: 200.0);
              });
              setState(() {
                _currentPage = _savedBookmarkPage!;
              });
            });
          }
        },
        onPageChanged: (PdfPageChangedDetails details) {
          setState(() {
            _currentPage = details.newPageNumber;
            // Bookmark status is based on whether a bookmark exists for this mushaf,
            // not whether we're on the bookmarked page
            // _isBookmarked remains true if _savedBookmarkPage is not null
          });
          
          // Reapply zoom when page changes (don't use jumpTo as it may reset page)
          Future.delayed(const Duration(milliseconds: 200), () {
            _pdfViewerController.zoomLevel = 1.1;
          });
        },
      ),
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
                    ? () {
                        _pdfViewerController.previousPage();
                        // Maintain zoom after page change (don't use jumpTo as it may reset page)
                        Future.delayed(const Duration(milliseconds: 200), () {
                          _pdfViewerController.zoomLevel = 1.5;
                        });
                      }
                    : null,
                tooltip: 'Previous Page',
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: _currentPage < _totalPages
                    ? () {
                        _pdfViewerController.nextPage();
                        // Maintain zoom after page change (don't use jumpTo as it may reset page)
                        Future.delayed(const Duration(milliseconds: 200), () {
                          _pdfViewerController.zoomLevel = 1.5;
                        });
                      }
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

