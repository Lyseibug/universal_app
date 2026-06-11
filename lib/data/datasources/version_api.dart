import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

import '../../core/api/api_exceptions.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/utils/logger.dart';
import '../models/version_model.dart';

/// API data source for version management.
/// Fetches version info from:
/// https://universaltest.lyseibug.com/files/mobile-updates/version.json
///
/// This does NOT use the main ApiClient because the version endpoint
/// is a standalone static JSON file, not relative to the ERP base URL.
///
/// Expected JSON format at the URL:
/// {
///   "latest_version": "1.0.2",
///   "minimum_version": "1.0.0",
///   "force_update": false,
///   "apk_url": "https://universaltest.lyseibug.com/files/mobile-updates/app-release.apk",
///   "message": "A new version is available."
/// }
class VersionApi {
  /// Dedicated Dio instance for version check (no cookies, no ERP base URL).
  final Dio _dio;

  /// Set to true to use local mock JSON files for testing version dialogs.
  static const bool useMock = false;

  /// Mock scenario (only used when useMock = true):
  /// - 'up_to_date'       → App is latest, no dialog shown
  /// - 'update_available' → Optional update dialog
  /// - 'force_update'     → Force update dialog (non-dismissible)
  static const String _mockScenario = 'update_available';

  VersionApi()
    : _dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {'Accept': 'application/json'},
        ),
      );

  /// Check the latest version info.
  /// Returns parsed [VersionModel] or throws on failure.
  Future<VersionModel> checkVersion() async {
    if (useMock) {
      return _loadMockVersion();
    }
    return _fetchFromServer();
  }

  /// Fetch version.json from the standalone server URL.
  Future<VersionModel> _fetchFromServer() async {
    try {
      final response = await _dio.get(ApiEndpoints.versionCheck);

      AppLogger.debug(
        'Version API response: ${response.data}',
        tag: 'VersionApi',
      );

      if (response.statusCode != 200) {
        throw ApiException(
          message: 'Version check failed with status ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }

      final data = response.data;

      if (data == null) {
        throw ApiException(
          message: 'Empty response from version check',
          statusCode: response.statusCode,
        );
      }

      // Handle if data is a String (raw JSON)
      Map<String, dynamic> json;
      if (data is String) {
        json = jsonDecode(data) as Map<String, dynamic>;
      } else if (data is Map<String, dynamic>) {
        json = data;
      } else {
        throw ApiException(
          message: 'Invalid version response format',
          statusCode: response.statusCode,
        );
      }

      // Handle Frappe-style wrapper if present
      if (json.containsKey('message') &&
          json['message'] is Map<String, dynamic>) {
        return VersionModel.fromJson(json['message'] as Map<String, dynamic>);
      }

      return VersionModel.fromJson(json);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        throw NoInternetException();
      }
      AppLogger.error('Version API Dio error', error: e, tag: 'VersionApi');
      throw ApiException(
        message: 'Failed to fetch version info: ${e.message}',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      if (e is NoInternetException || e is ApiException) rethrow;
      AppLogger.error('Version API call failed', error: e, tag: 'VersionApi');
      throw ApiException(
        message: 'Failed to fetch version info: ${e.toString()}',
      );
    }
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
