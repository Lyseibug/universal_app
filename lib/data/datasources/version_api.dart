import '../../core/api/api_client.dart';
import '../../core/constants/api_endpoints.dart';
import '../models/version_model.dart';

/// API service for version management endpoints.
class VersionApi {
  final ApiClient _apiClient;

  VersionApi({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Check the latest version info from ERP server.
  Future<VersionModel> checkVersion() async {
    final response = await _apiClient.get(ApiEndpoints.versionCheck);
    return VersionModel.fromJson(response.data as Map<String, dynamic>);
  }
}
