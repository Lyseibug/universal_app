import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_exceptions.dart';
import '../../core/auth/session_models.dart';
import '../../core/errors/error_mapper.dart';
import '../../core/menu/menu_models.dart';
import '../../core/models/maintenance_request_models.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/service_providers.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/pdt_scaffold.dart';
import 'maintenance_repository.dart';

/// Raise a Maintenance Request against a machine. Any PDT User can open
/// this screen (screen_key: maintenance_request) -- the shared queue is a
/// separate, role-restricted screen (maintenance_team_screen.dart), so
/// this one is deliberately create-only with no list-back-view.
class RaiseMaintenanceRequestScreen extends ConsumerStatefulWidget {
  final MenuScreen screen;
  const RaiseMaintenanceRequestScreen({required this.screen, super.key});

  @override
  ConsumerState<RaiseMaintenanceRequestScreen> createState() =>
      _RaiseMaintenanceRequestScreenState();
}

class _RaiseMaintenanceRequestScreenState extends ConsumerState<RaiseMaintenanceRequestScreen> {
  bool _loadingMachine = true;
  String? _machine;
  bool _machineLocked = false; // true when prefilled from an active session
  List<String> _availableMachines = [];

  bool _loadingIssues = false;
  List<DownTimeIssueGroup> _issueGroups = [];
  String? _selectedCategory;
  DownTimeIssue? _selectedIssue;

  final _descriptionCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _resolveMachine();
  }

  @override
  void dispose() {
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _resolveMachine() async {
    setState(() => _loadingMachine = true);
    try {
      final session = await ref.read(sessionRepositoryProvider).getSessionInfo();
      if (session?.workspace != null && session!.workspace!.isNotEmpty) {
        setState(() {
          _machine = session.workspace;
          _machineLocked = true;
          _loadingMachine = false;
        });
        _loadIssueTypes();
        return;
      }

      final workspaces = await ref.read(sessionRepositoryProvider).listWorkspaces();
      final all = <String>[];
      for (final WorkspaceModel w in workspaces) {
        for (final station in w.workstations) {
          if (!all.contains(station)) all.add(station);
        }
      }
      setState(() {
        _availableMachines = all;
        _machine = all.isNotEmpty ? all.first : null;
        _loadingMachine = false;
      });
      if (_machine != null) _loadIssueTypes();
    } catch (e) {
      if (mounted) setState(() => _loadingMachine = false);
    }
  }

  void _unlockMachine() {
    setState(() => _machineLocked = false);
  }

  Future<void> _loadIssueTypes() async {
    if (_machine == null) return;
    setState(() {
      _loadingIssues = true;
      _issueGroups = [];
      _selectedCategory = null;
      _selectedIssue = null;
    });
    try {
      final groups = await ref.read(maintenanceRepositoryProvider).listIssueTypes(_machine!);
      if (!mounted) return;
      setState(() {
        _issueGroups = groups;
        _selectedCategory = groups.isNotEmpty ? groups.first.category : null;
        _loadingIssues = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loadingIssues = false);
    }
  }

  List<DownTimeIssue> get _issuesForSelectedCategory {
    final group = _issueGroups.where((g) => g.category == _selectedCategory).toList();
    return group.isNotEmpty ? group.first.issues : const [];
  }

  Future<void> _submit() async {
    if (_machine == null || _machine!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a machine first.')),
      );
      return;
    }
    if (_selectedIssue == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select an issue type.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await ref.read(maintenanceRepositoryProvider).create(
            machine: _machine!,
            issueType: _selectedIssue!.name,
            description: _descriptionCtrl.text.trim().isNotEmpty ? _descriptionCtrl.text.trim() : null,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maintenance request submitted.'),
          backgroundColor: AppTheme.success,
        ),
      );
      setState(() {
        _selectedIssue = null;
        _descriptionCtrl.clear();
      });
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(messageFor(e)), backgroundColor: AppTheme.danger),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PdtScaffold(
      title: widget.screen.label,
      body: _loadingMachine
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppTheme.horizontalPad),
              children: [
                const Text('Machine', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                _buildMachineField(),
                const SizedBox(height: 20),
                const Text('Issue Type', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                _buildIssueFields(),
                const SizedBox(height: 20),
                const Text('Description (optional)',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                CustomTextField(
                  controller: _descriptionCtrl,
                  hintText: 'Additional details...',
                  maxLines: 4,
                ),
                const SizedBox(height: 28),
                CustomButton(
                  text: 'Submit Request',
                  isLoading: _submitting,
                  onPressed: _submit,
                ),
              ],
            ),
    );
  }

  Widget _buildMachineField() {
    if (_machineLocked && _machine != null) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.precision_manufacturing, color: AppTheme.primary),
          title: Text(_machine!, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: const Text('From your active workstation'),
          trailing: TextButton(onPressed: _unlockMachine, child: const Text('Change')),
        ),
      );
    }

    if (_availableMachines.isEmpty) {
      return const Text('No assigned workstations found.',
          style: TextStyle(color: AppTheme.textSecondary));
    }

    return DropdownButtonFormField<String>(
      value: _machine,
      isExpanded: true,
      decoration: const InputDecoration(border: OutlineInputBorder()),
      items: _availableMachines
          .map((m) => DropdownMenuItem(value: m, child: Text(m)))
          .toList(),
      onChanged: (v) {
        setState(() => _machine = v);
        _loadIssueTypes();
      },
    );
  }

  Widget _buildIssueFields() {
    if (_loadingIssues) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_issueGroups.isEmpty) {
      return const Text('No issue types available.', style: TextStyle(color: AppTheme.textSecondary));
    }

    return Column(
      children: [
        DropdownButtonFormField<String>(
          value: _selectedCategory,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
          items: _issueGroups
              .map((g) => DropdownMenuItem(value: g.category, child: Text(g.category)))
              .toList(),
          onChanged: (v) {
            setState(() {
              _selectedCategory = v;
              _selectedIssue = null;
            });
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<DownTimeIssue>(
          value: _selectedIssue,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Issue', border: OutlineInputBorder()),
          items: _issuesForSelectedCategory
              .map((i) => DropdownMenuItem(value: i, child: Text(i.issue)))
              .toList(),
          onChanged: (v) => setState(() => _selectedIssue = v),
        ),
      ],
    );
  }
}
