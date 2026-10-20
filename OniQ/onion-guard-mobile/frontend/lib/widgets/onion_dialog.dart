import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class OnionDialog {
  static void showSuccess(BuildContext context,
      {required String title, required String message, VoidCallback? onDismiss}) {
    _showDialog(context,
        icon: Icons.check_circle, iconColor: AppTheme.primaryGreen,
        title: title, message: message, onDismiss: onDismiss);
  }

  static void showError(BuildContext context,
      {required String title, required String message, VoidCallback? onDismiss}) {
    _showDialog(context,
        icon: Icons.error, iconColor: Colors.red,
        title: title, message: message, onDismiss: onDismiss);
  }

  static void showInfo(BuildContext context,
      {required String title, required String message, VoidCallback? onDismiss}) {
    _showDialog(context,
        icon: Icons.info, iconColor: AppTheme.primaryGreen,
        title: title, message: message, onDismiss: onDismiss);
  }

  static void _showDialog(BuildContext context,
      {required IconData icon, required Color iconColor,
      required String title, required String message, VoidCallback? onDismiss}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 60, color: iconColor),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                onDismiss?.call();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              ),
              child: const Text('OK'),
            ),
          ),
        ],
      ),
    );
  }
}
