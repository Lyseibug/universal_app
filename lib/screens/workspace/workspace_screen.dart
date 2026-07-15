import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/session_models.dart';
import '../../core/menu/menu_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/logger.dart';
import '../../providers/auth_provider.dart';
import '../../providers/service_providers.dart';
import '../../providers/workstation_provider.dart';
import '../../routes/app_router.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../home/screen_registry.dart';

/// Workspace + workstation selection screen shown after login.
///
/// Loads the worker's assigned production lines via `session.list_workspaces`.
/// If there is exactly one assignment with exactly one workstation, both are
/// auto-selected and this screen is skipped entirely. Otherwise the worker
/// picks an assignment (if more than one) and then a specific workstation
/// within it, optionally naming a helper. Confirming calls
/// `session.select_workspace`, which creates the Worker Session (so
/// supervisor idle-alerts work) and returns the full station list, which is
/// seeded directly into [workstationProvider] for the Line 2 screens.
class WorkspaceScreen extends ConsumerStatefulWidget {
  const WorkspaceScreen({super.key});

  @override
  ConsumerState<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends ConsumerState<WorkspaceScreen> {
  final _helperCtrl = TextEditingController();

  List<WorkspaceModel>? _workspaces;
  WorkspaceModel? _selectedAssignment;
  String? _selectedWorkstation;
  bool _loading = true;
  bool _confirming = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadWorkspaces();
  }

