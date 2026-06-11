import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../utils/logger.dart';

/// Service to download APK files and trigger the Android package installer.
///
/// Uses a native Kotlin method channel to invoke Android's ACTION_VIEW intent
/// with FileProvider — this is the only reliable way to trigger the package
/// installer across Android 7–14.
///
/// Flow: Download APK → Verify → Native Intent → Android Install Popup
class ApkDownloadService {
  final Dio _dio;
  CancelToken? _cancelToken;

  /// Method channel to the native Kotlin installer
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
        ),
      );

  /// Download APK from [url] and trigger the Android package installer.
  ///
  /// [onProgress] — receives 0.0 to 1.0 (throttled to integer percent changes).
  /// Returns the downloaded APK file path, or null on failure.
  Future<String?> downloadAndInstall(
    String url, {
    required ValueChanged<double> onProgress,
  }) async {
    try {
      final stopwatch = Stopwatch()..start();
      debugPrint('[ApkDownload] ▶ Starting download: $url');
      AppLogger.info('Downloading APK: $url', tag: 'ApkDownloadService');

      // Get storage directory
      final dir =
          await getExternalStorageDirectory() ??
          await getApplicationSupportDirectory();

      final apkPath = '${dir.path}/app-update.apk';
      debugPrint('[ApkDownload] Save path: $apkPath');

      // Delete old APK if exists
      final oldFile = File(apkPath);
      if (await oldFile.exists()) {
        await oldFile.delete();
        debugPrint('[ApkDownload] Deleted old APK');
      }

      _cancelToken = CancelToken();

      // Throttle progress: only emit when integer percent changes
      int lastPercent = -1;

      await _dio.download(
        url,
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

      // ─── Verify downloaded file ────────────────────────────────────────────
      final apkFile = File(apkPath);
      if (!await apkFile.exists()) {
        debugPrint('[ApkDownload] ✗ APK file not found after download');
        return null;
      }

      final fileSize = await apkFile.length();
      if (fileSize == 0) {
        debugPrint('[ApkDownload] ✗ Downloaded APK is empty (0 bytes)');
        return null;
      }

      // Verify valid ZIP/APK header (PK = 0x50 0x4B)
      final headerBytes = await apkFile.openRead(0, 4).first;
      if (headerBytes.length < 4 ||
          headerBytes[0] != 0x50 ||
          headerBytes[1] != 0x4B) {
        debugPrint('[ApkDownload] ✗ Invalid APK file (not a ZIP archive)');
        debugPrint('[ApkDownload] Header bytes: $headerBytes');
        return null;
      }

      stopwatch.stop();
      debugPrint('───────────────────────────────────────────');
      debugPrint('[ApkDownload] ✅ Download verified');
      debugPrint('[ApkDownload] Size: ${_formatBytes(fileSize)}');
      debugPrint('[ApkDownload] Time: ${stopwatch.elapsed.inSeconds}s');
      debugPrint('[ApkDownload] Path: $apkPath');
      debugPrint('───────────────────────────────────────────');

      AppLogger.info(
        'APK downloaded: ${_formatBytes(fileSize)} in ${stopwatch.elapsed.inSeconds}s',
        tag: 'ApkDownloadService',
      );

      // Ensure progress shows 100%
      onProgress(1.0);

      // ─── Trigger native Android installer ──────────────────────────────────
      debugPrint('[ApkDownload] Invoking native installer...');
      final success = await _installApkNative(apkPath);

      if (success) {
        debugPrint('[ApkDownload] ✅ Install intent launched successfully');
      } else {
        debugPrint('[ApkDownload] ✗ Install intent failed');
      }

      return success ? apkPath : null;
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        debugPrint('[ApkDownload] Download cancelled by user');
        return null;
      }
      debugPrint('[ApkDownload] ✗ Network error: ${e.type} - ${e.message}');
      AppLogger.error(
        'APK download failed',
        error: e,
        tag: 'ApkDownloadService',
      );
      return null;
    } catch (e) {
      debugPrint('[ApkDownload] ✗ Unexpected error: $e');
      AppLogger.error(
        'APK download/install error',
        error: e,
        tag: 'ApkDownloadService',
      );
      return null;
    }
  }

  /// Call native Kotlin code to trigger the Android package installer.
  /// Uses FileProvider + ACTION_VIEW intent — works on Android 7–14.
  Future<bool> _installApkNative(String filePath) async {
    try {
      final result = await _channel.invokeMethod<bool>('installApk', {
        'filePath': filePath,
      });
      debugPrint('[ApkDownload] Native installApk result: $result');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('[ApkDownload] PlatformException: ${e.code} - ${e.message}');
      AppLogger.error(
        'Native install failed: ${e.message}',
        error: e,
        tag: 'ApkDownloadService',
      );
      return false;
    } catch (e) {
      debugPrint('[ApkDownload] Channel error: $e');
      return false;
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
