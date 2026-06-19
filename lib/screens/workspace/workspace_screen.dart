import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/session_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/logger.dart';
import '../../providers/auth_provider.dart';
import '../../providers/service_providers.dart';

/// Workspace selection screen shown after login.
///
/// If the employee has only one workspace, it is auto-selected and this
/// screen is skipped. Otherwise, the worker picks their assignment.
class WorkspaceScreen extends ConsumerStatefulWidget {
  const WorkspaceScreen({super.key});

  @override
  ConsumerState<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends ConsumerState<WorkspaceScreen> {
  List<WorkspaceModel>? _workspaces;
  bool _loading = true;
  String? _error;
  String? _selectingId;

  @override
  void initState() {
    super.initState();
    _loadWorkspaces();
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

      if (workspaces.length == 1) {
        // Auto-select single workspace
        await _selectWorkspace(workspaces.first);
        return;
      }

      setState(() {
        _workspaces = workspaces;
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

  Future<void> _selectWorkspace(WorkspaceModel workspace) async {
    setState(() => _selectingId = workspace.assignment);
    try {
      final api = ref.read(sessionRepositoryProvider);
      final session = await api.selectWorkspace(workspace.assignment);
      if (!mounted) return;
      ref.read(authProvider.notifier).setSession(session);
      if (mounted) context.go('/home');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to select workspace. Please try again.';
        _selectingId = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final employeeName = authState.session?.employeeName ?? 'Employee';

    return Scaffold(
      backgroundColor: AppTheme.bgScaffold,
      appBar: AppBar(
        title: const Text('Select Workspace'),
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
            : _error != null
                ? _buildError()
                : _buildWorkspaceList(employeeName),
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
            'Loading your workspaces…',
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

  Widget _buildWorkspaceList(String employeeName) {
    final workspaces = _workspaces ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.horizontalPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // ── Header ──────────────────────────────────────────────────────────
          _buildHeader(employeeName, workspaces.length),
          const SizedBox(height: 24),

          // ── Workspace Cards ──────────────────────────────────────────────────
          ...workspaces.map((ws) => _buildWorkspaceCard(ws)),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeader(String name, int count) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
              ),
              child: const Icon(Icons.warehouse_outlined, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Welcome, $name', style: Theme.of(context).textTheme.titleMedium),
                  Text(
                    '$count workspace${count == 1 ? '' : 's'} available',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Divider(height: 1),
        const SizedBox(height: 16),
        Text(
          'Select your workstation to begin:',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ],
    );
  }

  Widget _buildWorkspaceCard(WorkspaceModel ws) {
    final isSelecting = _selectingId == ws.assignment;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppTheme.bgSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          side: BorderSide(
            color: isSelecting ? AppTheme.primary : AppTheme.bgBorder,
            width: isSelecting ? 2.0 : 1.0,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          onTap: isSelecting ? null : () => _selectWorkspace(ws),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // ── Icon ────────────────────────────────────────────────────
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                  ),
                  child: const Icon(Icons.place_outlined, color: AppTheme.primary, size: 28),
                ),
                const SizedBox(width: 16),

                // ── Details ─────────────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ws.label,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (ws.warehouse.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          ws.warehouse,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                      if (ws.supervisorName.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.person_outline, size: 13, color: AppTheme.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              'Supervisor: ${ws.supervisorName}',
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // ── Action ──────────────────────────────────────────────────
                const SizedBox(width: 12),
                isSelecting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.chevron_right, color: AppTheme.textDisabled, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
