import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/menu/menu_models.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/pdt_scaffold.dart';
import '../../widgets/status_chip.dart';
import 'line2_repository.dart';
import 'widgets/production_station_layout.dart';

class QcMeasurementScreen extends ConsumerStatefulWidget {
  final MenuScreen screen;
  const QcMeasurementScreen({required this.screen, super.key});

  @override
  ConsumerState<QcMeasurementScreen> createState() => _QcMeasurementScreenState();
}

class _QcMeasurementScreenState extends ConsumerState<QcMeasurementScreen> {
  final _flowchartCtrl = TextEditingController();
  final _flowchartFocus = FocusNode();

  bool _scanning = false;
  bool _submitting = false;
  String? _error;
  DateTime? _timerStart;

  Map<String, dynamic>? _scanResult;
  List<_QcParam> _params = [];

  List<String> _workstations = [];
  List<String> _assignedStations = [];
  String? _selectedWorkstation;

  // Several inspectors share one QC login — this is who actually did the
  // check, recorded on the Job Card instead of the shared session user.
  List<Map<String, dynamic>> _inspectors = [];
  String? _selectedInspector;

  @override
  void initState() {
    super.initState();
    _loadWorkerStations();
    _loadInspectors();
  }

  Future<void> _loadInspectors() async {
    try {
      final inspectors = await ref.read(line2RepositoryProvider).listInspectors();
      if (mounted) setState(() => _inspectors = inspectors);
    } catch (_) {}
  }

