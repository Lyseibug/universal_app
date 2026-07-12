import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/menu/menu_models.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/pdt_scaffold.dart';
import 'line2_repository.dart';
import 'widgets/production_station_layout.dart';

class ProcessingScreen extends ConsumerStatefulWidget {
  final MenuScreen screen;
  /// Pre-resolved scan_flowchart payload — used by Active Jobs' "resume"
  /// action to open this screen already loaded on an in-progress job,
  /// without requiring a fresh barcode scan.
  final Map<String, dynamic>? resumeJob;
  const ProcessingScreen({required this.screen, this.resumeJob, super.key});

  @override
  ConsumerState<ProcessingScreen> createState() => _ProcessingScreenState();
}

/// Steps where pieces are physically lost and must be recorded as scrap
/// with a reason code — see line2_building.complete_step.
const _scrapCapableSteps = {'CUTTING', 'RIB_GRINDING'};

class _ProcessingScreenState extends ConsumerState<ProcessingScreen> {
  final _flowchartCtrl = TextEditingController();
  final _flowchartFocus = FocusNode();
  final _scrapQtyCtrl = TextEditingController();

  bool _scanning = false;
  bool _completing = false;
  String? _error;

  Map<String, dynamic>? _scanResult;
  List<_MeasurementField> _measurements = [];
  DateTime? _timerStart;

  List<String> _workstations = [];
  List<String> _assignedStations = [];
  String? _selectedWorkstation;

  List<Map<String, dynamic>> _reasonCodes = [];
  String? _selectedScrapReason;

  @override
  void initState() {
    super.initState();
    _loadWorkerStations().then((_) {
      if (widget.resumeJob != null && mounted) {
        final data = widget.resumeJob!;
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
          _timerStart = _timerStartFromScan(data);
        });
        _loadReasonCodesIfNeeded(data);
      }
    });
  }

  DateTime _timerStartFromScan(Map<String, dynamic> scan) {
    final elapsed = (scan['elapsed_seconds'] as num?)?.toInt() ?? 0;
    return DateTime.now().subtract(Duration(seconds: elapsed));
  }

  @override
  void dispose() {
    _flowchartCtrl.dispose();
    _flowchartFocus.dispose();
    _scrapQtyCtrl.dispose();
    for (final m in _measurements) {
      m.dispose();
    }
    super.dispose();
  }

  bool get _isScrapCapableStep =>
      _scrapCapableSteps.contains(_scanResult?['current_step']?.toString());

  Future<void> _loadReasonCodesIfNeeded(Map<String, dynamic> scan) async {
    if (!_scrapCapableSteps.contains(scan['current_step']?.toString())) return;
    final productionType = scan['production_type']?.toString();
    if (productionType == null || productionType.isEmpty) return;
    try {
      final codes = await ref.read(line2RepositoryProvider).getRejectionCodes(productionType);
      if (mounted) setState(() => _reasonCodes = codes);
    } catch (_) {
      // Non-critical — scrap qty entry without a reason will be rejected
      // server-side with a clear error rather than silently failing here.
    }
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
        _timerStart = _timerStartFromScan(data);
        _reasonCodes = [];
        _selectedScrapReason = null;
        _scrapQtyCtrl.clear();
      });
      await _loadReasonCodesIfNeeded(data);
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

    final scrapQty = double.tryParse(_scrapQtyCtrl.text.trim());
    if (scrapQty != null && scrapQty > 0 && _selectedScrapReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Select a reason code for the scrap'), backgroundColor: AppTheme.danger));
      return;
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
        scrapQty: (scrapQty != null && scrapQty > 0) ? scrapQty : null,
        scrapReasonCode: (scrapQty != null && scrapQty > 0) ? _selectedScrapReason : null,
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
      _reasonCodes = [];
      _selectedScrapReason = null;
      _scrapQtyCtrl.clear();
    });
  }

  Widget _buildStepContent() {
    final stepName = _scanResult?['step_name']?.toString() ?? _scanResult?['current_step']?.toString() ?? 'Processing';
    final qty = _scanResult?['qty'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step badge
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(stepName,
                  style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primary, fontSize: 13)),
            ),
            if (qty != null)
              Text('Qty at this station: $qty',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ],
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

        if (_isScrapCapableStep) ...[
          const Text('SCRAP',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary, letterSpacing: 1.0)),
          const SizedBox(height: 10),
          TextField(
            controller: _scrapQtyCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Scrap Qty',
              helperText: 'Pieces lost at this station, if any',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          if ((double.tryParse(_scrapQtyCtrl.text.trim()) ?? 0) > 0)
            DropdownButtonFormField<String>(
              value: _selectedScrapReason,
              decoration: const InputDecoration(
                labelText: 'Scrap Reason *',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: _reasonCodes
                  .map((r) => DropdownMenuItem(
                        value: '${r['code']}: ${r['description'] ?? ''}',
                        child: Text('${r['code']} — ${r['description'] ?? ''}',
                            overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedScrapReason = v),
            ),
          const SizedBox(height: 12),
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
