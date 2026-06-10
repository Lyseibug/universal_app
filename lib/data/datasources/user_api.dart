import '../../core/api/api_client.dart';
import '../../core/constants/api_endpoints.dart';
import '../models/user_model.dart';

/// API service for ERPNext user-related endpoints.
class UserApi {
  final ApiClient _apiClient;

  UserApi({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Fetch user profile from ERPNext.
  /// Uses /api/resource/User/{email} endpoint.
  Future<UserModel> getProfile(String email) async {
    final response = await _apiClient.get('${ApiEndpoints.userProfile}/$email');
    final data = response.data as Map<String, dynamic>;
    final userData = data['data'] as Map<String, dynamic>? ?? data;
    return UserModel.fromFrappeJson(userData);
  }
}
