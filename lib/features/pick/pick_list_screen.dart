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
import 'pick_repository.dart';

class PickListScreen extends ConsumerStatefulWidget {
  final MenuScreen screen;

  const PickListScreen({required this.screen, super.key});

  @override
  ConsumerState<PickListScreen> createState() => _PickListScreenState();
}

class _PickListScreenState extends ConsumerState<PickListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = true;
  List<dynamic> _picks = [];
  String? _error;

  // Picking details
  Map<String, dynamic>? _selectedPick;
  bool _submitting = false;

  final _lotCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _lotFocus = FocusNode();
  final _qtyFocus = FocusNode();

  late StreamSubscription<String> _scanSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPicks();

    _scanSubscription = ref.read(keyboardScanServiceProvider).scans.listen(_onBarcodeScanned);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scanSubscription.cancel();
    _lotCtrl.dispose();
    _qtyCtrl.dispose();
    _lotFocus.dispose();
    _qtyFocus.dispose();
    super.dispose();
  }

  Future<void> _loadPicks() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ref.read(pickRepositoryProvider).listPicks();
      setState(() {
        _picks = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load picking lists.';
        _loading = false;
      });
    }
  }

  void _onBarcodeScanned(String barcode) {
    if (_selectedPick == null) return;
    
    if (_lotFocus.hasFocus) {
      _lotCtrl.text = barcode;
      _qtyFocus.requestFocus();
    } else {
      if (_lotCtrl.text.isEmpty) {
        _lotCtrl.text = barcode;
      }
    }
    setState(() {});
  }

  List<dynamic> _filterPicks(String status) {
    return _picks.where((p) => p['status']?.toString().toLowerCase() == status.toLowerCase()).toList();
  }

  Future<void> _claimItem(String pickItem) async {
    setState(() => _submitting = true);
    try {
      await ref.read(pickRepositoryProvider).claim(pickItem);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item claimed successfully!'), backgroundColor: AppTheme.success),
      );
      _loadPicks();
      _tabController.animateTo(1); // switch to In Progress tab
    } on ApiException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(messageFor(e)), backgroundColor: AppTheme.danger),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.danger),
      );
    } finally {
      setState(() => _submitting = false);
    }
  }

  Future<void> _submitPick() async {
    if (_selectedPick == null) return;

    final actualLot = _lotCtrl.text.trim();
    final pickedQty = double.tryParse(_qtyCtrl.text) ?? 0.0;
    final suggestedLot = (_selectedPick!['suggested_lot'] ?? '').toString();

    if (actualLot.isEmpty || pickedQty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please scan a Lot and enter a valid quantity.')),
      );
      return;
    }

    // Suggested lot validation gate
    if (actualLot != suggestedLot && !widget.screen.can('override_suggested_lot')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Scanned Lot ($actualLot) does not match Suggested Lot ($suggestedLot). Override permission required.'),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await ref.read(pickRepositoryProvider).pick(
            pickItem: _selectedPick!['name'].toString(),
            actualLot: actualLot,
            pickedQty: pickedQty,
          );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick list item submitted successfully!'), backgroundColor: AppTheme.success),
      );

      setState(() {
        _selectedPick = null;
      });
      _loadPicks();
    } on ApiException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(messageFor(e)), backgroundColor: AppTheme.danger),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.danger),
      );
    } finally {
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardWedgeScanWidget(
      service: ref.read(keyboardScanServiceProvider),
      child: Scaffold(
        backgroundColor: AppTheme.bgScaffold,
        appBar: AppBar(
          title: Text(_selectedPick == null ? 'Pick Lists' : 'Pick Item'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (_selectedPick != null) {
                setState(() => _selectedPick = null);
              } else {
                Navigator.of(context).pop();
              }
            },
          ),
          bottom: _selectedPick == null
              ? TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.white,
                  tabs: const [
                    Tab(text: 'Unassigned'),
                    Tab(text: 'In Progress'),
                    Tab(text: 'Completed'),
                  ],
                )
              : null,
        ),
        body: _selectedPick == null ? _buildTabsBody() : _buildPickFormBody(),
      ),
    );
  }

  Widget _buildTabsBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.horizontalPad),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, style: const TextStyle(color: AppTheme.danger)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadPicks, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildPickListSection('open', isClaimable: true),
        _buildPickListSection('claiming', isPickable: true),
        _buildPickListSection('completed'),
      ],
    );
  }

  Widget _buildPickListSection(String status, {bool isClaimable = false, bool isPickable = false}) {
    final filtered = _filterPicks(status);

    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.horizontalPad),
          child: Text(
            'No picks found.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.horizontalPad),
      itemCount: filtered.length,
      itemBuilder: (context, i) {
        final item = Map<String, dynamic>.from(filtered[i]);
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
                  Text('From Bin: ${item['warehouse'] ?? ''} | Qty: ${item['qty']}'),
                  const SizedBox(height: 2),
                  Text('Suggested Lot: ${item['suggested_lot'] ?? 'N/A'}'),
                ],
              ),
              trailing: isClaimable
                  ? (widget.screen.can('claim')
                      ? ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(80, 36),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          onPressed: _submitting ? null : () => _claimItem(item['name'].toString()),
                          child: const Text('Claim'),
                        )
                      : null)
                  : isPickable
                      ? (widget.screen.can('pick')
                          ? const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.textSecondary)
                          : null)
                      : const Icon(Icons.check, color: AppTheme.success, size: 20),
              onTap: isPickable && widget.screen.can('pick') ? () => _selectPick(item) : null,
            ),
          ),
        );
      },
    );
  }

  void _selectPick(Map<String, dynamic> pick) {
    setState(() {
      _selectedPick = pick;
      _lotCtrl.clear();
      _qtyCtrl.text = (pick['qty'] ?? '').toString();
    });
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _lotFocus.requestFocus();
    });
  }

  Widget _buildPickFormBody() {
    final item = _selectedPick!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.horizontalPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Details Card
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
                  Text(item['item_name'] ?? '', style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
                  const Divider(height: 24),
                  Text('Target Warehouse: ${item['warehouse'] ?? ''}'),
                  const SizedBox(height: 4),
                  Text('Suggested Lot: ${item['suggested_lot'] ?? 'None'}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('Target Quantity: ${item['qty']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Scanning Form
          CustomTextField(
            controller: _lotCtrl,
            focusNode: _lotFocus,
            labelText: 'Scan Lot',
            hintText: 'Scan Lot to pick from',
            prefixIcon: const Icon(Icons.qr_code_scanner),
            textStyle: AppTheme.scanValueStyle,
            onChanged: (val) => setState(() {}),
          ),
          const SizedBox(height: 14),

          CustomTextField(
            controller: _qtyCtrl,
            focusNode: _qtyFocus,
            labelText: 'Picked Qty',
            hintText: 'Enter quantity picked',
            prefixIcon: const Icon(Icons.calculate_outlined),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),

          CustomButton(
            text: 'Confirm Pick',
            isLoading: _submitting,
            icon: Icons.check_circle_outline,
            onPressed: _submitPick,
          ),
        ],
      ),
    );
  }
}
