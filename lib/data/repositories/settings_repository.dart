import '../../core/services/storage_service.dart';
import '../../core/utils/logger.dart';

/// Repository for application settings.
class SettingsRepository {
  final StorageService _storageService;

  SettingsRepository({required StorageService storageService})
    : _storageService = storageService;

  /// Get the current ERP URL.
  String getErpUrl() {
    return _storageService.getErpUrl();
  }

  /// Save the ERP URL.
  Future<bool> saveErpUrl(String url) async {
    final result = await _storageService.saveErpUrl(url);
    AppLogger.info('ERP URL saved: $url', tag: 'SettingsRepository');
    return result;
  }

  /// Check if ERP URL has been configured by user.
  bool hasConfiguredErpUrl() {
    return _storageService.hasErpUrl();
  }
}
