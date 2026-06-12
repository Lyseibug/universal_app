import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../utils/logger.dart';

/// Outcome of a download + install attempt.
///
/// `launched`  — install session was committed (installer engaged).
/// `success`   — installation actually completed (terminal STATUS_SUCCESS).
/// `userCancelled` — user dismissed the system install confirmation.
/// `permissionRequired` — blocked because "Install unknown apps" is off.
/// `statusCode` / `statusMessage` — raw values from
/// [`android.content.pm.PackageInstaller`](https://developer.android.com/reference/android/content/pm/PackageInstaller).
class ApkInstallResult {
  final bool launched;
  final bool success;
  final bool permissionRequired;
  final bool userCancelled;
  final int? statusCode;
  final String? statusMessage;
  final String? apkPath;
  final String? error;

  const ApkInstallResult({
    required this.launched,
    this.success = false,
    this.permissionRequired = false,
    this.userCancelled = false,
    this.statusCode,
    this.statusMessage,
    this.apkPath,
    this.error,
  });

  /// True only if the install **completed**. `launched` alone does not imply
  /// success — that's the silent-failure mode of the legacy ACTION_VIEW path.
  bool get installed => success;

  Map<String, Object?> toLogMap() => {
    'launched': launched,
    'success': success,
    'permissionRequired': permissionRequired,
    'userCancelled': userCancelled,
    'statusCode': statusCode,
    'statusMessage': statusMessage,
    'apkPath': apkPath,
    'error': error,
  };
}

/// Service to download APK files and trigger the Android package installer.
///
/// Install path uses Android's `PackageInstaller` Session API (via the native
/// method channel in `MainActivity.kt`). Compared to the legacy
/// `Intent.ACTION_VIEW` approach this gives us:
///
///   * Real terminal status (success / failure / user-cancelled) — no more
///     "installer launched but version unchanged" silent failures.
///   * Bytes are streamed from a session, so the on-disk APK location is
///     irrelevant. Files in `/Android/data/<pkg>/files/` work the same as
///     `/Download/`. FileProvider is no longer required.
///
/// Flow:
/// 1. Verify "install unknown apps" permission up front.
/// 2. Delete any stale APK files in the cache directory.
/// 3. Download the APK with cache-busting + no-cache headers.
/// 4. Verify file size, ZIP header, SHA256.
/// 5. Hand the path to native code, which streams it into a PackageInstaller
///    session and waits for the terminal status.
/// 6. Log the real outcome and forward it to the UI.
class ApkDownloadService {
  final Dio _dio;
  CancelToken? _cancelToken;

  /// Method channel to the native Kotlin installer.
  static const _channel = MethodChannel(
    'com.universal.universal_app/apk_installer',
  );

