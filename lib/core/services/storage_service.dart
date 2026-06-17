import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

/// Service for managing local storage.
/// Uses SharedPreferences for general data (URLs, login flag).
/// Uses FlutterSecureStorage for sensitive data (session cookies).
class StorageService {
  late final SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  /// Initialize SharedPreferences.
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ─── ERP URL ──────────────────────────────────────────────────────────────

  /// Saved ERP base URL (defaults to the constant if not set).
  String getErpUrl() {
    return _prefs.getString(AppConstants.keyErpUrl) ?? AppConstants.defaultErpUrl;
  }

  Future<bool> saveErpUrl(String url) =>
      _prefs.setString(AppConstants.keyErpUrl, url);

  bool hasErpUrl() => _prefs.containsKey(AppConstants.keyErpUrl);

  // ─── Login Session ────────────────────────────────────────────────────────

  bool isLoggedIn() => _prefs.getBool(AppConstants.keyIsLoggedIn) ?? false;

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

  Future<void> clearLoginSession() async {
    await _prefs.setBool(AppConstants.keyIsLoggedIn, false);
    await _prefs.remove(AppConstants.keyUserId);
    await _prefs.remove(AppConstants.keyUserName);
    await _prefs.remove(AppConstants.keyUserEmail);
    await _prefs.remove(AppConstants.keyUserRole);
  }

  Map<String, String?> getUserInfo() => {
    'userId':   _prefs.getString(AppConstants.keyUserId),
    'userName': _prefs.getString(AppConstants.keyUserName),
    'email':    _prefs.getString(AppConstants.keyUserEmail),
    'role':     _prefs.getString(AppConstants.keyUserRole),
  };

  // ─── Clear All ────────────────────────────────────────────────────────────

  Future<void> clearAll() async {
    await _prefs.clear();
    await _secureStorage.deleteAll();
  }
}
