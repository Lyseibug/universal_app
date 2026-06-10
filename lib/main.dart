import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/services/storage_service.dart';
import 'core/theme/app_theme.dart';
import 'providers/service_providers.dart';
import 'routes/app_router.dart';

/// Entry point of the Universal ERP application.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize storage service before app starts
  final storageService = StorageService();
  await storageService.init();

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
