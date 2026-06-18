import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/api/api_exceptions.dart';
import '../../core/errors/error_mapper.dart';
import '../../core/menu/menu_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/warehouse_models.dart';
import '../../providers/service_providers.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/pdt_scaffold.dart';
import '../../widgets/scan_input_field.dart';
import 'grn_repository.dart';

class GrnPutAwayScreen extends ConsumerStatefulWidget {
  final MenuScreen screen;

  const GrnPutAwayScreen({required this.screen, super.key});

  @override
  ConsumerState<GrnPutAwayScreen> createState() => _GrnPutAwayScreenState();
}

class _GrnPutAwayScreenState extends ConsumerState<GrnPutAwayScreen> {
  bool _loadingList = true;
  List<ReceivedItemLine> _pendingItems = [];
  String? _listError;

  // Selected item detail
  ReceivedItemLine? _selectedItem;
  bool _submitting = false;

  // Lot suggestion states
  LotSuggestion? _suggestion;
  bool _loadingSuggestion = false;

  // Controller & focus nodes
  final _binCtrl = TextEditingController();
  final _lotCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _prodDateCtrl = TextEditingController();
  final _expiryDateCtrl = TextEditingController();
  
  final _binFocus = FocusNode();
  final _lotFocus = FocusNode();
  final _qtyFocus = FocusNode();
  final _prodDateFocus = FocusNode();
  final _expiryDateFocus = FocusNode();

  bool _overrideCapacity = false;

  @override
  void initState() {
    super.initState();
    _loadPending();
  }

