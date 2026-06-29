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
  bool _creatingBox = false;
  bool _sealingBox = false;
  String? _activeBoxId;
  List<Map<String, dynamic>> _boxItems = [];

  // ── Pallet tab state ──
  final _palletScanCtrl = TextEditingController();
  final _palletScanFocus = FocusNode();
  bool _creatingPallet = false;
  bool _sealingPallet = false;
  String? _activePalletId;
  List<Map<String, dynamic>> _palletBoxes = [];

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
    _palletScanCtrl.dispose();
    _palletScanFocus.dispose();
    super.dispose();
  }

  // ── Box actions ──

  Future<void> _createBox() async {
    final so = _boxSoCtrl.text.trim();
    if (so.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Enter a Sales Order'),
        backgroundColor: AppTheme.danger,
      ));
      return;
    }

    setState(() => _creatingBox = true);
    try {
      final result = await ref.read(line2RepositoryProvider).createBox(so: so);
      final data = Map<String, dynamic>.from(result);
      setState(() {
        _activeBoxId = data['box_id']?.toString();
        _boxItems = [];
        _creatingBox = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Box ${_activeBoxId} created'),
          backgroundColor: AppTheme.success,
        ));
      }
    } catch (e) {
      setState(() => _creatingBox = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.danger,
        ));
      }
    }
  }

  Future<void> _onBoxItemScanned(String barcode) async {
    final trimmed = barcode.trim();
    if (trimmed.isEmpty || _activeBoxId == null) return;

    try {
      final result = await ref.read(line2RepositoryProvider).scanIntoBox(
            boxId: _activeBoxId!,
            itemBarcode: trimmed,
          );
      final data = Map<String, dynamic>.from(result);
      setState(() {
        _boxItems.add(data);
      });
      _boxScanCtrl.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Scan error: $e'),
          backgroundColor: AppTheme.danger,
        ));
      }
    }
  }

  Future<void> _sealBox() async {
    if (_activeBoxId == null) return;
    setState(() => _sealingBox = true);
    try {
      await ref.read(line2RepositoryProvider).sealBox(boxId: _activeBoxId!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Box $_activeBoxId sealed'),
          backgroundColor: AppTheme.success,
        ));
        setState(() {
          _activeBoxId = null;
          _boxItems = [];
          _boxSoCtrl.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.danger,
        ));
      }
    } finally {
      if (mounted) setState(() => _sealingBox = false);
    }
  }

  Future<void> _printBoxLabel() async {
    if (_activeBoxId == null) return;
    try {
      await ref
          .read(line2RepositoryProvider)
          .printLabel('Box', _activeBoxId!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Box label sent to printer'),
          backgroundColor: AppTheme.success,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Print error: $e'),
          backgroundColor: AppTheme.danger,
        ));
      }
    }
  }

  // ── Pallet actions ──

  Future<void> _createPallet() async {
    setState(() => _creatingPallet = true);
    try {
      final result = await ref.read(line2RepositoryProvider).createPallet();
      final data = Map<String, dynamic>.from(result);
      setState(() {
        _activePalletId = data['pallet_id']?.toString();
        _palletBoxes = [];
        _creatingPallet = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Pallet ${_activePalletId} created'),
          backgroundColor: AppTheme.success,
        ));
      }
    } catch (e) {
      setState(() => _creatingPallet = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.danger,
        ));
      }
    }
  }

  Future<void> _onPalletBoxScanned(String barcode) async {
    final trimmed = barcode.trim();
    if (trimmed.isEmpty || _activePalletId == null) return;

    try {
      final result = await ref.read(line2RepositoryProvider).scanIntoPallet(
            palletId: _activePalletId!,
            boxBarcode: trimmed,
          );
      final data = Map<String, dynamic>.from(result);
      setState(() {
        _palletBoxes.add(data);
      });
      _palletScanCtrl.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Scan error: $e'),
          backgroundColor: AppTheme.danger,
        ));
      }
    }
  }

  Future<void> _sealPallet() async {
    if (_activePalletId == null) return;
    setState(() => _sealingPallet = true);
    try {
      await ref
          .read(line2RepositoryProvider)
          .sealPallet(palletId: _activePalletId!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Pallet $_activePalletId sealed'),
          backgroundColor: AppTheme.success,
        ));
        setState(() {
          _activePalletId = null;
          _palletBoxes = [];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.danger,
        ));
      }
    } finally {
      if (mounted) setState(() => _sealingPallet = false);
    }
  }

  Future<void> _printPalletLabel() async {
    if (_activePalletId == null) return;
    try {
      await ref
          .read(line2RepositoryProvider)
          .printLabel('Pallet', _activePalletId!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Pallet label sent to printer'),
          backgroundColor: AppTheme.success,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Print error: $e'),
          backgroundColor: AppTheme.danger,
        ));
      }
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

  Widget _buildBoxTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_activeBoxId == null) ...[
          // Create box form
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
          // Active box
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
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('${_boxItems.length} items scanned'),
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

          // Scan items into box
          ScanInputField(
            controller: _boxScanCtrl,
            focusNode: _boxScanFocus,
            labelText: 'Scan Item into Box',
            hintText: 'Scan item barcode',
            onScanned: _onBoxItemScanned,
            onSubmitted: _onBoxItemScanned,
            autofocus: true,
          ),
          const SizedBox(height: 12),

          // Items list
          if (_boxItems.isNotEmpty) ...[
            Text('Items (${_boxItems.length})',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            ..._boxItems.map((item) => Card(
                  child: ListTile(
                    dense: true,
                    title: Text(
                        item['item_name']?.toString() ??
                            item['item_code']?.toString() ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                    trailing: Text(
                        'Qty: ${item['qty'] ?? 1}',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                )),
            const SizedBox(height: 12),
          ],

          // Seal box
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
          CustomButton(
            text: _creatingPallet ? 'Creating...' : 'Create Pallet',
            icon: Icons.pallet,
            isLoading: _creatingPallet,
            backgroundColor: AppTheme.primary,
            textColor: Colors.white,
            onPressed: _creatingPallet ? null : _createPallet,
          ),
        ] else ...[
          // Active pallet
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
                        Text('Pallet: $_activePalletId',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('${_palletBoxes.length} boxes loaded'),
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

          // Scan boxes onto pallet
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

          // Boxes list
          if (_palletBoxes.isNotEmpty) ...[
            Text('Boxes (${_palletBoxes.length})',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            ..._palletBoxes.map((box) => Card(
                  child: ListTile(
                    dense: true,
                    title: Text(
                        box['box_id']?.toString() ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                    trailing: Text(
                        'Items: ${box['item_count'] ?? 0}',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                )),
            const SizedBox(height: 12),
          ],

          // Seal pallet
          CustomButton(
            text: _sealingPallet ? 'Sealing...' : 'Seal Pallet',
            icon: Icons.lock,
            isLoading: _sealingPallet,
            backgroundColor: AppTheme.success,
            textColor: Colors.white,
            onPressed:
                _sealingPallet || _palletBoxes.isEmpty ? null : _sealPallet,
          ),
        ],
      ],
    );
  }
}
