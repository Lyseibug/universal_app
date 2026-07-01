import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../screens/home/home_screen.dart';
import '../screens/login/login_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/workspace/workspace_screen.dart';

/// Root navigator key — lets cross-cutting global UI (e.g. the worker
/// idle/overrun prompt dialog) show on top of whatever screen is active,
/// without needing a BuildContext from inside the widget tree.
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// Application router.
///
/// Redirect logic:
///  - Not authenticated       → /login
///  - Authenticated, no workspace → /workspace
///  - Otherwise               → stays on requested route (e.g. /home)
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final loc = state.uri.path;

      // Public routes — no auth required
      const publicRoutes = ['/', '/login', '/settings'];
      if (publicRoutes.contains(loc)) return null;

      // Not authenticated → login
      if (!authState.isAuthenticated) return '/login';

      return null;
    },
    routes: [
      // ── Splash ────────────────────────────────────────────────────────────
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),

      // ── Auth ──────────────────────────────────────────────────────────────
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      // ── Settings (accessible pre-login for URL config) ─────────────────────
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),

      // ── Workspace picker ───────────────────────────────────────────────────
      GoRoute(
        path: '/workspace',
        builder: (context, state) => const WorkspaceScreen(),
      ),

      // ── Home (dynamic menu) ────────────────────────────────────────────────
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),

      // ── Notifications ──────────────────────────────────────────────────────
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
    ],
  );
});
