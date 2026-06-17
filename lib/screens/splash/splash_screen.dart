import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/service_providers.dart';

/// Splash screen — animates for 1.5 s then routes based on auth state.
///
/// Flow:
///  1. Fade-in animation
///  2. Check auth (cookie still valid?) → if yes, /home or /workspace
///  3. If not authenticated → /login
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<double> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.6, curve: Curves.easeIn)),
    );
    _slide = Tween<double>(begin: 24.0, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.2, 1.0, curve: Curves.easeOut)),
    );

    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 1800), _navigate);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _navigate() async {
    if (!mounted) return;
    final authState = ref.read(authProvider);
    
    if (authState.isAuthenticated) {
      try {
        final sessionRepo = ref.read(sessionRepositoryProvider);
        // Verify session / token validity
        final sessionInfo = await sessionRepo.getSessionInfo();
        
        if (sessionInfo != null) {
          ref.read(authProvider.notifier).setSession(sessionInfo);
        }
        if (mounted) {
          context.go('/home');
        }
      } catch (e) {
        if (mounted) {
          context.go('/home');
        }
      }
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: Center(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, child) {
            return Opacity(
              opacity: _fade.value,
              child: Transform.translate(
                offset: Offset(0, _slide.value),
                child: child,
              ),
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Logo ──────────────────────────────────────────────────────
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'WMS',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primary,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // ── Title ─────────────────────────────────────────────────────
              const Text(
                'Universal WMS',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Warehouse Management',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 52),

              // ── Progress ──────────────────────────────────────────────────
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
