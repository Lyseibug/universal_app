import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

/// Service for managing local storage operations.
/// Uses SharedPreferences for general data and FlutterSecureStorage for sensitive data.
class StorageService {
  late final SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  /// Initialize SharedPreferences instance.
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ─── ERP URL ───────────────────────────────────────────────────────────────

  /// Get the saved ERP URL, or return the default.
  /// Automatically upgrades old IP-based URLs to the correct domain.
  String getErpUrl() {
    final savedUrl = _prefs.getString(AppConstants.keyErpUrl);
    if (savedUrl == null) return AppConstants.defaultErpUrl;
    // Auto-fix: upgrade old IP-based URLs to the correct domain
    if (savedUrl.contains('35.153.170.12')) {
      return AppConstants.defaultErpUrl;
    }
    return savedUrl;
  }

  /// Save the ERP URL.
  Future<bool> saveErpUrl(String url) async {
    return _prefs.setString(AppConstants.keyErpUrl, url);
  }

  /// Check if ERP URL has been configured.
  bool hasErpUrl() {
    return _prefs.containsKey(AppConstants.keyErpUrl);
  }

  // ─── Login Session ─────────────────────────────────────────────────────────

  /// Check if user is logged in.
  bool isLoggedIn() {
    return _prefs.getBool(AppConstants.keyIsLoggedIn) ?? false;
  }

  /// Save login session data.
  Future<void> saveLoginSession({
    required String userId,
    required String userName,
    required String email,
    required String role,
  }) async {
    await _prefs.setBool(AppConstants.keyIsLoggedIn, true);
    await _prefs.setString(AppConstants.keyUserId, userId);
    await _prefs.setString(AppConstants.keyUserName, userName);
    await _prefs.setString(AppConstants.keyUserEmail, email);
    await _prefs.setString(AppConstants.keyUserRole, role);
  }

  /// Clear login session.
  Future<void> clearLoginSession() async {
    await _prefs.setBool(AppConstants.keyIsLoggedIn, false);
    await _prefs.remove(AppConstants.keyUserId);
    await _prefs.remove(AppConstants.keyUserName);
    await _prefs.remove(AppConstants.keyUserEmail);
    await _prefs.remove(AppConstants.keyUserRole);
    await deleteSessionCookies();
    await deleteAuthToken();
    await deleteRefreshToken();
  }

  /// Get saved user info.
  Map<String, String?> getUserInfo() {
    return {
      'userId': _prefs.getString(AppConstants.keyUserId),
      'userName': _prefs.getString(AppConstants.keyUserName),
      'email': _prefs.getString(AppConstants.keyUserEmail),
      'role': _prefs.getString(AppConstants.keyUserRole),
    };
  }

  // ─── Session Cookies (ERPNext/Frappe) ──────────────────────────────────────

  /// Save session cookies from ERPNext response.
  Future<void> saveSessionCookies(String cookies) async {
    await _secureStorage.write(
      key: AppConstants.keySessionCookies,
      value: cookies,
    );
  }

  /// Get stored session cookies.
  Future<String?> getSessionCookies() async {
    return _secureStorage.read(key: AppConstants.keySessionCookies);
  }

  /// Delete session cookies.
  Future<void> deleteSessionCookies() async {
    await _secureStorage.delete(key: AppConstants.keySessionCookies);
  }

  // ─── Secure Storage (Tokens) ───────────────────────────────────────────────

  /// Save authentication token securely.
  Future<void> saveAuthToken(String token) async {
    await _secureStorage.write(key: AppConstants.keyAuthToken, value: token);
  }

  /// Get stored authentication token.
  Future<String?> getAuthToken() async {
    return _secureStorage.read(key: AppConstants.keyAuthToken);
  }

  /// Delete authentication token.
  Future<void> deleteAuthToken() async {
    await _secureStorage.delete(key: AppConstants.keyAuthToken);
  }

  /// Save refresh token securely.
  Future<void> saveRefreshToken(String token) async {
    await _secureStorage.write(key: AppConstants.keyRefreshToken, value: token);
  }

  /// Get stored refresh token.
  Future<String?> getRefreshToken() async {
    return _secureStorage.read(key: AppConstants.keyRefreshToken);
  }

  /// Delete refresh token.
  Future<void> deleteRefreshToken() async {
    await _secureStorage.delete(key: AppConstants.keyRefreshToken);
  }

  // ─── Clear All ─────────────────────────────────────────────────────────────

  /// Clear all stored data (for logout or reset).
  Future<void> clearAll() async {
    await _prefs.clear();
    await _secureStorage.deleteAll();
  }
}
