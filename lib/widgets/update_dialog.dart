import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../providers/update_provider.dart';

/// Modal bottom sheet that notifies the user about an available update.
///
/// Behaviour:
///  • [UpdatePhase.updateAvailable]  — shows "Later" + "Update Now" buttons
///  • [UpdatePhase.forceUpdate]      — hides "Later", shows urgency badge
///  • [UpdatePhase.downloading]      — shows animated progress bar
///  • [UpdatePhase.installing]       — shows "Opening installer…" spinner
///  • [UpdatePhase.downloadError]    — shows error + retry button
///
/// Call [UpdateDialog.show] to display. The dialog manages its own
/// dismiss/rebuild via Riverpod watch internally.
class UpdateDialog extends ConsumerStatefulWidget {
  const UpdateDialog({super.key});

  /// Shows the update dialog as a modal bottom sheet.
  ///
  /// Pass `isDismissible: false` for forceUpdate externally if needed,
  /// but the sheet also reads [UpdateState] directly to control itself.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isDismissible: false,     // always — we control dismiss from inside
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const UpdateDialog(),
    );
  }

  @override
  ConsumerState<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends ConsumerState<UpdateDialog>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _progressCtrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _progressCtrl.dispose();
    super.dispose();
  }

  /// Called when the user returns from the Android system installer.
  /// Resets the stuck 'installing' state so the user isn't locked out.
  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    if (lifecycleState == AppLifecycleState.resumed) {
      ref.read(updateProvider.notifier).onResumedFromInstaller();
    }
  }

  void _onDismiss() {
    ref.read(updateProvider.notifier).dismiss();
    if (mounted) Navigator.of(context).pop();
  }

  void _onUpdateNow() {
    ref.read(updateProvider.notifier).downloadAndInstall();
  }

  void _onRetry() {
    ref.read(updateProvider.notifier).retryDownload();
  }

  @override
  Widget build(BuildContext context) {
    final updateState = ref.watch(updateProvider);

    // Auto-close if we returned to idle (e.g. update check reset)
    if (!updateState.isVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      });
    }

    final isForce = updateState.phase == UpdatePhase.forceUpdate;
    final isDownloading = updateState.phase == UpdatePhase.downloading;
    final isInstalling = updateState.phase == UpdatePhase.installing;
    final isError = updateState.phase == UpdatePhase.downloadError;
    final isBusy = updateState.isBusy || isInstalling;

    return PopScope(
      canPop: !isBusy && !isForce,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop && !isForce) {
          ref.read(updateProvider.notifier).dismiss();
        }
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        decoration: BoxDecoration(
          color: AppTheme.bgSurface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Drag handle ─────────────────────────────────────────────────
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.bgBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildHeader(isForce),
            ),
            const SizedBox(height: 16),

            // ── Release notes ────────────────────────────────────────────────
            if (updateState.info != null && !isDownloading && !isInstalling)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildReleaseNotes(updateState.info!.message),
              ),

            // ── Progress / error area ────────────────────────────────────────
            if (isDownloading)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildProgressBar(updateState.downloadProgress),
              ),
            if (isInstalling)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: _InstallerIndicator(),
              ),
            if (isError)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildErrorBanner(updateState.errorMessage ?? 'Download failed.'),
              ),

            const SizedBox(height: 24),

            // ── Actions ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: _buildActions(
                isForce: isForce,
                isBusy: isBusy,
                isError: isError,
                isDownloading: isDownloading,
              ),
            ),

            // Safe area padding
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isForce) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon badge
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isForce ? AppTheme.amberLight : AppTheme.infoLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isForce ? Icons.warning_amber_rounded : Icons.system_update_alt_rounded,
            color: isForce ? AppTheme.amber : AppTheme.info,
            size: 26,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    isForce ? 'Update Required' : 'Update Available',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  if (isForce) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.amber,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'IMPORTANT',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 3),
              Consumer(builder: (_, ref, child) {
                final info = ref.watch(updateProvider).info;
                return Text(
                  info != null ? 'Version ${info.latestVersion} is ready' : 'A new version is ready',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReleaseNotes(String notes) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bgElevated,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: Text(
        notes,
        style: const TextStyle(
          fontSize: 13,
          color: AppTheme.textSecondary,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildProgressBar(double progress) {
    final pct = (progress * 100).toStringAsFixed(0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Downloading update…',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            Text(
              '$pct%',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: AppTheme.bgElevated,
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.dangerLight,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(color: AppTheme.danger.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.danger, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 13, color: AppTheme.danger),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions({
    required bool isForce,
    required bool isBusy,
    required bool isError,
    required bool isDownloading,
  }) {
    if (isError) {
      return Column(
        children: [
          _PrimaryButton(label: 'Retry', icon: Icons.refresh, onPressed: _onRetry),
          const SizedBox(height: 10),
          _SecondaryButton(label: 'Later', onPressed: _onDismiss),
        ],
      );
    }

    if (isBusy) {
      return _PrimaryButton(
        label: isDownloading ? 'Downloading…' : 'Opening installer…',
        icon: null,
        onPressed: null, // disabled while busy
        showSpinner: true,
      );
    }

    return Column(
      children: [
        _PrimaryButton(
          label: 'Update Now',
          icon: Icons.download_rounded,
          onPressed: _onUpdateNow,
        ),
        if (!isForce) ...[
          const SizedBox(height: 10),
          _SecondaryButton(label: 'Later', onPressed: _onDismiss),
        ],
        if (isForce)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text(
              'You can continue using the app, but please update soon.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ),
      ],
    );
  }
}

// ─── Small reusable widgets ──────────────────────────────────────────────────

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool showSpinner;

  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.showSpinner = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppTheme.bgElevated,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          ),
          elevation: 0,
        ),
        child: showSpinner
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white60),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const _SecondaryButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: TextButton(
        onPressed: onPressed,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _InstallerIndicator extends StatelessWidget {
  const _InstallerIndicator();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
        ),
        const SizedBox(width: 12),
        const Text(
          'Opening system installer…',
          style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        ),
      ],
    );
  }
}
