import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_exceptions.dart';
import '../../core/errors/error_mapper.dart';
import '../../core/menu/menu_models.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/pdt_scaffold.dart';
import '../../widgets/scan_input_field.dart';
import 'lot_repository.dart';

class ManualTransferScreen extends ConsumerStatefulWidget {
  final MenuScreen screen;

  const ManualTransferScreen({required this.screen, super.key});

  @override
  ConsumerState<ManualTransferScreen> createState() => _ManualTransferScreenState();
}

class _ManualTransferScreenState extends ConsumerState<ManualTransferScreen> {
  final _fromLotCtrl = TextEditingController();
  final _toLotCtrl = TextEditingController();
  final _itemCtrl = TextEditingController();
  final _batchCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();

  final _fromFocus = FocusNode();
  final _toFocus = FocusNode();
  final _itemFocus = FocusNode();
  final _batchFocus = FocusNode();
  final _qtyFocus = FocusNode();

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fromFocus.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _fromLotCtrl.dispose();
    _toLotCtrl.dispose();
    _itemCtrl.dispose();
    _batchCtrl.dispose();
    _qtyCtrl.dispose();
    
    _fromFocus.dispose();
    _toFocus.dispose();
    _itemFocus.dispose();
    _batchFocus.dispose();
    _qtyFocus.dispose();
    super.dispose();
  }

  Future<void> _submitTransfer() async {
    final fromLot = _fromLotCtrl.text.trim();
    final toLot = _toLotCtrl.text.trim();
    final item = _itemCtrl.text.trim();
    final batchNo = _batchCtrl.text.trim();
    final qty = double.tryParse(_qtyCtrl.text) ?? 0.0;

    if (fromLot.isEmpty || toLot.isEmpty || item.isEmpty || qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill From Lot, To Lot, Item, and positive Quantity.')),
      );
      return;
    }

    if (!widget.screen.can('transfer')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Access denied. Action: transfer is restricted.'), backgroundColor: AppTheme.danger),
      );
      return;
    }

    setState(() => _submitting = true);
    
    try {
      await ref.read(lotRepositoryProvider).transfer(
            fromLot: fromLot,
            toLot: toLot,
            item: item,
            batchNo: batchNo,
            qty: qty,
          );

      // No toast — the form clearing below is confirmation enough.
      // Reset form fields
      setState(() {
        _fromLotCtrl.clear();
        _toLotCtrl.clear();
        _itemCtrl.clear();
        _batchCtrl.clear();
        _qtyCtrl.clear();
      });
      _fromFocus.requestFocus();
    } on ApiException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(messageFor(e)), backgroundColor: AppTheme.danger),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.danger),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PdtScaffold(
      title: widget.screen.label,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.horizontalPad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Scan fields instruction banner
            Container(
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                border: Border.all(color: AppTheme.bgBorder),
              ),
              padding: const EdgeInsets.all(12),
              child: const Row(
                children: [
                  Icon(Icons.flash_on, color: AppTheme.amber, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sequential scanning active: Scan From Lot → Scan To Lot → Scan Item → Scan Batch.',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Inputs
            ScanInputField(
              controller: _fromLotCtrl,
              focusNode: _fromFocus,
              labelText: 'From Location / Lot',
              hintText: 'Scan origin lot bin',
              prefixIcon: Icons.outbox_outlined,
              textInputAction: TextInputAction.next,
              onScanned: (_) => _toFocus.requestFocus(),
              onSubmitted: (_) => _toFocus.requestFocus(),
            ),
            const SizedBox(height: 14),

            ScanInputField(
              controller: _toLotCtrl,
              focusNode: _toFocus,
              labelText: 'To Location / Lot',
              hintText: 'Scan destination lot bin',
              prefixIcon: Icons.move_to_inbox_outlined,
              textInputAction: TextInputAction.next,
              onScanned: (_) => _itemFocus.requestFocus(),
              onSubmitted: (_) => _itemFocus.requestFocus(),
            ),
            const SizedBox(height: 14),

            ScanInputField(
              controller: _itemCtrl,
              focusNode: _itemFocus,
              labelText: 'Scan Item Code',
              hintText: 'Scan item to transfer',
              prefixIcon: Icons.inventory_2_outlined,
              textInputAction: TextInputAction.next,
              onScanned: (_) => _batchFocus.requestFocus(),
              onSubmitted: (_) => _batchFocus.requestFocus(),
            ),
            const SizedBox(height: 14),

            ScanInputField(
              controller: _batchCtrl,
              focusNode: _batchFocus,
              labelText: 'Scan Batch / Lot Number',
              hintText: 'Scan batch (optional)',
              prefixIcon: Icons.qr_code_scanner,
              textInputAction: TextInputAction.next,
              onScanned: (_) => _qtyFocus.requestFocus(),
              onSubmitted: (_) => _qtyFocus.requestFocus(),
            ),
            const SizedBox(height: 14),

            CustomTextField(
              controller: _qtyCtrl,
              focusNode: _qtyFocus,
              labelText: 'Transfer Quantity',
              hintText: 'Enter quantity to transfer',
              prefixIcon: const Icon(Icons.calculate_outlined),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),

            CustomButton(
              text: 'Execute Stock Transfer',
              isLoading: _submitting,
              icon: Icons.swap_horiz_outlined,
              onPressed: widget.screen.can('transfer') ? _submitTransfer : null,
            ),
          ],
        ),
      ),
    );
  }
}
