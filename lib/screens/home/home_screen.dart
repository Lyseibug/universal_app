import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/menu/menu_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/icon_helper.dart';
import '../../providers/auth_provider.dart';
import '../../providers/service_providers.dart';
import '../../providers/update_provider.dart';
import '../../widgets/update_dialog.dart';
import 'screen_registry.dart';

/// Home screen — renders the dynamic menu returned by `session.get_menu`.
///
/// Layout: AppBar with employee name + workspace, then a scrollable list
/// of module sections, each containing screen tiles. Tiles not in the
/// [screenRegistry] are silently skipped (forward-compatible).
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Show the update dialog if a check already completed before we mounted
    // (e.g. splash fired the check and navigated here before it resolved).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowUpdateDialog();
    });
  }

  void _maybeShowUpdateDialog() {
    if (!mounted) return;
    final phase = ref.read(updateProvider).phase;
    if (phase == UpdatePhase.updateAvailable || phase == UpdatePhase.forceUpdate) {
      UpdateDialog.show(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for update state changes that happen AFTER we mount
    // (covers the case where checkForUpdate() resolves after navigation).
    ref.listen<UpdateState>(updateProvider, (previous, next) {
      final wasActionable = previous?.isVisible ?? false;
      final isActionable = next.phase == UpdatePhase.updateAvailable ||
          next.phase == UpdatePhase.forceUpdate;
      // Only show once per transition into an actionable phase
      if (isActionable && !wasActionable && mounted) {
        UpdateDialog.show(context);
      }
    });

    final authState = ref.watch(authProvider);
    final menuAsync = ref.watch(menuProvider);

    final employee = authState.session?.employeeName ?? 'Worker';
    final workspace = authState.session?.workspaceLabel ?? '';

    return Scaffold(
      backgroundColor: AppTheme.bgScaffold,
      appBar: _buildAppBar(employee, workspace),
      body: menuAsync.when(
        loading: () => _buildLoading(),
        error: (e, _) => _buildError(e.toString()),
        data: (payload) => payload == null
            ? _buildEmpty()
            : _buildMenu(payload),
      ),
    );
  }

  // ─── AppBar ────────────────────────────────────────────────────────────────

  AppBar _buildAppBar(String employee, String workspace) {
    return AppBar(
      toolbarHeight: 64,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            employee,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          if (workspace.isNotEmpty)
            Text(
              workspace,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
                fontWeight: FontWeight.w400,
              ),
            ),
        ],
      ),
      actions: [
        // Refresh menu
        IconButton(
          icon: const Icon(Icons.refresh_outlined),
          tooltip: 'Refresh menu',
          onPressed: () => ref.invalidate(menuProvider),
        ),
        // Logout
        IconButton(
          icon: const Icon(Icons.logout_outlined),
          tooltip: 'Logout',
          onPressed: () => _confirmLogout(),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ─── States ────────────────────────────────────────────────────────────────

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading menu…'),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.horizontalPad),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.warningLight,
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.wifi_off_outlined, color: AppTheme.warning, size: 26),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Could not load menu',
                          style: TextStyle(
                            color: AppTheme.warning,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          message,
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(menuProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.horizontalPad),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu_open_outlined,
                size: 72,
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.25)),
            const SizedBox(height: 16),
            Text(
              'No screens available',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'No workspaces or permissions are configured for your account.\n'
              'Please contact your supervisor.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Dynamic Menu ──────────────────────────────────────────────────────────

  Widget _buildMenu(MenuPayload payload) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.horizontalPad, 16, AppTheme.horizontalPad, 32,
      ),
      itemCount: payload.menu.length,
      itemBuilder: (context, i) {
        final module = payload.menu[i];
        // Filter to only screens we have a registered widget for
        final availableScreens = module.screens
            .where((s) => screenRegistry.containsKey(s.screenKey))
            .toList();
        if (availableScreens.isEmpty) return const SizedBox.shrink();

        final icon = IconHelper.getIcon(module.icon, fallback: Icons.widgets_outlined);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Theme(
            data: Theme.of(context).copyWith(
              dividerColor: Colors.transparent,
            ),
            child: ExpansionTile(
              collapsedBackgroundColor: AppTheme.bgSurface,
              backgroundColor: AppTheme.bgSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                side: const BorderSide(color: AppTheme.bgBorder),
              ),
              collapsedShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                side: const BorderSide(color: AppTheme.bgBorder),
              ),
              leading: Icon(icon, color: AppTheme.primary),
              title: Text(
                module.label.toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
              childrenPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: availableScreens.map(
                (screen) => _buildScreenTile(screen),
              ).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildScreenTile(MenuScreen screen) {
    debugPrint('HomeScreen: screen "${screen.label}" (key: ${screen.screenKey}) parsed icon = "${screen.icon}"');
    final icon = IconHelper.getIcon(screen.icon, fallback: Icons.grid_view_outlined);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppTheme.bgSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          side: const BorderSide(color: AppTheme.bgBorder, width: 1.0),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          onTap: () => _navigateToScreen(screen),
          child: SizedBox(
            height: AppTheme.listItemHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // ── Icon ──────────────────────────────────────────────────
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                    ),
                    child: Icon(icon, color: AppTheme.primary, size: 22),
                  ),
                  const SizedBox(width: 16),

                  // ── Label + action count ───────────────────────────────────
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          screen.label,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (screen.actions.isNotEmpty)
                          Text(
                            '${screen.actions.length} action${screen.actions.length == 1 ? '' : 's'} available',
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                      ],
                    ),
                  ),

                  // ── Arrow ─────────────────────────────────────────────────
                  const Icon(Icons.chevron_right, color: AppTheme.textDisabled, size: 22),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Navigation ──────────────────────────────────────────────────────────

  void _navigateToScreen(MenuScreen screen) {
    final builder = screenRegistry[screen.screenKey];
    if (builder == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => builder(screen)),
    );
  }

  // ─── Logout ──────────────────────────────────────────────────────────

  Future<void> _confirmLogout() async {
    final router = GoRouter.of(context); // capture before any await
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out?'),
        content: const Text(
          'Your session will end. The next worker will need to log in.',
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.danger,
              minimumSize: const Size(100, 44),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(authProvider.notifier).logout();
      if (mounted) router.go('/login');
    }
  }
}
