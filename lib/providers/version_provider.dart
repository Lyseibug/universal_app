import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../core/services/version_service.dart';
import '../core/utils/logger.dart';
import '../data/models/version_model.dart';
import 'service_providers.dart';

/// Live installed app version provider.
///
/// Reads the version directly from package_info_plus every time it's invalidated.
/// After an APK update + restart, this returns the NEW version automatically.
///
/// Usage in UI:
///   final versionAsync = ref.watch(appVersionProvider);
///   versionAsync.when(
///     data: (v) => Text('Current Version: $v'),
///     loading: () => Text('Current Version: ...'),
///     error: (_, __) => Text('Current Version: -'),
///   );
final appVersionProvider = FutureProvider<String>((ref) async {
  final packageInfo = await PackageInfo.fromPlatform();
  final version = packageInfo.version;
  AppLogger.info(
    'Installed Version (package_info_plus): $version (build ${packageInfo.buildNumber})',
    tag: 'AppVersionProvider',
  );
  return version;
});

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
