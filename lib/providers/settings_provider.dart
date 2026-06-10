import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/api_client.dart';
import '../data/repositories/settings_repository.dart';
import 'service_providers.dart';

/// Settings state.
class SettingsState {
  final String erpUrl;
  final bool isSaving;
  final bool isSaved;
  final String? error;

  const SettingsState({
    required this.erpUrl,
    this.isSaving = false,
    this.isSaved = false,
    this.error,
  });

  SettingsState copyWith({
    String? erpUrl,
    bool? isSaving,
    bool? isSaved,
    String? error,
  }) {
    return SettingsState(
      erpUrl: erpUrl ?? this.erpUrl,
      isSaving: isSaving ?? this.isSaving,
      isSaved: isSaved ?? this.isSaved,
      error: error,
    );
  }
}

/// Settings state notifier for managing ERP URL configuration.
class SettingsNotifier extends StateNotifier<SettingsState> {
  final SettingsRepository _settingsRepository;
  final ApiClient _apiClient;

  SettingsNotifier({
    required SettingsRepository settingsRepository,
    required ApiClient apiClient,
  }) : _settingsRepository = settingsRepository,
       _apiClient = apiClient,
       super(SettingsState(erpUrl: settingsRepository.getErpUrl()));

  /// Save the ERP URL.
  Future<bool> saveErpUrl(String url) async {
    state = state.copyWith(isSaving: true, error: null, isSaved: false);

    try {
      final trimmedUrl = url.trim().replaceAll(RegExp(r'/+$'), '');
      final success = await _settingsRepository.saveErpUrl(trimmedUrl);

      if (success) {
        // Update the API client base URL
        _apiClient.updateBaseUrl(trimmedUrl);
        state = state.copyWith(
          erpUrl: trimmedUrl,
          isSaving: false,
          isSaved: true,
        );
        return true;
      } else {
        state = state.copyWith(
          isSaving: false,
          error: 'Failed to save URL. Please try again.',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: 'Error saving URL: ${e.toString()}',
      );
      return false;
    }
  }

  /// Reset saved status (for UI feedback).
  void resetSavedStatus() {
    state = state.copyWith(isSaved: false);
  }
}

/// Provider for settings state.
final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) {
    final settingsRepository = ref.watch(settingsRepositoryProvider);
    final apiClient = ref.watch(apiClientProvider);
    return SettingsNotifier(
      settingsRepository: settingsRepository,
      apiClient: apiClient,
    );
  },
);
