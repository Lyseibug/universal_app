import 'package:dio/dio.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exceptions.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/utils/logger.dart';
import '../models/login_response_model.dart';

/// API service for ERPNext/Frappe authentication.
///
/// Frappe login endpoint:
/// - POST /api/method/login
/// - Content-Type: application/x-www-form-urlencoded
/// - Body: usr=email&pwd=password
/// - Success (200): {"message":"Logged In","full_name":"...","home_page":"/app"}
/// - Failure (401): {"message":"Invalid login credentials","exc_type":"AuthenticationError"}
class AuthApi {
  final ApiClient _apiClient;

  AuthApi({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Login to ERPNext/Frappe with username (email) and password.
  Future<LoginResponseModel> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.login,
        data:
            'usr=${Uri.encodeComponent(username)}&pwd=${Uri.encodeComponent(password)}',
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          // Accept all status codes for login so we can parse the error body
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      AppLogger.info(
        'Login response status: ${response.statusCode}',
        tag: 'AuthApi',
      );
      AppLogger.debug('Login response data: ${response.data}', tag: 'AuthApi');

      return LoginResponseModel.fromFrappeJson(
        response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : {},
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      // Handle 401 specifically for login - extract the error message
      if (e.response?.statusCode == 401) {
        final data = e.response?.data;
        if (data is Map<String, dynamic>) {
          return LoginResponseModel.fromFrappeJson(data, statusCode: 401);
        }
      }

      // Handle ApiException from our ErrorInterceptor
      if (e.error is ApiException) {
        final apiError = e.error as ApiException;
        return LoginResponseModel(success: false, message: apiError.message);
      }

      // Re-throw for network/timeout errors
      rethrow;
    }
  }

  /// Get the currently logged-in user from ERPNext session.
  /// Endpoint: GET /api/method/frappe.auth.get_logged_user
  /// Returns the user email (e.g., "naziya@gmail.com") or empty string.
  Future<String> getLoggedUser() async {
    final response = await _apiClient.get(ApiEndpoints.getLoggedUser);
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return data['message'] as String? ?? '';
    }
    return '';
  }

  /// Logout from ERPNext and invalidate the session.
  Future<void> logout() async {
    try {
      await _apiClient.get(ApiEndpoints.logout);
    } catch (e) {
      AppLogger.warning('Logout API error (non-critical): $e', tag: 'AuthApi');
    }
  }
}
