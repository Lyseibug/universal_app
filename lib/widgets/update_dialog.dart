import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';

/// Dialog widget for showing version update notifications.
class UpdateDialog extends StatelessWidget {
  final String currentVersion;
  final String newVersion;
  final String updateUrl;
  final bool isForceUpdate;

  const UpdateDialog({
    super.key,
    required this.currentVersion,
    required this.newVersion,
    required this.updateUrl,
    this.isForceUpdate = false,
  });

  /// Show the update dialog.
  static Future<void> show(
    BuildContext context, {
    required String currentVersion,
    required String newVersion,
    required String updateUrl,
    bool isForceUpdate = false,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: !isForceUpdate,
      builder: (context) => UpdateDialog(
        currentVersion: currentVersion,
        newVersion: newVersion,
        updateUrl: updateUrl,
        isForceUpdate: isForceUpdate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !isForceUpdate,
      child: AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        title: Row(
          children: [
            Icon(
              isForceUpdate ? Icons.system_update : Icons.update,
              color: isForceUpdate
                  ? AppTheme.errorColor
                  : AppTheme.primaryColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isForceUpdate ? 'Update Required' : 'Update Available',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isForceUpdate
                  ? 'Your app version ($currentVersion) is no longer supported. '
                        'Please update to version $newVersion to continue using ${AppConstants.appName}.'
                  : 'A new version ($newVersion) is available. '
                        'You are currently on version $currentVersion.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            if (isForceUpdate)
              Text(
                'This update is mandatory.',
                style: TextStyle(
                  color: AppTheme.errorColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        actions: [
          if (!isForceUpdate)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Later'),
            ),
          ElevatedButton(
            onPressed: () => _launchUpdate(context),
            child: const Text('Update Now'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUpdate(BuildContext context) async {
    final uri = Uri.parse(updateUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open update link')),
        );
      }
    }
  }
}
