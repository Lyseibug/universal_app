import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../screens/home/home_screen.dart';
import '../screens/login/login_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/workspace/workspace_screen.dart';
import '../screens/workstation/workstation_setup_screen.dart';

/// Application router.
///
/// Redirect logic:
///  - Not authenticated       → /login
///  - Authenticated, no workspace → /workspace
///  - Otherwise               → stays on requested route (e.g. /home)
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
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

      // ── Workstation Setup (post-login, pre-production) ─────────────────────
      GoRoute(
        path: '/workstation-setup',
        builder: (context, state) => const WorkstationSetupScreen(),
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
