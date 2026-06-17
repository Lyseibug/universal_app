import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/services/hive_service.dart';
import 'core/services/storage_service.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/logger.dart';
import 'providers/service_providers.dart';
import 'routes/app_router.dart';

/// Entry point of the Universal PDT WMS application.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive (boxes: write_queue, settings, session, menus)
  await initHive();

  // Initialize SharedPreferences-backed storage service
  final storageService = StorageService();
  await storageService.init();

  AppLogger.info('App started', tag: 'Main');

  final container = ProviderContainer(
    overrides: [
      storageServiceProvider.overrideWithValue(storageService),
    ],
  );

  // Wire up auto-flushing of the write queue on network restoration
  final connectivity = container.read(connectivityServiceProvider);
  final writeQueue = container.read(writeQueueProvider);
  connectivity.onConnectivityChanged.listen((results) {
    final hasNetwork = results.any((r) => r != ConnectivityResult.none);
    if (hasNetwork) {
      AppLogger.info('Network restored. Flushing pending writes...', tag: 'Main');
      writeQueue.flush();
    }
  });

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const PdtApp(),
    ),
  );
}

/// Root widget of the PDT WMS application.
class PdtApp extends ConsumerWidget {
  const PdtApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Universal WMS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
