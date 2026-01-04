import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';

class PhotoPermissionHelper {
  /// Check and request photo permission with full access encouragement
  /// Returns true if permission is granted (full or limited), false otherwise
  static Future<bool> checkAndRequestPhotoPermission(
    BuildContext context, {
    ImageSource? source,
    bool showLimitedAccessDialog = true,
  }) async {
    // On iOS, let image_picker handle permissions internally
    // - Gallery: PHPickerViewController doesn't require explicit permission (works with limited access)
    // - Camera: image_picker will request permission automatically when needed
    // This approach matches how apps like Facebook handle permissions
    if (Platform.isIOS) {
      if (source == ImageSource.gallery) {
      } else if (source == ImageSource.camera) {
      }
      return true; // Let image_picker handle permissions internally
    }

    Permission permission;
    if (source == ImageSource.camera) {
      permission = Permission.camera;
    } else {
      // Use Permission.photos for Android
      // permission_handler will automatically map to READ_MEDIA_IMAGES on Android 13+
      permission = Permission.photos;
    }

    var status = await permission.status;

    // Debug logging - initial status

    // Full access granted - proceed
    if (status.isGranted) {
      return true;
    }

    // Limited access detected - allow picker to open immediately
    // On iOS, the system picker will allow users to select photos even with limited access
    // We should not block the picker with a dialog - let it open so users can select photos
    if (status.isLimited && source != ImageSource.camera) {
      // Allow the picker to open - the system will handle photo selection
      // The upgrade dialog can be shown later if needed, but don't block the picker
      return true;
    }

    // Permanently denied - show settings dialog
    if (status.isPermanentlyDenied) {
      final openSettings = await _showPermanentlyDeniedDialog(context, source);
      if (openSettings == true) {
        await openAppSettings();
        // Wait a moment for user to potentially change settings
        await Future.delayed(const Duration(milliseconds: 500));
        // Re-check after returning from settings
        status = await permission.status;
        if (status.isGranted) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Akses penuh telah diberikan'),
                backgroundColor: Colors.green,
              ),
            );
          }
          return true;
        }
        if (status.isLimited) {
          return true;
        }
        // Still denied - show helpful message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                source == ImageSource.camera
                    ? 'Sila aktifkan kebenaran kamera dalam Tetapan > Privasi & Keselamatan > Kamera'
                    : 'Sila aktifkan kebenaran galeri dalam Tetapan > Privasi & Keselamatan > Foto',
              ),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
      return false;
    }

    // Request permission if not granted, not limited, and not permanently denied
    // This catches: denied, notDetermined (initial state on iOS), and restricted states
    if (!status.isGranted && !status.isLimited && !status.isPermanentlyDenied) {
      status = await permission.request();
      
      if (status.isGranted) {
        return true;
      }
      
      // Check if it became permanently denied after request
      if (status.isPermanentlyDenied) {
        final openSettings = await _showPermanentlyDeniedDialog(context, source);
        if (openSettings == true) {
          await openAppSettings();
          // Wait a moment for user to potentially change settings
          await Future.delayed(const Duration(milliseconds: 500));
          // Re-check after returning from settings
          status = await permission.status;
          if (status.isGranted) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Akses penuh telah diberikan'),
                  backgroundColor: Colors.green,
                ),
              );
            }
            return true;
          }
          if (status.isLimited) {
            return true;
          }
          // Still denied - show helpful message
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  source == ImageSource.camera
                      ? 'Sila aktifkan kebenaran kamera dalam Tetapan > Privasi & Keselamatan > Kamera'
                      : 'Sila aktifkan kebenaran galeri dalam Tetapan > Privasi & Keselamatan > Foto',
                ),
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
        return false;
      }
      
      // Limited access granted after request - allow picker to open
      // Don't show dialog that blocks the picker - let users select photos first
      if (status.isLimited && source != ImageSource.camera) {
        // Allow the picker to open immediately - users can select photos through the system picker
        return true;
      }
      
      // Permission denied after request (but not permanently denied)
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              source == ImageSource.camera
                  ? 'Kebenaran kamera diperlukan.'
                  : 'Kebenaran galeri diperlukan.',
            ),
          ),
        );
      }
      return false;
    }

    // Other states - show error
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            source == ImageSource.camera
                ? 'Kebenaran kamera diperlukan.'
                : 'Kebenaran galeri diperlukan.',
          ),
        ),
      );
    }
    return false;
  }

  /// Show dialog when limited access is detected
  static Future<bool?> _showLimitedAccessDialog(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Naik Taraf ke Akses Penuh'),
        content: const Text(
          'Anda kini mempunyai akses terhad kepada foto anda. Untuk pengalaman terbaik, kami mengesyorkan memberikan akses penuh kepada semua foto anda.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Teruskan dengan Akses Terhad'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Buka Tetapan'),
          ),
        ],
      ),
    );
  }

  /// Show dialog when permission is permanently denied
  static Future<bool?> _showPermanentlyDeniedDialog(
    BuildContext context,
    ImageSource? source,
  ) async {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          source == ImageSource.camera
              ? 'Kebenaran Kamera Diperlukan'
              : 'Kebenaran Galeri Diperlukan',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              source == ImageSource.camera
                  ? 'Kebenaran kamera telah ditolak. Untuk menggunakan kamera, sila:'
                  : 'Kebenaran galeri telah ditolak. Untuk memilih foto, sila:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              source == ImageSource.camera
                  ? '1. Tekan "Buka Tetapan" di bawah\n2. Pergi ke Privasi & Keselamatan\n3. Pilih Kamera\n4. Aktifkan untuk aplikasi ini'
                  : '1. Tekan "Buka Tetapan" di bawah\n2. Pergi ke Privasi & Keselamatan\n3. Pilih Foto\n4. Pilih "Semua Foto" atau "Foto Terpilih"',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Buka Tetapan'),
          ),
        ],
      ),
    );
  }
}

