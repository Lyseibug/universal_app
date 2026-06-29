import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/menu/menu_models.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/pdt_scaffold.dart';
import '../../widgets/scan_input_field.dart';
import 'line2_repository.dart';

class LabellingScreen extends ConsumerStatefulWidget {
  final MenuScreen screen;
  const LabellingScreen({required this.screen, super.key});

  @override
  ConsumerState<LabellingScreen> createState() => _LabellingScreenState();
}

class _LabellingScreenState extends ConsumerState<LabellingScreen> {
  final _scanCtrl = TextEditingController();
  final _scanFocus = FocusNode();

  bool _scanning = false;
  bool _printing = false;
  String? _error;
  String? _printStatus;

  Map<String, dynamic>? _itemData;

  @override
  void dispose() {
    _scanCtrl.dispose();
    _scanFocus.dispose();
    super.dispose();
  }

  Future<void> _onItemScanned(String barcode) async {
    final trimmed = barcode.trim();
    if (trimmed.isEmpty) return;

    setState(() {
      _scanning = true;
      _error = null;
      _itemData = null;
      _printStatus = null;
    });

    try {
      final result =
          await ref.read(line2RepositoryProvider).scanFlowchart(trimmed);
      setState(() {
        _itemData = Map<String, dynamic>.from(result);
        _scanning = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Scan failed: $e';
        _scanning = false;
      });
    }
  }

  Future<void> _printLabel() async {
    if (_itemData == null) return;

    setState(() {
      _printing = true;
      _printStatus = null;
    });

    try {
      final itemCode = _itemData!['item_code']?.toString() ?? _scanCtrl.text.trim();
      await ref.read(line2RepositoryProvider).printLabel('Item', itemCode);
      setState(() {
        _printStatus = 'success';
        _printing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Label sent to printer'),
          backgroundColor: AppTheme.success,
        ));
      }
    } catch (e) {
      setState(() {
        _printStatus = 'error';
        _printing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Print failed: $e'),
          backgroundColor: AppTheme.danger,
        ));
      }
    }
  }

  void _resetForm() {
    setState(() {
      _itemData = null;
      _error = null;
      _printStatus = null;
      _scanCtrl.clear();
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
            controller: _scanCtrl,
            focusNode: _scanFocus,
            labelText: 'Scan Item / Batch',
            hintText: 'Scan item or batch barcode',
            onScanned: _onItemScanned,
            onSubmitted: _onItemScanned,
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

          if (_itemData != null) ...[
            // Item details card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.inventory_2,
                            color: AppTheme.primary, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _itemData!['item_name']?.toString() ??
                                _itemData!['item_code']?.toString() ?? '',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    _infoRow('Item Code',
                        _itemData!['item_code']?.toString() ?? ''),
                    if (_itemData!['batch_no'] != null)
                      _infoRow('Batch', _itemData!['batch_no'].toString()),
                    if (_itemData!['work_order'] != null)
                      _infoRow(
                          'Work Order', _itemData!['work_order'].toString()),
                    if (_itemData!['qty'] != null)
                      _infoRow('Qty', _itemData!['qty'].toString()),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Print status
            if (_printStatus != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(
                      _printStatus == 'success'
                          ? Icons.check_circle
                          : Icons.error_outline,
                      color: _printStatus == 'success'
                          ? AppTheme.success
                          : AppTheme.danger,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _printStatus == 'success'
                          ? 'Label printed successfully'
                          : 'Print failed - try again',
                      style: TextStyle(
                        color: _printStatus == 'success'
                            ? AppTheme.success
                            : AppTheme.danger,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

            CustomButton(
              text: _printing ? 'Printing...' : 'Print Label',
              icon: Icons.print,
              isLoading: _printing,
              backgroundColor: AppTheme.primary,
              textColor: Colors.white,
              onPressed: _printing ? null : _printLabel,
            ),
            const SizedBox(height: 8),
            CustomButton(
              text: 'Scan Another',
              icon: Icons.qr_code_scanner,
              outlined: true,
              onPressed: _resetForm,
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
