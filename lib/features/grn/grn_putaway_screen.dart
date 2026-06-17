import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_exceptions.dart';
import '../../core/errors/error_mapper.dart';
import '../../core/menu/menu_models.dart';
import '../../core/scanner/scan_service.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/service_providers.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'grn_repository.dart';

class GrnPutAwayScreen extends ConsumerStatefulWidget {
  final MenuScreen screen;

  const GrnPutAwayScreen({required this.screen, super.key});

  @override
  ConsumerState<GrnPutAwayScreen> createState() => _GrnPutAwayScreenState();
}

class _GrnPutAwayScreenState extends ConsumerState<GrnPutAwayScreen> {
  bool _loadingList = true;
  List<dynamic> _pendingItems = [];
  String? _listError;

  // Selected item detail
  Map<String, dynamic>? _selectedItem;
  bool _submitting = false;

  // Controller & focus nodes
  final _binCtrl = TextEditingController();
  final _lotCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _prodDateCtrl = TextEditingController();
  
  final _binFocus = FocusNode();
  final _lotFocus = FocusNode();
  final _qtyFocus = FocusNode();

  late StreamSubscription<String> _scanSubscription;
  bool _overrideCapacity = false;

  @override
  void initState() {
    super.initState();
    _loadPending();
    
    // Listen to the barcode scanner stream
    _scanSubscription = ref.read(keyboardScanServiceProvider).scans.listen(_onBarcodeScanned);
  }

  @override
  void dispose() {
    _scanSubscription.cancel();
    _binCtrl.dispose();
    _lotCtrl.dispose();
    _qtyCtrl.dispose();
    _prodDateCtrl.dispose();
    _binFocus.dispose();
    _lotFocus.dispose();
    _qtyFocus.dispose();
    super.dispose();
  }

  Future<void> _loadPending() async {
    setState(() {
      _loadingList = true;
      _listError = null;
    });
    try {
      final items = await ref.read(grnRepositoryProvider).listPending();
      setState(() {
        _pendingItems = items;
        _loadingList = false;
      });
    } catch (e) {
      setState(() {
        _listError = 'Failed to load pending GRN lines.';
        _loadingList = false;
      });
    }
  }

  void _onBarcodeScanned(String barcode) {
    if (_selectedItem == null) return;
    
    // Determine active input based on focus or sequence
    if (_binFocus.hasFocus) {
      _binCtrl.text = barcode;
      _lotFocus.requestFocus();
    } else if (_lotFocus.hasFocus) {
      _lotCtrl.text = barcode;
      _qtyFocus.requestFocus();
    } else {
      // Default fallback: scan goes to active empty field
      if (_binCtrl.text.isEmpty) {
        _binCtrl.text = barcode;
      } else if (_lotCtrl.text.isEmpty) {
        _lotCtrl.text = barcode;
      }
    }
    setState(() {});
  }

