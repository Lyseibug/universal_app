import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/menu/menu_models.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/pdt_scaffold.dart';
import '../../widgets/scan_input_field.dart';
import 'line2_repository.dart';
import 'widgets/production_station_layout.dart';

class CuringScreen extends ConsumerStatefulWidget {
  final MenuScreen screen;
  const CuringScreen({required this.screen, super.key});

  @override
  ConsumerState<CuringScreen> createState() => _CuringScreenState();
}

class _CuringScreenState extends ConsumerState<CuringScreen> {
  final _flowchartCtrl = TextEditingController();
  final _flowchartFocus = FocusNode();
  final _airbagCtrl = TextEditingController();
  final _airbagFocus = FocusNode();

  bool _scanning = false;
  bool _assigningTool = false;
  bool _completing = false;
  String? _error;

  Map<String, dynamic>? _scanResult;
  bool _airbagAssigned = false;
  DateTime? _timerStart;

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
    _airbagCtrl.dispose();
    _airbagFocus.dispose();
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
        final pressStations = all.where((w) => w.contains('P')).toList();
        setState(() {
          _assignedStations = all;
          _workstations = pressStations.isNotEmpty ? pressStations : all;
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
      _airbagAssigned = false;
      _airbagCtrl.clear();
      _timerStart = null;
    });

    try {
      final result = await ref.read(line2RepositoryProvider).scanFlowchart(trimmed);
      setState(() {
        _scanResult = result;
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

  Future<void> _onAirbagScanned(String barcode) async {
    final trimmed = barcode.trim();
    if (trimmed.isEmpty) return;

    setState(() { _assigningTool = true; _error = null; });

    try {
      await ref.read(line2RepositoryProvider).assignTool(
        toolId: trimmed,
        jobCard: _scanResult!['job_card']?.toString() ?? '',
      );
      setState(() { _airbagAssigned = true; _assigningTool = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Airbag assigned'), backgroundColor: AppTheme.success));
      }
    } catch (e) {
      setState(() { _error = 'Airbag assignment failed: $e'; _assigningTool = false; });
    }
  }

  Future<void> _finishCuring() async {
    setState(() => _completing = true);
    try {
      await ref.read(line2RepositoryProvider).completeStep(
        jobCard: _scanResult!['job_card']?.toString() ?? '',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Curing completed - tools auto-released'),
          backgroundColor: AppTheme.success));
        _resetForm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'), backgroundColor: AppTheme.danger));
      }
    } finally {
      if (mounted) setState(() => _completing = false);
    }
  }

  void _resetForm() {
    setState(() {
      _scanResult = null;
      _airbagAssigned = false;
      _error = null;
      _timerStart = null;
      _flowchartCtrl.clear();
      _airbagCtrl.clear();
    });
  }

  Widget _buildStepContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ScanInputField(
          controller: _airbagCtrl,
          focusNode: _airbagFocus,
          labelText: 'Scan Airbag',
          hintText: 'Scan airbag barcode',
          onScanned: _onAirbagScanned,
          onSubmitted: _onAirbagScanned,
        ),
        if (_assigningTool)
          const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: LinearProgressIndicator()),
        if (_airbagAssigned)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Row(children: [
              Icon(Icons.check_circle, color: AppTheme.success, size: 20),
              SizedBox(width: 8),
              Text('Airbag assigned', style: TextStyle(color: AppTheme.success, fontWeight: FontWeight.w600)),
            ]),
          ),
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
        onFinish: _finishCuring,
        onBack: _resetForm,
        finishing: _completing,
        finishLabel: 'Finish Curing',
        error: _error,
        onDismissError: () => setState(() => _error = null),
      ),
    );
  }
}
