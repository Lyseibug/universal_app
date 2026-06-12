import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../core/services/apk_download_service.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/logger.dart';

/// Modern update dialog with in-app APK download + auto-install.
///
/// Flow:
/// 1. Show update info (current vs latest version)
/// 2. User taps "Update Now"
/// 3. APK downloads in background with progress bar
/// 4. At 100%, Android package installer opens automatically
/// 5. User sees native "Install" popup
///
/// Force Update:  Non-dismissible, only "Update Now" button.
/// Optional Update: Dismissible, "Later" + "Update Now" buttons.
class UpdateDialog extends StatefulWidget {
  final String currentVersion;
  final String newVersion;
  final String apkUrl;
  final String? updateMessage;
  final bool isForceUpdate;

  /// Called with the target version right before the install is launched, so
  /// the host can persist it and verify the outcome on next launch.
  final Future<void> Function(String version)? onInstallAttempt;

  const UpdateDialog({
    super.key,
    required this.currentVersion,
    required this.newVersion,
    required this.apkUrl,
    this.updateMessage,
    this.isForceUpdate = false,
    this.onInstallAttempt,
  });

  /// Show the update dialog.
  static Future<void> show(
    BuildContext context, {
    required String currentVersion,
    required String newVersion,
    required String apkUrl,
    String? updateMessage,
    bool isForceUpdate = false,
    Future<void> Function(String version)? onInstallAttempt,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: !isForceUpdate,
      builder: (context) => UpdateDialog(
        currentVersion: currentVersion,
        newVersion: newVersion,
        apkUrl: apkUrl,
        updateMessage: updateMessage,
        isForceUpdate: isForceUpdate,
        onInstallAttempt: onInstallAttempt,
      ),
    );
  }

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  bool _isDownloading = false;
  double _progress = 0.0;
  String? _error;
  late final ApkDownloadService _downloadService;

  @override
  void initState() {
    super.initState();
    _downloadService = ApkDownloadService();
  }

  @override
  void dispose() {
    _downloadService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.isForceUpdate && !_isDownloading,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildMessage(),
              const SizedBox(height: 20),
              _buildVersionCard(),
              const SizedBox(height: 16),
              _buildUpdateBadge(),
              const SizedBox(height: 8),
              // Download progress section
              if (_isDownloading) ...[
                const SizedBox(height: 16),
                _buildDownloadProgress(),
              ],
              // Error message
              if (_error != null) ...[
                const SizedBox(height: 12),
                _buildError(),
              ],
              const SizedBox(height: 24),
              // Action buttons (hidden during download)
              if (!_isDownloading) _buildButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: widget.isForceUpdate
                ? AppTheme.errorColor.withValues(alpha: 0.1)
                : AppTheme.primaryColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              widget.isForceUpdate ? '⚠️' : '🚀',
              style: const TextStyle(fontSize: 32),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          widget.isForceUpdate ? 'Update Required' : 'Update Available',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildMessage() {
    final message =
        widget.updateMessage ?? 'A new version of the app is available.';
    return Text(
      message,
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[700], height: 1.4),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildVersionCard() {
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
            label: 'Current Version',
            version: widget.currentVersion,
            icon: Icons.phone_android,
            color: Colors.grey[600]!,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Colors.grey[300]),
          ),
          _buildVersionRow(
            label: 'Latest Version',
            version: widget.newVersion,
            icon: Icons.cloud_download_outlined,
            color: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildVersionRow({
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

  Widget _buildUpdateBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: widget.isForceUpdate
            ? AppTheme.errorColor.withValues(alpha: 0.1)
            : Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.isForceUpdate
              ? AppTheme.errorColor.withValues(alpha: 0.3)
              : Colors.orange.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            widget.isForceUpdate
                ? Icons.warning_rounded
                : Icons.new_releases_outlined,
            size: 16,
            color: widget.isForceUpdate
                ? AppTheme.errorColor
                : Colors.orange[700],
          ),
          const SizedBox(width: 6),
          Text(
            widget.isForceUpdate
                ? 'Mandatory update required'
                : 'New update available',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: widget.isForceUpdate
                  ? AppTheme.errorColor
                  : Colors.orange[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadProgress() {
    final percent = (_progress * 100).toInt();
    return Column(
      children: [
        Row(
          children: [
            const Icon(
              Icons.downloading,
              size: 20,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(width: 8),
            Text(
              'Downloading update...',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Text(
              '$percent%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: _progress,
            minHeight: 8,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              _progress >= 1.0 ? Colors.green : AppTheme.primaryColor,
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (_progress >= 1.0)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, size: 16, color: Colors.green),
              const SizedBox(width: 6),
              Text(
                'Download complete. Installing...',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.green[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 18, color: AppTheme.errorColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error!,
              style: TextStyle(fontSize: 12, color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtons() {
    if (widget.isForceUpdate) {
      return SizedBox(
        width: double.infinity,
        height: AppConstants.buttonHeight,
        child: ElevatedButton.icon(
          onPressed: _startDownload,
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
              onPressed: _startDownload,
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

  /// Start APK download and trigger install on completion.
  Future<void> _startDownload() async {
    if (widget.apkUrl.isEmpty) {
      setState(() => _error = 'Download URL not available');
      return;
    }

    setState(() {
      _isDownloading = true;
      _progress = 0.0;
      _error = null;
    });

    debugPrint('[UpdateDialog] Starting APK download: ${widget.apkUrl}');
    debugPrint('[UpdateDialog] Target version: ${widget.newVersion}');
    AppLogger.info(
      'Starting APK download: ${widget.apkUrl} (target: v${widget.newVersion})',
      tag: 'UpdateDialog',
    );

    // Persist the version we are about to install so the next launch can
    // verify whether the install actually completed.
    await widget.onInstallAttempt?.call(widget.newVersion);

    final result = await _downloadService.downloadAndInstall(
      widget.apkUrl,
      expectedVersion: widget.newVersion,
      onProgress: (progress) {
        if (mounted) {
          setState(() => _progress = progress);
        }
      },
    );

    if (!mounted) return;

    // The PackageInstaller session reports a real terminal status. Branch on
    // it so the user sees what actually happened instead of a generic "ok".
    if (result.success) {
      // Note: in practice the OS often kills our process during the package
      // replace, so this branch may never run. The post-restart check in
      // main.dart compares the pending version against PackageInfo.version
      // and is the source of truth either way.
      debugPrint('[UpdateDialog] ✅ Install completed for ${result.apkPath}');
      AppLogger.info('APK install completed successfully', tag: 'UpdateDialog');
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) Navigator.of(context).pop();
      return;
    }

    setState(() {
      _isDownloading = false;
      if (result.permissionRequired) {
        _error =
            'Please allow "Install unknown apps" for this app, then tap '
            'Update Now again.';
      } else if (result.userCancelled) {
        _error = 'Install was cancelled. Tap Update Now to try again.';
      } else if (result.launched) {
        // Installer ran but reported a failure (signature mismatch,
        // incompatible APK, storage, etc.). Surface the real reason.
        _error =
            result.error ??
            'Installation failed (status ${result.statusCode}). Please try again.';
      } else {
        _error =
            result.error ??
            'Download failed. Please check your internet and try again.';
      }
    });

    debugPrint('[UpdateDialog] Install not successful: ${result.toLogMap()}');
    AppLogger.warning(
      'Install not successful: ${result.toLogMap()}',
      tag: 'UpdateDialog',
    );
  }
}
