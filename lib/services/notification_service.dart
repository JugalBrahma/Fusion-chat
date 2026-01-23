import 'package:flutter/material.dart';

class NotificationService {
  static void showSuccess(BuildContext context, String message) {
    _showNotification(
      context,
      message: message,
      backgroundColor: Colors.green,
      icon: Icons.check_circle,
    );
  }

  static void showError(BuildContext context, String message) {
    // Disabled - don't show error popups
    return;
  }

  static void showInfo(BuildContext context, String message) {
    // Disabled - don't show info popups
    return;
  }

  static void showWarning(BuildContext context, String message) {
    // Disabled - don't show warning popups
    return;
  }

  static void _showNotification(
    BuildContext context, {
    required String message,
    required Color backgroundColor,
    required IconData icon,
  }) {
    // Truncate message if too long
    String displayMessage = message;
    if (message.length > 100) {
      displayMessage = '${message.substring(0, 97)}...';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                displayMessage,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
                softWrap: true,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  static void showDeleteConfirmation(
    BuildContext context, {
    required String title,
    required String itemName,
    required List<String> warnings,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Are you sure you want to delete "$itemName"?',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                ...warnings.map((warning) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(
                        child: Text(
                          warning,
                          style: TextStyle(
                            color: warning.contains('⚠️') ? Colors.orange : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
