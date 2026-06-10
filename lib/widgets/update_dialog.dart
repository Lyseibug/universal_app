import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';

/// Dialog widget for showing version update notifications.
/// Downloads APK directly from the ERP server.
class UpdateDialog extends StatelessWidget {
  final String currentVersion;
  final String newVersion;
  final String updateUrl;
  final String? updateMessage;
  final bool isForceUpdate;

  const UpdateDialog({
    super.key,
    required this.currentVersion,
    required this.newVersion,
    required this.updateUrl,
    this.updateMessage,
    this.isForceUpdate = false,
  });

  /// Show the update dialog.
  static Future<void> show(
    BuildContext context, {
    required String currentVersion,
    required String newVersion,
    required String updateUrl,
    String? updateMessage,
    bool isForceUpdate = false,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: !isForceUpdate,
      builder: (context) => UpdateDialog(
        currentVersion: currentVersion,
        newVersion: newVersion,
        updateUrl: updateUrl,
        updateMessage: updateMessage,
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
              size: 28,
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
            // Server message (if provided)
            if (updateMessage != null && updateMessage!.isNotEmpty) ...[
              Text(
                updateMessage!,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
            ],
            // Version info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _buildVersionRow(context, 'Current Version', currentVersion),
                  const Divider(height: 16),
                  _buildVersionRow(context, 'New Version', newVersion),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (isForceUpdate)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: AppTheme.errorColor,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This update is mandatory to continue using the app.',
                        style: TextStyle(
                          color: AppTheme.errorColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Text(
                'You can update later from Settings.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
          ],
        ),
        actions: [
          if (!isForceUpdate)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Later'),
            ),
          ElevatedButton.icon(
            onPressed: () => _launchUpdate(context),
            icon: const Icon(Icons.download, size: 18),
            label: const Text('Download Update'),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionRow(BuildContext context, String label, String version) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Text(
          'v$version',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Future<void> _launchUpdate(BuildContext context) async {
    final uri = Uri.parse(updateUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open download link')),
        );
      }
    }
  }
}
