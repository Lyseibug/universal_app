import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/version_model.dart';
import '../data/repositories/version_repository.dart';
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
  final VersionRepository _versionRepository;

  VersionNotifier({required VersionRepository versionRepository})
    : _versionRepository = versionRepository,
      super(const VersionState());

  /// Perform version check against ERP server.
  Future<VersionStatus> checkVersion() async {
    state = state.copyWith(isChecking: true, error: null);

    try {
      final result = await _versionRepository.checkVersion();
      state = VersionState(
        isChecking: false,
        status: result.status,
        serverVersion: result.serverVersion,
        appVersion: result.appVersion,
      );
      return result.status;
    } catch (e) {
      state = state.copyWith(
        isChecking: false,
        status: VersionStatus.upToDate,
        error: e.toString(),
      );
      return VersionStatus.upToDate;
    }
  }
}

/// Provider for version management state.
final versionProvider = StateNotifierProvider<VersionNotifier, VersionState>((
  ref,
) {
  final versionRepository = ref.watch(versionRepositoryProvider);
  return VersionNotifier(versionRepository: versionRepository);
});
