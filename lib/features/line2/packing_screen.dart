import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/menu/menu_models.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/pdt_scaffold.dart';
import '../../widgets/scan_input_field.dart';
import 'line2_repository.dart';

class PackingScreen extends ConsumerStatefulWidget {
  final MenuScreen screen;
  const PackingScreen({required this.screen, super.key});

  @override
  ConsumerState<PackingScreen> createState() => _PackingScreenState();
}

class _PackingScreenState extends ConsumerState<PackingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  // ── Box tab state ──
  final _boxSoCtrl = TextEditingController();
  final _boxScanCtrl = TextEditingController();
  final _boxScanFocus = FocusNode();
  final _boxQtyCtrl = TextEditingController(text: '1');
  final _boxNetWeightCtrl = TextEditingController();
  final _boxGrossWeightCtrl = TextEditingController();
  bool _creatingBox = false;
  bool _sealingBox = false;
  String? _activeBoxId;
  String? _activeBoxSo;
  List<Map<String, dynamic>> _boxItems = [];
  List<Map<String, dynamic>> _boxPickList = [];

  // ── Pallet tab state ──
  final _palletSoCtrl = TextEditingController();
  final _palletScanCtrl = TextEditingController();
  final _palletScanFocus = FocusNode();
  final _palletQtyCtrl = TextEditingController(text: '1');
  final _palletNetWeightCtrl = TextEditingController();
  final _palletGrossWeightCtrl = TextEditingController();
  String _palletType = 'Belt';
  bool _creatingPallet = false;
  bool _sealingPallet = false;
  String? _activePalletId;
  String? _activePalletSo;
  String? _activePalletType;
  List<Map<String, dynamic>> _palletContents = [];
  List<Map<String, dynamic>> _palletPickList = [];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _boxSoCtrl.dispose();
    _boxScanCtrl.dispose();
    _boxScanFocus.dispose();
    _boxQtyCtrl.dispose();
    _boxNetWeightCtrl.dispose();
    _boxGrossWeightCtrl.dispose();
    _palletSoCtrl.dispose();
    _palletScanCtrl.dispose();
    _palletScanFocus.dispose();
    _palletQtyCtrl.dispose();
    _palletNetWeightCtrl.dispose();
    _palletGrossWeightCtrl.dispose();
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

  double? _parseWeight(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    return double.tryParse(trimmed);
  }

  // ── Box actions ──

  Future<void> _createBox() async {
    final so = _boxSoCtrl.text.trim();
    if (so.isEmpty) {
      _showError('Enter a Sales Order');
      return;
    }

    setState(() => _creatingBox = true);
    try {
      final data = await ref.read(line2RepositoryProvider).createBox(salesOrder: so);
      setState(() {
        _activeBoxId = data['box_barcode']?.toString();
        _activeBoxSo = so;
        _boxItems = [];
        _creatingBox = false;
      });
      await _refreshBoxPickList();
      // No toast — the active Box ID now showing on screen is confirmation
      // enough for this per-box action.
    } catch (e) {
      setState(() => _creatingBox = false);
      _showError('Error: $e');
    }
  }

  Future<void> _refreshBoxPickList() async {
    if (_activeBoxSo == null) return;
    try {
      final items = await ref.read(line2RepositoryProvider).getDispatchPickList(_activeBoxSo!);
      if (mounted) setState(() => _boxPickList = items);
    } catch (_) {
      // Non-critical — the pick list is a convenience view, not a gate.
    }
  }

  Future<void> _onBoxItemScanned(String barcode) async {
    final trimmed = barcode.trim();
    if (trimmed.isEmpty || _activeBoxId == null) return;
    final qty = double.tryParse(_boxQtyCtrl.text.trim());
    if (qty == null || qty <= 0) {
      _showError('Enter a quantity greater than 0');
      return;
    }

    try {
      final data = await ref.read(line2RepositoryProvider).addToBox(
            boxBarcode: _activeBoxId!,
            itemBarcode: trimmed,
            qty: qty,
          );
      setState(() => _boxItems.add(data));
      _boxScanCtrl.clear();
    } catch (e) {
      _showError('Scan error: $e');
    }
  }

  Future<void> _sealBox() async {
    if (_activeBoxId == null) return;
    setState(() => _sealingBox = true);
    try {
      await ref.read(line2RepositoryProvider).sealBox(
            _activeBoxId!,
            netWeight: _parseWeight(_boxNetWeightCtrl.text),
            grossWeight: _parseWeight(_boxGrossWeightCtrl.text),
          );
      _showSuccess('Box $_activeBoxId sealed');
      setState(() {
        _activeBoxId = null;
        _activeBoxSo = null;
        _boxItems = [];
        _boxPickList = [];
        _boxSoCtrl.clear();
        _boxNetWeightCtrl.clear();
        _boxGrossWeightCtrl.clear();
      });
    } catch (e) {
      _showError('Error: $e');
    } finally {
      if (mounted) setState(() => _sealingBox = false);
    }
  }

  Future<void> _printBoxLabel() async {
    if (_activeBoxId == null) return;
    try {
      await ref
          .read(line2RepositoryProvider)
          .printLabel(barcode: _activeBoxId!, labelType: 'Box');
      _showSuccess('Box label sent to printer');
    } catch (e) {
      _showError('Print error: $e');
    }
  }

  // ── Pallet actions ──

  Future<void> _createPallet() async {
    final so = _palletSoCtrl.text.trim();
    if (so.isEmpty) {
      _showError('Enter a Sales Order');
      return;
    }

    setState(() => _creatingPallet = true);
    try {
      final data = await ref.read(line2RepositoryProvider).createPallet(
            salesOrder: so,
            palletType: _palletType,
          );
      setState(() {
        _activePalletId = data['pallet_barcode']?.toString();
        _activePalletSo = so;
        _activePalletType = data['pallet_type']?.toString() ?? _palletType;
        _palletContents = [];
        _creatingPallet = false;
      });
      await _refreshPalletPickList();
      // No toast — the active Pallet ID now showing on screen is
      // confirmation enough for this per-pallet action.
    } catch (e) {
      setState(() => _creatingPallet = false);
      _showError('Error: $e');
    }
  }

  Future<void> _refreshPalletPickList() async {
    if (_activePalletSo == null) return;
    try {
      final items = await ref.read(line2RepositoryProvider).getDispatchPickList(_activePalletSo!);
      if (mounted) setState(() => _palletPickList = items);
    } catch (_) {
      // Non-critical — the pick list is a convenience view, not a gate.
    }
  }

  Future<void> _onPalletBoxScanned(String barcode) async {
    final trimmed = barcode.trim();
    if (trimmed.isEmpty || _activePalletId == null) return;

    try {
      final data = await ref.read(line2RepositoryProvider).addBoxToPallet(
            palletBarcode: _activePalletId!,
            boxBarcode: trimmed,
          );
      setState(() => _palletContents.add(data));
      _palletScanCtrl.clear();
    } catch (e) {
      _showError('Scan error: $e');
    }
  }

  Future<void> _onPalletItemScanned(String barcode) async {
    final trimmed = barcode.trim();
    if (trimmed.isEmpty || _activePalletId == null) return;
    final qty = double.tryParse(_palletQtyCtrl.text.trim());
    if (qty == null || qty <= 0) {
      _showError('Enter a quantity greater than 0');
      return;
    }

    try {
      final data = await ref.read(line2RepositoryProvider).addItemToPallet(
            palletBarcode: _activePalletId!,
            itemBarcode: trimmed,
            qty: qty,
          );
      setState(() => _palletContents.add(data));
      _palletScanCtrl.clear();
    } catch (e) {
      _showError('Scan error: $e');
    }
  }

  Future<void> _sealPallet() async {
    if (_activePalletId == null) return;
    setState(() => _sealingPallet = true);
    try {
      await ref.read(line2RepositoryProvider).sealPallet(
            _activePalletId!,
            netWeight: _parseWeight(_palletNetWeightCtrl.text),
            grossWeight: _parseWeight(_palletGrossWeightCtrl.text),
          );
      _showSuccess('Pallet $_activePalletId sealed');
      setState(() {
        _activePalletId = null;
        _activePalletSo = null;
        _activePalletType = null;
        _palletContents = [];
        _palletPickList = [];
        _palletSoCtrl.clear();
        _palletNetWeightCtrl.clear();
        _palletGrossWeightCtrl.clear();
      });
    } catch (e) {
      _showError('Error: $e');
    } finally {
      if (mounted) setState(() => _sealingPallet = false);
    }
  }

  Future<void> _printPalletLabel() async {
    if (_activePalletId == null) return;
    try {
      await ref
          .read(line2RepositoryProvider)
          .printLabel(barcode: _activePalletId!, labelType: 'Pallet');
      _showSuccess('Pallet label sent to printer');
    } catch (e) {
      _showError('Print error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PdtScaffold(
      title: widget.screen.label,
      body: Column(
        children: [
          TabBar(
            controller: _tabCtrl,
            labelColor: AppTheme.primary,
            tabs: const [
              Tab(text: 'Boxes'),
              Tab(text: 'Pallets'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildBoxTab(),
                _buildPalletTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickListPanel(List<Map<String, dynamic>> items, VoidCallback onRefresh) {
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.checklist_outlined),
        title: Text('Ready to Pack (${items.length})',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: const Text('Received at warehouse, not yet packed',
            style: TextStyle(fontSize: 11)),
        children: [
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('Nothing outstanding for this Sales Order',
                  style: TextStyle(color: Colors.grey)),
            )
          else
            ...items.map((it) => ListTile(
                  dense: true,
                  title: Text(it['item_name']?.toString() ?? it['item_code']?.toString() ?? ''),
                  trailing: Text('${it['remaining_to_pack_qty']}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                )),
          TextButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildBoxTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_activeBoxId == null) ...[
          TextField(
            controller: _boxSoCtrl,
            decoration: const InputDecoration(
              labelText: 'Sales Order',
              hintText: 'Enter SO number',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          CustomButton(
            text: _creatingBox ? 'Creating...' : 'Create Box',
            icon: Icons.add_box,
            isLoading: _creatingBox,
            backgroundColor: AppTheme.primary,
            textColor: Colors.white,
            onPressed: _creatingBox ? null : _createBox,
          ),
        ] else ...[
          Card(
            color: AppTheme.primaryLight.withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.inventory_2, color: AppTheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Box: $_activeBoxId',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('SO: $_activeBoxSo · ${_boxItems.length} items scanned'),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.print, color: AppTheme.primary),
                    onPressed: _printBoxLabel,
                    tooltip: 'Print Label',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildPickListPanel(_boxPickList, _refreshBoxPickList),
          const SizedBox(height: 12),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: ScanInputField(
                  controller: _boxScanCtrl,
                  focusNode: _boxScanFocus,
                  labelText: 'Scan Batch into Box',
                  hintText: 'Scan batch barcode',
                  onScanned: _onBoxItemScanned,
                  onSubmitted: _onBoxItemScanned,
                  autofocus: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _boxQtyCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Qty',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_boxItems.isNotEmpty) ...[
            Text('Items (${_boxItems.length})', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            ..._boxItems.map((item) => Card(
                  child: ListTile(
                    dense: true,
                    title: Text(
                        item['item_name']?.toString() ?? item['item_code']?.toString() ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                    trailing: Text('Qty: ${item['qty'] ?? 1}',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                )),
            const SizedBox(height: 12),
          ],

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _boxNetWeightCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Net Weight (Kg)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _boxGrossWeightCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Gross Weight (Kg)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          CustomButton(
            text: _sealingBox ? 'Sealing...' : 'Seal Box',
            icon: Icons.lock,
            isLoading: _sealingBox,
            backgroundColor: AppTheme.success,
            textColor: Colors.white,
            onPressed: _sealingBox || _boxItems.isEmpty ? null : _sealBox,
          ),
        ],
      ],
    );
  }

  Widget _buildPalletTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_activePalletId == null) ...[
          TextField(
            controller: _palletSoCtrl,
            decoration: const InputDecoration(
              labelText: 'Sales Order',
              hintText: 'Enter SO number',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'Belt', label: Text('Belt (boxes)'), icon: Icon(Icons.inventory_2)),
              ButtonSegment(value: 'Sleeve', label: Text('Sleeve (direct)'), icon: Icon(Icons.layers)),
            ],
            selected: {_palletType},
            onSelectionChanged: (s) => setState(() => _palletType = s.first),
          ),
          const SizedBox(height: 12),
          CustomButton(
            text: _creatingPallet ? 'Creating...' : 'Create Pallet',
            icon: Icons.pallet,
            isLoading: _creatingPallet,
            backgroundColor: AppTheme.primary,
            textColor: Colors.white,
            onPressed: _creatingPallet ? null : _createPallet,
          ),
        ] else ...[
          Card(
            color: AppTheme.primaryLight.withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.pallet, color: AppTheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Pallet: $_activePalletId (${_activePalletType})',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('SO: $_activePalletSo · ${_palletContents.length} loaded'),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.print, color: AppTheme.primary),
                    onPressed: _printPalletLabel,
                    tooltip: 'Print Label',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildPickListPanel(_palletPickList, _refreshPalletPickList),
          const SizedBox(height: 12),

          if (_activePalletType == 'Sleeve') ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: ScanInputField(
                    controller: _palletScanCtrl,
                    focusNode: _palletScanFocus,
                    labelText: 'Scan Sleeve Batch onto Pallet',
                    hintText: 'Scan batch barcode',
                    onScanned: _onPalletItemScanned,
                    onSubmitted: _onPalletItemScanned,
                    autofocus: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _palletQtyCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Qty',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ] else
            ScanInputField(
              controller: _palletScanCtrl,
              focusNode: _palletScanFocus,
              labelText: 'Scan Box onto Pallet',
              hintText: 'Scan box barcode',
              onScanned: _onPalletBoxScanned,
              onSubmitted: _onPalletBoxScanned,
              autofocus: true,
            ),
          const SizedBox(height: 12),

          if (_palletContents.isNotEmpty) ...[
            Text('Loaded (${_palletContents.length})', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            ..._palletContents.map((row) => Card(
                  child: ListTile(
                    dense: true,
                    title: Text(
                        row['box_barcode']?.toString() ??
                            row['item_name']?.toString() ??
                            row['item_code']?.toString() ??
                            '',
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                    trailing: Text(
                        row.containsKey('qty') ? 'Qty: ${row['qty']}' : 'Boxes: ${row['total_boxes'] ?? 0}',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                )),
            const SizedBox(height: 12),
          ],

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _palletNetWeightCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Net Weight (Kg)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _palletGrossWeightCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Gross Weight (Kg)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          CustomButton(
            text: _sealingPallet ? 'Sealing...' : 'Seal Pallet',
            icon: Icons.lock,
            isLoading: _sealingPallet,
            backgroundColor: AppTheme.success,
            textColor: Colors.white,
            onPressed: _sealingPallet || _palletContents.isEmpty ? null : _sealPallet,
          ),
        ],
      ],
    );
  }
}
