import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/menu/menu_models.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/pdt_scaffold.dart';
import '../../widgets/scan_input_field.dart';
import 'line2_repository.dart';
import 'widgets/product_details_card.dart';
import 'widgets/support_help_section.dart';

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

  Map<String, dynamic>? _scanResult;

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
      _scanResult = null;
      _printStatus = null;
    });

    try {
      final result = await ref.read(line2RepositoryProvider).scanFlowchart(trimmed);
      setState(() { _scanResult = result; _scanning = false; });
    } catch (e) {
      setState(() { _error = 'Scan failed: $e'; _scanning = false; });
    }
  }

  Future<void> _printLabel() async {
    if (_scanResult == null) return;

    setState(() { _printing = true; _printStatus = null; });

    try {
      final barcode = _scanResult!['flowchart_barcode']?.toString() ?? _scanCtrl.text.trim();
      await ref.read(line2RepositoryProvider).printLabel(barcode: barcode, labelType: 'Item');
      setState(() { _printStatus = 'success'; _printing = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Label sent to printer'), backgroundColor: AppTheme.success));
      }
    } catch (e) {
      setState(() { _printStatus = 'error'; _printing = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Print failed: $e'), backgroundColor: AppTheme.danger));
      }
    }
  }

  void _resetForm() {
    setState(() {
      _scanResult = null;
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
            labelText: 'Scan Flowchart / Item',
            hintText: 'Scan item or flowchart barcode',
            onScanned: _onItemScanned,
            onSubmitted: _onItemScanned,
            autofocus: true,
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
                ]),
              ),
            ),

          if (_scanResult != null) ...[
            ProductDetailsCard.fromScanResult(_scanResult!),
            const SizedBox(height: 16),

            if (_printStatus != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(children: [
                  Icon(
                    _printStatus == 'success' ? Icons.check_circle : Icons.error_outline,
                    color: _printStatus == 'success' ? AppTheme.success : AppTheme.danger, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    _printStatus == 'success' ? 'Label printed successfully' : 'Print failed - try again',
                    style: TextStyle(
                      color: _printStatus == 'success' ? AppTheme.success : AppTheme.danger,
                      fontWeight: FontWeight.w600)),
                ]),
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
            const SizedBox(height: 16),
            const SupportHelpSection(),
          ],
        ],
      ),
    );
  }
}
