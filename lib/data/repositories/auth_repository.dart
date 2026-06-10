import '../../core/services/storage_service.dart';
import '../../core/utils/logger.dart';
import '../datasources/auth_api.dart';
import '../models/user_model.dart';

/// Repository for ERPNext/Frappe authentication operations.
/// Frappe uses cookie-based sessions (sid cookie).
class AuthRepository {
  final AuthApi _authApi;
  final StorageService _storageService;

  AuthRepository({
    required AuthApi authApi,
    required StorageService storageService,
  }) : _authApi = authApi,
       _storageService = storageService;

  /// Perform login to ERPNext and persist session.
  Future<UserModel> login({
    required String username,
    required String password,
  }) async {
    // Call Frappe login endpoint
    final response = await _authApi.login(
      username: username,
      password: password,
    );

    if (!response.success) {
      throw Exception(response.message ?? 'Login failed. Invalid credentials.');
    }

    // After successful login, cookies are automatically saved by CookieInterceptor.
    // Now fetch the logged-in user email to confirm the session is active.
    final loggedUserEmail = await _authApi.getLoggedUser();

    AppLogger.info('Logged in as: $loggedUserEmail', tag: 'AuthRepository');

    // Build user model from login response
    final user = UserModel(
      id: loggedUserEmail,
      username: loggedUserEmail,
      email: loggedUserEmail,
      role: 'User',
      fullName: response.fullName,
    );

    // Persist session locally
    await _storageService.saveLoginSession(
      userId: user.id,
      userName: user.username,
      email: user.email,
      role: user.role,
    );

    AppLogger.info(
      'Login session saved for: ${user.email}',
      tag: 'AuthRepository',
    );
    return user;
  }

  /// Perform logout and clear session.
  Future<void> logout() async {
    try {
      await _authApi.logout();
    } catch (e) {
      AppLogger.warning('Logout API call failed: $e', tag: 'AuthRepository');
    } finally {
      await _storageService.clearLoginSession();
      AppLogger.info('Session cleared', tag: 'AuthRepository');
    }
  }

  /// Check if user has an active local session.
  bool isLoggedIn() {
    return _storageService.isLoggedIn();
  }

  /// Get cached user info from local storage.
  UserModel? getCachedUser() {
    final info = _storageService.getUserInfo();
    if (info['userId'] == null) return null;
    return UserModel(
      id: info['userId']!,
      username: info['userName'] ?? '',
      email: info['email'] ?? '',
      role: info['role'] ?? '',
    );
  }

  /// Verify if the stored session is still valid by calling ERPNext.
  Future<bool> verifySession() async {
    try {
      final user = await _authApi.getLoggedUser();
      return user.isNotEmpty && user != 'Guest';
    } catch (_) {
      return false;
    }
  }
}