  @override
  void dispose() {
    _helperCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadWorkspaces() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ref.read(sessionRepositoryProvider);
      final workspaces = await api.listWorkspaces();

      if (!mounted) return;

      if (workspaces.length == 1 && workspaces.first.workstations.length == 1) {
        // Single assignment, single workstation — auto-select silently.
        await _confirm(workspaces.first, workspaces.first.workstations.first);
        return;
      }

      setState(() {
        _workspaces = workspaces;
        _selectedAssignment = workspaces.length == 1 ? workspaces.first : null;
        _selectedWorkstation = _selectedAssignment?.workstations.firstOrNull;
        _loading = false;
      });
    } catch (e) {
      AppLogger.warning('Failed to load workspaces: $e', tag: 'WorkspaceScreen');
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load workspaces. Please check your connection.';
        _loading = false;
      });
    }
  }

  Future<void> _confirm(WorkspaceModel assignment, String workstation) async {
    setState(() {
      _confirming = true;
      _error = null;
    });
    try {
      final api = ref.read(sessionRepositoryProvider);
      final session = await api.selectWorkspace(
        assignment.assignment,
        workstation: workstation,
        helperName: _helperCtrl.text.trim().isNotEmpty ? _helperCtrl.text.trim() : null,
      );
      if (!mounted) return;

      ref.read(authProvider.notifier).setSession(session);
      ref.read(workstationProvider.notifier).state = WorkstationState(
        selectedWorkstation: session.workspace,
        productionLine: session.productionLine,
        assignedStations: session.assignedStations,
        helperName: _helperCtrl.text.trim().isNotEmpty ? _helperCtrl.text.trim() : null,
      );

      if (!mounted) return;
      // Resolve the auto-route target *before* leaving this screen — once
      // context.go('/home') fires, WorkspaceScreen starts getting disposed,
      // and the menu fetch below is a real network call, so by the time it
      // resolves `mounted` would already be false and the push silently no-ops.
      final pendingScreen = await _resolveAutoRouteScreen(session.screenKey);
      if (!mounted) return;
      context.go('/home');
      _pushAutoRouteScreen(pendingScreen);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to select workstation. Please try again.';
        _confirming = false;
      });
    }
  }

  /// If this workstation has a mapped PDT screen (Workstation.
  /// custom_pdt_screen_key), resolve its [MenuScreen] config so it can be
  /// opened directly instead of leaving the worker on the tile menu. No
  /// mapping configured -> null, unchanged behavior.
  ///
  /// Must be awaited (and its result used) *before* navigating away from
  /// this screen — `ref` and `context` are only guaranteed valid while
  /// WorkspaceScreen is still mounted, and the menu fetch below is a real
  /// network call.
  Future<(ScreenBuilder, MenuScreen)?> _resolveAutoRouteScreen(String? screenKey) async {
    if (screenKey == null || screenKey.isEmpty) return null;
    final builder = screenRegistry[screenKey];
    if (builder == null) return null;

    MenuScreen? menuScreen;
    try {
      final menu = await ref.read(menuProvider.future);
      if (menu != null) {
        outer:
        for (final mod in menu.menu) {
          for (final s in mod.screens) {
            if (s.screenKey == screenKey) {
              menuScreen = s;
              break outer;
            }
          }
        }
      }
    } catch (_) {}

    menuScreen ??= MenuScreen(
      screenKey: screenKey,
      label: screenKey,
      route: '/$screenKey',
      apiModule: 'line2',
      actions: const ['complete_step', 'assign_tool', 'release_tool'],
    );

    return (builder, menuScreen);
  }

  /// Pushes the screen resolved by [_resolveAutoRouteScreen] on top of the
  /// current route. Uses [rootNavigatorKey] rather than this screen's own
  /// BuildContext — by the time this runs, WorkspaceScreen has just been
  /// replaced by `context.go('/home')` and its context is no longer safe to use.
  void _pushAutoRouteScreen((ScreenBuilder, MenuScreen)? pending) {
    if (pending == null) return;
    final (builder, menuScreen) = pending;
    rootNavigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => builder(menuScreen)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final employeeName = authState.session?.employeeName ?? 'Employee';

    return Scaffold(
      backgroundColor: AppTheme.bgScaffold,
      appBar: AppBar(
        title: const Text('Workstation Setup'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton.icon(
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (!mounted) return;
              // ignore: use_build_context_synchronously
              context.go('/login');
            },
            icon: const Icon(Icons.logout, color: Colors.white70, size: 18),
            label: const Text('Logout', style: TextStyle(color: Colors.white70)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? _buildLoading()
            : _error != null && _workspaces == null
                ? _buildError()
                : _buildSetupForm(employeeName),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text(
            'Loading your workstations…',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.horizontalPad),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.dangerLight,
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppTheme.danger, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: AppTheme.danger, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loadWorkspaces,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetupForm(String employeeName) {
    final workspaces = _workspaces ?? [];

    if (workspaces.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.horizontalPad),
          child: Text(
            'No workstations assigned. Contact your supervisor.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.danger, fontSize: 14),
          ),
        ),
      );
    }

    final stations = _selectedAssignment?.workstations ?? const <String>[];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.horizontalPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                ),
                child: const Icon(Icons.precision_manufacturing_outlined, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Welcome, $employeeName', style: Theme.of(context).textTheme.titleMedium),
                    Text(
                      '${workspaces.length} assignment${workspaces.length == 1 ? '' : 's'} available',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 20),

          // Assignment picker (only shown when there's more than one)
          if (workspaces.length > 1) ...[
            const Text('PRODUCTION LINE',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary, letterSpacing: 1.0)),
            const SizedBox(height: 8),
            ...workspaces.map(_buildAssignmentCard),
            const SizedBox(height: 20),
          ],

          if (_selectedAssignment != null) ...[
            const Text('WORKSTATION ID',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary, letterSpacing: 1.0)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _selectedWorkstation,
              decoration: const InputDecoration(
                hintText: 'Select workstation',
                prefixIcon: Icon(Icons.place_outlined),
              ),
              items: stations.map((ws) => DropdownMenuItem(value: ws, child: Text(ws))).toList(),
              onChanged: (ws) => setState(() => _selectedWorkstation = ws),
            ),
            if (stations.length > 1) ...[
              const SizedBox(height: 4),
              Text(
                'Assigned: ${stations.join(" · ")}',
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            ],
            if (_selectedAssignment!.supervisorName.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 14, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text('Supervisor: ${_selectedAssignment!.supervisorName}',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
            ],
            const SizedBox(height: 20),

            const Text('MACHINE OPERATOR',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary, letterSpacing: 1.0)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.bgElevated,
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                border: Border.all(color: AppTheme.bgBorder, width: 1.5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person, color: AppTheme.textSecondary, size: 20),
                  const SizedBox(width: 12),
                  Text(employeeName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text('HELPER (IF APPLICABLE)',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary, letterSpacing: 1.0)),
            const SizedBox(height: 6),
            CustomTextField(
              controller: _helperCtrl,
              hintText: 'Helper Name',
              prefixIcon: const Icon(Icons.person_add_outlined),
            ),
            const SizedBox(height: 28),
          ],

          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(_error!, style: const TextStyle(color: AppTheme.danger, fontSize: 13), textAlign: TextAlign.center),
            ),

          if (_selectedAssignment != null)
            CustomButton(
              text: _confirming ? 'Setting up...' : 'Next',
              icon: Icons.arrow_forward,
              isLoading: _confirming,
              onPressed: _selectedWorkstation == null
                  ? null
                  : () => _confirm(_selectedAssignment!, _selectedWorkstation!),
            ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildAssignmentCard(WorkspaceModel ws) {
    final isSelected = _selectedAssignment?.assignment == ws.assignment;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppTheme.bgSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          side: BorderSide(
            color: isSelected ? AppTheme.primary : AppTheme.bgBorder,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          onTap: () => setState(() {
            _selectedAssignment = ws;
            _selectedWorkstation = ws.workstations.firstOrNull;
          }),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                  ),
                  child: const Icon(Icons.precision_manufacturing_outlined, color: AppTheme.primary, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ws.label, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        '${ws.workstations.length} station${ws.workstations.length == 1 ? '' : 's'}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (ws.supervisorName.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.person_outline, size: 13, color: AppTheme.textSecondary),
                            const SizedBox(width: 4),
                            Text('Supervisor: ${ws.supervisorName}', style: Theme.of(context).textTheme.labelMedium),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  isSelected ? Icons.check_circle : Icons.chevron_right,
                  color: isSelected ? AppTheme.primary : AppTheme.textDisabled,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
