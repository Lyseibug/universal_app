import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../utils/logger.dart';

/// Service to download APK files and trigger the Android package installer.
/// Mimics WhatsApp-style in-app update: download → install popup.
class ApkDownloadService {
  final Dio _dio;
  CancelToken? _cancelToken;

  ApkDownloadService()
    : _dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(minutes: 10),
          // Larger buffer + follow redirects for faster, reliable downloads
          followRedirects: true,
          maxRedirects: 5,
        ),
      );

  /// Download APK from [url] and trigger install.
  ///
  /// [onProgress] callback receives download progress (0.0 to 1.0).
  /// IMPORTANT: progress is throttled to fire only when the integer percent
  /// changes (0,1,2...100), preventing UI jank from excessive setState calls.
  ///
  /// Returns the file path of the downloaded APK, or null on failure.
  Future<String?> downloadAndInstall(
    String url, {
    required ValueChanged<double> onProgress,
  }) async {
    try {
      final stopwatch = Stopwatch()..start();
      debugPrint('[ApkDownload] Starting download: $url');
      AppLogger.info('Downloading APK: $url', tag: 'ApkDownloadService');

      // Use cache directory — fast, no permissions needed, works with FileProvider.
      final dir =
          await getExternalStorageDirectory() ??
          await getApplicationSupportDirectory();

      final apkPath = '${dir.path}/app-update.apk';
      debugPrint('[ApkDownload] Save path: $apkPath');

      // Delete old APK if exists (avoid stale installs)
      final oldFile = File(apkPath);
      if (await oldFile.exists()) {
        await oldFile.delete();
        debugPrint('[ApkDownload] Deleted old APK');
      }

      _cancelToken = CancelToken();

      // Throttle: only emit when integer percent changes
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

      // Verify file exists and has content
      final apkFile = File(apkPath);
      if (!await apkFile.exists()) {
        debugPrint('[ApkDownload] ERROR: APK file not found after download');
        return null;
      }

      final fileSize = await apkFile.length();
      if (fileSize == 0) {
        debugPrint('[ApkDownload] ERROR: Downloaded APK is empty');
        return null;
      }

      // Verify APK is not corrupted (basic check: valid ZIP header)
      final bytes = await apkFile.openRead(0, 4).first;
      if (bytes.length < 4 || bytes[0] != 0x50 || bytes[1] != 0x4B) {
        debugPrint('[ApkDownload] ERROR: File is not a valid APK/ZIP');
        debugPrint('[ApkDownload] First 4 bytes: $bytes');
        AppLogger.error(
          'Downloaded file is not a valid APK (bad ZIP header)',
          tag: 'ApkDownloadService',
        );
        return null;
      }

      stopwatch.stop();
      debugPrint('───────────────────────────────────────────');
      debugPrint('[ApkDownload] ✅ Download complete');
      debugPrint('[ApkDownload] File size: ${_formatBytes(fileSize)}');
      debugPrint('[ApkDownload] Time: ${stopwatch.elapsed.inSeconds}s');
      debugPrint('[ApkDownload] Path: $apkPath');
      debugPrint('[ApkDownload] ZIP header valid: ✓');
      debugPrint('───────────────────────────────────────────');
      AppLogger.info(
        'APK downloaded: ${_formatBytes(fileSize)} in ${stopwatch.elapsed.inSeconds}s',
        tag: 'ApkDownloadService',
      );

      // Ensure progress shows 100%
      onProgress(1.0);

      // Trigger Android package installer immediately
      debugPrint('[ApkDownload] Opening package installer...');
      final result = await OpenFilex.open(
        apkPath,
        type: 'application/vnd.android.package-archive',
      );
      debugPrint(
        '[ApkDownload] Installer result: ${result.type} - ${result.message}',
      );

      if (result.type != ResultType.done) {
        AppLogger.warning(
          'OpenFilex failed: ${result.type} - ${result.message}',
          tag: 'ApkDownloadService',
        );
      }

      return apkPath;
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        debugPrint('[ApkDownload] Download cancelled');
        return null;
      }
      debugPrint('[ApkDownload] Dio error: ${e.type} - ${e.message}');
      AppLogger.error(
        'APK download failed',
        error: e,
        tag: 'ApkDownloadService',
      );
      return null;
    } catch (e) {
      debugPrint('[ApkDownload] Error: $e');
      AppLogger.error(
        'APK download/install error',
        error: e,
        tag: 'ApkDownloadService',
      );
      return null;
    }
  }

  /// Format bytes to human-readable string.
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Cancel any ongoing download and clean up resources.
  void dispose() {
    _cancelToken?.cancel('Dialog closed');
    _dio.close(force: true);
  }
}
