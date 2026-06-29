import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/menu/menu_models.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/pdt_scaffold.dart';
import '../../widgets/scan_input_field.dart';
import '../../widgets/status_chip.dart';
import 'line2_repository.dart';

class QcFinalScreen extends ConsumerStatefulWidget {
  final MenuScreen screen;
  const QcFinalScreen({required this.screen, super.key});

  @override
  ConsumerState<QcFinalScreen> createState() => _QcFinalScreenState();
}

class _QcFinalScreenState extends ConsumerState<QcFinalScreen> {
  final _flowchartCtrl = TextEditingController();
  final _flowchartFocus = FocusNode();
  final _acceptedQtyCtrl = TextEditingController();

  bool _scanning = false;
  bool _completing = false;
  String? _error;

  Map<String, dynamic>? _qcInfo;
  List<Map<String, dynamic>> _measurements = [];

  @override
  void dispose() {
    _flowchartCtrl.dispose();
    _flowchartFocus.dispose();
    _acceptedQtyCtrl.dispose();
    super.dispose();
  }

  Future<void> _onFlowchartScanned(String barcode) async {
    final trimmed = barcode.trim();
    if (trimmed.isEmpty) return;

    setState(() {
      _scanning = true;
      _error = null;
      _qcInfo = null;
      _measurements = [];
    });

    try {
      final result =
          await ref.read(line2RepositoryProvider).getQcInfo(trimmed);
      final data = Map<String, dynamic>.from(result);
      final meas = data['submitted_measurements'];
      List<Map<String, dynamic>> measList = [];
      if (meas is List) {
        measList = meas
            .map((m) => Map<String, dynamic>.from(m))
            .toList();
      }

      final fullQty = data['qty']?.toString() ?? '1';
      _acceptedQtyCtrl.text = fullQty;

      setState(() {
        _qcInfo = data;
        _measurements = measList;
        _scanning = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load QC info: $e';
        _scanning = false;
      });
    }
  }

  void _showRejectSheet() {
    final reasonCtrl = TextEditingController();
    String rejectionType = 'Rework';
    String? returnToStep;

    final steps = <String>[];
    if (_qcInfo != null && _qcInfo!['available_steps'] is List) {
      steps.addAll(
        (_qcInfo!['available_steps'] as List).map((s) => s.toString()),
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Reject',
                  style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextField(
                controller: reasonCtrl,
                decoration: const InputDecoration(
                  labelText: 'Reason Code',
                  hintText: 'Enter rejection reason',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              Text('Rejection Type',
                  style: Theme.of(ctx).textTheme.titleSmall),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Rework', style: TextStyle(fontSize: 14)),
                      value: 'Rework',
                      groupValue: rejectionType,
                      dense: true,
                      onChanged: (v) =>
                          setSheetState(() => rejectionType = v ?? 'Rework'),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Full Scrap', style: TextStyle(fontSize: 14)),
                      value: 'Full Scrap',
                      groupValue: rejectionType,
                      dense: true,
                      onChanged: (v) =>
                          setSheetState(() => rejectionType = v ?? 'Full Scrap'),
                    ),
                  ),
                ],
              ),
              if (rejectionType == 'Rework' && steps.isNotEmpty) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: returnToStep,
                  decoration: const InputDecoration(
                    labelText: 'Return to Step',
                    border: OutlineInputBorder(),
                  ),
                  items: steps
                      .map((s) =>
                          DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) =>
                      setSheetState(() => returnToStep = v),
                ),
              ],
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.danger,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: () {
                  if (reasonCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                      content: Text('Enter a reason code'),
                      backgroundColor: AppTheme.danger,
                    ));
                    return;
                  }
                  Navigator.pop(ctx, {
                    'reason': reasonCtrl.text.trim(),
                    'rejection_type': rejectionType,
                    if (returnToStep != null)
                      'return_to_step': returnToStep,
                  });
                },
                child: const Text('Confirm Rejection'),
              ),
            ],
          ),
        ),
      ),
    ).then((result) {
      if (result != null && result is Map<String, dynamic>) {
        _submitQcResult(
          accepted: false,
          rejectionData: result,
        );
      }
    });
  }

  Future<void> _capturePhoto() async {
    // Placeholder for camera integration
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Photo capture - feature coming soon'),
      backgroundColor: AppTheme.info,
    ));
  }

  Future<void> _submitQcResult({
    required bool accepted,
    Map<String, dynamic>? rejectionData,
  }) async {
    setState(() => _completing = true);
    try {
      final flowchart = _flowchartCtrl.text.trim();
      final acceptedQty = double.tryParse(_acceptedQtyCtrl.text.trim());

      await ref.read(line2RepositoryProvider).submitQcResult(
        flowchart: flowchart,
        accepted: accepted,
        acceptedQty: acceptedQty,
        rejectionData: rejectionData,
      );

      if (accepted) {
        await ref.read(line2RepositoryProvider).completeWo(
              flowchart: flowchart,
            );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(accepted
              ? 'Work order completed'
              : 'QC rejection submitted'),
          backgroundColor: accepted ? AppTheme.success : AppTheme.warning,
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
      _qcInfo = null;
      _measurements = [];
      _error = null;
      _flowchartCtrl.clear();
      _acceptedQtyCtrl.clear();
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
            hintText: 'Scan flowchart for final QC',
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
            // Item info header
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
                        StatusChip(
                            status: _qcInfo!['status']?.toString() ?? 'Open'),
                      ],
                    ),
                    if (_qcInfo!['work_order'] != null)
                      Text('WO: ${_qcInfo!['work_order']}'),
                    if (_qcInfo!['qty'] != null)
                      Text('Qty: ${_qcInfo!['qty']}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Submitted measurements (read-only)
            if (_measurements.isNotEmpty) ...[
              Text('Submitted Measurements',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: _measurements.map((m) {
                    final passing = m['pass'] == true;
                    return ListTile(
                      dense: true,
                      title: Text(
                        m['label']?.toString() ?? m['param']?.toString() ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        'Value: ${m['value']} ${m['unit'] ?? ''}',
                      ),
                      trailing: StatusChip(
                          status: passing ? 'success' : 'failed'),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Accepted qty
            TextField(
              controller: _acceptedQtyCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Accepted Qty',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                // Camera
                IconButton(
                  onPressed: _capturePhoto,
                  icon: const Icon(Icons.camera_alt, color: AppTheme.primary),
                  tooltip: 'Capture Flowchart Photo',
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.primaryLight.withValues(alpha: 0.15),
                  ),
                ),
                const SizedBox(width: 12),
                // Reject
                Expanded(
                  child: CustomButton(
                    text: 'Reject',
                    icon: Icons.cancel,
                    backgroundColor: AppTheme.danger,
                    textColor: Colors.white,
                    onPressed: _completing ? null : _showRejectSheet,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            CustomButton(
              text: _completing
                  ? 'Completing...'
                  : 'Complete Work Order',
              icon: Icons.check_circle,
              isLoading: _completing,
              backgroundColor: AppTheme.success,
              textColor: Colors.white,
              onPressed: _completing
                  ? null
                  : () => _submitQcResult(accepted: true),
            ),
          ],
        ],
      ),
    );
  }
}
