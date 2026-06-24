import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/menu/menu_models.dart';
import '../../core/models/line1_models.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/pdt_scaffold.dart';
import '../../widgets/scan_input_field.dart';
import 'line1_repository.dart';

class SiloLoadingScreen extends ConsumerStatefulWidget {
  final MenuScreen screen;
  const SiloLoadingScreen({required this.screen, super.key});

  @override
  ConsumerState<SiloLoadingScreen> createState() => _SiloLoadingScreenState();
}

class _SiloLoadingScreenState extends ConsumerState<SiloLoadingScreen> {
  bool _loading = true;
  String? _error;
  List<StockItem> _outsideStock = [];
  List<StockItem> _insideStock = [];

  StockItem? _scannedItem;
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
        repo.listOutsideStock('silo'),
        repo.listInsideStock('silo'),
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

  void _onScanned(String barcode) {
    final trimmed = barcode.trim();
    if (trimmed.isEmpty) return;

    final match = _outsideStock.where((s) => s.itemCode == trimmed).toList();
    if (match.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('No stock for "$trimmed" in Outside Silo'),
        backgroundColor: AppTheme.error,
      ));
      return;
    }

    setState(() {
      _scannedItem = match.first;
      _qtyCtrl.text = match.first.qty.toStringAsFixed(2);
      _qtyError = null;
    });
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
    if (val > _scannedItem!.qty) {
      setState(() => _qtyError = 'Only ${_scannedItem!.qty} Kg available');
      return false;
    }
    setState(() => _qtyError = null);
    return true;
  }

  Future<void> _confirmAndLoad() async {
    if (!_validateQty()) return;
    final qty = double.parse(_qtyCtrl.text.trim());
    final item = _scannedItem!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Load'),
        content: Text('Load $qty Kg of ${item.itemName ?? item.itemCode} into the silo?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirm')),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _submitting = true);
    try {
      final result = await ref.read(line1RepositoryProvider).siloLoad(
        itemCode: item.itemCode,
        qty: qty,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Loaded ${result.qty} Kg to Inside Silo'),
          backgroundColor: AppTheme.success,
        ));
        setState(() => _scannedItem = null);
        _scanCtrl.clear();
        _qtyCtrl.clear();
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$e'),
          backgroundColor: AppTheme.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
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
                    Text(_error!, style: const TextStyle(color: AppTheme.error)),
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
                        labelText: 'Scan Silo Barcode',
                        hintText: 'Scan item barcode on silo',
                        onScanned: _onScanned,
                        onSubmitted: _onScanned,
                        autofocus: true,
                      ),
                      const SizedBox(height: 16),
                      if (_scannedItem != null) _buildLoadCard(),
                      if (_scannedItem == null) ...[
                        _buildStockSection('Outside Silo — Ready to Load', _outsideStock),
                        const SizedBox(height: 24),
                        _buildStockSection('Inside Silo — Currently Loaded', _insideStock),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildLoadCard() {
    final item = _scannedItem!;
    return Card(
      elevation: 3,
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle, color: AppTheme.success),
                const SizedBox(width: 8),
                Expanded(child: Text(item.itemName ?? item.itemCode, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() { _scannedItem = null; _scanCtrl.clear(); _qtyCtrl.clear(); }),
                ),
              ],
            ),
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
                      : const Icon(Icons.download),
                  label: Text(_submitting ? 'Loading...' : 'Load to Silo'),
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
          ...items.map((item) => Card(
            child: ListTile(
              title: Text(item.itemName ?? item.itemCode, style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: Text('${item.qty} Kg', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          )),
      ],
    );
  }
}
