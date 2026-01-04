import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class MushafDownloadService {
  static final MushafDownloadService _instance = MushafDownloadService._internal();
  factory MushafDownloadService() => _instance;
  MushafDownloadService._internal();

  final Dio _dio = Dio();
  final Map<String, CancelToken> _downloadTokens = {};

  /// Get the local directory for storing mushaf PDFs
  Future<Directory> _getMushafDirectory() async {
    final appDocumentsDir = await getApplicationDocumentsDirectory();
    final mushafDir = Directory(path.join(appDocumentsDir.path, 'mushafs'));
    if (!await mushafDir.exists()) {
      await mushafDir.create(recursive: true);
    }
    return mushafDir;
  }

  /// Get the local file path for a mushaf PDF
  Future<String> getLocalPdfPath(String mushafId) async {
    final mushafDir = await _getMushafDirectory();
    return path.join(mushafDir.path, '$mushafId.pdf');
  }

  /// Check if a PDF is already cached locally
  Future<bool> isPdfCached(String mushafId) async {
    final filePath = await getLocalPdfPath(mushafId);
    final file = File(filePath);
    return await file.exists();
  }

  /// Download PDF from remote URL
  /// Returns the local file path on success
  Future<String> downloadPdf(
    String mushafId,
    String pdfUrl, {
    Function(int received, int total)? onProgress,
  }) async {
    try {
      // Check if already cached
      if (await isPdfCached(mushafId)) {
        return await getLocalPdfPath(mushafId);
      }

      final filePath = await getLocalPdfPath(mushafId);
      final file = File(filePath);

      // Cancel any existing download for this mushaf
      _downloadTokens[mushafId]?.cancel();
      _downloadTokens[mushafId] = CancelToken();

      // Download the file
      await _dio.download(
        pdfUrl,
        filePath,
        cancelToken: _downloadTokens[mushafId],
        onReceiveProgress: (received, total) {
          if (onProgress != null && total > 0) {
            onProgress(received, total);
          }
        },
      );

      // Remove cancel token after successful download
      _downloadTokens.remove(mushafId);

      return filePath;
    } catch (e) {
      // Remove cancel token on error
      _downloadTokens.remove(mushafId);
      rethrow;
    }
  }

  /// Cancel an ongoing download
  void cancelDownload(String mushafId) {
    _downloadTokens[mushafId]?.cancel();
    _downloadTokens.remove(mushafId);
  }

  /// Delete a cached PDF
  Future<bool> deleteCachedPdf(String mushafId) async {
    try {
      final filePath = await getLocalPdfPath(mushafId);
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Get the size of a cached PDF in bytes
  Future<int?> getCachedPdfSize(String mushafId) async {
    try {
      final filePath = await getLocalPdfPath(mushafId);
      final file = File(filePath);
      if (await file.exists()) {
        return await file.length();
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}

