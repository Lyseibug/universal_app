import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/version_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/version_provider.dart';
import '../../providers/service_providers.dart';
import '../../widgets/update_dialog.dart';

/// Splash screen shown on app startup.
///
/// Startup Flow:
/// 1. Show splash animation (2 seconds)
/// 2. Call: https://universaltest.lyseibug.com/files/mobile-updates/version.json
/// 3. Get installed version via package_info_plus
/// 4. Compare installed version with latest_version & minimum_version
/// 5. If installed < minimum_version OR force_update=true → Force Update dialog
/// 6. If installed < latest_version → Optional Update dialog
/// 7. Check auth → navigate to dashboard or login
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _animationController.forward();

    // Start initialization after splash animation
    Future.delayed(const Duration(milliseconds: 2000), _initializeApp);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Main initialization flow after splash animation.
  Future<void> _initializeApp() async {
    if (!mounted) return;

    // ─── Step 1: Version Check ─────────────────────────────────────────────
    final versionStatus = await ref
        .read(versionProvider.notifier)
        .checkVersion();

    debugPrint('[Splash] Version check result: ${versionStatus.name}');

    if (!mounted) return;

    // ─── Step 2: Force Update Dialog (non-dismissible) ─────────────────────
    if (versionStatus == VersionStatus.forceUpdate) {
      final state = ref.read(versionProvider);
      debugPrint('[Splash] 🚫 Showing FORCE UPDATE dialog');
      debugPrint('[Splash] Installed: ${state.appVersion}');
      debugPrint('[Splash] Latest: ${state.serverVersion?.latestVersion}');
      debugPrint('[Splash] Minimum: ${state.serverVersion?.minimumVersion}');

      await UpdateDialog.show(
        context,
        currentVersion: state.appVersion ?? '1.0.0',
        newVersion: state.serverVersion?.latestVersion ?? '',
        apkUrl: state.serverVersion?.apkUrl ?? '',
        updateMessage: state.serverVersion?.message,
        isForceUpdate: true,
        onInstallAttempt: (version) =>
            ref.read(storageServiceProvider).savePendingUpdateVersion(version),
      );
      // User cannot dismiss this → app stays blocked here
      return;
    }

    // ─── Step 3: Optional Update Dialog (dismissible) ──────────────────────
    if (versionStatus == VersionStatus.updateAvailable) {
      final state = ref.read(versionProvider);
      debugPrint('[Splash] 📦 Showing OPTIONAL UPDATE dialog');
      debugPrint('[Splash] Installed: ${state.appVersion}');
      debugPrint('[Splash] Latest: ${state.serverVersion?.latestVersion}');

      if (mounted) {
        await UpdateDialog.show(
          context,
          currentVersion: state.appVersion ?? '1.0.0',
          newVersion: state.serverVersion?.latestVersion ?? '',
          apkUrl: state.serverVersion?.apkUrl ?? '',
          updateMessage: state.serverVersion?.message,
          isForceUpdate: false,
          onInstallAttempt: (version) => ref
              .read(storageServiceProvider)
              .savePendingUpdateVersion(version),
        );
      }
    }

    if (!mounted) return;

    // ─── Step 4: Auth Check & Navigation ───────────────────────────────────
    final authState = ref.read(authProvider);
    debugPrint('[Splash] Auth: isAuthenticated=${authState.isAuthenticated}');

    if (authState.isAuthenticated) {
      context.go('/dashboard');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.primaryColor, AppTheme.primaryDark],
          ),
        ),
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              ),
            );
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Company Logo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'U',
                    style: TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Company Name
              const Text(
                AppConstants.companyName,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enterprise Resource Planning',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.8),
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 48),
              // Loading indicator
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withValues(alpha: 0.8),
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
