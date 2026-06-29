import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/menu/menu_models.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/pdt_scaffold.dart';
import '../../widgets/scan_input_field.dart';
import '../../widgets/status_chip.dart';
import 'line2_repository.dart';

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

  @override
  void dispose() {
    _flowchartCtrl.dispose();
    _flowchartFocus.dispose();
    _airbagCtrl.dispose();
    _airbagFocus.dispose();
    super.dispose();
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
    });

    try {
      final result =
          await ref.read(line2RepositoryProvider).scanFlowchart(trimmed);
      setState(() {
        _scanResult = result;
        _scanning = false;
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

    setState(() {
      _assigningTool = true;
      _error = null;
    });

    try {
      await ref.read(line2RepositoryProvider).assignTool(
            toolId: trimmed,
            jobCard: _scanResult!['job_card']?.toString() ?? _flowchartCtrl.text.trim(),
          );
      setState(() {
        _airbagAssigned = true;
        _assigningTool = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Airbag assigned'),
          backgroundColor: AppTheme.success,
        ));
      }
    } catch (e) {
      setState(() {
        _error = 'Airbag assignment failed: $e';
        _assigningTool = false;
      });
    }
  }

  Future<void> _finishCuring() async {
    setState(() => _completing = true);
    try {
      await ref.read(line2RepositoryProvider).completeStep(
            jobCard: _scanResult!['job_card']?.toString() ?? _flowchartCtrl.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Curing completed - tools auto-released'),
          backgroundColor: AppTheme.success,
        ));
        setState(() {
          _scanResult = null;
          _airbagAssigned = false;
          _flowchartCtrl.clear();
          _airbagCtrl.clear();
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
                            status:
                                _scanResult!['status']?.toString() ?? 'Open'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                        'Item: ${_scanResult!['item_name'] ?? _scanResult!['item_code'] ?? ''}'),
                    Text(
                        'Step: ${_scanResult!['current_step'] ?? 'Curing'}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Airbag scan
            ScanInputField(
              controller: _airbagCtrl,
              focusNode: _airbagFocus,
              labelText: 'Scan Airbag',
              hintText: 'Scan airbag barcode',
              onScanned: _onAirbagScanned,
              onSubmitted: _onAirbagScanned,
            ),
            if (_assigningTool)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(),
              ),
            if (_airbagAssigned)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: AppTheme.success, size: 20),
                    SizedBox(width: 8),
                    Text('Airbag assigned',
                        style: TextStyle(
                            color: AppTheme.success,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            const SizedBox(height: 12),

            // Airbag weight display
            if (_scanResult!['airbag_weight'] != null)
              Card(
                color: AppTheme.infoLight,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.monitor_weight_outlined,
                          color: AppTheme.info),
                      const SizedBox(width: 8),
                      Text(
                        'Airbag Weight: ${_scanResult!['airbag_weight']} Kg',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.info),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Finish button
            CustomButton(
              text: _completing ? 'Completing...' : 'Finish Curing',
              icon: Icons.check_circle,
              isLoading: _completing,
              backgroundColor: AppTheme.success,
              textColor: Colors.white,
              onPressed: _completing ? null : _finishCuring,
            ),
          ],
        ],
      ),
    );
  }
}
