import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:path/path.dart' as path;

class ImageUploadService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final fb_auth.FirebaseAuth _auth = fb_auth.FirebaseAuth.instance;

  /// Upload profile picture to Firebase Storage
  /// Returns the download URL of the uploaded image
  Future<String> uploadProfilePicture(File imageFile) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get file extension
      final extension = path.extension(imageFile.path);
      
      // Create reference: profile_pictures/{userId}.{extension}
      final ref = _storage.ref().child('profile_pictures/${user.uid}$extension');

      // Upload file
      final uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      // Wait for upload to complete
      final snapshot = await uploadTask;
      
      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload profile picture: $e');
    }
  }

  /// Delete profile picture from Firebase Storage
  Future<void> deleteProfilePicture(String imageUrl) async {
    try {
      // Extract the path from the URL
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      // Ignore errors if file doesn't exist
    }
  }

  /// Upload class thumbnail to Firebase Storage
  /// Returns the download URL of the uploaded image
  Future<String> uploadClassThumbnail(File imageFile, {String? existingUrl}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated. Please log in and try again.');
      }

      // Check file size (5MB limit)
      final fileSize = await imageFile.length();
      if (fileSize > 5 * 1024 * 1024) {
        throw Exception('File size exceeds 5MB limit. Please choose a smaller image.');
      }

      // Get file extension
      final extension = path.extension(imageFile.path);
      
      // Generate unique filename: Image_class/{timestamp}_{userId}{extension}
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${timestamp}_${user.uid}$extension';
      
      // Create reference: Image_class/{fileName}
      final ref = _storage.ref().child('Image_class/$fileName');

      // Determine content type based on extension
      String contentType = 'image/jpeg';
      if (extension.toLowerCase() == '.png') {
        contentType = 'image/png';
      } else if (extension.toLowerCase() == '.webp') {
        contentType = 'image/webp';
      }

      // Upload file
      final uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: contentType,
          customMetadata: {
            'uploadedAt': DateTime.now().toIso8601String(),
            'uploadedBy': user.uid,
          },
        ),
      );

      // Wait for upload to complete
      final snapshot = await uploadTask;
      
      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      // Delete old image if exists and is different
      if (existingUrl != null && existingUrl.isNotEmpty && existingUrl != downloadUrl) {
        try {
          await deleteClassThumbnail(existingUrl);
        } catch (e) {
        }
      }
      
      return downloadUrl;
    } on FirebaseException catch (e) {
      String errorMessage = 'Failed to upload class thumbnail';
      if (e.code == 'unauthorized') {
        errorMessage = 'You are not authorized to upload images. Please check your permissions.';
      } else if (e.code == 'permission-denied') {
        errorMessage = 'Permission denied. Please ensure you are logged in and have the required permissions.';
      } else if (e.code == 'unauthenticated') {
        errorMessage = 'Authentication required. Please log in and try again.';
      } else {
        errorMessage = 'Upload failed: ${e.message ?? e.code}';
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Failed to upload class thumbnail: ${e.toString()}');
    }
  }

  /// Delete class thumbnail from Firebase Storage
  Future<void> deleteClassThumbnail(String imageUrl) async {
    try {
      // Extract the path from the URL
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      // Ignore errors if file doesn't exist
    }
  }

  /// Upload video thumbnail to Firebase Storage
  /// Returns the download URL of the uploaded image
  Future<String> uploadVideoThumbnail(File imageFile, {String? existingUrl}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated. Please log in and try again.');
      }

      // Check file size (5MB limit)
      final fileSize = await imageFile.length();
      if (fileSize > 5 * 1024 * 1024) {
        throw Exception('File size exceeds 5MB limit. Please choose a smaller image.');
      }

      // Get file extension
      final extension = path.extension(imageFile.path);
      
      // Generate unique filename: video_thumbnails/{timestamp}_{userId}{extension}
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${timestamp}_${user.uid}$extension';
      
      // Create reference: video_thumbnails/{fileName}
      final ref = _storage.ref().child('video_thumbnails/$fileName');

      // Determine content type based on extension
      String contentType = 'image/jpeg';
      if (extension.toLowerCase() == '.png') {
        contentType = 'image/png';
      } else if (extension.toLowerCase() == '.webp') {
        contentType = 'image/webp';
      }

      // Upload file
      final uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: contentType,
          customMetadata: {
            'uploadedAt': DateTime.now().toIso8601String(),
            'uploadedBy': user.uid,
          },
        ),
      );

      // Wait for upload to complete
      final snapshot = await uploadTask;
      
      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      // Delete old image if exists and is different
      if (existingUrl != null && existingUrl.isNotEmpty && existingUrl != downloadUrl) {
        try {
          await deleteVideoThumbnail(existingUrl);
        } catch (e) {
        }
      }
      
      return downloadUrl;
    } on FirebaseException catch (e) {
      String errorMessage = 'Failed to upload video thumbnail';
      if (e.code == 'unauthorized') {
        errorMessage = 'You are not authorized to upload images. Please check your permissions.';
      } else if (e.code == 'permission-denied') {
        errorMessage = 'Permission denied. Please ensure you are logged in and have the required permissions.';
      } else if (e.code == 'unauthenticated') {
        errorMessage = 'Authentication required. Please log in and try again.';
      } else {
        errorMessage = 'Upload failed: ${e.message ?? e.code}';
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Failed to upload video thumbnail: ${e.toString()}');
    }
  }

  /// Delete video thumbnail from Firebase Storage
  Future<void> deleteVideoThumbnail(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
    }
  }

  /// Upload video file to Firebase Storage
  /// Returns the download URL of the uploaded video
  Future<String> uploadVideo(File videoFile, {String? existingUrl}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated. Please log in and try again.');
      }

      // Check file size (500MB limit)
      final fileSize = await videoFile.length();
      if (fileSize > 500 * 1024 * 1024) {
        throw Exception('File size exceeds 500MB limit. Please choose a smaller video file.');
      }

      // Get file extension
      final extension = path.extension(videoFile.path);
      
      // Generate unique filename: videos/{timestamp}_{userId}{extension}
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${timestamp}_${user.uid}$extension';
      
      // Create reference: videos/{fileName}
      final ref = _storage.ref().child('videos/$fileName');

      // Determine content type based on extension
      String contentType = 'video/mp4';
      if (extension.toLowerCase() == '.mov') {
        contentType = 'video/quicktime';
      } else if (extension.toLowerCase() == '.webm') {
        contentType = 'video/webm';
      } else if (extension.toLowerCase() == '.avi') {
        contentType = 'video/x-msvideo';
      }

      // Upload file
      final uploadTask = ref.putFile(
        videoFile,
        SettableMetadata(
          contentType: contentType,
          customMetadata: {
            'uploadedAt': DateTime.now().toIso8601String(),
            'uploadedBy': user.uid,
          },
        ),
      );

      // Wait for upload to complete
      final snapshot = await uploadTask;
      
      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      // Delete old video if exists and is different
      if (existingUrl != null && existingUrl.isNotEmpty && existingUrl != downloadUrl) {
        try {
          await deleteVideo(existingUrl);
        } catch (e) {
        }
      }
      
      return downloadUrl;
    } on FirebaseException catch (e) {
      String errorMessage = 'Failed to upload video';
      if (e.code == 'unauthorized') {
        errorMessage = 'You are not authorized to upload videos. Please check your permissions.';
      } else if (e.code == 'permission-denied') {
        errorMessage = 'Permission denied. Please ensure you are logged in and have the required permissions.';
      } else if (e.code == 'unauthenticated') {
        errorMessage = 'Authentication required. Please log in and try again.';
      } else {
        errorMessage = 'Upload failed: ${e.message ?? e.code}';
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Failed to upload video: ${e.toString()}');
    }
  }

  /// Delete video from Firebase Storage
  Future<void> deleteVideo(String videoUrl) async {
    try {
      final ref = _storage.refFromURL(videoUrl);
      await ref.delete();
    } catch (e) {
    }
  }

  /// Upload hadith image to Firebase Storage
  /// Returns the download URL of the uploaded image
  Future<String> uploadHadithImage(File imageFile, {String? existingUrl}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated. Please log in and try again.');
      }

      // Check file size (5MB limit)
      final fileSize = await imageFile.length();
      if (fileSize > 5 * 1024 * 1024) {
        throw Exception('File size exceeds 5MB limit. Please choose a smaller image.');
      }

      // Get file extension
      final extension = path.extension(imageFile.path);
      
      // Generate unique filename: hadith_images/{timestamp}_{userId}{extension}
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${timestamp}_${user.uid}$extension';
      
      // Create reference: hadith_images/{fileName}
      final ref = _storage.ref().child('hadith_images/$fileName');

      // Determine content type based on extension
      String contentType = 'image/jpeg';
      if (extension.toLowerCase() == '.png') {
        contentType = 'image/png';
      } else if (extension.toLowerCase() == '.webp') {
        contentType = 'image/webp';
      }

      // Upload file
      final uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: contentType,
          customMetadata: {
            'uploadedAt': DateTime.now().toIso8601String(),
            'uploadedBy': user.uid,
          },
        ),
      );

      // Wait for upload to complete
      final snapshot = await uploadTask;
      
      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      // Delete old image if exists and is different
      if (existingUrl != null && existingUrl.isNotEmpty && existingUrl != downloadUrl) {
        try {
          await deleteHadithImage(existingUrl);
        } catch (e) {
        }
      }
      
      return downloadUrl;
    } on FirebaseException catch (e) {
      String errorMessage = 'Failed to upload hadith image';
      if (e.code == 'unauthorized') {
        errorMessage = 'You are not authorized to upload images. Please check your permissions.';
      } else if (e.code == 'permission-denied') {
        errorMessage = 'Permission denied. Please ensure you are logged in and have the required permissions.';
      } else if (e.code == 'unauthenticated') {
        errorMessage = 'Authentication required. Please log in and try again.';
      } else {
        errorMessage = 'Upload failed: ${e.message ?? e.code}';
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Failed to upload hadith image: ${e.toString()}');
    }
  }

  /// Delete hadith image from Firebase Storage
  Future<void> deleteHadithImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
    }
  }

  /// Upload news image to Firebase Storage
  /// Returns the download URL of the uploaded image
  Future<String> uploadNewsImage(File imageFile, {String? existingUrl}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated. Please log in and try again.');
      }

      // Check file size (5MB limit)
      final fileSize = await imageFile.length();
      if (fileSize > 5 * 1024 * 1024) {
        throw Exception('File size exceeds 5MB limit. Please choose a smaller image.');
      }

      // Get file extension
      final extension = path.extension(imageFile.path);
      
      // Generate unique filename: news_images/{timestamp}_{userId}{extension}
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${timestamp}_${user.uid}$extension';
      
      // Create reference: news_images/{fileName}
      final ref = _storage.ref().child('news_images/$fileName');

      // Determine content type based on extension
      String contentType = 'image/jpeg';
      if (extension.toLowerCase() == '.png') {
        contentType = 'image/png';
      } else if (extension.toLowerCase() == '.webp') {
        contentType = 'image/webp';
      }

      // Upload file
      final uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: contentType,
          customMetadata: {
            'uploadedAt': DateTime.now().toIso8601String(),
            'uploadedBy': user.uid,
          },
        ),
      );

      // Wait for upload to complete
      final snapshot = await uploadTask;
      
      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      // Delete old image if exists and is different
      if (existingUrl != null && existingUrl.isNotEmpty && existingUrl != downloadUrl) {
        try {
          await deleteNewsImage(existingUrl);
        } catch (e) {
        }
      }
      
      return downloadUrl;
    } on FirebaseException catch (e) {
      String errorMessage = 'Failed to upload news image';
      if (e.code == 'unauthorized') {
        errorMessage = 'You are not authorized to upload images. Please check your permissions.';
      } else if (e.code == 'permission-denied') {
        errorMessage = 'Permission denied. Please ensure you are logged in and have the required permissions.';
      } else if (e.code == 'unauthenticated') {
        errorMessage = 'Authentication required. Please log in and try again.';
      } else {
        errorMessage = 'Upload failed: ${e.message ?? e.code}';
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Failed to upload news image: ${e.toString()}');
    }
  }

  /// Delete news image from Firebase Storage
  Future<void> deleteNewsImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
    }
  }

  /// Upload dua image to Firebase Storage
  /// Returns the download URL of the uploaded image
  Future<String> uploadDuaImage(File imageFile, {String? existingUrl}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated. Please log in and try again.');
      }

      // Check file size (5MB limit)
      final fileSize = await imageFile.length();
      if (fileSize > 5 * 1024 * 1024) {
        throw Exception('File size exceeds 5MB limit. Please choose a smaller image.');
      }

      // Get file extension
      final extension = path.extension(imageFile.path);
      
      // Generate unique filename: dua_images/{timestamp}_{userId}{extension}
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${timestamp}_${user.uid}$extension';
      
      // Create reference: dua_images/{fileName}
      final ref = _storage.ref().child('dua_images/$fileName');

      // Determine content type based on extension
      String contentType = 'image/jpeg';
      if (extension.toLowerCase() == '.png') {
        contentType = 'image/png';
      } else if (extension.toLowerCase() == '.webp') {
        contentType = 'image/webp';
      }

      // Upload file
      final uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: contentType,
          customMetadata: {
            'uploadedAt': DateTime.now().toIso8601String(),
            'uploadedBy': user.uid,
          },
        ),
      );

      // Wait for upload to complete
      final snapshot = await uploadTask;
      
      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      // Delete old image if exists and is different
      if (existingUrl != null && existingUrl.isNotEmpty && existingUrl != downloadUrl) {
        try {
          await deleteDuaImage(existingUrl);
        } catch (e) {
        }
      }
      
      return downloadUrl;
    } on FirebaseException catch (e) {
      String errorMessage = 'Failed to upload dua image';
      if (e.code == 'unauthorized') {
        errorMessage = 'You are not authorized to upload images. Please check your permissions.';
      } else if (e.code == 'permission-denied') {
        errorMessage = 'Permission denied. Please ensure you are logged in and have the required permissions.';
      } else if (e.code == 'unauthenticated') {
        errorMessage = 'Authentication required. Please log in and try again.';
      } else {
        errorMessage = 'Upload failed: ${e.message ?? e.code}';
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Failed to upload dua image: ${e.toString()}');
    }
  }

  /// Delete dua image from Firebase Storage
  Future<void> deleteDuaImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
    }
  }

  /// Upload ad image to Firebase Storage
  /// Returns the download URL of the uploaded image
  Future<String> uploadAdImage(File imageFile, {String? existingUrl}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated. Please log in and try again.');
      }

      // Check file size (5MB limit)
      final fileSize = await imageFile.length();
      if (fileSize > 5 * 1024 * 1024) {
        throw Exception('File size exceeds 5MB limit. Please choose a smaller image.');
      }

      // Get file extension
      final extension = path.extension(imageFile.path);
      
      // Generate unique filename: ad_images/{timestamp}_{userId}{extension}
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${timestamp}_${user.uid}$extension';
      
      // Create reference: ad_images/{fileName}
      final ref = _storage.ref().child('ad_images/$fileName');

      // Determine content type based on extension
      String contentType = 'image/jpeg';
      if (extension.toLowerCase() == '.png') {
        contentType = 'image/png';
      } else if (extension.toLowerCase() == '.webp') {
        contentType = 'image/webp';
      }

      // Upload file
      final uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: contentType,
          customMetadata: {
            'uploadedAt': DateTime.now().toIso8601String(),
            'uploadedBy': user.uid,
          },
        ),
      );

      // Wait for upload to complete
      final snapshot = await uploadTask;
      
      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      // Delete old image if exists and is different
      if (existingUrl != null && existingUrl.isNotEmpty && existingUrl != downloadUrl) {
        try {
          await deleteAdImage(existingUrl);
        } catch (e) {
        }
      }
      
      return downloadUrl;
    } on FirebaseException catch (e) {
      String errorMessage = 'Failed to upload ad image';
      if (e.code == 'unauthorized') {
        errorMessage = 'You are not authorized to upload images. Please check your permissions.';
      } else if (e.code == 'permission-denied') {
        errorMessage = 'Permission denied. Please ensure you are logged in and have the required permissions.';
      } else if (e.code == 'unauthenticated') {
        errorMessage = 'Authentication required. Please log in and try again.';
      } else {
        errorMessage = 'Upload failed: ${e.message ?? e.code}';
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Failed to upload ad image: ${e.toString()}');
    }
  }

  /// Delete ad image from Firebase Storage
  Future<void> deleteAdImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
    }
  }
}