  @override
  void dispose() {
    _binCtrl.dispose();
    _lotCtrl.dispose();
    _qtyCtrl.dispose();
    _prodDateCtrl.dispose();
    _expiryDateCtrl.dispose();
    _binFocus.dispose();
    _lotFocus.dispose();
    _qtyFocus.dispose();
    _prodDateFocus.dispose();
    _expiryDateFocus.dispose();
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

  Future<void> _selectItem(ReceivedItemLine item) async {
    setState(() {
      _selectedItem = item;
      _binCtrl.clear();
      _lotCtrl.text = item.lotNo ?? '';
      _qtyCtrl.text = item.pendingQty.toString();
      _prodDateCtrl.text = item.productionDate ?? '';
      _expiryDateCtrl.text = item.expiryDate ?? '';
      _overrideCapacity = false;
      _suggestion = null;
      _loadingSuggestion = true;
    });
    
    // Auto focus bin field after selection
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _binFocus.requestFocus();
      }
    });

    try {
      final suggest = await ref.read(grnRepositoryProvider).suggestLot(item.name);
      if (mounted && _selectedItem?.name == item.name) {
        setState(() {
          _suggestion = suggest;
          _loadingSuggestion = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loadingSuggestion = false);
      }
    }
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() {
        controller.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
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
            receivedItemLine: _selectedItem!.name,
            lot: lot,
            qty: qty,
            productionDate: _prodDateCtrl.text.isNotEmpty ? _prodDateCtrl.text : null,
            expiryDate: _expiryDateCtrl.text.isNotEmpty ? _expiryDateCtrl.text : null,
            forceCapacity: _overrideCapacity,
          );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Put-Away successful!'), backgroundColor: AppTheme.success),
      );
      
      final currentItem = _selectedItem!;
      setState(() {
        if (currentItem.pendingQty > qty) {
          // Decrement pending qty inline
          _pendingItems = _pendingItems.map((e) {
            if (e.name == currentItem.name) {
              return e.copyWith(pendingQty: e.pendingQty - qty);
            }
            return e;
          }).toList();
        } else {
          // Remove from list inline
          _pendingItems = _pendingItems.where((e) => e.name != currentItem.name).toList();
        }
        _selectedItem = null;
        _suggestion = null;
      });
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
      if (mounted) setState(() => _submitting = false);
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
    return PdtScaffold(
      title: _selectedItem == null ? widget.screen.label : 'Allocate Item',
      body: _selectedItem == null ? _buildListBody() : _buildAllocationBody(),
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

    return RefreshIndicator(
      onRefresh: _loadPending,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.horizontalPad, vertical: 16),
        itemCount: _pendingItems.length,
        itemBuilder: (context, i) {
          final item = _pendingItems[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              child: ListTile(
                title: Text(
                  '${item.itemCode} (${item.itemName ?? ''})',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text('GRN: ${item.parent} | Line: ${item.name}'),
                    const SizedBox(height: 2),
                    Text('Qty: ${item.pendingQty} | Warehouse: ${item.warehouse ?? 'Not specified'}'),
                  ],
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.textSecondary),
                onTap: () => _selectItem(item),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAllocationBody() {
    final item = _selectedItem!;
    return WillPopScope(
      onWillPop: () async {
        setState(() {
          _selectedItem = null;
          _suggestion = null;
        });
        return false;
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.horizontalPad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Back navigation helper
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedItem = null;
                    _suggestion = null;
                  });
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to list'),
              ),
            ),
            const SizedBox(height: 8),

            // Item Details Card
            Card(
              color: AppTheme.bgElevated,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.itemCode,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.itemName ?? '',
                      style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Pending Qty: ${item.pendingQty}', style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text('UOM: ${item.uom ?? 'Units'}'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Suggestion Card
            if (_loadingSuggestion)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_suggestion != null)
              Card(
                color: AppTheme.warningLight,
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: AppTheme.warning, width: 1.5),
                  borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.lightbulb_outline, color: AppTheme.warning),
                          SizedBox(width: 8),
                          Text(
                            'Suggested Bin / Lot Recommendation',
                            style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.warning),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Recommended Bin: ${_suggestion!.lot}', style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text('Available Qty in Bin: ${_suggestion!.availableQty}'),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.warning,
                          side: const BorderSide(color: AppTheme.warning),
                          minimumSize: const Size(140, 36),
                        ),
                        onPressed: () {
                          setState(() {
                            _binCtrl.text = _suggestion!.lot;
                          });
                          _lotFocus.requestFocus();
                        },
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Use Suggested Bin'),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Form Input Fields
            ScanInputField(
              controller: _binCtrl,
              focusNode: _binFocus,
              labelText: 'Scan Bin',
              hintText: 'Scan target bin location',
              prefixIcon: Icons.place_outlined,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => _lotFocus.requestFocus(),
            ),
            const SizedBox(height: 14),

            ScanInputField(
              controller: _lotCtrl,
              focusNode: _lotFocus,
              labelText: 'Scan Lot',
              hintText: 'Scan item Lot number',
              prefixIcon: Icons.qr_code_scanner,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => _qtyFocus.requestFocus(),
            ),
            const SizedBox(height: 14),

            CustomTextField(
              controller: _qtyCtrl,
              focusNode: _qtyFocus,
              labelText: 'Put-Away Qty',
              hintText: 'Enter quantity',
              prefixIcon: const Icon(Icons.calculate_outlined),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => _prodDateFocus.requestFocus(),
            ),
            const SizedBox(height: 14),

            CustomTextField(
              controller: _prodDateCtrl,
              focusNode: _prodDateFocus,
              labelText: 'Production Date (YYYY-MM-DD)',
              hintText: 'Select or enter production date',
              prefixIcon: const Icon(Icons.calendar_today_outlined),
              readOnly: true,
              suffixIcon: IconButton(
                icon: const Icon(Icons.calendar_month),
                onPressed: () => _selectDate(context, _prodDateCtrl),
              ),
              onTap: () => _selectDate(context, _prodDateCtrl),
            ),
            const SizedBox(height: 14),

            CustomTextField(
              controller: _expiryDateCtrl,
              focusNode: _expiryDateFocus,
              labelText: 'Expiry Date (YYYY-MM-DD)',
              hintText: 'Select or enter expiry date',
              prefixIcon: const Icon(Icons.event_busy_outlined),
              readOnly: true,
              suffixIcon: IconButton(
                icon: const Icon(Icons.calendar_month),
                onPressed: () => _selectDate(context, _expiryDateCtrl),
              ),
              onTap: () => _selectDate(context, _expiryDateCtrl),
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
      ),
    );
  }
}
