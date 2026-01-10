import 'package:flutter/material.dart';

class ToastUtil {
  static void showToast(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    Color? textColor,
    Duration duration = const Duration(seconds: 3),
  }) {
    // Hide any existing snackbar first
    ScaffoldMessenger.of(context).clearSnackBars();
    
    // Show toast-like snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: textColor ?? Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: backgroundColor ?? Colors.black87,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(
          bottom: 100,
          left: 20,
          right: 20,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 6,
      ),
    );
  }

  static void showError(BuildContext context, String message) {
    // Don't show snackbars for permission-denied errors
    // These are handled in UI cards instead
    if (message.contains('permission-denied') ||
        message.contains('cloud_firestore') ||
        message.contains('Kebenaran ditolak')) {
      return;
    }
    
    showToast(
      context,
      message,
      backgroundColor: Colors.red.shade700,
      textColor: Colors.white,
    );
  }

  static void showSuccess(BuildContext context, String message) {
    showToast(
      context,
      message,
      backgroundColor: Colors.green.shade700,
      textColor: Colors.white,
    );
  }

  static void showInfo(BuildContext context, String message) {
    showToast(
      context,
      message,
      backgroundColor: Colors.blue.shade700,
      textColor: Colors.white,
    );
  }
}