  void _selectItem(Map<String, dynamic> item) {
    setState(() {
      _selectedItem = item;
      _binCtrl.clear();
      _lotCtrl.text = (item['lot_no'] ?? '').toString();
      _qtyCtrl.text = (item['pending_qty'] ?? '').toString();
      _prodDateCtrl.text = (item['production_date'] ?? '').toString();
      _overrideCapacity = false;
    });
    
    // Auto focus bin field after selection
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _binFocus.requestFocus();
    });
  }

  Future<void> _submitPutAway() async {
    if (_selectedItem == null) return;
    
    final bin = _binCtrl.text.trim();
    final lot = _lotCtrl.text.trim();
    final qty = double.tryParse(_qtyCtrl.text) ?? 0.0;
    
    if (bin.isEmpty || lot.isEmpty || qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please scan a valid Bin, Lot, and enter quantity.')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      await ref.read(grnRepositoryProvider).putAway(
            receivedItemLine: _selectedItem!['name'].toString(),
            lot: lot,
            qty: qty,
            productionDate: _prodDateCtrl.text.isNotEmpty ? _prodDateCtrl.text : null,
            forceCapacity: _overrideCapacity,
          );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Put-Away successful!'), backgroundColor: AppTheme.success),
      );
      
      setState(() {
        _selectedItem = null;
      });
      _loadPending();
    } on ApiException catch (e) {
      if (e.code == 'BIN_FULL' && widget.screen.can('override_capacity')) {
        _promptOverrideCapacity();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(messageFor(e)), backgroundColor: AppTheme.danger),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.danger),
      );
    } finally {
      setState(() => _submitting = false);
    }
  }

  void _promptOverrideCapacity() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bin Full Override'),
        content: const Text(
          'The selected bin is marked as full. As a supervisor, would you like to force this put-away?',
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.warning,
              minimumSize: const Size(100, 44),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _overrideCapacity = true;
              });
              _submitPutAway();
            },
            child: const Text('Force Put-Away'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardWedgeScanWidget(
      service: ref.read(keyboardScanServiceProvider),
      child: Scaffold(
        backgroundColor: AppTheme.bgScaffold,
        appBar: AppBar(
          title: Text(
            _selectedItem == null ? 'GRN Put-Away' : 'Allocate Item',
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (_selectedItem != null) {
                setState(() => _selectedItem = null);
              } else {
                Navigator.of(context).pop();
              }
            },
          ),
        ),
        body: _selectedItem == null ? _buildListBody() : _buildAllocationBody(),
      ),
    );
  }

  Widget _buildListBody() {
    if (_loadingList) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_listError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.horizontalPad),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_listError!, style: const TextStyle(color: AppTheme.danger)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadPending, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (_pendingItems.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.horizontalPad),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.inventory_2_outlined, size: 64, color: AppTheme.textDisabled),
              const SizedBox(height: 16),
              Text(
                'No pending put-away items found',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.horizontalPad, vertical: 16),
      itemCount: _pendingItems.length,
      itemBuilder: (context, i) {
        final item = Map<String, dynamic>.from(_pendingItems[i]);
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Card(
            child: ListTile(
              title: Text(
                '${item['item_code']} (${item['item_name'] ?? ''})',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('GRN: ${item['parent']} | Line: ${item['name']}'),
                  const SizedBox(height: 2),
                  Text('Qty: ${item['pending_qty']} | Warehouse: ${item['warehouse'] ?? 'Not specified'}'),
                ],
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.textSecondary),
              onTap: () => _selectItem(item),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAllocationBody() {
    final item = _selectedItem!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.horizontalPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Item Details Card
          Card(
            color: AppTheme.bgElevated,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${item['item_code']}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['item_name'] ?? '',
                    style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Pending Qty: ${item['pending_qty']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text('UOM: ${item['uom'] ?? 'Units'}'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Form Input Fields
          CustomTextField(
            controller: _binCtrl,
            focusNode: _binFocus,
            labelText: 'Scan Bin',
            hintText: 'Scan target bin location',
            prefixIcon: const Icon(Icons.place_outlined),
            textStyle: AppTheme.scanValueStyle,
            onChanged: (val) => setState(() {}),
          ),
          const SizedBox(height: 14),

          CustomTextField(
            controller: _lotCtrl,
            focusNode: _lotFocus,
            labelText: 'Scan Lot',
            hintText: 'Scan item Lot number',
            prefixIcon: const Icon(Icons.qr_code_scanner),
            textStyle: AppTheme.scanValueStyle,
            onChanged: (val) => setState(() {}),
          ),
          const SizedBox(height: 14),

          CustomTextField(
            controller: _qtyCtrl,
            focusNode: _qtyFocus,
            labelText: 'Put-Away Qty',
            hintText: 'Enter quantity',
            prefixIcon: const Icon(Icons.calculate_outlined),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),

          CustomButton(
            text: 'Confirm Put-Away',
            isLoading: _submitting,
            icon: Icons.check_circle_outline,
            onPressed: _submitPutAway,
          ),
        ],
      ),
    );
  }
}
