/// Centralized API endpoint definitions for ERPNext/Frappe backend.
/// All endpoints are relative to the base ERP URL.
class ApiEndpoints {
  ApiEndpoints._();

  // Authentication (Frappe)
  static const String login = '/api/method/login';
  static const String logout = '/api/method/logout';
  static const String getLoggedUser = '/api/method/frappe.auth.get_logged_user';

  // Version Management — relative path appended to ERP base URL by AppUpdateService.
  // Frappe endpoint: allow_guest=True (no auth token required).
  static const String versionCheck =
      '/api/method/universal_mobile_api.api.app_update.get_version_info';

  // User
  static const String userProfile = '/api/resource/User';

  // Common
  static const String ping = '/api/method/ping';
}
