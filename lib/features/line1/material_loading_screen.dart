import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/menu/menu_models.dart';
import '../../core/models/line1_models.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/pdt_scaffold.dart';
import '../../widgets/scan_input_field.dart';
import 'line1_repository.dart';

class MaterialLoadingScreen extends ConsumerStatefulWidget {
  final MenuScreen screen;
  const MaterialLoadingScreen({required this.screen, super.key});

  @override
  ConsumerState<MaterialLoadingScreen> createState() => _MaterialLoadingScreenState();
}

class _MaterialLoadingScreenState extends ConsumerState<MaterialLoadingScreen> {
  bool _loading = true;
  String? _error;
  List<StockItem> _outsideStock = [];
  List<StockItem> _insideStock = [];

  // Scan → resolve → load flow
  StockItem? _resolvedItem;
  String? _resolvedStream;
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
      final results = await Future.wait([
        repo.listAllOutsideStock(),
        repo.listAllInsideStock(),
      ]);
      setState(() {
        _outsideStock = results[0];
        _insideStock = results[1];
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = 'Failed to load stock'; _loading = false; });
    }
  }

  Future<void> _onScanned(String barcode) async {
    final trimmed = barcode.trim();
    if (trimmed.isEmpty) return;

    setState(() { _resolving = true; _resolvedItem = null; _resolvedStream = null; _qtyError = null; });

    try {
      final resolved = await ref.read(line1RepositoryProvider).resolveItem(trimmed);
      setState(() {
        _resolvedItem = StockItem(
          itemCode: resolved['item_code'] as String,
          itemName: resolved['item_name'] as String?,
          qty: (resolved['qty'] as num).toDouble(),
        );
        _resolvedStream = resolved['stream'] as String?;
        _qtyCtrl.text = _resolvedItem!.qty.toStringAsFixed(2);
        _resolving = false;
      });
    } catch (e) {
      setState(() => _resolving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$e'),
          backgroundColor: AppTheme.danger,
        ));
      }
    }
  }

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
    if (val > _resolvedItem!.qty) {
      setState(() => _qtyError = 'Only ${_resolvedItem!.qty} Kg available');
      return false;
    }
    setState(() => _qtyError = null);
    return true;
  }

  Future<void> _confirmAndLoad() async {
    if (!_validateQty() || _resolvedItem == null) return;
    final qty = double.parse(_qtyCtrl.text.trim());
    final item = _resolvedItem!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Load'),
        content: Text(
          'Load $qty Kg of ${item.itemName ?? item.itemCode}\n'
          'Stream: $_resolvedStream',
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
      final result = await ref.read(line1RepositoryProvider).loadMaterial(
        itemCode: item.itemCode,
        qty: qty,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Loaded ${result.qty} Kg → ${result.stream ?? _resolvedStream}'),
          backgroundColor: AppTheme.success,
        ));
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
    setState(() { _resolvedItem = null; _resolvedStream = null; _qtyError = null; });
    _scanCtrl.clear();
    _qtyCtrl.clear();
  }

  Color _streamColor(String stream) {
    switch (stream) {
      case 'Silo': return Colors.blue;
      case 'Oil': return Colors.amber;
      case 'Weighing': return Colors.green;
      default: return Colors.grey;
    }
  }

  IconData _streamIcon(String stream) {
    switch (stream) {
      case 'Silo': return Icons.download;
      case 'Oil': return Icons.water_drop;
      case 'Weighing': return Icons.scale;
      default: return Icons.inventory_2;
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
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      ScanInputField(
                        controller: _scanCtrl,
                        focusNode: _scanFocus,
                        labelText: 'Scan Item Barcode',
                        hintText: 'Scan barcode on silo / oil tank / weighing box',
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

                      if (_resolvedItem != null && !_resolving) _buildLoadCard(),

                      if (_resolvedItem == null && !_resolving) ...[
                        _buildStockSection('Outside — Ready to Load', _outsideStock),
                        const SizedBox(height: 24),
                        _buildStockSection('Inside — Currently Loaded', _insideStock),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildLoadCard() {
    final item = _resolvedItem!;
    final stream = _resolvedStream ?? '';
    return Card(
      elevation: 3,
      color: _streamColor(stream).withOpacity(0.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_streamIcon(stream), color: _streamColor(stream)),
                const SizedBox(width: 8),
                Chip(
                  label: Text(stream, style: const TextStyle(color: Colors.white, fontSize: 12)),
                  backgroundColor: _streamColor(stream),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _reset,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(item.itemName ?? item.itemCode, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text('Total Available: ${item.qty} Kg', style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 16),
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
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Icon(_streamIcon(stream)),
                  label: Text(_submitting ? 'Loading...' : 'Load to $stream'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockSection(String title, List<StockItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (items.isEmpty)
          const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No stock')))
        else
          ...items.map((item) {
            final stream = item.stream;
            return Card(
              child: ListTile(
                leading: stream != null
                    ? CircleAvatar(
                        backgroundColor: _streamColor(stream).withOpacity(0.15),
                        radius: 18,
                        child: Icon(_streamIcon(stream), size: 18, color: _streamColor(stream)),
                      )
                    : null,
                title: Text(item.itemName ?? item.itemCode, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: stream != null ? Text(stream) : null,
                trailing: Text('${item.qty} Kg', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            );
          }),
      ],
    );
  }
}
