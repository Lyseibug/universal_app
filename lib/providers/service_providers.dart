import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../core/api/api_client.dart';
import '../core/auth/session_repository.dart';
import '../core/auth/token_store.dart';
import '../core/menu/menu_models.dart';
import '../core/scanner/scan_service.dart';
import '../core/services/connectivity_service.dart';
import '../core/services/storage_service.dart';
import '../core/sync/write_queue.dart';
import '../core/sync/write_queue_entry.dart';
import '../data/repositories/settings_repository.dart';

// ─── Core Services ───────────────────────────────────────────────────────────

/// Storage service provider — overridden in main with initialized instance.
final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('StorageService must be initialized before use');
});

/// Connectivity service provider.
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});

/// Token store provider for secure token storage.
final tokenStoreProvider = Provider<TokenStore>((ref) {
  return TokenStore();
});

/// Provider to track session expiry events and break circular dependency cycles.
final sessionExpiredProvider = StateProvider<bool>((ref) => false);

// ─── API Client ──────────────────────────────────────────────────────────────

/// Central API client provider.
final apiClientProvider = Provider<ApiClient>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  final connectivityService = ref.watch(connectivityServiceProvider);
  final tokenStore = ref.watch(tokenStoreProvider);

  return ApiClient(
    tokenStore,
    baseUrl: storageService.getErpUrl(),
    connectivityService: connectivityService,
    onUnauthenticated: () {
      // Trigger session expired flag
      ref.read(sessionExpiredProvider.notifier).state = true;
    },
  );
});

// ─── Repositories ────────────────────────────────────────────────────────────

/// Session repository handling token-based auth and workspaces.
final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final tokenStore = ref.watch(tokenStoreProvider);
  return SessionRepository(apiClient, tokenStore);
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(storageService: ref.watch(storageServiceProvider));
});

// ─── Menu Provider ───────────────────────────────────────────────────────────

/// Provider for the active dynamic menu.
final menuProvider = FutureProvider<MenuPayload?>((ref) async {
  final repo = ref.watch(sessionRepositoryProvider);
  return repo.getMenu();
});

// ─── Write Queue ─────────────────────────────────────────────────────────────

final writeQueueProvider = Provider<WriteQueue>((ref) {
  final box = Hive.box<WriteQueueEntry>('write_queue');
  return WriteQueue(
    apiClient: ref.watch(apiClientProvider),
    box: box,
  );
});

// ─── Scanner ─────────────────────────────────────────────────────────────────

/// Keyboard-wedge scanner (primary — PDT hardware).
final keyboardScanServiceProvider = Provider<KeyboardWedgeScanService>((ref) {
  final service = KeyboardWedgeScanService();
  ref.onDispose(service.dispose);
  return service;
});

/// Camera scanner (fallback for non-PDT devices).
final cameraScanServiceProvider = Provider<CameraScanService>((ref) {
  final service = CameraScanService();
  ref.onDispose(service.dispose);
  return service;
});
