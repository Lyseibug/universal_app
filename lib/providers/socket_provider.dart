import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/models/app_notification.dart';
import '../core/services/socket_service.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/logger.dart';
import '../main.dart';
import '../routes/app_router.dart';
import 'auth_provider.dart';
import 'notification_provider.dart';
import 'service_providers.dart';

class SocketNotifier extends StateNotifier<void> {
  final Ref _ref;
  SocketService? _service;

  SocketNotifier(this._ref) : super(null) {
    _init();
  }

  void _init() {
    // Listen to authentication changes to connect/disconnect socket
    _ref.listen<AuthState>(
      authProvider,
      (previous, next) {
        final employee = next.session?.employee;
        if (next.isAuthenticated && employee != null && employee.isNotEmpty) {
          _connect(employee);
        } else {
          // No Employee linked to this user → no per-employee socket room to join.
          if (next.isAuthenticated) {
            AppLogger.warning(
                'Session has no employee code; skipping socket connect',
                tag: 'SocketNotifier');
          }
          _disconnect();
        }
      },
      fireImmediately: true,
    );
  }

  Future<void> _connect(String employeeId) async {
    _disconnect(); // Clean up previous socket if any

    final erpUrl = _ref.read(storageServiceProvider).getErpUrl();
    final token = await _ref.read(tokenStoreProvider).read();
    final userEmail = await _ref.read(sessionRepositoryProvider).getUsername() ?? '';

    if (erpUrl.isEmpty || token == null || token.isEmpty) {
      AppLogger.warning('Cannot connect socket: URL or token is missing', tag: 'SocketNotifier');
      return;
    }

    _service = SocketService(
      baseUrl: erpUrl,
      token: token,
      employeeId: employeeId,
      userEmail: userEmail,
      onNotificationReceived: (data) {
        _handleNotification(data);
      },
    );

    _service?.connect();
  }

  void _disconnect() {
    _service?.disconnect();
    _service = null;
  }

  void _handleNotification(Map<String, dynamic> data) {
    try {
      final map = Map<String, dynamic>.from(data);
      // Map 'name' from ERPNext to 'id' for the app model
      map['id'] = map['name'] ?? map['id'] ?? '';
      
      // Parse creation time correctly
      if (map['creation'] != null && map['creation'] is String) {
        final dateStr = map['creation'] as String;
        map['creation'] = DateTime.parse(dateStr).toIso8601String();
      } else {
        map['creation'] = DateTime.now().toIso8601String();
      }

      final notification = AppNotification.fromJson(map);

      // 1. Update count
      _ref.read(unreadNotificationCountProvider.notifier).increment();
      
      // 2. Insert into notifications list
      _ref.read(notificationsListProvider.notifier).insertNotification(notification);

      // 3. Show global SnackBar notification if not already on notifications screen
      final router = _ref.read(appRouterProvider);
      final currentPath = router.routerDelegate.currentConfiguration.uri.path;
      if (currentPath != '/notifications') {
        scaffoldMessengerKey.currentState?.clearSnackBars();
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.notifications_active, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    notification.subject,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.primary,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'VIEW',
              textColor: AppTheme.amber,
              onPressed: () {
                router.push('/notifications');
              },
            ),
          ),
        );
      }

      AppLogger.info('Successfully parsed and processed socket notification: ${notification.id}', tag: 'SocketNotifier');
    } catch (e, stack) {
      AppLogger.error('Failed to parse socket notification payload: $e', tag: 'SocketNotifier', stackTrace: stack);
    }
  }

  @override
  void dispose() {
    _disconnect();
    super.dispose();
  }
}

/// Provider that manages Socket.io connection lifecycle
final socketProvider = StateNotifierProvider<SocketNotifier, void>((ref) {
  return SocketNotifier(ref);
});
