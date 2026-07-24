import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/menu/menu_models.dart';
import '../../core/models/line1_models.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/pdt_scaffold.dart';
import '../../widgets/scan_input_field.dart';
import 'line1_repository.dart';

/// Mixer Loading — track what physically goes into the mixer machine.
///
/// Worker scans a staged batch (chemical bag / CMB / chilled polymer) and
/// loads it: stock moves staging → Mixer WIP. Machine consumption data later
/// reduces Mixer WIP. Lab-tracked batches must be Pass / Conditional Pass.
class MixerLoadingScreen extends ConsumerStatefulWidget {
  final MenuScreen screen;
  const MixerLoadingScreen({required this.screen, super.key});

  @override
  ConsumerState<MixerLoadingScreen> createState() => _MixerLoadingScreenState();
}

class _MixerLoadingScreenState extends ConsumerState<MixerLoadingScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _stageable = [];
  List<Map<String, dynamic>> _wip = [];

  // Operator must pick a Work Order before anything can be scanned — every
  // scan afterwards is validated server-side against its BOM.
  List<WorkOrderSummary> _workOrders = [];
  WorkOrderSummary? _selectedWorkOrder;

  // Scan → resolve → load flow
  Map<String, dynamic>? _resolvedEntry;
  bool _resolving = false;
  bool _submitting = false;
  String? _qtyError;
  final _scanCtrl = TextEditingController();
  final _scanFocus = FocusNode();
  final _qtyCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _scanCtrl.dispose();
    _scanFocus.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final repo = ref.read(line1RepositoryProvider);
      final stageable = await repo.listMixerStageable();
      final wip = await repo.listMixerWip();
      final workOrders = await repo.listMixerWorkOrders();
      setState(() {
        _stageable = stageable;
        _wip = wip;
        _workOrders = workOrders;
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = 'Failed to load mixer stock'; _loading = false; });
    }
  }

  void _onScanned(String barcode) {
    final trimmed = barcode.trim();
    if (trimmed.isEmpty) return;
    _doResolve(trimmed);
  }

  Future<void> _doResolve(String code) async {
    setState(() { _resolving = true; _resolvedEntry = null; _qtyError = null; });

    try {
      final resolved =
          await ref.read(line1RepositoryProvider).resolveMixerScan(code);
      if (!mounted) return;
      final entries = (resolved['entries'] as List?) ?? const [];
      if (entries.isEmpty) {
        throw Exception('No stageable stock found for "$code"');
      }
      // Batch scan resolves to exactly one entry; item scan may span several —
      // take the oldest (FIFO order from the server) as the default.
      final entry = Map<String, dynamic>.from(entries.first);
      setState(() {
        _resolvedEntry = entry;
        _qtyCtrl.text = ((entry['qty'] as num?) ?? 0).toStringAsFixed(2);
        _resolving = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _resolving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('$e'),
        backgroundColor: AppTheme.danger,
      ));
    }
  }

  void _selectEntry(Map<String, dynamic> entry) {
    setState(() {
      _resolvedEntry = Map<String, dynamic>.from(entry);
      _qtyCtrl.text = ((entry['qty'] as num?) ?? 0).toStringAsFixed(2);
      _qtyError = null;
    });
  }

  double get _availableQty =>
      ((_resolvedEntry?['qty'] as num?) ?? 0).toDouble();

  bool get _labBlocked => (_resolvedEntry?['lab_blocked'] as bool?) ?? false;

  bool _validateQty() {
    final text = _qtyCtrl.text.trim();
    if (text.isEmpty) {
      setState(() => _qtyError = 'Enter a quantity');
      return false;
    }
    final val = double.tryParse(text);
    if (val == null || val <= 0) {
      setState(() => _qtyError = 'Must be greater than 0');
      return false;
    }
    if (val > _availableQty) {
      setState(() => _qtyError = 'Only $_availableQty Kg staged');
      return false;
    }
    setState(() => _qtyError = null);
    return true;
  }

  Future<void> _confirmAndLoad() async {
    if (_selectedWorkOrder == null || _resolvedEntry == null || !_validateQty()) return;
    final entry = _resolvedEntry!;
    final qty = double.parse(_qtyCtrl.text.trim());
    final itemLabel = (entry['item_name'] ?? entry['item_code']).toString();
    final batchNo = entry['batch_no']?.toString();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Mixer Load'),
        content: Text(
          'Load $qty Kg of $itemLabel\n'
          '${batchNo != null ? 'Batch: $batchNo\n' : ''}'
          'From: ${entry['warehouse']}',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirm')),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _submitting = true);
    try {
      await ref.read(line1RepositoryProvider).loadToMixer(
            itemCode: entry['item_code'] as String,
            qty: qty,
            workOrder: _selectedWorkOrder!.name,
            batchNo: batchNo,
            sourceWarehouse: entry['warehouse'] as String?,
          );
      if (mounted) {
        // No routine "Loaded" toast — the screen resetting to the scan
        // prompt is confirmation enough for this per-scan action.
        _reset();
        _loadData();
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
    setState(() { _resolvedEntry = null; _qtyError = null; });
    _scanCtrl.clear();
    _qtyCtrl.clear();
  }

  Color _labColor(String status) {
    switch (status) {
      case 'Pass': return Colors.green;
      case 'Conditional Pass': return Colors.orange;
      case 'Fail': return AppTheme.danger;
      case 'Pending': return Colors.grey;
      default: return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PdtScaffold(
      title: widget.screen.label,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!, style: const TextStyle(color: AppTheme.danger)),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
                  ],
                ))
              : _selectedWorkOrder == null
                  ? _buildWorkOrderPicker()
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _buildSelectedWorkOrderCard(),
                          const SizedBox(height: 12),
                          ScanInputField(
                            controller: _scanCtrl,
                            focusNode: _scanFocus,
                            labelText: 'Scan Batch / Item Barcode',
                            hintText: 'Scan the bag, CMB batch or item label',
                            onScanned: _onScanned,
                            onSubmitted: _onScanned,
                            autofocus: true,
                          ),
                          const SizedBox(height: 16),

                          if (_resolving)
                            const Center(child: Padding(
                              padding: EdgeInsets.all(24),
                              child: CircularProgressIndicator(),
                            )),

                          if (_resolvedEntry != null && !_resolving) _buildLoadCard(),

                          if (_resolvedEntry == null && !_resolving) ...[
                            _buildStockSection('Staged for Mixer', _stageable,
                                selectable: true),
                            const SizedBox(height: 24),
                            _buildStockSection('In Mixer (WIP)', _wip),
                          ],
                        ],
                      ),
                    ),
    );
  }

  Widget _buildWorkOrderPicker() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Select a Work Order', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          const Text(
            'Pick which Work Order you are mixing for. '
            'Only items on its BOM can be loaded into the mixer.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 12),
          if (_workOrders.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No open Work Orders for Mixer'),
              ),
            )
          else
            ..._workOrders.map((wo) => Card(
                  child: ListTile(
                    title: Text(wo.itemName ?? wo.productionItem,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${wo.name} · Qty ${wo.qty}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => setState(() => _selectedWorkOrder = wo),
                  ),
                )),
        ],
      ),
    );
  }

  Widget _buildSelectedWorkOrderCard() {
    final wo = _selectedWorkOrder!;
    return Card(
      color: Colors.deepPurple.withAlpha(13),
      child: ListTile(
        dense: true,
        leading: const Icon(Icons.assignment, color: Colors.deepPurple),
        title: Text(wo.itemName ?? wo.productionItem,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(wo.name),
        trailing: TextButton(
          onPressed: () => setState(() {
            _selectedWorkOrder = null;
            _reset();
          }),
          child: const Text('Change'),
        ),
      ),
    );
  }

  Widget _buildLoadCard() {
    final entry = _resolvedEntry!;
    final labStatus = (entry['lab_status'] ?? '').toString();
    final blocked = _labBlocked;

    return Card(
      elevation: 3,
      color: blocked
          ? AppTheme.danger.withAlpha(20)
          : Colors.deepPurple.withAlpha(20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.blender, color: Colors.deepPurple),
                const SizedBox(width: 8),
                if (labStatus.isNotEmpty)
                  Chip(
                    label: Text(labStatus,
                        style: const TextStyle(color: Colors.white, fontSize: 12)),
                    backgroundColor: _labColor(labStatus),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close), onPressed: _reset),
              ],
            ),
            const SizedBox(height: 8),
            Text((entry['item_name'] ?? entry['item_code']).toString(),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            if (entry['batch_no'] != null) ...[
              const SizedBox(height: 4),
              Text('Batch: ${entry['batch_no']}'),
            ],
            const SizedBox(height: 4),
            Text('From: ${entry['warehouse']}'),
            const SizedBox(height: 4),
            Text('Staged: $_availableQty Kg', style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 16),

            if (blocked)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.danger.withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Lab status is "$labStatus" — only Pass or Conditional Pass '
                  'batches can be loaded into the mixer.',
                  style: const TextStyle(color: AppTheme.danger),
                ),
              )
            else ...[
              TextField(
                controller: _qtyCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Load Qty (Kg)',
                  errorText: _qtyError,
                  isDense: true,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) { if (_qtyError != null) _validateQty(); },
              ),
              const SizedBox(height: 16),
              if (widget.screen.can('load'))
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _submitting ? null : _confirmAndLoad,
                    icon: _submitting
                        ? const SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.blender),
                    label: Text(_submitting ? 'Loading...' : 'Load to Mixer'),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStockSection(String title, List<Map<String, dynamic>> items,
      {bool selectable = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (items.isEmpty)
          const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No stock')))
        else
          ...items.map((entry) {
            final labStatus = (entry['lab_status'] ?? '').toString();
            final blocked = (entry['lab_blocked'] as bool?) ?? false;
            return Card(
              child: ListTile(
                onTap: selectable && !blocked ? () => _selectEntry(entry) : null,
                leading: CircleAvatar(
                  backgroundColor: Colors.deepPurple.withAlpha(38),
                  radius: 18,
                  child: const Icon(Icons.inventory_2, size: 18, color: Colors.deepPurple),
                ),
                title: Text((entry['item_name'] ?? entry['item_code']).toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text([
                  if (entry['batch_no'] != null) 'Batch ${entry['batch_no']}',
                  if (labStatus.isNotEmpty) 'Lab: $labStatus',
                ].join(' · ')),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${entry['qty']} Kg',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    if (blocked)
                      const Text('BLOCKED',
                          style: TextStyle(color: AppTheme.danger, fontSize: 11,
                              fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}
