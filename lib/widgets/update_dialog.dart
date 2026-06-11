import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/logger.dart';

/// Modern update dialog widget.
///
/// Force Update:  Non-dismissible, only "Update Now" button.
/// Optional Update: Dismissible, "Later" + "Update Now" buttons.
///
/// Displays:
/// - 🚀 Update Available (or ⚠️ Update Required)
/// - Server message
/// - Current Version vs Latest Version
/// - "New update available" badge
/// - Action buttons
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
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon + Title
              _buildHeader(context),
              const SizedBox(height: 20),

              // Message
              _buildMessage(context),
              const SizedBox(height: 20),

              // Version info card
              _buildVersionCard(context),
              const SizedBox(height: 16),

              // "New update available" chip
              _buildUpdateBadge(context),
              const SizedBox(height: 24),

              // Action buttons
              _buildButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        // Emoji icon in a circle
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: isForceUpdate
                ? AppTheme.errorColor.withValues(alpha: 0.1)
                : AppTheme.primaryColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              isForceUpdate ? '⚠️' : '🚀',
              style: const TextStyle(fontSize: 32),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          isForceUpdate ? 'Update Required' : 'Update Available',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildMessage(BuildContext context) {
    final message = updateMessage ?? 'A new version of the app is available.';
    return Text(
      message,
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[700], height: 1.4),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildVersionCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          _buildVersionRow(
            context,
            label: 'Current Version',
            version: currentVersion,
            icon: Icons.phone_android,
            color: Colors.grey[600]!,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Colors.grey[300]),
          ),
          _buildVersionRow(
            context,
            label: 'Latest Version',
            version: newVersion,
            icon: Icons.cloud_download_outlined,
            color: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildVersionRow(
    BuildContext context, {
    required String label,
    required String version,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            'v$version',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUpdateBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isForceUpdate
            ? AppTheme.errorColor.withValues(alpha: 0.1)
            : Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isForceUpdate
              ? AppTheme.errorColor.withValues(alpha: 0.3)
              : Colors.orange.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isForceUpdate ? Icons.warning_rounded : Icons.new_releases_outlined,
            size: 16,
            color: isForceUpdate ? AppTheme.errorColor : Colors.orange[700],
          ),
          const SizedBox(width: 6),
          Text(
            isForceUpdate
                ? 'Mandatory update required'
                : 'New update available',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isForceUpdate ? AppTheme.errorColor : Colors.orange[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtons(BuildContext context) {
    if (isForceUpdate) {
      // Force update: only "Update Now" button, full width
      return SizedBox(
        width: double.infinity,
        height: AppConstants.buttonHeight,
        child: ElevatedButton.icon(
          onPressed: () => _launchUpdate(context),
          icon: const Icon(Icons.system_update_alt, size: 20),
          label: const Text(
            'Update Now',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.errorColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    }

    // Optional update: "Later" + "Update Now"
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: AppConstants.buttonHeight,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey[400]!),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Later',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: AppConstants.buttonHeight,
            child: ElevatedButton.icon(
              onPressed: () => _launchUpdate(context),
              icon: const Icon(Icons.system_update_alt, size: 18),
              label: const Text(
                'Update Now',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Open the APK download URL in an external browser.
  /// Uses launchUrl directly without canLaunchUrl() — the latter is unreliable
  /// on Android 11+ without explicit <queries> in AndroidManifest.xml.
  Future<void> _launchUpdate(BuildContext context) async {
    debugPrint('[UpdateDialog] APK URL: $updateUrl');

    if (updateUrl.isEmpty) {
      debugPrint('[UpdateDialog] ERROR: APK URL is empty');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Download URL not available'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    try {
      final uri = Uri.parse(updateUrl);
      debugPrint('[UpdateDialog] Launching URL: $uri');

      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      debugPrint('[UpdateDialog] Launch result: $launched');

      if (!launched && context.mounted) {
        AppLogger.warning(
          'launchUrl returned false for: $updateUrl',
          tag: 'UpdateDialog',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open download link'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('[UpdateDialog] Exception: $e');
      AppLogger.error('Error launching URL', error: e, tag: 'UpdateDialog');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
