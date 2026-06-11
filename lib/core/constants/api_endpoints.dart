/// Centralized API endpoint definitions for ERPNext/Frappe backend.
/// All endpoints are relative to the base ERP URL.
class ApiEndpoints {
  ApiEndpoints._();

  // Authentication (Frappe)
  static const String login = '/api/method/login';
  static const String logout = '/api/method/logout';
  static const String getLoggedUser = '/api/method/frappe.auth.get_logged_user';

  // Version Management (standalone URL — not relative to ERP base)
  static const String versionCheck =
      'https://universaltest.lyseibug.com/files/mobile-updates/version.json';

  // User
  static const String userProfile = '/api/resource/User';

  // Common
  static const String ping = '/api/method/ping';
}
