import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/menu/menu_models.dart';
import '../../core/models/line1_models.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/pdt_scaffold.dart';
import 'line1_repository.dart';

class BagViewerScreen extends ConsumerStatefulWidget {
  final MenuScreen screen;
  const BagViewerScreen({required this.screen, super.key});

  @override
  ConsumerState<BagViewerScreen> createState() => _BagViewerScreenState();
}

class _BagViewerScreenState extends ConsumerState<BagViewerScreen> {
  bool _loading = true;
  String? _error;
  List<BagItem> _bags = [];
  BagDetail? _selectedBag;
  bool _loadingDetail = false;

  @override
  void initState() {
    super.initState();
    _loadBags();
  }

  Future<void> _loadBags() async {
    setState(() { _loading = true; _error = null; });
    try {
      _bags = await ref.read(line1RepositoryProvider).listBags();
      setState(() => _loading = false);
    } catch (e) {
      setState(() { _error = 'Failed to load bags'; _loading = false; });
    }
  }

  Future<void> _showBagDetail(BagItem bag) async {
    final batchNo = bag.batchNo.trim();
    if (batchNo.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Unable to open bag detail because the batch number is missing.'),
          backgroundColor: AppTheme.danger,
        ));
      }
      return;
    }

    setState(() => _loadingDetail = true);
    try {
      final detail = await ref.read(line1RepositoryProvider).getBag(batchNo);
      setState(() { _selectedBag = detail; _loadingDetail = false; });
    } catch (e) {
      setState(() => _loadingDetail = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Unable to load bag detail: $e'),
          backgroundColor: AppTheme.danger,
        ));
      }
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
                    ElevatedButton(onPressed: _loadBags, child: const Text('Retry')),
                  ],
                ))
              : _selectedBag != null
                  ? _buildDetail()
                  : _buildList(),
    );
  }

  Widget _buildList() {
    if (_bags.isEmpty) {
      return const Center(child: Text('No bags in WIP'));
    }
    return RefreshIndicator(
      onRefresh: _loadBags,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _bags.length,
        itemBuilder: (context, index) {
          final bag = _bags[index];
          return Card(
            child: ListTile(
              title: Text(bag.itemName ?? bag.itemCode, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Batch: ${bag.batchNo}'),
                  Text('Qty: ${bag.qty} Kg'),
                  if (bag.formulaName != null) Text('Formula: ${bag.formulaName}'),
                ],
              ),
              trailing: const Icon(Icons.chevron_right),
              isThreeLine: true,
              onTap: () => _showBagDetail(bag),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetail() {
    final bag = _selectedBag!;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _selectedBag = null);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _selectedBag = null),
              ),
              Expanded(
                child: Text('Bag Detail', style: Theme.of(context).textTheme.titleLarge),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(bag.itemName ?? bag.itemCode, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 8),
                  _infoRow('Batch', bag.batchNo),
                  _infoRow('Qty', '${bag.qty} Kg'),
                  if (bag.formulaName != null) _infoRow('Formula', bag.formulaName!),
                  if (bag.manufacturingDate != null) _infoRow('Date', bag.manufacturingDate!),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Consumed Materials', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (bag.consumeItems.isEmpty)
            const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No consumption data')))
          else
            ...bag.consumeItems.map((ci) => Card(
              child: ListTile(
                title: Text(ci.itemName ?? ci.itemCode),
                subtitle: Text('Batch: ${ci.batchNo ?? "—"} | From: ${ci.warehouse ?? "—"}'),
                trailing: Text('${ci.qty} Kg', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            )),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label, style: TextStyle(color: Colors.grey[600]))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
