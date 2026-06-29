import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/menu/menu_models.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/pdt_scaffold.dart';
import '../../widgets/scan_input_field.dart';
import '../../widgets/status_chip.dart';
import 'line2_repository.dart';

class QcMeasurementScreen extends ConsumerStatefulWidget {
  final MenuScreen screen;
  const QcMeasurementScreen({required this.screen, super.key});

  @override
  ConsumerState<QcMeasurementScreen> createState() =>
      _QcMeasurementScreenState();
}

class _QcMeasurementScreenState extends ConsumerState<QcMeasurementScreen> {
  final _flowchartCtrl = TextEditingController();
  final _flowchartFocus = FocusNode();

  bool _scanning = false;
  bool _submitting = false;
  String? _error;

  Map<String, dynamic>? _qcInfo;
  List<_QcParam> _params = [];

  @override
  void dispose() {
    _flowchartCtrl.dispose();
    _flowchartFocus.dispose();
    for (final p in _params) {
      p.dispose();
    }
    super.dispose();
  }

  Future<void> _onFlowchartScanned(String barcode) async {
    final trimmed = barcode.trim();
    if (trimmed.isEmpty) return;

    for (final p in _params) {
      p.dispose();
    }

    setState(() {
      _scanning = true;
      _error = null;
      _qcInfo = null;
      _params = [];
    });

    try {
      final result =
          await ref.read(line2RepositoryProvider).getQcInfo(workOrder: trimmed);
      final data = result;
      final parameters = data['parameters'];
      List<_QcParam> paramList = [];
      if (parameters is List) {
        paramList = parameters.map((p) {
          final param = Map<String, dynamic>.from(p);
          return _QcParam(
            name: param['name']?.toString() ?? '',
            label: param['label']?.toString() ?? param['name']?.toString() ?? '',
            unit: param['unit']?.toString() ?? '',
            min: (param['min'] as num?)?.toDouble(),
            max: (param['max'] as num?)?.toDouble(),
          );
        }).toList();
      }
      setState(() {
        _qcInfo = data;
        _params = paramList;
        _scanning = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load QC info: $e';
        _scanning = false;
      });
    }
  }

  bool _isParamPassing(_QcParam param) {
    final val = double.tryParse(param.controller.text.trim());
    if (val == null) return false;
    if (param.min != null && val < param.min!) return false;
    if (param.max != null && val > param.max!) return false;
    return true;
  }

  Future<void> _submitMeasurements() async {
    for (final p in _params) {
      final val = p.controller.text.trim();
      if (val.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Please fill in "${p.label}"'),
          backgroundColor: AppTheme.danger,
        ));
        return;
      }
      if (double.tryParse(val) == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('"${p.label}" must be a valid number'),
          backgroundColor: AppTheme.danger,
        ));
        return;
      }
    }

    setState(() => _submitting = true);
    try {
      final measurements = _params
          .map((p) => {
                'param': p.name,
                'value': double.tryParse(p.controller.text.trim()) ?? 0,
              })
          .toList();

      await ref.read(line2RepositoryProvider).submitMeasurement(
            jobCard: _qcInfo!['job_card']?.toString() ?? _flowchartCtrl.text.trim(),
            measurements: measurements,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('QC measurements submitted'),
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
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _resetForm() {
    for (final p in _params) {
      p.dispose();
    }
    setState(() {
      _qcInfo = null;
      _params = [];
      _error = null;
      _flowchartCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PdtScaffold(
      title: widget.screen.label,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ScanInputField(
            controller: _flowchartCtrl,
            focusNode: _flowchartFocus,
            labelText: 'Scan Flowchart',
            hintText: 'Scan flowchart barcode for QC',
            onScanned: _onFlowchartScanned,
            onSubmitted: _onFlowchartScanned,
            autofocus: true,
          ),
          const SizedBox(height: 12),

          if (_scanning)
            const Center(child: CircularProgressIndicator()),

          if (_error != null)
            Card(
              color: AppTheme.dangerLight,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppTheme.danger),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error!,
                        style: const TextStyle(color: AppTheme.danger))),
                  ],
                ),
              ),
            ),

          if (_qcInfo != null) ...[
            // QC info header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _qcInfo!['item_name']?.toString() ??
                                _qcInfo!['item_code']?.toString() ?? '',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                        if (_qcInfo!['qc_mode'] != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.infoLight,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _qcInfo!['qc_mode'].toString().toUpperCase(),
                              style: const TextStyle(
                                  color: AppTheme.info,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (_qcInfo!['work_order'] != null)
                      Text('WO: ${_qcInfo!['work_order']}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Measurement parameters
            Text('Measurements (${_params.length} parameters)',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),

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
                          Expanded(
                            child: Text(param.label,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                          ),
                          if (param.min != null || param.max != null)
                            Text(
                              '${param.min ?? '-'} - ${param.max ?? '-'} ${param.unit}',
                              style: const TextStyle(
                                  color: AppTheme.textSecondary, fontSize: 12),
                            ),
                          const SizedBox(width: 8),
                          if (hasValue)
                            StatusChip(
                                status: passing ? 'success' : 'failed'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: param.controller,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: InputDecoration(
                          hintText: 'Enter value',
                          suffixText: param.unit,
                          border: const OutlineInputBorder(),
                          isDense: true,
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: failing
                                  ? AppTheme.danger
                                  : passing
                                      ? AppTheme.success
                                      : AppTheme.bgBorder,
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
            const SizedBox(height: 16),

            CustomButton(
              text: _submitting ? 'Submitting...' : 'Submit Measurements',
              icon: Icons.upload,
              isLoading: _submitting,
              backgroundColor: AppTheme.primary,
              textColor: Colors.white,
              onPressed: _submitting ? null : _submitMeasurements,
            ),
          ],
        ],
      ),
    );
  }
}

class _QcParam {
  final String name;
  final String label;
  final String unit;
  final double? min;
  final double? max;
  final TextEditingController controller;

  _QcParam({
    required this.name,
    required this.label,
    this.unit = '',
    this.min,
    this.max,
  }) : controller = TextEditingController();

  void dispose() {
    controller.dispose();
  }
}
