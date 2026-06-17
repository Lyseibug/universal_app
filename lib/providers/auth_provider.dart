import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/auth/session_models.dart';
import '../core/auth/session_repository.dart';
import '../core/auth/token_store.dart';
import '../core/utils/logger.dart';
import 'service_providers.dart';

const _tag = 'AuthNotifier';

/// Complete authentication + session state for the PDT app.
class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  
  /// Stored session details (populated after login and workspace selection)
  final SessionInfo? session;
  final String? error;

  const AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.session,
    this.error,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    SessionInfo? session,
    String? error,
    bool clearError = false,
    bool clearSession = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      session: clearSession ? null : (session ?? this.session),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Manages token authentication state, login, logout, and workstation session selection.
class AuthNotifier extends StateNotifier<AuthState> {
  final SessionRepository _sessionRepository;
  final TokenStore _tokenStore;
  final Ref _ref;

  AuthNotifier({
    required SessionRepository sessionRepository,
    required TokenStore tokenStore,
    required Ref ref,
  })  : _sessionRepository = sessionRepository,
        _tokenStore = tokenStore,
        _ref = ref,
        super(const AuthState()) {
    _checkAuthStatus();
    _listenToSessionExpiry();
  }

  /// Verify on startup if a secure token is already present.
  ///
  /// If present, we pre-authenticate the state so GoRouter doesn't immediately boot to login.
  /// The SplashScreen/bootstrap then triggers remote checks to load the menu/workspace info.
  void _checkAuthStatus() async {
    final token = await _tokenStore.read();
    if (token != null && token.isNotEmpty) {
      AppLogger.info('Found stored session token', tag: _tag);
      
      // Try to load cached session info if available to pre-fill the workspace/employee name
      final cachedSession = await _sessionRepository.getSessionInfo();
      state = AuthState(
        isAuthenticated: true,
        session: cachedSession,
      );
    } else {
      AppLogger.info('No stored session token found', tag: _tag);
      state = const AuthState();
    }
  }

  /// Listen to the session expiry state provider.
  void _listenToSessionExpiry() {
    _ref.listen<bool>(sessionExpiredProvider, (prev, next) {
      if (next == true) {
        AppLogger.warning('Session expired. Logging out worker.', tag: _tag);
        logout();
        _ref.read(sessionExpiredProvider.notifier).state = false; // Reset the trigger
      }
    });
  }

  /// Perform login using Token authentication params (`usr` / `pwd`).
  Future<bool> login({
    required String username,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final roles = await _sessionRepository.login(username, password);
      final sessionInfo = await _sessionRepository.getSessionInfo();
      
      // Successfully logged in (token stored by repo)
      state = AuthState(
        isAuthenticated: true,
        session: sessionInfo,
      );
      AppLogger.info('Logged in successfully. Assigned roles: $roles', tag: _tag);
      return true;
    } catch (e) {
      String msg = 'Login failed. Please try again.';
      if (e.toString().contains('ApiException:')) {
        msg = e.toString().replaceFirst('ApiException: ', '');
      } else if (e.toString().contains('Exception:')) {
        msg = e.toString().replaceFirst('Exception: ', '');
      }
      state = state.copyWith(isLoading: false, error: msg);
      return false;
    }
  }

  /// Set active workstation session details after user picks a workspace.
  void setSession(SessionInfo session) {
    state = state.copyWith(session: session);
  }

  /// Clear session credentials and reset navigation.
  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    await _sessionRepository.logout();
    state = const AuthState();
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

/// Provider for authentication + session state.
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final sessionRepository = ref.watch(sessionRepositoryProvider);
  final tokenStore = ref.watch(tokenStoreProvider);
  return AuthNotifier(
    sessionRepository: sessionRepository,
    tokenStore: tokenStore,
    ref: ref,
  );
});
