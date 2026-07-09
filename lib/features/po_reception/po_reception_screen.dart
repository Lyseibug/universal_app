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
import 'po_reception_models.dart';
import 'po_reception_repository.dart';

enum _View { list, detail }

class PoReceptionScreen extends ConsumerStatefulWidget {
  final MenuScreen screen;

  const PoReceptionScreen({required this.screen, super.key});

  @override
  ConsumerState<PoReceptionScreen> createState() => _PoReceptionScreenState();
}

class _PoReceptionScreenState extends ConsumerState<PoReceptionScreen> {
  // ── List state ──
  bool _loadingList = true;
  List<PurchaseOrderSummary> _poList = [];
  String? _listError;

  // ── Search / scan ──
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  bool _showSearch = false;
  bool _searching = false;

  // ── Detail state ──
  _View _currentView = _View.list;
  PurchaseOrderDetail? _poDetail;
  bool _loadingDetail = false;
  String? _detailError;

  // Editable receive quantities keyed by PO Item row name
  final Map<String, TextEditingController> _qtyControllers = {};
  // Selected reception UOM per PO Item row name (defaults to the PO line's UOM)
  final Map<String, String> _selectedUom = {};
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadPending();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _disposeQtyControllers();
    super.dispose();
  }

  void _disposeQtyControllers() {
    for (final c in _qtyControllers.values) {
      c.dispose();
    }
    _qtyControllers.clear();
    _selectedUom.clear();
  }

  // ── Data loading ──

  Future<void> _loadPending() async {
    setState(() {
      _loadingList = true;
      _listError = null;
    });
    try {
      final list = await ref.read(poReceptionRepositoryProvider).listPending();
      if (mounted) {
        setState(() {
          _poList = list;
          _loadingList = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _listError = 'Failed to load pending Purchase Orders.';
          _loadingList = false;
        });
      }
    }
  }

  Future<void> _handleSearch(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      _loadPending();
      return;
    }
    setState(() {
      _searching = true;
      _listError = null;
    });
    try {
      final results = await ref.read(poReceptionRepositoryProvider).search(q);
      if (mounted) {
        setState(() {
          _poList = results;
          _searching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _listError = 'Search failed.';
          _searching = false;
        });
      }
    }
  }

  Future<void> _selectPO(String poName) async {
    setState(() {
      _loadingDetail = true;
      _detailError = null;
      _currentView = _View.detail;
    });
    try {
      final detail = await ref.read(poReceptionRepositoryProvider).get(poName);
      _disposeQtyControllers();
      for (final item in detail.items) {
        _qtyControllers[item.name] =
            TextEditingController(text: item.pendingQty.toString());
        _selectedUom[item.name] = item.uom ?? '';
      }
      if (mounted) {
        setState(() {
          _poDetail = detail;
          _loadingDetail = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _detailError = 'Failed to load Purchase Order details.';
          _loadingDetail = false;
        });
      }
    }
  }

  // ── UOM helpers ──

  /// Conversion factor of `uom` relative to the item's stock UOM, from the
  /// `available_uoms` list the backend returns (defaults to 1 if not found).
  double _conversionFactorFor(PurchaseOrderItemLine item, String? uom) {
    for (final entry in item.availableUoms) {
      final map = entry as Map<String, dynamic>;
      if (map['uom'] == uom) {
        return (map['conversion_factor'] as num?)?.toDouble() ?? 1;
      }
    }
    return 1;
  }

  /// Converts a quantity from `fromUom` to `toUom` via the item's stock UOM.
  double _convertQty(PurchaseOrderItemLine item, double qty, String? fromUom,
      String? toUom) {
    if (fromUom == toUom) return qty;
    final toFactor = _conversionFactorFor(item, toUom);
    if (toFactor <= 0) return qty;
    return qty * _conversionFactorFor(item, fromUom) / toFactor;
  }

  /// Converts a quantity entered in `uom` back into the PO line's own
  /// ordered UOM, so it can be compared against ordered/received/pending qty.
  double _convertToPoUom(PurchaseOrderItemLine item, double qty, String? uom) {
    return _convertQty(item, qty, uom, item.uom);
  }

  // ── Submit reception ──

  Future<void> _submitReception() async {
    if (_poDetail == null) return;

    final items = <Map<String, dynamic>>[];
    final warnings = <String>[];
    for (final item in _poDetail!.items) {
      final ctrl = _qtyControllers[item.name];
      final qty = double.tryParse(ctrl?.text ?? '') ?? 0;
      if (qty <= 0) continue;
      final chosenUom = _selectedUom[item.name] ?? item.uom;
      // Warn but don't block if qty (converted to the PO's ordered UOM) exceeds pending
      final qtyInPoUom = _convertToPoUom(item, qty, chosenUom);
      if (qtyInPoUom - item.pendingQty > 0.0001) {
        warnings.add(
            '${item.itemName ?? item.itemCode}: qty $qty $chosenUom exceeds pending ${item.pendingQty} ${item.uom}');
      }
      items.add({
        'item_code': item.itemCode,
        'qty': qty,
        'rate': item.rate,
        'uom': chosenUom,
        'warehouse': item.warehouse,
        'po_detail': item.name,
      });
    }

    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter quantity for at least one item.')),
      );
      return;
    }

    // Show warning if any items exceed pending qty
    if (warnings.isNotEmpty) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppTheme.warning),
              SizedBox(width: 8),
              Text('Quantity Warning'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('The following items exceed pending quantity:'),
              const SizedBox(height: 8),
              ...warnings.map((w) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('• $w',
                        style: const TextStyle(color: AppTheme.danger)),
                  )),
              const SizedBox(height: 12),
              const Text('Do you want to proceed anyway?'),
            ],
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.warning,
                minimumSize: const Size(120, 44),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Proceed'),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }

    final confirmed = await _showConfirmDialog(items);
    if (confirmed != true) return;

    setState(() => _submitting = true);
    try {
      final result =
          await ref.read(poReceptionRepositoryProvider).submitReception(
                purchaseOrder: _poDetail!.name,
                currency: _poDetail!.currency,
                items: items,
              );
      final prName = result['purchase_receipt'] ?? '';

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Receipt $prName created successfully!'),
            backgroundColor: AppTheme.success,
          ),
        );
        _disposeQtyControllers();
        setState(() {
          _poDetail = null;
          _currentView = _View.list;
        });
        _loadPending();
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(messageFor(e)), backgroundColor: AppTheme.danger),
        );
      }
    } on NoInternetException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('No internet connection. Please check your network and try again.'),
              backgroundColor: AppTheme.danger),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Something went wrong. Please try again.'),
              backgroundColor: AppTheme.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<bool?> _showConfirmDialog(List<Map<String, dynamic>> items) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Reception'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('PO: ${_poDetail!.name}'),
            Text('Supplier: ${_poDetail!.supplierName ?? _poDetail!.supplier ?? ''}'),
            const SizedBox(height: 12),
            Text('${items.length} item(s) to receive:',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...items.map((i) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('  ${i['item_code']}  -  ${i['qty']}'),
                )),
          ],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              minimumSize: const Size(120, 44),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  // ── Navigation ──

  Future<bool> _handleBackPress() async {
    if (_currentView == _View.detail) {
      _disposeQtyControllers();
      setState(() {
        _poDetail = null;
        _currentView = _View.list;
      });
      return false;
    }
    return true;
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _handleBackPress,
      child: PdtScaffold(
        title: _currentView == _View.list
            ? widget.screen.label
            : 'Receive - ${_poDetail?.name ?? ''}',
        actions: _currentView == _View.list
            ? [
                IconButton(
                  icon: Icon(
                      _showSearch ? Icons.search_off : Icons.search),
                  onPressed: () {
                    setState(() {
                      _showSearch = !_showSearch;
                      if (!_showSearch) {
                        _searchCtrl.clear();
                        _loadPending();
                      }
                    });
                  },
                ),
              ]
            : null,
        body: _currentView == _View.list ? _buildListBody() : _buildDetailBody(),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  LIST VIEW
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildListBody() {
    return Column(
      children: [
        if (_showSearch) _buildSearchBar(),
        Expanded(child: _buildListContent()),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.bgSurface,
        border: Border(bottom: BorderSide(color: AppTheme.bgBorder)),
      ),
      padding: const EdgeInsets.all(AppTheme.horizontalPad),
      child: ScanInputField(
        controller: _searchCtrl,
        focusNode: _searchFocus,
        labelText: 'Search / Scan PO',
        hintText: 'PO number or supplier name',
        prefixIcon: Icons.search,
        autofocus: true,
        onScanned: _handleSearch,
        onSubmitted: _handleSearch,
      ),
    );
  }

  Widget _buildListContent() {
    if (_loadingList || _searching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_listError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.horizontalPad),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_listError!,
                  style: const TextStyle(color: AppTheme.danger)),
              const SizedBox(height: 16),
              ElevatedButton(
                  onPressed: _loadPending, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (_poList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.horizontalPad),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.inbox_outlined,
                  size: 64, color: AppTheme.textDisabled),
              const SizedBox(height: 16),
              Text(
                'No pending Purchase Orders',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPending,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.horizontalPad, vertical: 8),
        itemCount: _poList.length,
        itemBuilder: (context, i) {
          final po = _poList[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              child: ListTile(
                title: Text(
                  po.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(po.supplierName ?? po.supplier ?? ''),
                    const SizedBox(height: 2),
                    Text('Date: ${po.transactionDate ?? '-'}'),
                    const SizedBox(height: 2),
                    Text(
                        '${po.itemCount} item(s)  |  ${po.currency ?? ''} ${po.grandTotal.toStringAsFixed(2)}'),
                  ],
                ),
                trailing: const Icon(Icons.arrow_forward_ios,
                    size: 16, color: AppTheme.textSecondary),
                onTap: () => _selectPO(po.name),
              ),
            ),
          );
        },
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  DETAIL VIEW — items with editable quantities
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildDetailBody() {
    if (_loadingDetail) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_detailError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.horizontalPad),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_detailError!,
                  style: const TextStyle(color: AppTheme.danger)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _selectPO(_poDetail?.name ?? ''),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final detail = _poDetail!;
    final items = detail.items;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.horizontalPad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Back button
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () {
                      _disposeQtyControllers();
                      setState(() {
                        _poDetail = null;
                        _currentView = _View.list;
                      });
                    },
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back to list'),
                  ),
                ),
                const SizedBox(height: 8),

                // PO Header Card
                Card(
                  color: AppTheme.bgElevated,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          detail.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: AppTheme.primary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                            'Supplier: ${detail.supplierName ?? detail.supplier ?? ''}'),
                        Text('Date: ${detail.transactionDate ?? '-'}'),
                        Text(
                            'Total: ${detail.currency ?? ''} ${detail.grandTotal.toStringAsFixed(2)}'),
                        Text(
                            'Receiving to: ${detail.inboundWarehouse ?? '-'}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Section header
                const Text(
                  'ITEMS TO RECEIVE',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      letterSpacing: 1.0),
                ),
                const SizedBox(height: 8),

                if (items.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'All items have been fully received.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: AppTheme.textSecondary),
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    itemBuilder: (context, i) =>
                        _buildItemCard(items[i]),
                  ),
              ],
            ),
          ),
        ),

        // Bottom submit bar
        if (items.isNotEmpty)
          Container(
            decoration: const BoxDecoration(
              color: AppTheme.bgSurface,
              border: Border(top: BorderSide(color: AppTheme.bgBorder)),
            ),
            padding: const EdgeInsets.all(AppTheme.horizontalPad),
            child: SafeArea(
              top: false,
              child: CustomButton(
                text: 'SUBMIT RECEPTION',
                isLoading: _submitting,
                icon: Icons.check_circle_outline,
                onPressed: widget.screen.can('submit_reception')
                    ? _submitReception
                    : null,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildItemCard(PurchaseOrderItemLine item) {
    final ctrl = _qtyControllers[item.name]!;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item header
            Text(
              item.itemCode,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppTheme.primary),
            ),
            if (item.itemName != null && item.itemName!.isNotEmpty)
              Text(item.itemName!,
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.textSecondary)),
            if (item.upcCode != null && item.upcCode!.isNotEmpty)
              Text('UPC: ${item.upcCode}',
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary)),
            const SizedBox(height: 10),

            // Quantity info row
            Row(
              children: [
                _buildQtyChip('Ordered', item.orderedQty, item.uom ?? ''),
                const SizedBox(width: 8),
                _buildQtyChip('Received', item.receivedQty, item.uom ?? ''),
                const SizedBox(width: 8),
                _buildQtyChip('Pending', item.pendingQty, item.uom ?? '',
                    highlight: true),
              ],
            ),
            const SizedBox(height: 12),

            // Editable quantity input
            Row(
              children: [
                const Text('Receive Qty:',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 12),
                SizedBox(
                  width: 120,
                  child: CustomTextField(
                    controller: ctrl,
                    labelText: '',
                    hintText: '0',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                _buildUomSelector(item, ctrl),
                const Spacer(),
                // Quick-fill to max
                TextButton(
                  onPressed: () {
                    final selected = _selectedUom[item.name] ?? item.uom;
                    final maxQty =
                        _convertQty(item, item.pendingQty, item.uom, selected);
                    ctrl.text = maxQty.toStringAsFixed(3);
                  },
                  child: const Text('Max'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// UOM display/selector for the receive-qty row. Shows a dropdown when the
  /// item has more than one configured UOM; otherwise a plain label.
  Widget _buildUomSelector(PurchaseOrderItemLine item, TextEditingController ctrl) {
    final uoms = item.availableUoms
        .map((e) => (e as Map<String, dynamic>)['uom'] as String?)
        .whereType<String>()
        .toSet()
        .toList();
    if (uoms.length <= 1) {
      return Text(item.uom ?? '',
          style: const TextStyle(color: AppTheme.textSecondary));
    }

    final selected = _selectedUom[item.name] ?? item.uom;
    return DropdownButton<String>(
      value: uoms.contains(selected) ? selected : item.uom,
      isDense: true,
      underline: const SizedBox.shrink(),
      items: uoms
          .map((u) => DropdownMenuItem(value: u, child: Text(u)))
          .toList(),
      onChanged: (newUom) {
        if (newUom == null) return;
        final oldUom = _selectedUom[item.name] ?? item.uom;
        final currentQty = double.tryParse(ctrl.text) ?? 0;
        setState(() {
          _selectedUom[item.name] = newUom;
          if (currentQty > 0) {
            final converted = _convertQty(item, currentQty, oldUom, newUom);
            ctrl.text = converted.toStringAsFixed(3);
          }
        });
      },
    );
  }

  Widget _buildQtyChip(String label, double qty, String uom,
      {bool highlight = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: highlight
              ? AppTheme.primary.withValues(alpha: 0.08)
              : AppTheme.bgElevated,
          borderRadius: BorderRadius.circular(6),
          border: highlight
              ? Border.all(color: AppTheme.primary.withValues(alpha: 0.3))
              : null,
        ),
        child: Column(
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 10, color: AppTheme.textSecondary)),
            const SizedBox(height: 2),
            Text(
              '$qty',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: highlight ? AppTheme.primary : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