  @override
  void dispose() {
    _flowchartCtrl.dispose();
    _flowchartFocus.dispose();
    for (final p in _params) { p.dispose(); }
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
        final qcStations = all.where((w) => w.startsWith('Q')).toList();
        setState(() {
          _assignedStations = all;
          _workstations = qcStations.isNotEmpty ? qcStations : all;
          if (_workstations.isNotEmpty) _selectedWorkstation = _workstations.first;
        });
      }
    } catch (_) {}
  }

  Future<void> _onFlowchartScanned(String barcode) async {
    final trimmed = barcode.trim();
    if (trimmed.isEmpty) return;

    for (final p in _params) { p.dispose(); }

    setState(() {
      _scanning = true;
      _error = null;
      _scanResult = null;
      _params = [];
      _timerStart = null;
    });

    try {
      final data = await ref.read(line2RepositoryProvider).scanFlowchart(trimmed);
      final params = data['measurement_params'];
      List<_QcParam> paramList = [];
      if (params is List) {
        paramList = params.map((p) {
          final param = Map<String, dynamic>.from(p);
          return _QcParam(
            name: param['param_name']?.toString() ?? '',
            unit: param['uom']?.toString() ?? '',
            min: (param['expected_min'] as num?)?.toDouble(),
            max: (param['expected_max'] as num?)?.toDouble(),
            isMandatory: (param['is_mandatory'] ?? 0) == 1,
          );
        }).toList();
      }
      setState(() {
        _scanResult = data;
        _params = paramList;
        _scanning = false;
        _timerStart = DateTime.now();
      });
    } catch (e) {
      setState(() { _error = 'Failed to load QC info: $e'; _scanning = false; });
    }
  }

  bool _isParamPassing(_QcParam param) {
    final val = double.tryParse(param.controller.text.trim());
    if (val == null) return false;
    if (param.min != null && param.min! > 0 && val < param.min!) return false;
    if (param.max != null && param.max! > 0 && val > param.max!) return false;
    return true;
  }

  Future<void> _submitMeasurements() async {
    if (_inspectors.isNotEmpty && _selectedInspector == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Select which inspector is submitting this check'),
        backgroundColor: AppTheme.danger,
      ));
      return;
    }

    for (final p in _params) {
      final val = p.controller.text.trim();
      if (p.isMandatory && val.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Please fill in "${p.name}"'), backgroundColor: AppTheme.danger));
        return;
      }
      if (val.isNotEmpty && double.tryParse(val) == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('"${p.name}" must be a valid number'), backgroundColor: AppTheme.danger));
        return;
      }
    }

    setState(() => _submitting = true);
    try {
      final measurements = _params
          .where((p) => p.controller.text.trim().isNotEmpty)
          .map((p) => {
                'parameter_name': p.name,
                'actual_value': double.tryParse(p.controller.text.trim()) ?? 0,
                'expected_min': p.min ?? 0,
                'expected_max': p.max ?? 0,
                'uom': p.unit,
              })
          .toList();

      await ref.read(line2RepositoryProvider).submitMeasurement(
        workOrder: _scanResult!['work_order']?.toString() ?? '',
        jobCard: _scanResult!['job_card']?.toString() ?? '',
        measurements: measurements,
        inspector: _selectedInspector,
      );

      // No routine "submitted" toast — the screen resetting straight back
      // to the scan prompt is confirmation enough for this per-scan action.
      if (mounted) {
        _resetForm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'), backgroundColor: AppTheme.danger));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _resetForm() {
    for (final p in _params) { p.dispose(); }
    setState(() {
      _scanResult = null;
      _params = [];
      _error = null;
      _timerStart = null;
      _flowchartCtrl.clear();
    });
  }

  Widget _buildStepContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_inspectors.isNotEmpty) ...[
          const Text('INSPECTOR',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary, letterSpacing: 1.0)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _selectedInspector,
            isExpanded: true,
            decoration: const InputDecoration(
              hintText: 'Who is submitting this check?',
              prefixIcon: Icon(Icons.badge_outlined),
              isDense: true,
            ),
            items: _inspectors
                .map((e) => DropdownMenuItem(
                      value: e['name']?.toString(),
                      child: Text(e['employee_name']?.toString() ?? e['name']?.toString() ?? ''),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _selectedInspector = v),
          ),
          const SizedBox(height: 16),
        ],
        const Text('MEASUREMENTS',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary, letterSpacing: 1.0)),
        const SizedBox(height: 10),
        ..._params.map((param) {
          final hasValue = param.controller.text.trim().isNotEmpty;
          final passing = hasValue && _isParamPassing(param);
          final failing = hasValue && !_isParamPassing(param);

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text('${param.name}${param.isMandatory ? " *" : ""}',
                          style: const TextStyle(fontWeight: FontWeight.w600))),
                      if (param.min != null && param.min! > 0 || param.max != null && param.max! > 0)
                        Text('${param.min ?? "-"} - ${param.max ?? "-"} ${param.unit}',
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                      const SizedBox(width: 8),
                      if (hasValue) StatusChip(status: passing ? 'success' : 'failed'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: param.controller,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      hintText: 'Enter value',
                      suffixText: param.unit,
                      isDense: true,
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: failing ? AppTheme.danger : passing ? AppTheme.success : AppTheme.bgBorder,
                        ),
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            ),
          );
        }),
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
        scanLabel: 'Scan Flowchart',
        scanHint: 'Scan flowchart barcode for QC',
        onScanned: _onFlowchartScanned,
        scanning: _scanning,
        scanResult: _scanResult,
        stepContent: _scanResult != null ? _buildStepContent() : null,
        timerStartTime: _timerStart,
        targetMinutes: (_scanResult?['target_time_minutes'] as num?)?.toInt(),
        onFinish: _submitMeasurements,
        onBack: _resetForm,
        finishing: _submitting,
        finishLabel: 'Submit Measurements',
        error: _error,
        onDismissError: () => setState(() => _error = null),
      ),
    );
  }
}

class _QcParam {
  final String name;
  final String unit;
  final double? min;
  final double? max;
  final bool isMandatory;
  final TextEditingController controller;

  _QcParam({required this.name, this.unit = '', this.min, this.max, this.isMandatory = false})
      : controller = TextEditingController();

  void dispose() { controller.dispose(); }
}
