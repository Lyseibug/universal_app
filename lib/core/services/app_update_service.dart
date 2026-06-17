import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../models/app_version_info.dart';
import '../utils/logger.dart';

/// Service responsible for all auto-update logic:
///  1. Fetching version metadata from ERPNext (guest endpoint, no auth token).
///  2. Comparing running version against server version.
///  3. Downloading the APK with progress callbacks + auth token.
///  4. Triggering the system installer intent via [open_filex].
///
/// The version-check request is always unauthenticated (allow_guest=True).
/// The APK download uses an optional [tokenGetter] so private Frappe file
/// attachments don't redirect to an HTML login page (which would be saved as
/// the APK and cause "problem parsing the package" on Android).
class AppUpdateService {
  static const String _tag = 'AppUpdateService';

  final String _erpBaseUrl;

  /// Optional supplier of the current auth token.
  /// Called just before each APK download so it always reflects the latest token.
  final Future<String?> Function()? _tokenGetter;

  late final Dio _dio;

  AppUpdateService({
    required String erpBaseUrl,
    Future<String?> Function()? tokenGetter,
  })  : _erpBaseUrl = erpBaseUrl,
        _tokenGetter = tokenGetter {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
    ));
    // Accept self-signed certs (same as ApiClient)
    (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      client.badCertificateCallback = (cert, host, port) => true;
      return client;
    };
  }

  // ─── Version check ────────────────────────────────────────────────────────

  /// Fetches version info from ERPNext and compares it against the running build.
  ///
  /// Returns `null` silently on any network/parse failure so the app can
  /// continue normally if the update server is unreachable.
  Future<({AppVersionInfo info, UpdateStatus status})?> checkForUpdate() async {
    try {
      final info = await _fetchVersionInfo();
      if (info == null) return null;

      final packageInfo = await PackageInfo.fromPlatform();
      final runningVersion = packageInfo.version; // e.g. "1.0.8"

      final status = _compareVersions(runningVersion, info);
      AppLogger.info(
        'Running: $runningVersion | Latest: ${info.latestVersion} | Min: ${info.minimumVersion} → $status',
        tag: _tag,
      );

      return (info: info, status: status);
    } catch (e, st) {
      AppLogger.error('Update check failed: $e', tag: _tag, error: e, stackTrace: st);
      return null;
    }
  }

  /// Fetches and parses the version info JSON from ERPNext.
  Future<AppVersionInfo?> _fetchVersionInfo() async {
    // Build full URL — endpoint is relative to ERP base
    final url =
        '${_erpBaseUrl.replaceAll(RegExp(r'/+$'), '')}'
        '/api/method/universal_mobile_api.api.app_update.get_version_info'
        '?t=${DateTime.now().millisecondsSinceEpoch}'; // cache-bust

    AppLogger.info('Fetching version info: $url', tag: _tag);

    final response = await _dio.get<Map<String, dynamic>>(
      url,
      options: Options(
        headers: {
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache',
        },
        validateStatus: (s) => s != null && s < 500,
      ),
    );

    if (response.statusCode != 200 || response.data == null) {
      AppLogger.warning('Version check returned ${response.statusCode}', tag: _tag);
      return null;
    }

    // Frappe wraps the return value in { "message": <your return value> }
    final root = response.data!;
    final payload = root['message'];
    if (payload is! Map<String, dynamic>) {
      AppLogger.warning('Unexpected version payload shape: $root', tag: _tag);
      return null;
    }

    return AppVersionInfo.fromJson(payload);
  }

  // ─── Version comparison ────────────────────────────────────────────────────

  /// Compares [runningVersion] (e.g. "1.0.8") against server [info].
  UpdateStatus _compareVersions(String runningVersion, AppVersionInfo info) {
    final running = _parse(runningVersion);
    final latest = _parse(info.latestVersion);
    final minimum = _parse(info.minimumVersion);

    // Force update: explicitly flagged OR running below minimum
    if (info.forceUpdate || _isLessThan(running, minimum)) {
      return UpdateStatus.forceUpdate;
    }

    // Optional update: a newer version exists
    if (_isLessThan(running, latest)) {
      return UpdateStatus.updateAvailable;
    }

    return UpdateStatus.upToDate;
  }

  /// Parses "major.minor.patch" into a [List<int>], tolerating missing parts.
  List<int> _parse(String v) {
    final parts = v.trim().split('.');
    return List.generate(3, (i) => i < parts.length ? (int.tryParse(parts[i]) ?? 0) : 0);
  }

  bool _isLessThan(List<int> a, List<int> b) {
    for (var i = 0; i < 3; i++) {
      if (a[i] < b[i]) return true;
      if (a[i] > b[i]) return false;
    }
    return false; // equal
  }

  // ─── Download ──────────────────────────────────────────────────────────

  /// Downloads the APK from [apkUrl] into the app's external files directory.
  ///
  /// [onProgress] is called with values from 0.0 to 1.0 as bytes arrive.
  /// Auth token (from [_tokenGetter]) is added to the request so private
  /// Frappe file attachments are served correctly.
  /// Returns the local [File] on success, or throws on failure.
  Future<File> downloadApk(
    String apkUrl, {
    required void Function(double progress) onProgress,
    CancelToken? cancelToken,
  }) async {
    final dir = await getExternalStorageDirectory() ?? await getTemporaryDirectory();
    const fileName = 'universal_app_update.apk';
    final savePath = '${dir.path}/$fileName';

    // Remove stale file if present
    final existing = File(savePath);
    if (await existing.exists()) await existing.delete();

    // Obtain auth token — needed for private Frappe file attachments.
    // Without it, Frappe returns an HTML login page which gets saved as the
    // APK file and causes "There was a problem parsing the package".
    final token = await _tokenGetter?.call();
    AppLogger.info(
      'Downloading APK to $savePath (auth=${token != null ? 'yes' : 'none'})',
      tag: _tag,
    );

    await _dio.download(
      apkUrl,
      savePath,
      cancelToken: cancelToken,
      onReceiveProgress: (received, total) {
        if (total > 0) onProgress(received / total);
      },
      options: Options(
        receiveTimeout: const Duration(minutes: 10),
        validateStatus: (s) => s != null && s < 500,
        headers: {
          if (token != null) 'Authorization': 'token $token',
          'Cache-Control': 'no-cache',
        },
      ),
    );

    // Validate the downloaded file is actually an APK and not an HTML error page.
    final downloadedFile = File(savePath);
    final fileSize = await downloadedFile.length();
    AppLogger.info('Download complete: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB', tag: _tag);

    if (fileSize < 512 * 1024) {
      // Less than 512 KB — almost certainly an HTML error page, not an APK.
      // Read the first bytes to confirm.
      final bytes = await downloadedFile.openRead(0, 256).first;
      final preview = String.fromCharCodes(bytes).toLowerCase();
      if (preview.contains('<html') || preview.contains('<!doctype')) {
        await downloadedFile.delete();
        throw Exception(
          'The server returned an HTML page instead of the APK.\n'
          'Make sure the APK file attachment is set to Public in ERPNext,\n'
          'or that the download URL is correct.',
        );
      }
    }

    return downloadedFile;
  }
}
