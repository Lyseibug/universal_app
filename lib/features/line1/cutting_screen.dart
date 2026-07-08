import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/menu/menu_models.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/pdt_scaffold.dart';
import '../../widgets/scan_input_field.dart';
import 'line1_repository.dart';

/// Cutting & Splicing — convert one calendered sheet batch into a different
/// sheet item via a Repack Stock Entry (quality trim / width correction).
/// Worker scans the source sheet batch, enters the target item, input qty
/// (consumed) and output qty (produced); output lands in Cutting WH.
class CuttingScreen extends ConsumerStatefulWidget {
  final MenuScreen screen;
  const CuttingScreen({required this.screen, super.key});

  @override
  ConsumerState<CuttingScreen> createState() => _CuttingScreenState();
}

class _CuttingScreenState extends ConsumerState<CuttingScreen> {
  bool _resolving = false;
  bool _submitting = false;
  Map<String, dynamic>? _sourceBatch;
  String? _batchError;
  String? _inputQtyError;
  String? _outputQtyError;

  final _batchScanCtrl = TextEditingController();
  final _batchScanFocus = FocusNode();
  final _targetItemCtrl = TextEditingController();
  final _inputQtyCtrl = TextEditingController();
  final _outputQtyCtrl = TextEditingController();

  @override
  void dispose() {
    _batchScanCtrl.dispose();
    _batchScanFocus.dispose();
    _targetItemCtrl.dispose();
    _inputQtyCtrl.dispose();
    _outputQtyCtrl.dispose();
    super.dispose();
  }

  void _onBatchScanned(String code) {
    final trimmed = code.trim();
    if (trimmed.isEmpty) return;
    _resolveBatch(trimmed);
  }

  Future<void> _resolveBatch(String batchNo) async {
    setState(() {
      _resolving = true;
      _sourceBatch = null;
      _batchError = null;
    });
    try {
      final batches = await ref
          .read(line1RepositoryProvider)
          .listEligibleCutSourceBatches();
      final match = batches.firstWhere(
        (b) => (b['batch_no']?.toString() ?? '') == batchNo,
        orElse: () => const {},
      );
      if (match.isEmpty) {
        throw Exception(
            'Batch "$batchNo" not found (or has no stock) in Finished Sheet WH');
      }
      setState(() {
        _sourceBatch = Map<String, dynamic>.from(match);
        _inputQtyCtrl.text = ((match['qty'] as num?) ?? 0).toStringAsFixed(2);
        _resolving = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _resolving = false;
        _batchError = '$e';
      });
    }
  }

  double get _availableQty => ((_sourceBatch?['qty'] as num?) ?? 0).toDouble();

  bool _validate() {
    var ok = true;
    final input = double.tryParse(_inputQtyCtrl.text.trim());
    if (input == null || input <= 0) {
      setState(() => _inputQtyError = 'Must be greater than 0');
      ok = false;
    } else if (input > _availableQty) {
      setState(() => _inputQtyError = 'Only $_availableQty available');
      ok = false;
    } else {
      setState(() => _inputQtyError = null);
    }

    final output = double.tryParse(_outputQtyCtrl.text.trim());
    if (output == null || output <= 0) {
      setState(() => _outputQtyError = 'Must be greater than 0');
      ok = false;
    } else {
      setState(() => _outputQtyError = null);
    }

    if (_targetItemCtrl.text.trim().isEmpty) {
      ok = false;
    }
    return ok;
  }

  Future<void> _confirmAndCut() async {
    if (_sourceBatch == null || !_validate()) return;
    final sourceItemLabel =
        (_sourceBatch!['item_code'] ?? '').toString();
    final targetItem = _targetItemCtrl.text.trim();
    final inputQty = double.parse(_inputQtyCtrl.text.trim());
    final outputQty = double.parse(_outputQtyCtrl.text.trim());

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Cut'),
        content: Text(
          'Consume $inputQty of $sourceItemLabel\n'
          '(batch ${_sourceBatch!['batch_no']})\n'
          'Produce $outputQty of $targetItem',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirm')),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _submitting = true);
    try {
      await ref.read(line1RepositoryProvider).performCut(
            sourceBatch: _sourceBatch!['batch_no'].toString(),
            targetItem: targetItem,
            inputQty: inputQty,
            outputQty: outputQty,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Cut complete: $outputQty of $targetItem produced'),
          backgroundColor: AppTheme.success,
        ));
        _reset();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$e'),
          backgroundColor: AppTheme.danger,
        ));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _reset() {
    setState(() {
      _sourceBatch = null;
      _batchError = null;
      _inputQtyError = null;
      _outputQtyError = null;
    });
    _batchScanCtrl.clear();
    _targetItemCtrl.clear();
    _inputQtyCtrl.clear();
    _outputQtyCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return PdtScaffold(
      title: widget.screen.label,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ScanInputField(
            controller: _batchScanCtrl,
            focusNode: _batchScanFocus,
            labelText: 'Scan Source Sheet Batch',
            hintText: 'Scan the calendered sheet batch to cut',
            onScanned: _onBatchScanned,
            onSubmitted: _onBatchScanned,
            autofocus: true,
          ),
          const SizedBox(height: 16),

          if (_resolving)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            ),

          if (_batchError != null && !_resolving)
            Card(
              color: AppTheme.danger.withAlpha(20),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_batchError!,
                    style: const TextStyle(color: AppTheme.danger)),
              ),
            ),

          if (_sourceBatch != null && !_resolving) _buildCutCard(),
        ],
      ),
    );
  }

  Widget _buildCutCard() {
    final b = _sourceBatch!;
    return Card(
      elevation: 3,
      color: Colors.teal.withAlpha(20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.content_cut, color: Colors.teal),
                const SizedBox(width: 8),
                Expanded(
                  child: Text((b['item_code'] ?? '').toString(),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: _reset),
              ],
            ),
            const SizedBox(height: 4),
            Text('Batch: ${b['batch_no']}'),
            const SizedBox(height: 4),
            Text('Available: $_availableQty', style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 16),

            TextField(
              controller: _inputQtyCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Input Qty (consumed)',
                errorText: _inputQtyError,
                isDense: true,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _targetItemCtrl,
              decoration: const InputDecoration(
                labelText: 'Target Item',
                hintText: 'Scan or enter the resulting item code',
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _outputQtyCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Output Qty (produced)',
                errorText: _outputQtyError,
                isDense: true,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            if (widget.screen.can('perform_cut'))
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _submitting ? null : _confirmAndCut,
                  icon: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.content_cut),
                  label: Text(_submitting ? 'Cutting...' : 'Perform Cut'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
