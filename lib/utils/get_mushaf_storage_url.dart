/// Utility to get Firebase Storage download URLs for mushaf PDFs
/// 
/// This is a helper script you can use to get download URLs for PDFs
/// uploaded to Firebase Storage. Copy the URLs to Firestore documents.
/// 
/// Usage:
/// 1. Upload PDF to Firebase Storage at path: mushafs/{filename}.pdf
/// 2. Run this function to get the download URL
/// 3. Copy the URL to the Firestore document's pdfUrl field

import 'package:firebase_storage/firebase_storage.dart';

class MushafStorageHelper {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Get download URL for a mushaf PDF
  /// 
  /// [fileName] - Name of the PDF file (e.g., 'madinah_old.pdf', 'warsh.pdf')
  /// Returns the download URL that can be stored in Firestore
  Future<String> getMushafDownloadUrl(String fileName) async {
    try {
      // Reference to the PDF file in Storage
      final ref = _storage.ref().child('mushafs/$fileName');
      
      // Get download URL
      final downloadUrl = await ref.getDownloadURL();
      
      
      return downloadUrl;
    } catch (e) {
      rethrow;
    }
  }

  /// Get download URLs for multiple mushaf PDFs
  Future<Map<String, String>> getMushafDownloadUrls(List<String> fileNames) async {
    final Map<String, String> urls = {};
    
    for (var fileName in fileNames) {
      try {
        final url = await getMushafDownloadUrl(fileName);
        urls[fileName] = url;
      } catch (e) {
      }
    }
    
    return urls;
  }
}

/// Example usage:
/// 
/// ```dart
/// final helper = MushafStorageHelper();
/// 
/// // Get URL for a single PDF
/// final url = await helper.getMushafDownloadUrl('madinah_old.pdf');
/// 
/// // Get URLs for multiple PDFs
/// final urls = await helper.getMushafDownloadUrls([
///   'madinah_old.pdf',
///   'warsh.pdf',
/// ]);
/// ```

