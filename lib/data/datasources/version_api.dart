import 'dart:convert';

import 'package:flutter/services.dart';

import '../../core/api/api_client.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/utils/logger.dart';
import '../models/version_model.dart';

/// API service for version management.
/// Supports both live ERP API and local mock for testing.
class VersionApi {
  final ApiClient _apiClient;

  /// Set to false to use the real server API.
  /// Set to true to use local mock JSON files for testing version dialogs.
  static const bool useMock = true;

  /// Mock scenario options (only used when useMock = true):
  /// - 'up_to_date'       → App is latest, no dialog shown
  /// - 'update_available' → Optional update dialog (can dismiss)
  /// - 'force_update'     → Force update dialog, blocks app usage
  static const String _mockScenario = 'update_available';

  VersionApi({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Check the latest version info from server.
  Future<VersionModel> checkVersion() async {
    if (useMock) {
      return _loadMockVersion();
    }
    return _fetchFromServer();
  }

  /// Fetch version info from ERP server.
  /// Expected server response format:
  /// {
  ///   "current_version": "1.1.0",
  ///   "minimum_supported_version": "1.0.0",
  ///   "force_update": false,
  ///   "update_url": "https://universaltest.lyseibug.com/files/universal-v1.1.0.apk",
  ///   "message": "A new version is available."
  /// }
  Future<VersionModel> _fetchFromServer() async {
    final response = await _apiClient.get(ApiEndpoints.versionCheck);
    final data = response.data;

    AppLogger.debug('Version check response: $data', tag: 'VersionApi');

    if (data is Map<String, dynamic>) {
      // Frappe wraps API responses in a "message" key
      if (data.containsKey('message') &&
          data['message'] is Map<String, dynamic>) {
        return VersionModel.fromJson(data['message'] as Map<String, dynamic>);
      }
      // Direct JSON response (no Frappe wrapper)
      return VersionModel.fromJson(data);
    }

    throw Exception('Invalid version response format');
  }

  /// Load mock version data from local assets for testing.
  Future<VersionModel> _loadMockVersion() async {
    AppLogger.info(
      'Using mock version data: $_mockScenario',
      tag: 'VersionApi',
    );

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    final jsonString = await rootBundle.loadString(
      'assets/mock/version_$_mockScenario.json',
    );
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return VersionModel.fromJson(json);
  }
}
