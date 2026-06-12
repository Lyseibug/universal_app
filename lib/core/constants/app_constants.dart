/// Application-wide constants.
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'Universal ERP';
  static const String companyName = 'Universal';

  // Default ERP Server URL (not hardcoded for usage - stored in SharedPreferences)
  static const String defaultErpUrl = 'https://universaltest.lyseibug.com';

  // SharedPreferences Keys
  static const String keyErpUrl = 'erp_url';
  static const String keyIsLoggedIn = 'is_logged_in';
  static const String keyUserId = 'user_id';
  static const String keyUserName = 'user_name';
  static const String keyUserEmail = 'user_email';
  static const String keyUserRole = 'user_role';

  // Update / version tracking
  /// Version we attempted to install via the in-app updater. On next launch we
  /// compare the running version against this to confirm the install succeeded.
  static const String keyPendingUpdateVersion = 'pending_update_version';

  // Secure Storage Keys
  static const String keyAuthToken = 'auth_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keySessionCookies = 'session_cookies';

  // Timeouts (in seconds)
  static const int connectionTimeout = 30;
  static const int receiveTimeout = 30;
  static const int maxRetries = 3;

  // UI Constants
  static const double borderRadius = 12.0;
  static const double buttonHeight = 52.0;
  static const double inputHeight = 56.0;
  static const double horizontalPadding = 24.0;
}
