import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/menu/menu_models.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/pdt_scaffold.dart';
import '../../widgets/scan_input_field.dart';
import '../../widgets/status_chip.dart';
import 'line2_repository.dart';

/// Generic processing screen for Grinding, Cutting, Rib Grinding, Chamfering.
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

  @override
  void dispose() {
    _flowchartCtrl.dispose();
    _flowchartFocus.dispose();
    for (final m in _measurements) {
      m.dispose();
    }
    super.dispose();
  }

  Future<void> _onFlowchartScanned(String barcode) async {
    final trimmed = barcode.trim();
    if (trimmed.isEmpty) return;

    // Dispose old measurement controllers
    for (final m in _measurements) {
      m.dispose();
    }

    setState(() {
      _scanning = true;
      _error = null;
      _scanResult = null;
      _measurements = [];
    });

    try {
      final result =
          await ref.read(line2RepositoryProvider).scanFlowchart(trimmed);
      final data = Map<String, dynamic>.from(result);
      final params = data['measurement_params'];
      List<_MeasurementField> fields = [];
      if (params is List) {
        fields = params.map((p) {
          final param = Map<String, dynamic>.from(p);
          return _MeasurementField(
            name: param['name']?.toString() ?? '',
            label: param['label']?.toString() ?? param['name']?.toString() ?? '',
            unit: param['unit']?.toString() ?? '',
            defaultValue: param['default']?.toString(),
          );
        }).toList();
      }
      setState(() {
        _scanResult = data;
        _measurements = fields;
        _scanning = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Scan failed: $e';
        _scanning = false;
      });
    }
  }

  Future<void> _completeStep() async {
    // Validate measurements
    for (final m in _measurements) {
      final val = m.controller.text.trim();
      if (val.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Please fill in "${m.label}"'),
          backgroundColor: AppTheme.danger,
        ));
        return;
      }
      if (double.tryParse(val) == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('"${m.label}" must be a valid number'),
          backgroundColor: AppTheme.danger,
        ));
        return;
      }
    }

    setState(() => _completing = true);
    try {
      final measurementData = _measurements
          .map((m) => {
                'param': m.name,
                'value': double.tryParse(m.controller.text.trim()) ?? 0,
              })
          .toList();

      await ref.read(line2RepositoryProvider).completeStep(
            flowchart: _flowchartCtrl.text.trim(),
            measurements: measurementData,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Processing step completed'),
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
    for (final m in _measurements) {
      m.dispose();
    }
    setState(() {
      _scanResult = null;
      _measurements = [];
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
            hintText: 'Scan flowchart barcode',
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

          if (_scanResult != null) ...[
            // Info card with auto-detected step
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
                            _scanResult!['work_order']?.toString() ?? '',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                        StatusChip(
                            status: _scanResult!['status']?.toString() ??
                                'Open'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                        'Item: ${_scanResult!['item_name'] ?? _scanResult!['item_code'] ?? ''}'),
                    Row(
                      children: [
                        Text('Step: ',
                            style: TextStyle(color: AppTheme.textSecondary)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryLight.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _scanResult!['current_step']?.toString() ??
                                'Processing',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Measurement fields
            if (_measurements.isNotEmpty) ...[
              Text('Measurements',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ..._measurements.map((m) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextField(
                      controller: m.controller,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: InputDecoration(
                        labelText: m.label,
                        suffixText: m.unit,
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  )),
              const SizedBox(height: 8),
            ],

            // Complete button
            CustomButton(
              text: _completing ? 'Completing...' : 'Complete Step',
              icon: Icons.check_circle,
              isLoading: _completing,
              backgroundColor: AppTheme.success,
              textColor: Colors.white,
              onPressed: _completing ? null : _completeStep,
            ),
            const SizedBox(height: 8),
            CustomButton(
              text: 'Reset',
              icon: Icons.refresh,
              outlined: true,
              onPressed: _resetForm,
            ),
          ],
        ],
      ),
    );
  }
}

class _MeasurementField {
  final String name;
  final String label;
  final String unit;
  final TextEditingController controller;

  _MeasurementField({
    required this.name,
    required this.label,
    this.unit = '',
    String? defaultValue,
  }) : controller = TextEditingController(text: defaultValue ?? '');

  void dispose() {
    controller.dispose();
  }
}
