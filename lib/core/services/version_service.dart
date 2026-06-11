import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../data/models/version_model.dart';
import '../../data/repositories/version_repository.dart';
import '../api/api_exceptions.dart';
import '../utils/logger.dart';

/// Result of the version check operation.
class VersionCheckResult {
  final VersionStatus status;
  final VersionModel serverVersion;
  final String appVersion;
  final String? error;

  const VersionCheckResult({
    required this.status,
    required this.serverVersion,
    required this.appVersion,
    this.error,
  });
}

/// Service layer for version management.
///
/// Flow:
/// 1. Get installed app version via package_info_plus
/// 2. Fetch server version from version.json
/// 3. Compare versions (handles 1.0.9 < 1.0.10 correctly)
/// 4. Return status: upToDate / updateAvailable / forceUpdate
///
/// Error handling:
/// - No internet → returns upToDate (app continues)
/// - API failure → returns upToDate (app continues)
/// - Invalid version → returns upToDate (app continues)
class VersionService {
  final VersionRepository _versionRepository;

  VersionService({required VersionRepository versionRepository})
    : _versionRepository = versionRepository;

  /// Perform full version check.
  Future<VersionCheckResult> checkVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final appVersion = packageInfo.version;

      debugPrint('═══════════════════════════════════════════');
      debugPrint('📱 VERSION CHECK');
      debugPrint('───────────────────────────────────────────');
      debugPrint(
        'Installed Version: $appVersion (build ${packageInfo.buildNumber})',
      );

      AppLogger.info(
        'Installed Version: $appVersion (build ${packageInfo.buildNumber})',
        tag: 'VersionService',
      );

      final serverVersion = await _versionRepository.fetchServerVersion();

      debugPrint('Server Version: ${serverVersion.latestVersion}');
      debugPrint('Minimum Version: ${serverVersion.minimumVersion}');
      debugPrint('Force Update: ${serverVersion.forceUpdate}');
      debugPrint('APK URL: ${serverVersion.apkUrl}');

      AppLogger.info(
        'Server Version: ${serverVersion.latestVersion}',
        tag: 'VersionService',
      );
      AppLogger.info(
        'Minimum Version: ${serverVersion.minimumVersion}',
        tag: 'VersionService',
      );

      final status = _determineStatus(
        appVersion: appVersion,
        serverVersion: serverVersion,
      );

      debugPrint('Version Status: ${status.name}');
      debugPrint('═══════════════════════════════════════════');

      AppLogger.info('Version Status: ${status.name}', tag: 'VersionService');

      return VersionCheckResult(
        status: status,
        serverVersion: serverVersion,
        appVersion: appVersion,
      );
    } on NoInternetException {
      debugPrint('⚠️ Version check: No internet — skipping');
      AppLogger.warning(
        'No internet — skipping version check',
        tag: 'VersionService',
      );
      return _fallbackResult('No internet connection');
    } on ApiException catch (e) {
      debugPrint('⚠️ Version check: API error — ${e.message}');
      AppLogger.warning(
        'API error during version check: $e',
        tag: 'VersionService',
      );
      return _fallbackResult('Server error: ${e.message}');
    } on FormatException catch (e) {
      debugPrint('⚠️ Version check: Invalid data — $e');
      AppLogger.warning('Invalid version data: $e', tag: 'VersionService');
      return _fallbackResult('Invalid version data');
    } catch (e) {
      debugPrint('⚠️ Version check: Unexpected error — $e');
      AppLogger.error(
        'Unexpected error during version check',
        error: e,
        tag: 'VersionService',
      );
      return _fallbackResult(e.toString());
    }
  }

  /// Determine version status by comparing installed vs server versions.
  ///
  /// Priority:
  /// 1. If current < minimum → forceUpdate
  /// 2. If force_update=true AND current < latest → forceUpdate
  /// 3. If current < latest → updateAvailable
  /// 4. Otherwise → upToDate
  VersionStatus _determineStatus({
    required String appVersion,
    required VersionModel serverVersion,
  }) {
    final app = _parseVersion(appVersion);
    final minimum = _parseVersion(serverVersion.minimumVersion);
    final latest = _parseVersion(serverVersion.latestVersion);

    // Case 1: App version is below minimum supported → force update
    if (_isLessThan(app, minimum)) {
      return VersionStatus.forceUpdate;
    }

    // Case 2: Server explicitly says force update AND app is outdated
    if (serverVersion.forceUpdate && _isLessThan(app, latest)) {
      return VersionStatus.forceUpdate;
    }

    // Case 3: A newer version is available → optional update
    if (_isLessThan(app, latest)) {
      return VersionStatus.updateAvailable;
    }

    // Case 4: App is up to date
    return VersionStatus.upToDate;
  }

  /// Parse a semantic version string (e.g. "1.0.10") into integer segments.
  /// Each segment is parsed independently as an integer.
  /// This correctly handles: 1.0.9 < 1.0.10 (9 < 10, not string "9" vs "10").
  List<int> _parseVersion(String version) {
    return version.split('.').map((part) => int.tryParse(part) ?? 0).toList();
  }

  /// Returns true if version [a] is strictly less than version [b].
  /// Compares segment by segment: major, minor, patch, etc.
  /// Handles different segment lengths (e.g. "1.0" vs "1.0.1").
  bool _isLessThan(List<int> a, List<int> b) {
    final maxLength = a.length > b.length ? a.length : b.length;
    for (int i = 0; i < maxLength; i++) {
      final partA = i < a.length ? a[i] : 0;
      final partB = i < b.length ? b[i] : 0;
      if (partA < partB) return true;
      if (partA > partB) return false;
    }
    return false; // Versions are equal
  }

  /// Fallback result when version check fails. App continues normally.
  Future<VersionCheckResult> _fallbackResult(String error) async {
    String appVersion = '1.0.0';
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      appVersion = packageInfo.version;
    } catch (_) {}

    return VersionCheckResult(
      status: VersionStatus.upToDate,
      serverVersion: VersionModel(
        latestVersion: appVersion,
        minimumVersion: appVersion,
        forceUpdate: false,
        apkUrl: '',
      ),
      appVersion: appVersion,
      error: error,
    );
  }
}
