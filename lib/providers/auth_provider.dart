import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/user_model.dart';
import '../data/repositories/auth_repository.dart';
import 'service_providers.dart';

/// Authentication state.
class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final UserModel? user;
  final String? error;

  const AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.user,
    this.error,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    UserModel? user,
    String? error,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      error: error,
    );
  }
}

/// Authentication state notifier managing login/logout operations.
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;

  AuthNotifier({required AuthRepository authRepository})
    : _authRepository = authRepository,
      super(const AuthState()) {
    // Check initial authentication state
    _checkAuthStatus();
  }

  /// Check if user is already authenticated.
  void _checkAuthStatus() {
    final isLoggedIn = _authRepository.isLoggedIn();
    if (isLoggedIn) {
      final user = _authRepository.getCachedUser();
      state = AuthState(isAuthenticated: true, user: user);
    }
  }

  /// Perform login.
  Future<bool> login({
    required String username,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = await _authRepository.login(
        username: username,
        password: password,
      );
      state = AuthState(isAuthenticated: true, user: user);
      return true;
    } catch (e) {
      String errorMessage = 'Login failed. Please try again.';
      if (e.toString().contains('Exception:')) {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      }
      state = state.copyWith(isLoading: false, error: errorMessage);
      return false;
    }
  }

  /// Perform logout.
  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    await _authRepository.logout();
    state = const AuthState();
  }

  /// Clear error message.
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for authentication state.
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthNotifier(authRepository: authRepository);
});
