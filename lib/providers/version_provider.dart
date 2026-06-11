import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/version_service.dart';
import '../data/models/version_model.dart';
import 'service_providers.dart';

/// Version check state.
class VersionState {
  final bool isChecking;
  final VersionStatus? status;
  final VersionModel? serverVersion;
  final String? appVersion;
  final String? error;

  const VersionState({
    this.isChecking = false,
    this.status,
    this.serverVersion,
    this.appVersion,
    this.error,
  });

  VersionState copyWith({
    bool? isChecking,
    VersionStatus? status,
    VersionModel? serverVersion,
    String? appVersion,
    String? error,
  }) {
    return VersionState(
      isChecking: isChecking ?? this.isChecking,
      status: status ?? this.status,
      serverVersion: serverVersion ?? this.serverVersion,
      appVersion: appVersion ?? this.appVersion,
      error: error,
    );
  }
}

/// Version management state notifier.
class VersionNotifier extends StateNotifier<VersionState> {
  final VersionService _versionService;

  VersionNotifier({required VersionService versionService})
    : _versionService = versionService,
      super(const VersionState());

  /// Perform version check.
  /// Returns the [VersionStatus] for the splash screen to act on.
  Future<VersionStatus> checkVersion() async {
    state = state.copyWith(isChecking: true, error: null);

    final result = await _versionService.checkVersion();

    state = VersionState(
      isChecking: false,
      status: result.status,
      serverVersion: result.serverVersion,
      appVersion: result.appVersion,
      error: result.error,
    );

    return result.status;
  }

  /// Launch the APK download URL.
  Future<bool> launchUpdate() async {
    final url = state.serverVersion?.apkUrl;
    if (url == null || url.isEmpty) return false;
    return _versionService.launchUpdate(url);
  }
}

/// Provider for version service.
final versionServiceProvider = Provider<VersionService>((ref) {
  final versionRepository = ref.watch(versionRepositoryProvider);
  return VersionService(versionRepository: versionRepository);
});

/// Provider for version management state.
final versionProvider = StateNotifierProvider<VersionNotifier, VersionState>((
  ref,
) {
  final versionService = ref.watch(versionServiceProvider);
  return VersionNotifier(versionService: versionService);
});
