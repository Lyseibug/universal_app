import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/menu/menu_models.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/pdt_scaffold.dart';
import '../../widgets/scan_input_field.dart';
import '../../widgets/workstation_picker_field.dart';
import 'line2_repository.dart';
import 'widgets/flowchart_photo_capture.dart';
import 'widgets/product_details_card.dart';
import 'widgets/rejection_modal.dart';
import 'widgets/support_help_section.dart';

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

  Map<String, dynamic>? _scanResult;
  List<Map<String, dynamic>> _rejectionCodes = [];
  final List<RejectionEntry> _rejections = [];

  double get _inspectedQty => (_scanResult?['qty'] as num?)?.toDouble() ?? 0;
  double get _rejectedQty => _rejections.fold<double>(0, (sum, r) => sum + r.qty);
  double get _acceptedQty {
    final manual = double.tryParse(_acceptedQtyCtrl.text.trim());
    return manual ?? (_inspectedQty - _rejectedQty);
  }

  List<String> _workstations = [];
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
    _acceptedQtyCtrl.dispose();
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
        final qcStations = all.where((w) => w.contains('QC')).toList();
        setState(() {
          _workstations = qcStations.isNotEmpty ? qcStations : all;
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
      _rejections.clear();
      _rejectionCodes = [];
    });

    try {
      final data = await ref.read(line2RepositoryProvider).scanFlowchart(trimmed);
      final productionType = data['production_type']?.toString() ?? '';

      List<Map<String, dynamic>> codes = [];
      if (productionType.isNotEmpty) {
        codes = await ref.read(line2RepositoryProvider).getRejectionCodes(productionType);
      }

      final qty = (data['qty'] as num?)?.toDouble() ?? 0;
      _acceptedQtyCtrl.text = qty.toStringAsFixed(qty == qty.roundToDouble() ? 0 : 2);

      setState(() {
        _scanResult = data;
        _rejectionCodes = codes;
        _scanning = false;
      });
    } catch (e) {
      setState(() { _error = 'Failed to load: $e'; _scanning = false; });
    }
  }

  Future<void> _addRejection() async {
    final remaining = (_inspectedQty - _rejectedQty).toInt();
    if (remaining <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('No remaining qty to reject'), backgroundColor: AppTheme.warning));
      return;
    }

    final entry = await RejectionModal.show(
      context,
      rejectionCodes: _rejectionCodes,
      maxQty: remaining,
    );

    if (entry != null) {
      setState(() {
        _rejections.add(entry);
        final newAccepted = _inspectedQty - _rejectedQty;
        _acceptedQtyCtrl.text = newAccepted.toStringAsFixed(newAccepted == newAccepted.roundToDouble() ? 0 : 2);
      });
    }
  }

  Future<void> _completeWo() async {
    // Require flowchart photo before completion
    final photoResult = await FlowchartPhotoCapture.show(
      context,
      lotNumber: _scanResult!['flowchart_barcode']?.toString() ?? '',
      productName: _scanResult!['item_name']?.toString() ?? '',
    );

    if (photoResult == null) return;

    setState(() => _completing = true);
    try {
      final woName = _scanResult!['work_order']?.toString() ?? '';

      // Submit rejections first
      for (final r in _rejections) {
        await ref.read(line2RepositoryProvider).createRejection(
          jobCard: _scanResult!['job_card']?.toString() ?? '',
          rejectionType: r.isFullScrap ? 'Full Scrap' : 'Rework',
          reason: '${r.code}: ${r.description}',
          qty: r.qty.toDouble(),
        );
      }

      // Submit QC result
      await ref.read(line2RepositoryProvider).submitQcResult(
        workOrder: woName,
        result: _rejections.isEmpty ? 'Pass' : 'Fail',
        acceptedQty: _acceptedQty,
      );

      // Complete WO
      await ref.read(line2RepositoryProvider).completeWo(
        workOrder: woName,
        qty: _acceptedQty,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Work order completed'), backgroundColor: AppTheme.success));
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
      _rejections.clear();
      _rejectionCodes = [];
      _error = null;
      _flowchartCtrl.clear();
      _acceptedQtyCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PdtScaffold(
      title: widget.screen.label,
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Workstation
                if (_workstations.isNotEmpty) ...[
                  const Text('WORKSTATION ID',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary, letterSpacing: 1.0)),
                  const SizedBox(height: 6),
                  WorkstationPickerField(
                    availableWorkstations: _workstations,
                    selectedWorkstation: _selectedWorkstation,
                    onWorkstationChanged: (ws) => setState(() => _selectedWorkstation = ws),
                  ),
                  const SizedBox(height: 16),
                ],

                // Scan
                ScanInputField(
                  controller: _flowchartCtrl,
                  focusNode: _flowchartFocus,
                  labelText: 'Scan Flowchart',
                  hintText: 'Scan flowchart for final QC',
                  onScanned: _onFlowchartScanned,
                  onSubmitted: _onFlowchartScanned,
                  autofocus: _workstations.isEmpty,
                ),
                const SizedBox(height: 12),

                if (_scanning) const Center(child: CircularProgressIndicator()),

                if (_error != null)
                  Card(
                    color: AppTheme.dangerLight,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(children: [
                        const Icon(Icons.error_outline, color: AppTheme.danger),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_error!, style: const TextStyle(color: AppTheme.danger))),
                        IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => setState(() => _error = null)),
                      ]),
                    ),
                  ),

                if (_scanResult != null) ...[
                  ProductDetailsCard.fromScanResult(_scanResult!),
                  const SizedBox(height: 16),

                  // Qty summary
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('QUANTITY SUMMARY',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary, letterSpacing: 1.0)),
                          const SizedBox(height: 10),
                          _qtyRow('Inspected Qty', _inspectedQty.toStringAsFixed(0)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const SizedBox(width: 110, child: Text('Accepted Qty', style: TextStyle(fontSize: 14))),
                              Expanded(
                                child: SizedBox(
                                  height: 40,
                                  child: TextField(
                                    controller: _acceptedQtyCtrl,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.success),
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          _qtyRow('Rejected Qty', _rejectedQty.toStringAsFixed(0), color: AppTheme.danger),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Rejection details
                  Row(
                    children: [
                      const Text('REJECTION DETAILS',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary, letterSpacing: 1.0)),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _addRejection,
                        icon: const Icon(Icons.add_circle_outline, size: 18),
                        label: const Text('Add rejection'),
                      ),
                    ],
                  ),
                  if (_rejections.isNotEmpty)
                    Card(
                      child: Column(
                        children: _rejections.asMap().entries.map((entry) {
                          final i = entry.key;
                          final r = entry.value;
                          return ListTile(
                            dense: true,
                            title: Text('${r.code} - ${r.description}', style: const TextStyle(fontWeight: FontWeight.w500)),
                            subtitle: Text(
                              r.isFullScrap ? 'Scrap: ${r.qty}' : 'Rework: ${r.qty} → ${r.reworkStep ?? ""}',
                              style: TextStyle(color: r.isFullScrap ? AppTheme.danger : AppTheme.warning, fontSize: 12),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20, color: AppTheme.danger),
                              onPressed: () {
                                setState(() {
                                  _rejections.removeAt(i);
                                  final newAccepted = _inspectedQty - _rejectedQty;
                                  _acceptedQtyCtrl.text = newAccepted.toStringAsFixed(newAccepted == newAccepted.roundToDouble() ? 0 : 2);
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    )
                  else
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('No rejections added', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                    ),
                  const SizedBox(height: 16),

                  // Rework assignment summary
                  if (_rejections.any((r) => !r.isFullScrap)) ...[
                    const Text('ASSIGNED STATION & QTY (REWORK)',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary, letterSpacing: 1.0)),
                    const SizedBox(height: 8),
                    Card(
                      child: Column(
                        children: _rejections.where((r) => !r.isFullScrap).map((r) {
                          return ListTile(
                            dense: true,
                            leading: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.warningLight,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(r.reworkStep ?? 'N/A',
                                  style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.warning, fontSize: 12)),
                            ),
                            title: Text('${r.code} — ${r.description}', style: const TextStyle(fontSize: 13)),
                            trailing: Text('Qty: ${r.qty}',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  const SupportHelpSection(),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),

          // Bottom buttons
          if (_scanResult != null)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              decoration: const BoxDecoration(
                color: AppTheme.bgSurface,
                border: Border(top: BorderSide(color: AppTheme.bgBorder)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Back',
                      icon: Icons.arrow_back,
                      outlined: true,
                      onPressed: _resetForm,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: CustomButton(
                      text: _completing ? 'Completing...' : 'Complete WO',
                      icon: Icons.check_circle,
                      isLoading: _completing,
                      backgroundColor: AppTheme.success,
                      textColor: Colors.white,
                      onPressed: _completing ? null : _completeWo,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _qtyRow(String label, String value, {Color? color}) {
    return Row(
      children: [
        SizedBox(width: 110, child: Text(label, style: const TextStyle(fontSize: 14))),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color ?? AppTheme.textPrimary)),
      ],
    );
  }
}
