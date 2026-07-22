import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/menu/menu_models.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/pdt_scaffold.dart';
import '../../widgets/scan_input_field.dart';
import 'line2_repository.dart';

class ReceptionScreen extends ConsumerStatefulWidget {
  final MenuScreen screen;
  const ReceptionScreen({required this.screen, super.key});

  @override
  ConsumerState<ReceptionScreen> createState() => _ReceptionScreenState();
}

class _ReceptionScreenState extends ConsumerState<ReceptionScreen> {
  final _receiveScanCtrl = TextEditingController();
  final _receiveScanFocus = FocusNode();
  final _receiveQtyCtrl = TextEditingController(text: '1');
  bool _receiving = false;
  Map<String, dynamic>? _lastReceived;

  @override
  void dispose() {
    _receiveScanCtrl.dispose();
    _receiveScanFocus.dispose();
    _receiveQtyCtrl.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: AppTheme.danger,
    ));
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: AppTheme.success,
    ));
  }

  Future<void> _receiveFlowchart(String barcode) async {
    final trimmed = barcode.trim();
    if (trimmed.isEmpty) return;
    final qty = double.tryParse(_receiveQtyCtrl.text.trim());
    if (qty == null || qty <= 0) {
      _showError('Enter a received quantity greater than 0');
      return;
    }

    setState(() => _receiving = true);
    try {
      final result = await ref.read(line2RepositoryProvider).receiveFlowchart(
            barcode: trimmed,
            receivedQty: qty,
          );
      setState(() {
        _lastReceived = result;
        _receiving = false;
      });
      _receiveScanCtrl.clear();
      final status = result['dispatch_status']?.toString() ?? '';
      if (status == 'Not Completed') {
        _showError(
            'Received ${result['total_received_qty']} of ${result['qc_accepted_qty']} — ${result['shortfall_qty']} short, flowchart Not Completed');
      } else {
        _showSuccess('Flowchart fully received');
      }
    } catch (e) {
      setState(() => _receiving = false);
      _showError('Receive error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PdtScaffold(
      title: widget.screen.label,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Scan a finished flowchart barcode and enter how many were physically received.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _receiveQtyCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Received Qty',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          ScanInputField(
            controller: _receiveScanCtrl,
            focusNode: _receiveScanFocus,
            labelText: 'Scan Flowchart',
            hintText: 'Scan flowchart barcode',
            onScanned: _receiving ? null : _receiveFlowchart,
            onSubmitted: _receiving ? null : _receiveFlowchart,
            autofocus: true,
          ),
          const SizedBox(height: 16),
          if (_lastReceived != null) _buildReceiveResultCard(_lastReceived!),
        ],
      ),
    );
  }

  Widget _buildReceiveResultCard(Map<String, dynamic> result) {
    final status = result['dispatch_status']?.toString() ?? '';
    final isComplete = status == 'Received';
    return Card(
      color: (isComplete ? AppTheme.success : AppTheme.danger).withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(isComplete ? Icons.check_circle : Icons.warning,
                    color: isComplete ? AppTheme.success : AppTheme.danger),
                const SizedBox(width: 8),
                Text(status,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isComplete ? AppTheme.success : AppTheme.danger)),
              ],
            ),
            const SizedBox(height: 6),
            Text('Work Order: ${result['work_order']}'),
            Text('QC Accepted: ${result['qc_accepted_qty']}'),
            Text('Total Received: ${result['total_received_qty']}'),
            if (!isComplete) Text('Shortfall: ${result['shortfall_qty']}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.danger)),
          ],
        ),
      ),
    );
  }
}
