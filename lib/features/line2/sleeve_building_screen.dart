import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/menu/menu_models.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/pdt_scaffold.dart';
import '../../widgets/scan_input_field.dart';
import 'line2_repository.dart';
import 'widgets/production_station_layout.dart';

class SleeveBuildingScreen extends ConsumerStatefulWidget {
  final MenuScreen screen;
  const SleeveBuildingScreen({required this.screen, super.key});

  @override
  ConsumerState<SleeveBuildingScreen> createState() =>
      _SleeveBuildingScreenState();
}

class _SleeveBuildingScreenState extends ConsumerState<SleeveBuildingScreen> {
  final _flowchartCtrl = TextEditingController();
  final _flowchartFocus = FocusNode();
  final _moldCtrl = TextEditingController();
  final _moldFocus = FocusNode();

  bool _scanning = false;
  bool _assigningTool = false;
  bool _completing = false;
  String? _error;

  Map<String, dynamic>? _scanResult;
  List<_LayerCheck> _layeringChecks = [];
  bool _moldAssigned = false;
  DateTime? _timerStart;

  // Workstation
  List<String> _workstations = [];
  List<String> _assignedStations = [];
  String? _selectedWorkstation;

  @override
  void initState() {
    super.initState();
    _loadWorkerStations();
  }

  @override
  void dispose() {
    _flowchartCtrl.dispose();
    _flowchartFocus.dispose();
    _moldCtrl.dispose();
    _moldFocus.dispose();
    super.dispose();
  }

  Future<void> _loadWorkerStations() async {
    try {
      final stations = await ref.read(line2RepositoryProvider).getWorkerStations();
      if (stations.isNotEmpty && mounted) {
        final all = <String>[];
        for (final s in stations) {
          final ws = s['workstations'];
          if (ws is List) all.addAll(ws.map((w) => w.toString()));
        }
        final buildingStations = all.where((w) => w.contains('B')).toList();
        setState(() {
          _assignedStations = all;
          _workstations = buildingStations.isNotEmpty ? buildingStations : all;
          if (_workstations.isNotEmpty) _selectedWorkstation = _workstations.first;
        });
      }
    } catch (_) {}
  }

  Future<void> _onFlowchartScanned(String barcode) async {
    final trimmed = barcode.trim();
    if (trimmed.isEmpty) return;

    setState(() {
      _scanning = true;
      _error = null;
      _scanResult = null;
      _layeringChecks = [];
      _moldAssigned = false;
      _moldCtrl.clear();
      _timerStart = null;
    });

    try {
      final data = await ref.read(line2RepositoryProvider).scanFlowchart(trimmed);
      final layering = data['layering_sequence'];
      List<_LayerCheck> checks = [];
      if (layering is List) {
        checks = layering.map((l) => _LayerCheck(label: l.toString())).toList();
      }
      setState(() {
        _scanResult = data;
        _layeringChecks = checks;
        _scanning = false;
        _timerStart = DateTime.now();
      });
    } catch (e) {
      setState(() {
        _error = 'Scan failed: $e';
        _scanning = false;
      });
    }
  }

  Future<void> _onMoldScanned(String barcode) async {
    final trimmed = barcode.trim();
    if (trimmed.isEmpty) return;

    setState(() {
      _assigningTool = true;
      _error = null;
    });

    try {
      await ref.read(line2RepositoryProvider).assignTool(
            toolId: trimmed,
            jobCard: _scanResult!['job_card']?.toString() ?? '',
          );
      setState(() {
        _moldAssigned = true;
        _assigningTool = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Mold assigned successfully'),
          backgroundColor: AppTheme.success,
        ));
      }
    } catch (e) {
      setState(() {
        _error = 'Tool assignment failed: $e';
        _assigningTool = false;
      });
    }
  }

  Future<void> _finishStep() async {
    final allChecked = _layeringChecks.every((c) => c.checked);
    if (!allChecked) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Complete all layering steps before finishing'),
        backgroundColor: AppTheme.danger,
      ));
      return;
    }

    setState(() => _completing = true);
    try {
      await ref.read(line2RepositoryProvider).completeStep(
            jobCard: _scanResult!['job_card']?.toString() ?? '',
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Sleeve building step completed'),
          backgroundColor: AppTheme.success,
        ));
        _resetForm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.danger,
        ));
      }
    } finally {
      if (mounted) setState(() => _completing = false);
    }
  }

  void _resetForm() {
    setState(() {
      _scanResult = null;
      _layeringChecks = [];
      _moldAssigned = false;
      _error = null;
      _timerStart = null;
      _flowchartCtrl.clear();
      _moldCtrl.clear();
    });
  }

  Widget _buildStepContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mold scan
        ScanInputField(
          controller: _moldCtrl,
          focusNode: _moldFocus,
          labelText: 'Scan Mold',
          hintText: 'Scan mold barcode',
          onScanned: _onMoldScanned,
          onSubmitted: _onMoldScanned,
        ),
        if (_assigningTool)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(),
          ),
        if (_moldAssigned)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: AppTheme.success, size: 20),
                SizedBox(width: 8),
                Text('Mold assigned',
                    style: TextStyle(color: AppTheme.success, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        const SizedBox(height: 12),

        // Layering checklist
        if (_layeringChecks.isNotEmpty) ...[
          const Text(
            'LAYERING CHECKLIST',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: _layeringChecks.asMap().entries.map((entry) {
                final i = entry.key;
                final check = entry.value;
                return CheckboxListTile(
                  title: Text('${i + 1}. ${check.label}'),
                  value: check.checked,
                  activeColor: AppTheme.success,
                  onChanged: (val) {
                    setState(() => check.checked = val ?? false);
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return PdtScaffold(
      title: widget.screen.label,
      body: ProductionStationLayout(
        title: widget.screen.label,
        availableWorkstations: _workstations,
        selectedWorkstation: _selectedWorkstation,
        onWorkstationChanged: (ws) => setState(() => _selectedWorkstation = ws),
        assignedStations: _assignedStations,
        scanController: _flowchartCtrl,
        scanFocusNode: _flowchartFocus,
        onScanned: _onFlowchartScanned,
        scanning: _scanning,
        scanResult: _scanResult,
        stepContent: _scanResult != null ? _buildStepContent() : null,
        timerStartTime: _timerStart,
        targetMinutes: (_scanResult?['target_time_minutes'] as num?)?.toInt(),
        onFinish: _finishStep,
        onBack: _resetForm,
        finishing: _completing,
        error: _error,
        onDismissError: () => setState(() => _error = null),
      ),
    );
  }
}

class _LayerCheck {
  final String label;
  bool checked;
  _LayerCheck({required this.label, this.checked = false});
}
