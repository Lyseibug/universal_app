import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../features/line2/line2_repository.dart';
import '../../providers/auth_provider.dart';
import '../../providers/workstation_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class WorkstationSetupScreen extends ConsumerStatefulWidget {
  const WorkstationSetupScreen({super.key});

  @override
  ConsumerState<WorkstationSetupScreen> createState() => _WorkstationSetupScreenState();
}

class _WorkstationSetupScreenState extends ConsumerState<WorkstationSetupScreen> {
  final _helperCtrl = TextEditingController();
  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> _assignments = [];
  String? _selectedWorkstation;
  List<String> _allStations = [];

  @override
  void initState() {
    super.initState();
    _loadStations();
  }

  @override
  void dispose() {
    _helperCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStations() async {
    setState(() { _loading = true; _error = null; });
    try {
      final stations = await ref.read(line2RepositoryProvider).getWorkerStations();
      if (!mounted) return;

      final all = <String>[];
      for (final s in stations) {
        final ws = s['workstations'];
        if (ws is List) all.addAll(ws.map((w) => w.toString()));
      }

      setState(() {
        _assignments = stations;
        _allStations = all;
        if (all.isNotEmpty) _selectedWorkstation = all.first;
        _loading = false;
      });

      if (all.isEmpty) {
        setState(() => _error = 'No workstations assigned. Contact your supervisor.');
      }
    } catch (e) {
      if (mounted) {
        setState(() { _error = 'Failed to load stations: $e'; _loading = false; });
      }
    }
  }

  void _proceed() {
    if (_selectedWorkstation == null) return;

    String? line;
    for (final a in _assignments) {
      final ws = a['workstations'];
      if (ws is List && ws.map((w) => w.toString()).contains(_selectedWorkstation)) {
        line = a['production_line']?.toString();
        break;
      }
    }

    ref.read(workstationProvider.notifier).state = WorkstationState(
      selectedWorkstation: _selectedWorkstation,
      productionLine: line,
      assignedStations: _allStations,
      helperName: _helperCtrl.text.trim().isNotEmpty ? _helperCtrl.text.trim() : null,
    );

    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final operatorName = authState.session?.fullName ?? authState.session?.user ?? 'Operator';

    return Scaffold(
      backgroundColor: AppTheme.bgScaffold,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo
                  Center(
                    child: Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Text('U', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'WORKSTATION SETUP',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textPrimary, letterSpacing: 1.0),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Select your workstation to begin',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 32),

                  if (_loading)
                    const Center(child: CircularProgressIndicator())
                  else ...[
                    // Workstation ID
                    const Text('WORKSTATION ID',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary, letterSpacing: 1.0)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _selectedWorkstation,
                      decoration: const InputDecoration(
                        hintText: 'Select workstation',
                        prefixIcon: Icon(Icons.precision_manufacturing_outlined),
                      ),
                      items: _allStations.map((ws) {
                        return DropdownMenuItem(value: ws, child: Text(ws));
                      }).toList(),
                      onChanged: (ws) => setState(() => _selectedWorkstation = ws),
                    ),
                    if (_allStations.length > 1) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Assigned: ${_allStations.join(" · ")}',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                    const SizedBox(height: 20),

                    // Machine Operator (read-only)
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
                          Text(operatorName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Helper
                    const Text('HELPER (IF APPLICABLE)',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary, letterSpacing: 1.0)),
                    const SizedBox(height: 6),
                    CustomTextField(
                      controller: _helperCtrl,
                      hintText: 'Helper Name',
                      prefixIcon: const Icon(Icons.person_add_outlined),
                    ),
                    const SizedBox(height: 32),

                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(_error!, style: const TextStyle(color: AppTheme.danger, fontSize: 13), textAlign: TextAlign.center),
                      ),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            text: 'Cancel',
                            icon: Icons.arrow_back,
                            outlined: true,
                            onPressed: () => context.go('/home'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: CustomButton(
                            text: 'Next',
                            icon: Icons.arrow_forward,
                            onPressed: _selectedWorkstation != null ? _proceed : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
