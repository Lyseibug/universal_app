import 'package:package_info_plus/package_info_plus.dart';

import '../../core/utils/logger.dart';
import '../datasources/version_api.dart';
import '../models/version_model.dart';

/// Repository for version management operations.
class VersionRepository {
  final VersionApi _versionApi;

  VersionRepository({required VersionApi versionApi})
    : _versionApi = versionApi;

  /// Check version status by comparing installed app version with server version.
  Future<
    ({VersionStatus status, VersionModel serverVersion, String appVersion})
  >
  checkVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final appVersion = packageInfo.version;

    AppLogger.info(
      'Current app version: $appVersion',
      tag: 'VersionRepository',
    );

    try {
      final serverVersion = await _versionApi.checkVersion();

      AppLogger.info(
        'Server version info - current: ${serverVersion.currentVersion}, '
        'minimum: ${serverVersion.minimumSupportedVersion}',
        tag: 'VersionRepository',
      );

      final status = _compareVersions(
        appVersion: appVersion,
        currentVersion: serverVersion.currentVersion,
        minimumVersion: serverVersion.minimumSupportedVersion,
      );

      return (
        status: status,
        serverVersion: serverVersion,
        appVersion: appVersion,
      );
    } catch (e) {
      AppLogger.warning(
        'Version check failed, continuing with current version: $e',
        tag: 'VersionRepository',
      );
      // If version check fails, allow app to continue
      return (
        status: VersionStatus.upToDate,
        serverVersion: VersionModel(
          currentVersion: appVersion,
          minimumSupportedVersion: appVersion,
          updateUrl: '',
        ),
        appVersion: appVersion,
      );
    }
  }

  /// Compare semantic versions.
  VersionStatus _compareVersions({
    required String appVersion,
    required String currentVersion,
    required String minimumVersion,
  }) {
    final app = _parseVersion(appVersion);
    final current = _parseVersion(currentVersion);
    final minimum = _parseVersion(minimumVersion);

    // Check if below minimum supported version
    if (_isLessThan(app, minimum)) {
      return VersionStatus.forceUpdate;
    }

    // Check if a newer version is available
    if (_isLessThan(app, current)) {
      return VersionStatus.updateAvailable;
    }

    return VersionStatus.upToDate;
  }

  /// Parse version string into list of integers.
  List<int> _parseVersion(String version) {
    return version.split('.').map((part) => int.tryParse(part) ?? 0).toList();
  }

  /// Check if version A is less than version B.
  bool _isLessThan(List<int> a, List<int> b) {
    for (int i = 0; i < 3; i++) {
      final partA = i < a.length ? a[i] : 0;
      final partB = i < b.length ? b[i] : 0;
      if (partA < partB) return true;
      if (partA > partB) return false;
    }
    return false;
  }
}
