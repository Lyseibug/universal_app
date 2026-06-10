import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/user_model.dart';
import '../data/repositories/user_repository.dart';
import 'auth_provider.dart';
import 'service_providers.dart';

/// User profile state.
class UserProfileState {
  final bool isLoading;
  final UserModel? user;
  final String? error;

  const UserProfileState({this.isLoading = false, this.user, this.error});

  UserProfileState copyWith({bool? isLoading, UserModel? user, String? error}) {
    return UserProfileState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      error: error,
    );
  }
}

/// User profile state notifier for ERPNext.
class UserProfileNotifier extends StateNotifier<UserProfileState> {
  final UserRepository _userRepository;
  final String? _userEmail;

  UserProfileNotifier({
    required UserRepository userRepository,
    required String? userEmail,
  }) : _userRepository = userRepository,
       _userEmail = userEmail,
       super(const UserProfileState());

  /// Fetch user profile from ERPNext.
  Future<void> fetchProfile() async {
    if (_userEmail == null || _userEmail.isEmpty) {
      state = state.copyWith(error: 'No user email available');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = await _userRepository.getProfile(_userEmail);
      state = UserProfileState(user: user);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load profile: ${e.toString()}',
      );
    }
  }
}

/// Provider for user profile state.
final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfileState>((ref) {
      final userRepository = ref.watch(userRepositoryProvider);
      final authState = ref.watch(authProvider);
      return UserProfileNotifier(
        userRepository: userRepository,
        userEmail: authState.user?.email,
      );
    });
