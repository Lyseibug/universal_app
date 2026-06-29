import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/menu/menu_models.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/pdt_scaffold.dart';
import 'line2_repository.dart';
import 'widgets/production_station_layout.dart';

class ProcessingScreen extends ConsumerStatefulWidget {
  final MenuScreen screen;
  const ProcessingScreen({required this.screen, super.key});

  @override
  ConsumerState<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends ConsumerState<ProcessingScreen> {
  final _flowchartCtrl = TextEditingController();
  final _flowchartFocus = FocusNode();

  bool _scanning = false;
  bool _completing = false;
  String? _error;

  Map<String, dynamic>? _scanResult;
  List<_MeasurementField> _measurements = [];
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
    for (final m in _measurements) {
      m.dispose();
    }
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
        setState(() {
          _assignedStations = all;
          _workstations = all;
          if (_workstations.isNotEmpty) _selectedWorkstation = _workstations.first;
        });
      }
    } catch (_) {}
  }

  Future<void> _onFlowchartScanned(String barcode) async {
    final trimmed = barcode.trim();
    if (trimmed.isEmpty) return;

    for (final m in _measurements) { m.dispose(); }

    setState(() {
      _scanning = true;
      _error = null;
      _scanResult = null;
      _measurements = [];
      _timerStart = null;
    });

    try {
      final data = await ref.read(line2RepositoryProvider).scanFlowchart(trimmed);
      final params = data['measurement_params'];
      List<_MeasurementField> fields = [];
      if (params is List) {
        fields = params.map((p) {
          final param = Map<String, dynamic>.from(p);
          return _MeasurementField(
            name: param['param_name']?.toString() ?? param['name']?.toString() ?? '',
            code: param['param_code']?.toString() ?? '',
            unit: param['uom']?.toString() ?? '',
            expectedMin: (param['expected_min'] as num?)?.toDouble() ?? 0,
            expectedMax: (param['expected_max'] as num?)?.toDouble() ?? 0,
            isMandatory: (param['is_mandatory'] ?? 0) == 1,
          );
        }).toList();
      }
      setState(() {
        _scanResult = data;
        _measurements = fields;
        _scanning = false;
        _timerStart = DateTime.now();
      });
    } catch (e) {
      setState(() { _error = 'Scan failed: $e'; _scanning = false; });
    }
  }

  Future<void> _completeStep() async {
    for (final m in _measurements) {
      final val = m.controller.text.trim();
      if (m.isMandatory && val.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Please fill in "${m.name}"'), backgroundColor: AppTheme.danger));
        return;
      }
      if (val.isNotEmpty && double.tryParse(val) == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('"${m.name}" must be a valid number'), backgroundColor: AppTheme.danger));
        return;
      }
    }

    setState(() => _completing = true);
    try {
      final measurementData = _measurements
          .where((m) => m.controller.text.trim().isNotEmpty)
          .map((m) => {
                'parameter_name': m.name,
                'actual_value': double.tryParse(m.controller.text.trim()) ?? 0,
                'expected_min': m.expectedMin,
                'expected_max': m.expectedMax,
                'uom': m.unit,
              })
          .toList();

      await ref.read(line2RepositoryProvider).completeStep(
        jobCard: _scanResult!['job_card']?.toString() ?? '',
        measurements: measurementData,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Processing step completed'), backgroundColor: AppTheme.success));
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
    for (final m in _measurements) { m.dispose(); }
    setState(() {
      _scanResult = null;
      _measurements = [];
      _error = null;
      _timerStart = null;
      _flowchartCtrl.clear();
    });
  }

  Widget _buildStepContent() {
    final stepName = _scanResult?['step_name']?.toString() ?? _scanResult?['current_step']?.toString() ?? 'Processing';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.primaryLight.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(stepName,
              style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primary, fontSize: 13)),
        ),
        const SizedBox(height: 16),

        if (_measurements.isNotEmpty) ...[
          const Text('MEASUREMENTS',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary, letterSpacing: 1.0)),
          const SizedBox(height: 10),
          ..._measurements.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextField(
                  controller: m.controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: '${m.name}${m.isMandatory ? ' *' : ''}',
                    suffixText: m.unit,
                    helperText: m.expectedMin > 0 || m.expectedMax > 0
                        ? 'Range: ${m.expectedMin} - ${m.expectedMax} ${m.unit}'
                        : null,
                  ),
                ),
              )),
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
        onFinish: _completeStep,
        onBack: _resetForm,
        finishing: _completing,
        error: _error,
        onDismissError: () => setState(() => _error = null),
      ),
    );
  }
}

class _MeasurementField {
  final String name;
  final String code;
  final String unit;
  final double expectedMin;
  final double expectedMax;
  final bool isMandatory;
  final TextEditingController controller;

  _MeasurementField({
    required this.name,
    this.code = '',
    this.unit = '',
    this.expectedMin = 0,
    this.expectedMax = 0,
    this.isMandatory = false,
  }) : controller = TextEditingController();

  void dispose() { controller.dispose(); }
}