  ApkDownloadService()
    : _dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(minutes: 10),
          followRedirects: true,
          maxRedirects: 5,
          headers: {
            'Cache-Control': 'no-cache, no-store, must-revalidate',
            'Pragma': 'no-cache',
          },
        ),
      );

  /// Returns true if the app is currently allowed to install APKs.
  /// On Android 8+ this reflects the per-app "Install unknown apps" setting.
  Future<bool> canInstallPackages() async {
    if (!Platform.isAndroid) return true;
    try {
      final allowed = await _channel.invokeMethod<bool>('canInstallPackages');
      debugPrint('[ApkDownload] canInstallPackages = $allowed');
      return allowed ?? false;
    } catch (e) {
      debugPrint('[ApkDownload] canInstallPackages error: $e');
      return false;
    }
  }

  /// Open the system "Install unknown apps" screen for this app and wait for
  /// the user to return. Returns the resulting permission state.
  Future<bool> requestInstallPermission() async {
    if (!Platform.isAndroid) return true;
    try {
      final granted = await _channel.invokeMethod<bool>(
        'requestInstallPermission',
      );
      debugPrint('[ApkDownload] requestInstallPermission granted = $granted');
      AppLogger.info(
        'Install-unknown-apps permission granted: $granted',
        tag: 'ApkDownloadService',
      );
      return granted ?? false;
    } catch (e) {
      debugPrint('[ApkDownload] requestInstallPermission error: $e');
      return false;
    }
  }

  /// Download APK from [url], stream it into a PackageInstaller session, and
  /// wait for the real install result.
  ///
  /// [onProgress] receives 0.0 to 1.0 (throttled to integer percent changes).
  Future<ApkInstallResult> downloadAndInstall(
    String url, {
    required ValueChanged<double> onProgress,
    String? expectedVersion,
  }) async {
    try {
      final stopwatch = Stopwatch()..start();

      // ─── Step 0: Verify install permission BEFORE downloading ────────────
      // On Android 8+ the package installer silently no-ops without this
      // permission. This is the #1 cause of "installer launched but version
      // never changes". Check it up front.
      if (!await canInstallPackages()) {
        debugPrint(
          '[ApkDownload] ⚠️ Install permission not granted — requesting...',
        );
        final granted = await requestInstallPermission();
        if (!granted) {
          debugPrint('[ApkDownload] ✗ User did not grant install permission');
          return const ApkInstallResult(
            launched: false,
            permissionRequired: true,
            error: 'Install permission not granted',
          );
        }
      }

      // ─── Step 1: Get storage directory ───────────────────────────────────
      // We keep the APK in the app-private external dir. With the
      // PackageInstaller session API the system installer reads the bytes
      // we stream — it never opens the file directly — so the on-disk
      // location is no longer relevant. We still benefit from this dir
      // because it requires no permissions on Android 10+ and is wiped on
      // uninstall (no orphaned APKs in /Download).
      final dir =
          await getExternalStorageDirectory() ??
          await getApplicationSupportDirectory();
      final apkPath = '${dir.path}/app-update.apk';

      // ─── Step 2: Delete any existing APK before download ─────────────────
      final oldFile = File(apkPath);
      if (await oldFile.exists()) {
        await oldFile.delete();
        debugPrint('[ApkDownload] 🗑️ Deleted existing app-update.apk');
      }
      await _cleanupOldApks(dir);

      // ─── Step 3: Cache busting — append timestamp to URL ─────────────────
      final cacheBuster = DateTime.now().millisecondsSinceEpoch;
      final downloadUrl = '$url?t=$cacheBuster';

      debugPrint('[ApkDownload] ▶ Starting download');
      debugPrint('[ApkDownload] Download URL : $downloadUrl');
      debugPrint('[ApkDownload] APK path     : $apkPath');
      AppLogger.info(
        'Downloading APK: $downloadUrl → $apkPath',
        tag: 'ApkDownloadService',
      );

      // ─── Step 4: Download ────────────────────────────────────────────────
      _cancelToken = CancelToken();
      int lastPercent = -1;

      await _dio.download(
        downloadUrl,
        apkPath,
        cancelToken: _cancelToken,
        deleteOnError: true,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            final percent = (received / total * 100).toInt();
            if (percent != lastPercent) {
              lastPercent = percent;
              onProgress(received / total);
            }
          }
        },
      );

      // ─── Step 5: Verify the downloaded file ──────────────────────────────
      final apkFile = File(apkPath);
      if (!await apkFile.exists()) {
        debugPrint('[ApkDownload] ✗ APK file not found after download');
        return const ApkInstallResult(
          launched: false,
          error: 'APK file not found after download',
        );
      }
      final fileSize = await apkFile.length();
      if (fileSize == 0) {
        debugPrint('[ApkDownload] ✗ Downloaded APK is empty (0 bytes)');
        return const ApkInstallResult(
          launched: false,
          error: 'Downloaded APK is empty',
        );
      }
      // Verify valid ZIP/APK header (PK = 0x50 0x4B).
      final headerBytes = await apkFile.openRead(0, 4).first;
      if (headerBytes.length < 4 ||
          headerBytes[0] != 0x50 ||
          headerBytes[1] != 0x4B) {
        debugPrint('[ApkDownload] ✗ Invalid APK file (not a ZIP archive)');
        debugPrint('[ApkDownload] Header bytes: $headerBytes');
        return const ApkInstallResult(
          launched: false,
          error: 'Invalid APK file (not a ZIP archive)',
        );
      }

      // ─── Step 6: SHA256 + last modified ──────────────────────────────────
      final fileBytes = await apkFile.readAsBytes();
      final sha256Hash = sha256.convert(fileBytes).toString();
      final lastModified = await apkFile.lastModified();

      stopwatch.stop();
      debugPrint('═══════════════════════════════════════════');
      debugPrint('[ApkDownload] ✅ Download complete');
      debugPrint('[ApkDownload] Download URL : $downloadUrl');
      debugPrint('[ApkDownload] APK path     : $apkPath');
      debugPrint('[ApkDownload] File size    : ${_formatBytes(fileSize)}');
      debugPrint('[ApkDownload] Last modified: $lastModified');
      debugPrint('[ApkDownload] SHA256       : $sha256Hash');
      debugPrint(
        '[ApkDownload] Time         : ${stopwatch.elapsed.inSeconds}s',
      );
      debugPrint('═══════════════════════════════════════════');

      AppLogger.info(
        'APK downloaded: ${_formatBytes(fileSize)} in '
        '${stopwatch.elapsed.inSeconds}s | SHA256: $sha256Hash | Path: $apkPath',
        tag: 'ApkDownloadService',
      );

      onProgress(1.0);

      // ─── Step 7: Hand to native PackageInstaller session ─────────────────
      debugPrint('[ApkDownload] ─── PRE-INSTALL CHECK ───');
      debugPrint('  APK Path: $apkPath');
      debugPrint('  APK Size: $fileSize');
      debugPrint('  Expected version: $expectedVersion');
      debugPrint('[ApkDownload] ─────────────────────────');

      debugPrint('[ApkDownload] Invoking native PackageInstaller...');
      final installResult = await _installApkNative(apkPath);

      debugPrint('═══════════════════════════════════════════');
      debugPrint('[ApkDownload] ─── INSTALL RESULT ───');
      debugPrint('  APK path           : $apkPath');
      debugPrint('  Launched           : ${installResult.launched}');
      debugPrint('  Success            : ${installResult.success}');
      debugPrint('  User cancelled     : ${installResult.userCancelled}');
      debugPrint('  Permission required: ${installResult.permissionRequired}');
      debugPrint('  Status code        : ${installResult.statusCode}');
      debugPrint('  Status message     : ${installResult.statusMessage}');
      debugPrint('  Error              : ${installResult.error}');
      debugPrint('  Expected version   : $expectedVersion');
      debugPrint('═══════════════════════════════════════════');

      AppLogger.info(
        'Install result: ${installResult.toLogMap()} '
        '(expected v$expectedVersion)',
        tag: 'ApkDownloadService',
      );

      if (installResult.success) {
        debugPrint('[ApkDownload] ✅ Install completed successfully');
      } else if (installResult.userCancelled) {
        debugPrint('[ApkDownload] ⚠️ User cancelled the install');
      } else if (installResult.launched) {
        debugPrint('[ApkDownload] ✗ Install failed: ${installResult.error}');
      } else {
        debugPrint('[ApkDownload] ✗ Installer was never launched');
      }

      return ApkInstallResult(
        launched: installResult.launched,
        success: installResult.success,
        permissionRequired: installResult.permissionRequired,
        userCancelled: installResult.userCancelled,
        statusCode: installResult.statusCode,
        statusMessage: installResult.statusMessage,
        apkPath: apkPath,
        error: installResult.error,
      );
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        debugPrint('[ApkDownload] Download cancelled by user');
        return const ApkInstallResult(
          launched: false,
          error: 'Download cancelled',
        );
      }
      debugPrint('[ApkDownload] ✗ Network error: ${e.type} - ${e.message}');
      AppLogger.error(
        'APK download failed: ${e.type} - ${e.message}',
        error: e,
        tag: 'ApkDownloadService',
      );
      return ApkInstallResult(
        launched: false,
        error: 'Network error: ${e.message}',
      );
    } catch (e) {
      debugPrint('[ApkDownload] ✗ Unexpected error: $e');
      AppLogger.error(
        'APK download/install error',
        error: e,
        tag: 'ApkDownloadService',
      );
      return ApkInstallResult(launched: false, error: e.toString());
    }
  }

  /// Remove any previously downloaded APK files to prevent stale installs.
  Future<void> _cleanupOldApks(Directory dir) async {
    try {
      final files = dir.listSync();
      for (final entity in files) {
        if (entity is File && entity.path.endsWith('.apk')) {
          await entity.delete();
          debugPrint('[ApkDownload] 🗑️ Cleaned up: ${entity.path}');
        }
      }
    } catch (e) {
      debugPrint('[ApkDownload] Cleanup warning: $e');
    }
  }

  /// Call native Kotlin code to stream the APK into a PackageInstaller session
  /// and return the **terminal** install status (success / failure / cancel).
  Future<ApkInstallResult> _installApkNative(String filePath) async {
    try {
      final result = await _channel.invokeMethod<dynamic>('installApk', {
        'filePath': filePath,
      });
      debugPrint('[ApkDownload] Native installApk returned: $result');

      if (result is Map) {
        return ApkInstallResult(
          launched: result['launched'] == true,
          success: result['success'] == true,
          permissionRequired: result['permissionRequired'] == true,
          userCancelled: result['userCancelled'] == true,
          statusCode: result['statusCode'] is int
              ? result['statusCode'] as int
              : null,
          statusMessage: result['statusMessage'] as String?,
          error: result['error'] as String?,
        );
      }
      // Backward-compatible fallback if native returns a bare bool.
      return ApkInstallResult(
        launched: result == true,
        success: result == true,
      );
    } on PlatformException catch (e) {
      debugPrint('[ApkDownload] PlatformException: ${e.code} - ${e.message}');
      AppLogger.error(
        'Native install failed: ${e.message}',
        error: e,
        tag: 'ApkDownloadService',
      );
      return ApkInstallResult(launched: false, error: e.message);
    } catch (e) {
      debugPrint('[ApkDownload] Channel error: $e');
      return ApkInstallResult(launched: false, error: e.toString());
    }
  }

  /// Format bytes to human-readable string.
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Cancel ongoing download and clean up.
  void dispose() {
    _cancelToken?.cancel('Dialog closed');
    _dio.close(force: true);
  }
}
