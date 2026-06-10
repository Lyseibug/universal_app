import '../../core/api/api_client.dart';
import '../../core/constants/api_endpoints.dart';

/// API service for common/shared ERPNext endpoints.
class CommonApi {
  final ApiClient _apiClient;

  CommonApi({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Ping - verify ERPNext server is reachable.
  Future<bool> healthCheck() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.ping);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
