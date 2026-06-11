import '../../core/utils/logger.dart';
import '../datasources/version_api.dart';
import '../models/version_model.dart';

/// Repository for version management.
/// Fetches version data from the data source.
/// Business logic (comparison, status) lives in VersionService.
class VersionRepository {
  final VersionApi _versionApi;

  VersionRepository({required VersionApi versionApi})
    : _versionApi = versionApi;

  /// Fetch server version information.
  /// Throws on network/parsing failures — service layer handles errors.
  Future<VersionModel> fetchServerVersion() async {
    AppLogger.debug(
      'Fetching version.json from server...',
      tag: 'VersionRepository',
    );

    final serverVersion = await _versionApi.checkVersion();

    AppLogger.info(
      'Server version fetched — latest: ${serverVersion.latestVersion}, '
      'minimum: ${serverVersion.minimumVersion}, '
      'force_update: ${serverVersion.forceUpdate}',
      tag: 'VersionRepository',
    );

    return serverVersion;
  }
}
