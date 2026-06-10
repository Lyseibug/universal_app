import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/api_client.dart';
import '../core/services/connectivity_service.dart';
import '../core/services/storage_service.dart';
import '../data/datasources/auth_api.dart';
import '../data/datasources/common_api.dart';
import '../data/datasources/user_api.dart';
import '../data/datasources/version_api.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../data/repositories/user_repository.dart';
import '../data/repositories/version_repository.dart';

// ─── Core Services ───────────────────────────────────────────────────────────

/// Storage service provider - must be overridden in main with initialized instance.
final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('StorageService must be initialized before use');
});

/// Connectivity service provider.
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});

// ─── API Client ──────────────────────────────────────────────────────────────

/// Central API client provider.
final apiClientProvider = Provider<ApiClient>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  final connectivityService = ref.watch(connectivityServiceProvider);
  return ApiClient(
    storageService: storageService,
    connectivityService: connectivityService,
  );
});

// ─── API Services ────────────────────────────────────────────────────────────

final authApiProvider = Provider<AuthApi>((ref) {
  return AuthApi(apiClient: ref.watch(apiClientProvider));
});

final versionApiProvider = Provider<VersionApi>((ref) {
  return VersionApi(apiClient: ref.watch(apiClientProvider));
});

final userApiProvider = Provider<UserApi>((ref) {
  return UserApi(apiClient: ref.watch(apiClientProvider));
});

final commonApiProvider = Provider<CommonApi>((ref) {
  return CommonApi(apiClient: ref.watch(apiClientProvider));
});

// ─── Repositories ────────────────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    authApi: ref.watch(authApiProvider),
    storageService: ref.watch(storageServiceProvider),
  );
});

final versionRepositoryProvider = Provider<VersionRepository>((ref) {
  return VersionRepository(versionApi: ref.watch(versionApiProvider));
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(storageService: ref.watch(storageServiceProvider));
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(userApi: ref.watch(userApiProvider));
});
