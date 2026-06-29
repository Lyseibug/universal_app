import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/menu/menu_models.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/pdt_scaffold.dart';
import '../../widgets/scan_input_field.dart';
import '../../widgets/status_chip.dart';
import 'line2_repository.dart';

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

  @override
  void dispose() {
    _flowchartCtrl.dispose();
    _flowchartFocus.dispose();
    _moldCtrl.dispose();
    _moldFocus.dispose();
    super.dispose();
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
    });

    try {
      final result =
          await ref.read(line2RepositoryProvider).scanFlowchart(trimmed);
      final data = Map<String, dynamic>.from(result);
      final layering = data['layering_sequence'];
      List<_LayerCheck> checks = [];
      if (layering is List) {
        checks = layering
            .map((l) => _LayerCheck(label: l.toString()))
            .toList();
      }
      setState(() {
        _scanResult = data;
        _layeringChecks = checks;
        _scanning = false;
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
            flowchart: _flowchartCtrl.text.trim(),
            toolBarcode: trimmed,
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
            flowchart: _flowchartCtrl.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Sleeve building step completed'),
          backgroundColor: AppTheme.success,
        ));
        setState(() {
          _scanResult = null;
          _layeringChecks = [];
          _moldAssigned = false;
          _flowchartCtrl.clear();
          _moldCtrl.clear();
        });
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
      _flowchartCtrl.clear();
      _moldCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PdtScaffold(
      title: widget.screen.label,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Step 1: Flowchart scan
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
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => setState(() => _error = null),
                    ),
                  ],
                ),
              ),
            ),

          if (_scanResult != null) ...[
            // WO info card
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
                    Text(
                        'Step: ${_scanResult!['current_step'] ?? 'Sleeve Building'}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Step 2: Mold scan
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
                        style: TextStyle(
                            color: AppTheme.success,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // Layering checklist
            if (_layeringChecks.isNotEmpty) ...[
              Text('Layering Checklist',
                  style: Theme.of(context).textTheme.titleMedium),
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
              const SizedBox(height: 16),
            ],

            // Finish button
            CustomButton(
              text: _completing ? 'Completing...' : 'Finish Step',
              icon: Icons.check_circle,
              isLoading: _completing,
              backgroundColor: AppTheme.success,
              textColor: Colors.white,
              onPressed: _completing ? null : _finishStep,
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

class _LayerCheck {
  final String label;
  bool checked;

  _LayerCheck({required this.label, this.checked = false});
}
