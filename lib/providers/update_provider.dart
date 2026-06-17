import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';

import '../core/models/app_version_info.dart';
import '../core/services/app_update_service.dart';
import '../core/utils/logger.dart';
import 'service_providers.dart';

// ─── State ─────────────────────────────────────────────────────────────────

enum UpdatePhase {
  /// No update found or check not yet run.
  idle,

  /// Actively fetching version info from server.
  checking,

  /// A newer version exists — optional (dismissible) reminder.
  updateAvailable,

  /// Running below minimum or force_update=true — persistent (non-dismissible) reminder.
  forceUpdate,

  /// User tapped "Update Now" — downloading APK.
  downloading,

  /// Download complete, opening installer intent.
  installing,

  /// Something went wrong during download.
  downloadError,
}

class UpdateState {
  final UpdatePhase phase;

  /// Version info fetched from server. Null until a check has succeeded.
  final AppVersionInfo? info;

  /// Download progress 0.0–1.0. Only meaningful when phase == downloading.
  final double downloadProgress;

  /// Error message. Only meaningful when phase == downloadError.
  final String? errorMessage;

  const UpdateState({
    this.phase = UpdatePhase.idle,
    this.info,
    this.downloadProgress = 0.0,
    this.errorMessage,
  });

  UpdateState copyWith({
    UpdatePhase? phase,
    AppVersionInfo? info,
    double? downloadProgress,
    String? errorMessage,
  }) {
    return UpdateState(
      phase: phase ?? this.phase,
      info: info ?? this.info,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      errorMessage: errorMessage,
    );
  }

  /// True when the dialog is showing any actionable state.
  bool get isVisible =>
      phase == UpdatePhase.updateAvailable ||
      phase == UpdatePhase.forceUpdate ||
      phase == UpdatePhase.downloading ||
      phase == UpdatePhase.installing ||
      phase == UpdatePhase.downloadError;

  /// True when a download / install is in progress — disables dismiss.
  bool get isBusy =>
      phase == UpdatePhase.downloading || phase == UpdatePhase.installing;
}

// ─── Notifier ──────────────────────────────────────────────────────────────

class UpdateNotifier extends StateNotifier<UpdateState> {
  static const _tag = 'UpdateNotifier';

  final AppUpdateService _updateService;
  CancelToken? _cancelToken;

  UpdateNotifier(this._updateService) : super(const UpdateState());

  // ── Public API ────────────────────────────────────────────────────────────

  /// Runs the version check.
  ///
  /// Called from splash (pre-login) and from login screen after successful auth.
  /// Silent on failure — the app always continues normally.
  Future<void> checkForUpdate() async {
    if (state.phase == UpdatePhase.checking) return; // debounce
    state = state.copyWith(phase: UpdatePhase.checking);

    try {
      final result = await _updateService.checkForUpdate();

      if (result == null || result.status == UpdateStatus.upToDate) {
        state = state.copyWith(phase: UpdatePhase.idle);
        return;
      }

      state = UpdateState(
        phase: result.status == UpdateStatus.forceUpdate
            ? UpdatePhase.forceUpdate
            : UpdatePhase.updateAvailable,
        info: result.info,
      );
    } catch (e) {
      // Silently swallow — update check must never crash the app
      AppLogger.warning('checkForUpdate error: $e', tag: _tag);
      state = state.copyWith(phase: UpdatePhase.idle);
    }
  }

  /// Starts the APK download. Called when user taps "Update Now".
  Future<void> downloadAndInstall() async {
    final info = state.info;
    if (info == null || info.apkUrl.isEmpty) return;

    _cancelToken = CancelToken();
    state = state.copyWith(phase: UpdatePhase.downloading, downloadProgress: 0.0);

    try {
      final file = await _updateService.downloadApk(
        info.apkUrl,
        onProgress: (p) {
          state = state.copyWith(downloadProgress: p);
        },
        cancelToken: _cancelToken,
      );

      state = state.copyWith(phase: UpdatePhase.installing, downloadProgress: 1.0);
      await _launchInstaller(file);
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        state = state.copyWith(phase: UpdatePhase.updateAvailable, downloadProgress: 0.0);
      } else {
        AppLogger.error('APK download failed: $e', tag: _tag);
        state = state.copyWith(
          phase: UpdatePhase.downloadError,
          errorMessage: 'Download failed. Please check your connection and try again.',
        );
      }
    } catch (e) {
      AppLogger.error('Unexpected download error: $e', tag: _tag);
      state = state.copyWith(
        phase: UpdatePhase.downloadError,
        errorMessage: 'An unexpected error occurred. Please try again.',
      );
    }
  }

  /// Retries after a download error.
  void retryDownload() {
    if (state.info != null) {
      state = state.copyWith(phase: UpdatePhase.updateAvailable, errorMessage: null);
    }
  }

  /// Dismisses the update dialog.
  ///
  /// Only allowed when [state.phase] is [UpdatePhase.updateAvailable] or
  /// [UpdatePhase.downloadError] — forceUpdate dialogs cannot be permanently dismissed.
  void dismiss() {
    if (state.isBusy) return;
    if (state.phase == UpdatePhase.forceUpdate) return; // can't dismiss force
    state = const UpdateState(); // back to idle
  }

  /// Called when the app resumes from background (e.g. after Android installer
  /// closes — whether the install succeeded or the user cancelled).
  ///
  /// If we were in [UpdatePhase.installing], we reset to [UpdatePhase.updateAvailable]
  /// so the user can retry or dismiss. The next launch will confirm the version.
  void onResumedFromInstaller() {
    if (state.phase == UpdatePhase.installing) {
      AppLogger.info('Returned from installer — resetting to updateAvailable', tag: _tag);
      state = state.copyWith(
        phase: UpdatePhase.updateAvailable,
        downloadProgress: 0.0,
        errorMessage: null,
      );
    }
  }

  @override
  void dispose() {
    _cancelToken?.cancel();
    super.dispose();
  }

  // ── Private ───────────────────────────────────────────────────────────────

  Future<void> _launchInstaller(File file) async {
    AppLogger.info('Launching installer for ${file.path}', tag: _tag);
    final result = await OpenFilex.open(
      file.path,
      type: 'application/vnd.android.package-archive',
    );
    AppLogger.info('OpenFilex result: ${result.type} — ${result.message}', tag: _tag);

    // After triggering the installer the phase stays at "installing".
    // When the user returns from the system installer we remain ready.
    // The next app launch will re-check and confirm the update succeeded.
  }
}

// ─── Providers ─────────────────────────────────────────────────────────────

/// Provider for [AppUpdateService] — wired to the current ERP base URL
/// and the auth token store for authenticated APK downloads.
final appUpdateServiceProvider = Provider<AppUpdateService>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  final tokenStore = ref.watch(tokenStoreProvider);
  return AppUpdateService(
    erpBaseUrl: storageService.getErpUrl(),
    tokenGetter: () => tokenStore.read(),
  );
});

/// Provider for update state.
final updateProvider = StateNotifierProvider<UpdateNotifier, UpdateState>((ref) {
  final service = ref.watch(appUpdateServiceProvider);
  return UpdateNotifier(service);
});
