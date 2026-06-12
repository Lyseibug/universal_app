import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'core/services/storage_service.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/logger.dart';
import 'providers/service_providers.dart';
import 'routes/app_router.dart';

/// Entry point of the Universal ERP application.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize storage service before app starts
  final storageService = StorageService();
  await storageService.init();

  // Log the actual installed version reported by the binary.
  // This is the SOURCE OF TRUTH for what version is running.
  await _logInstalledVersion(storageService);

  runApp(
    ProviderScope(
      overrides: [
        // Override with the initialized storage service instance
        storageServiceProvider.overrideWithValue(storageService),
      ],
      child: const UniversalApp(),
    ),
  );
}

/// Print the installed app version from package_info_plus.
/// Use this to verify the APK was built with the correct version, and to
/// confirm whether a pending in-app update actually completed.
Future<void> _logInstalledVersion(StorageService storage) async {
  try {
    final info = await PackageInfo.fromPlatform();
    final installedVersion = info.version;
    final pending = storage.getPendingUpdateVersion();

    debugPrint('═══════════════════════════════════════════');
    debugPrint('✅ Installed Version After Update');
    debugPrint('PackageInfo.appName     : ${info.appName}');
    debugPrint('PackageInfo.packageName : ${info.packageName}');
    debugPrint('PackageInfo.version     : $installedVersion');
    debugPrint('PackageInfo.buildNumber : ${info.buildNumber}');
    debugPrint('Pending update target   : ${pending ?? "(none)"}');
    debugPrint('═══════════════════════════════════════════');

    AppLogger.info(
      'Installed Version After Update: $installedVersion+${info.buildNumber}',
      tag: 'Main',
    );

    // ─── Verify pending in-app update outcome ──────────────────────────────
    if (pending != null) {
      if (installedVersion == pending) {
        debugPrint('[Main] ✅ Update SUCCESS — now running v$installedVersion');
        AppLogger.info(
          'In-app update succeeded: now running v$installedVersion',
          tag: 'Main',
        );
        await storage.clearPendingUpdateVersion();
      } else {
        debugPrint(
          '[Main] ⚠️ Update NOT applied — expected v$pending but running '
          'v$installedVersion. The user likely cancelled the install or it '
          'failed silently (check install-unknown-apps permission).',
        );
        AppLogger.warning(
          'In-app update not applied: expected v$pending, running '
          'v$installedVersion',
          tag: 'Main',
        );
        // Keep the marker so the update prompt can re-trigger.
      }
    }
  } catch (e) {
    debugPrint('[Main] Failed to read package info: $e');
  }
}

/// Root widget of the application.
/// Uses Riverpod's ConsumerWidget for reactive state management.
class UniversalApp extends ConsumerWidget {
  const UniversalApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Universal ERP',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
