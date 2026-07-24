import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/api/api_exceptions.dart';
import '../../core/errors/error_mapper.dart';
import '../../core/menu/menu_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/warehouse_models.dart';
import '../../core/utils/logger.dart';
import '../../providers/service_providers.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/pdt_scaffold.dart';
import '../../widgets/scan_input_field.dart';
import 'grn_repository.dart';

enum PutAwayView {
  list,
  detail,
  createBatch,
  selectBatch,
  allocateBin,
}

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

  // Flow State
  PutAwayView _currentView = PutAwayView.list;
  ReceivedItemLine? _selectedItem;
  bool _submitting = false;

  // Created Batches List State
  List<GrnBatch> _createdBatches = [];
  bool _loadingBatches = false;
  String? _batchesError;

  // Selected Batch for allocation
  GrnBatch? _selectedBatch;

  // Lot suggestion states
  LotSuggestion? _suggestion;
  bool _loadingSuggestion = false;

  // Form Controllers & focus nodes
  final _lotCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _prodDateCtrl = TextEditingController();
  final _expiryDateCtrl = TextEditingController();
  final _batchScanCtrl = TextEditingController();
  
  final _lotFocus = FocusNode();
  final _qtyFocus = FocusNode();
  final _prodDateFocus = FocusNode();
  final _expiryDateFocus = FocusNode();
  final _batchScanFocus = FocusNode();

  // Filter controllers & focus nodes
  final _receiptFilterCtrl = TextEditingController();
  final _itemFilterCtrl = TextEditingController();

  final _receiptFilterFocus = FocusNode();
  final _itemFilterFocus = FocusNode();

  // Filter application states
  bool _showFilterPanel = false;
  String _appliedReceiptFilter = '';
  String _appliedItemFilter = '';

  bool _overrideCapacity = false;

  @override
  void initState() {
    super.initState();
    _loadPending();
  }

  @override
  void dispose() {
    _lotCtrl.dispose();
    _qtyCtrl.dispose();
    _prodDateCtrl.dispose();
    _expiryDateCtrl.dispose();
    _batchScanCtrl.dispose();
    _lotFocus.dispose();
    _qtyFocus.dispose();
    _prodDateFocus.dispose();
    _expiryDateFocus.dispose();
    _batchScanFocus.dispose();
    _receiptFilterCtrl.dispose();
    _itemFilterCtrl.dispose();
    _receiptFilterFocus.dispose();
    _itemFilterFocus.dispose();
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

  Future<void> _loadCreatedBatches(String receivedItemLine) async {
    setState(() {
      _loadingBatches = true;
      _batchesError = null;
    });
    try {
      final batches = await ref.read(grnRepositoryProvider).listCreatedBatches(receivedItemLine);
      setState(() {
        _createdBatches = batches;
        _loadingBatches = false;
      });
    } catch (e) {
      setState(() {
        _batchesError = 'Failed to load created batches.';
        _loadingBatches = false;
      });
    }
  }

  Future<void> _selectItem(ReceivedItemLine item) async {
    setState(() {
      _selectedItem = item;
      _currentView = PutAwayView.detail;
    });
    await _loadCreatedBatches(item.name);
  }

  void _navigateToCreateBatch() {
    final remainingBatchQty = _selectedItem!.pendingBatchQty ?? _selectedItem!.pendingQty;
    final defaultDate = _selectedItem!.receiptDate ?? DateFormat('yyyy-MM-dd').format(DateTime.now());
    setState(() {
      _qtyCtrl.text = remainingBatchQty.toString();
      _prodDateCtrl.text = defaultDate;
      _expiryDateCtrl.clear();
      _currentView = PutAwayView.createBatch;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _qtyFocus.requestFocus();
    });
  }

  void _navigateToSelectBatch() {
    setState(() {
      _batchScanCtrl.clear();
      _currentView = PutAwayView.selectBatch;
    });
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _batchScanFocus.requestFocus();
    });
  }

  Future<void> _navigateToAllocateBin(GrnBatch batch) async {
    setState(() {
      _selectedBatch = batch;
      _qtyCtrl.text = batch.availableQty.toString();
      _lotCtrl.clear();
      _overrideCapacity = false;
      _suggestion = null;
      _loadingSuggestion = true;
      _currentView = PutAwayView.allocateBin;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _lotFocus.requestFocus();
    });

    try {
      final suggest = await ref.read(grnRepositoryProvider).suggestLot(
        _selectedItem!.name,
        qty: double.tryParse(_qtyCtrl.text) ?? _selectedItem!.pendingQty,
      );
      if (mounted && _selectedBatch?.batchNo == batch.batchNo) {
        setState(() {
          _suggestion = suggest;
          _loadingSuggestion = false;
        });
      }
    } catch (e) {
      AppLogger.warning('suggest_lot failed: $e', tag: 'GrnPutaway');
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

  void _handleBatchScan(String barcode) {
    final scanned = barcode.trim();
    if (scanned.isEmpty) return;

    final matched = _createdBatches.where((b) => b.batchNo.toLowerCase() == scanned.toLowerCase()).firstOrNull;
    if (matched != null) {
      _batchScanCtrl.clear();
      _navigateToAllocateBin(matched);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Batch $scanned not found in WH-A for this line.'), backgroundColor: AppTheme.danger),
      );
    }
  }

  Future<void> _submitCreateBatch() async {
    if (_selectedItem == null) return;

    final qty = double.tryParse(_qtyCtrl.text) ?? 0.0;
    final prodDate = _prodDateCtrl.text.trim();
    final expDate = _expiryDateCtrl.text.trim();

    final remainingBatchQty = _selectedItem!.pendingBatchQty ?? _selectedItem!.pendingQty;
    if (qty <= 0 || qty > remainingBatchQty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid quantity between 0 and $remainingBatchQty')),
      );
      return;
    }
    if (prodDate.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Production date is required.')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final res = await ref.read(grnRepositoryProvider).createBatch(
        receivedItemLine: _selectedItem!.name,
        qty: qty,
        productionDate: prodDate,
        expiryDate: expDate.isNotEmpty ? expDate : null,
      );

      final String batchNo = res['batch_no'] ?? '';

      // Call printLabel immediately (omit printer parameter to use default)
      try {
        await ref.read(grnRepositoryProvider).printLabel(
          referenceDoctype: 'Batch',
          referenceName: batchNo,
          printFormat: 'Batch Label',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Batch $batchNo created and sent to printer!'), backgroundColor: AppTheme.success),
        );
      } catch (printErr) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Batch $batchNo created, but printing failed: $printErr'), backgroundColor: AppTheme.warning),
        );
      }

      await _loadPending();

      final updatedItem = _pendingItems.firstWhere(
        (e) => e.name == _selectedItem!.name,
        orElse: () => _selectedItem!,
      );

      setState(() {
        _selectedItem = updatedItem;
        _currentView = PutAwayView.detail;
      });

      await _loadCreatedBatches(updatedItem.name);
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

  Future<void> _submitAllocateBin() async {
    if (_selectedItem == null || _selectedBatch == null) return;

    final lot = _lotCtrl.text.trim();
    final qty = double.tryParse(_qtyCtrl.text) ?? 0.0;

    if (lot.isEmpty || qty <= 0 || qty > _selectedBatch!.availableQty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please scan a valid Bin/LOT and enter quantity <= ${_selectedBatch!.availableQty}.')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      await ref.read(grnRepositoryProvider).allocateToBin(
        receivedItemLine: _selectedItem!.name,
        lot: lot,
        qty: qty,
        batchNo: _selectedBatch!.batchNo,
        forceCapacity: _overrideCapacity,
        suggestedLot: _suggestion?.lot,
      );

      // No toast — the pending list refreshing below (and the view
      // switching back to the list once the line is fully allocated) is
      // confirmation enough for this per-allocation action.
      await _loadPending();

      final updatedItem = _pendingItems.where((e) => e.name == _selectedItem!.name).firstOrNull;

      if (updatedItem == null || updatedItem.pendingQty <= 0) {
        // Line fully completed
        setState(() {
          _selectedItem = null;
          _selectedBatch = null;
          _currentView = PutAwayView.list;
        });
      } else {
        // Line still has pending allocation
        setState(() {
          _selectedItem = updatedItem;
          _selectedBatch = null;
          _currentView = PutAwayView.detail;
        });
        await _loadCreatedBatches(updatedItem.name);
      }
    } on ApiException catch (e) {
      if (e.code == 'BIN_FULL' && widget.screen.can('override_capacity')) {
        _promptOverrideCapacityAllocate();
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

  void _promptOverrideCapacityAllocate() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bin Full Override'),
        content: const Text(
          'The selected bin is marked as full. As a supervisor, would you like to force this allocation?',
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
              _submitAllocateBin();
            },
            child: const Text('Force Allocate'),
          ),
        ],
      ),
    );
  }

  Future<bool> _handleBackPress() async {
    if (_currentView == PutAwayView.list) {
      return true;
    } else if (_currentView == PutAwayView.detail) {
      setState(() {
        _selectedItem = null;
        _currentView = PutAwayView.list;
      });
      return false;
    } else if (_currentView == PutAwayView.createBatch) {
      setState(() {
        _currentView = PutAwayView.detail;
      });
      return false;
    } else if (_currentView == PutAwayView.selectBatch) {
      setState(() {
        _currentView = PutAwayView.detail;
      });
      return false;
    } else if (_currentView == PutAwayView.allocateBin) {
      setState(() {
        _currentView = PutAwayView.selectBatch;
        _selectedBatch = null;
      });
      return false;
    }
    return true;
  }

  String _getScreenTitle() {
    switch (_currentView) {
      case PutAwayView.list:
        return widget.screen.label;
      case PutAwayView.detail:
        return 'Put-Away Details';
      case PutAwayView.createBatch:
        return 'Create Batch';
      case PutAwayView.selectBatch:
        return 'Select Batch';
      case PutAwayView.allocateBin:
        return 'Allocate to Bin';
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _handleBackPress,
      child: PdtScaffold(
        title: _getScreenTitle(),
        actions: _currentView == PutAwayView.list
            ? [
                IconButton(
                  icon: Icon(_showFilterPanel ? Icons.filter_list_off : Icons.filter_list),
                  onPressed: () {
                    setState(() {
                      _showFilterPanel = !_showFilterPanel;
                    });
                  },
                ),
              ]
            : null,
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentView) {
      case PutAwayView.list:
        return _buildListBody();
      case PutAwayView.detail:
        return _buildDetailBody();
      case PutAwayView.createBatch:
        return _buildCreateBatchBody();
      case PutAwayView.selectBatch:
        return _buildSelectBatchBody();
      case PutAwayView.allocateBin:
        return _buildAllocateBinBody();
    }
  }

  void _clearFilters() {
    _receiptFilterCtrl.clear();
    _itemFilterCtrl.clear();
    setState(() {
      _appliedReceiptFilter = '';
      _appliedItemFilter = '';
    });
  }

  Widget _buildFilterPanel() {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.bgSurface,
        border: Border(bottom: BorderSide(color: AppTheme.bgBorder)),
      ),
      padding: const EdgeInsets.all(AppTheme.horizontalPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _receiptFilterCtrl,
                  focusNode: _receiptFilterFocus,
                  labelText: 'Receipt / GRN No.',
                  hintText: 'e.g. GRN-001',
                  prefixIcon: const Icon(Icons.receipt_long_outlined),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomTextField(
                  controller: _itemFilterCtrl,
                  focusNode: _itemFilterFocus,
                  labelText: 'Item Code / Name',
                  hintText: 'e.g. ITEM-A',
                  prefixIcon: const Icon(Icons.search),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _clearFilters,
                  child: const Text('Reset'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  text: 'Apply Filters',
                  onPressed: () {
                    setState(() {
                      _appliedReceiptFilter = _receiptFilterCtrl.text.trim();
                      _appliedItemFilter = _itemFilterCtrl.text.trim();
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFilteredState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.horizontalPad),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_outlined, size: 64, color: AppTheme.textDisabled),
            const SizedBox(height: 16),
            Text(
              'No items match search criteria',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.clear_all),
              label: const Text('Reset Filters'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 48),
              ),
            ),
          ],
        ),
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

    final filteredItems = _pendingItems.where((item) {
      final receiptQuery = _appliedReceiptFilter.toLowerCase();
      final itemQuery = _appliedItemFilter.toLowerCase();

      final matchesReceipt = receiptQuery.isEmpty ||
          item.parent.toLowerCase().contains(receiptQuery);
      final matchesItem = itemQuery.isEmpty ||
          item.itemCode.toLowerCase().contains(itemQuery) ||
          (item.itemName ?? '').toLowerCase().contains(itemQuery);

      return matchesReceipt && matchesItem;
    }).toList();

    return Column(
      children: [
        if (_showFilterPanel) _buildFilterPanel(),
        Expanded(
          child: filteredItems.isEmpty
              ? _buildEmptyFilteredState()
              : RefreshIndicator(
                  onRefresh: _loadPending,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.horizontalPad, vertical: 8),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, i) {
                      final item = filteredItems[i];
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
                                Text('GRN: ${item.parent}'),
                                const SizedBox(height: 2),
                                Text('Line: ${item.name}'),
                                const SizedBox(height: 2),
                                Text('Qty: ${item.pendingQty}'),
                                const SizedBox(height: 2),
                                Text('Warehouse: ${item.warehouse ?? 'Not specified'}'),
                              ],
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.textSecondary),
                            onTap: () => _selectItem(item),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildDetailBody() {
    final item = _selectedItem!;
    final uom = item.uom ?? 'Units';
    
    final recQty = item.receivedQty ?? item.pendingQty;
    final batCreated = item.batchQtyCreated ?? 0.0;
    final pendBatch = item.pendingBatchQty ?? item.pendingQty;
    final binAllocated = item.binAllocatedQuantity ?? 0.0;
    final pendAlloc = item.pendingQty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.horizontalPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Back button
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _selectedItem = null;
                  _currentView = PutAwayView.list;
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
                    '${item.itemCode} (${item.itemName ?? ''})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primary),
                  ),
                  if (item.upcCode != null && item.upcCode!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'UPC: ${item.upcCode}',
                      style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Breakdown statistics
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Put-Away Metrics', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const Divider(height: 24),
                  _buildMetricRow('Received Quantity:', '$recQty $uom'),
                  const SizedBox(height: 8),
                  _buildMetricRow('Batches Created (Step 1):', '$batCreated $uom'),
                  const SizedBox(height: 8),
                  _buildMetricRow('Pending Batch Split:', '$pendBatch $uom', highlight: pendBatch > 0),
                  const SizedBox(height: 8),
                  _buildMetricRow('Allocated to Bins (Step 2):', '$binAllocated $uom'),
                  const SizedBox(height: 8),
                  _buildMetricRow('Pending Bin Allocation:', '$pendAlloc $uom', highlight: pendAlloc > 0),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Create Batch',
                  onPressed: widget.screen.can('create_batch') && pendBatch > 0
                      ? _navigateToCreateBatch
                      : null,
                  icon: Icons.add_box_outlined,
                  outlined: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  text: 'Allocate to Bin',
                  onPressed: widget.screen.can('allocate_bin') && _createdBatches.any((b) => b.availableQty > 0)
                      ? _navigateToSelectBatch
                      : null,
                  icon: Icons.place_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Created Batches Header
          const Text(
            'PRODUCTION BATCHES IN WH-A',
            style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary, fontSize: 12, letterSpacing: 1.0),
          ),
          const SizedBox(height: 8),

          // Created Batches List
          if (_loadingBatches)
            const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
          else if (_batchesError != null)
            Center(child: Padding(padding: const EdgeInsets.all(16), child: Text(_batchesError!, style: const TextStyle(color: AppTheme.danger))))
          else if (_createdBatches.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('No batches created yet. Click "Create Batch" above to start.', textAlign: TextAlign.center, style: TextStyle(fontStyle: FontStyle.italic, color: AppTheme.textSecondary)),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _createdBatches.length,
              itemBuilder: (context, i) {
                final batch = _createdBatches[i];
                final available = batch.availableQty > 0;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: available ? Colors.white : AppTheme.bgElevated,
                  child: ListTile(
                    title: Text(
                      batch.batchNo,
                      style: TextStyle(fontWeight: FontWeight.bold, color: available ? AppTheme.textPrimary : AppTheme.textSecondary),
                    ),
                    subtitle: Text(
                      'Prod: ${batch.productionDate ?? 'N/A'} | Exp: ${batch.expiryDate ?? 'N/A'}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${batch.availableQty} $uom',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: available ? AppTheme.primary : AppTheme.textSecondary,
                          ),
                        ),
                        if (available) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.check_circle_outline, color: AppTheme.success, size: 18),
                        ],
                      ],
                    ),
                    onTap: available && widget.screen.can('allocate_bin')
                        ? () => _navigateToAllocateBin(batch)
                        : null,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: AppTheme.textSecondary, fontWeight: highlight ? FontWeight.w600 : FontWeight.normal)),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: highlight ? AppTheme.primary : AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildCreateBatchBody() {
    final item = _selectedItem!;
    final remainingBatchQty = item.pendingBatchQty ?? item.pendingQty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.horizontalPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Back button
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                setState(() => _currentView = PutAwayView.detail);
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to details'),
            ),
          ),
          const SizedBox(height: 8),

          // Detail Card
          Card(
            color: AppTheme.bgElevated,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${item.itemCode} (${item.itemName ?? ''})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text('Staging Batch: ${item.batchNo ?? 'N/A'}'),
                  Text('Remaining to split: $remainingBatchQty ${item.uom ?? 'Units'}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Form fields
          CustomTextField(
            controller: _qtyCtrl,
            focusNode: _qtyFocus,
            labelText: 'Batch Quantity',
            hintText: 'Enter quantity to split',
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
            hintText: 'Select production date',
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
            hintText: 'Select expiry date (optional)',
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
            text: 'CREATE & PRINT',
            isLoading: _submitting,
            icon: Icons.print_outlined,
            onPressed: _submitCreateBatch,
          ),
        ],
      ),
    );
  }

  Widget _buildSelectBatchBody() {
    final item = _selectedItem!;
    final uom = item.uom ?? 'Units';

    final availableBatches = _createdBatches.where((b) => b.availableQty > 0).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.horizontalPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Back button
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                setState(() => _currentView = PutAwayView.detail);
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to details'),
            ),
          ),
          const SizedBox(height: 8),

          // Scan Batch Input
          ScanInputField(
            controller: _batchScanCtrl,
            focusNode: _batchScanFocus,
            labelText: 'Scan Batch Label',
            hintText: 'Scan printed batch barcode',
            prefixIcon: Icons.qr_code_scanner,
            onChanged: _handleBatchScan,
            onScanned: _handleBatchScan,
          ),
          const SizedBox(height: 24),

          const Text(
            'SELECT A BATCH FOR BIN ALLOCATION',
            style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary, fontSize: 12, letterSpacing: 1.0),
          ),
          const SizedBox(height: 8),

          if (availableBatches.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('No batches available in WH-A.', textAlign: TextAlign.center, style: TextStyle(fontStyle: FontStyle.italic, color: AppTheme.textSecondary)),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: availableBatches.length,
              itemBuilder: (context, i) {
                final batch = availableBatches[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(batch.batchNo, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Prod: ${batch.productionDate ?? 'N/A'} | Exp: ${batch.expiryDate ?? 'N/A'}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${batch.availableQty} $uom', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_ios, size: 14),
                      ],
                    ),
                    onTap: () => _navigateToAllocateBin(batch),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAllocateBinBody() {
    final item = _selectedItem!;
    final batch = _selectedBatch!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.horizontalPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Back button
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _selectedBatch = null;
                  _currentView = PutAwayView.selectBatch;
                });
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to batch list'),
            ),
          ),
          const SizedBox(height: 8),

          // Detail Card
          Card(
            color: AppTheme.bgElevated,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${item.itemCode} (${item.itemName ?? ''})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primary)),
                  const SizedBox(height: 4),
                  Text('Batch: ${batch.batchNo}'),
                  Text('Available in WH-A: ${batch.availableQty} ${item.uom ?? 'Units'}'),
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
                    if (_suggestion!.reason != null)
                      Text(_suggestion!.reason!, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    Text('Free capacity: ${_suggestion!.availableQty} KG'),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.warning,
                        side: const BorderSide(color: AppTheme.warning),
                        minimumSize: const Size(140, 36),
                      ),
                      onPressed: () {
                        setState(() {
                          _lotCtrl.text = _suggestion!.lot;
                        });
                        _qtyFocus.requestFocus();
                      },
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Use Suggested Bin'),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),

          // Inputs
          ScanInputField(
            controller: _lotCtrl,
            focusNode: _lotFocus,
            labelText: 'Scan Bin / LOT',
            hintText: 'Scan target bin barcode',
            prefixIcon: Icons.place_outlined,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _qtyFocus.requestFocus(),
          ),
          const SizedBox(height: 14),

          CustomTextField(
            controller: _qtyCtrl,
            focusNode: _qtyFocus,
            labelText: 'Allocation Qty',
            hintText: 'Enter quantity to allocate',
            prefixIcon: const Icon(Icons.calculate_outlined),
            keyboardType: TextInputType.number,
            onSubmitted: (_) => _submitAllocateBin(),
          ),
          const SizedBox(height: 24),

          CustomButton(
            text: 'ALLOCATE',
            isLoading: _submitting,
            icon: Icons.check_circle_outline,
            onPressed: _submitAllocateBin,
          ),
        ],
      ),
    );
  }
}
