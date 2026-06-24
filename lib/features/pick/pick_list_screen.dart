import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
import 'pick_repository.dart';

class PickListScreen extends ConsumerStatefulWidget {
  final MenuScreen screen;
  final String? pickingType;
  final String? materialRequestFilter;

  const PickListScreen({
    required this.screen,
    this.pickingType,
    this.materialRequestFilter,
    super.key,
  });

  @override
  ConsumerState<PickListScreen> createState() => _PickListScreenState();
}

class _PickListScreenState extends ConsumerState<PickListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = true;
  List<PickItem> _picks = [];
  String? _error;

  // Picking details
  PickItem? _selectedPick;
  bool _submitting = false;

  final _lotCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _mrFilterCtrl = TextEditingController();

  final _lotFocus = FocusNode();
  final _qtyFocus = FocusNode();
  final _mrFilterFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPicks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _lotCtrl.dispose();
    _qtyCtrl.dispose();
    _mrFilterCtrl.dispose();
    _lotFocus.dispose();
    _qtyFocus.dispose();
    _mrFilterFocus.dispose();
    super.dispose();
  }

  Future<void> _loadPicks() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final filter = _mrFilterCtrl.text.trim().isNotEmpty
          ? _mrFilterCtrl.text.trim()
          : widget.materialRequestFilter;
      final data = await ref.read(pickRepositoryProvider).listPicks(
            materialRequest: filter,
            pickingType: widget.pickingType,
          );
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

  List<PickItem> _filterPicks(String status) {
    return _picks.where((p) => p.status.toLowerCase() == status.toLowerCase()).toList();
  }

  Future<void> _claimItem(String pickItem) async {
    setState(() => _submitting = true);
    try {
      await ref.read(pickRepositoryProvider).claim(pickItem);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item claimed successfully!'), backgroundColor: AppTheme.success),
      );
      await _loadPicks();
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
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _submitPick() async {
    if (_selectedPick == null) return;

    final actualLot = _lotCtrl.text.trim();
    final pickedQty = double.tryParse(_qtyCtrl.text) ?? 0.0;
    final suggestedLot = _selectedPick!.suggestedLot ?? '';

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
            pickItem: _selectedPick!.name,
            actualLot: actualLot,
            pickedQty: pickedQty,
          );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick list item submitted successfully!'), backgroundColor: AppTheme.success),
      );

      final currentItem = _selectedPick!;
      final remaining = currentItem.requiredQty - currentItem.pickedQty;
      setState(() {
        if (remaining > pickedQty) {
          _picks = _picks.map((e) {
            if (e.name == currentItem.name) {
              return e.copyWith(pickedQty: e.pickedQty + pickedQty);
            }
            return e;
          }).toList();
        } else {
          _picks = _picks.where((e) => e.name != currentItem.name).toList();
        }
        _selectedItemDismiss();
      });
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

  void _selectedItemDismiss() {
    setState(() {
      _selectedPick = null;
    });
  }

  void _selectPick(PickItem pick) {
    setState(() {
      _selectedPick = pick;
      _lotCtrl.clear();
      final remaining = pick.requiredQty - pick.pickedQty;
      _qtyCtrl.text = remaining.toStringAsFixed(remaining.truncateToDouble() == remaining ? 0 : 2);
    });
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _lotFocus.requestFocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PdtScaffold(
      title: _selectedPick == null ? widget.screen.label : 'Pick Item',
      body: _selectedPick == null ? _buildTabsBody() : _buildPickFormBody(),
    );
  }

  Widget _buildTabsBody() {
    return Column(
      children: [
        // Material Request Filter Bar
        Padding(
          padding: const EdgeInsets.all(AppTheme.horizontalPad),
          child: Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _mrFilterCtrl,
                  focusNode: _mrFilterFocus,
                  labelText: 'Filter Material Request',
                  hintText: 'Enter MR number...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _mrFilterCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _mrFilterCtrl.clear();
                            _loadPicks();
                          },
                        )
                      : null,
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _loadPicks(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(60, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                  ),
                ),
                onPressed: _loadPicks,
                child: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),
        
        // TabBar
        TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primary,
          tabs: const [
            Tab(text: 'Unassigned'),
            Tab(text: 'In Progress'),
            Tab(text: 'Completed'),
          ],
        ),
        
        // TabBarView content
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? _buildErrorView()
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildPickListSection('Pending', isClaimable: true),
                        _buildPickListSection('In Progress', isPickable: true),
                        _buildPickListSection('Completed'),
                      ],
                    ),
        ),
      ],
    );
  }

  Widget _buildErrorView() {
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

  Widget _buildPickListSection(String status, {bool isClaimable = false, bool isPickable = false}) {
    final filtered = _filterPicks(status);

    if (filtered.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadPicks,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: 200,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.horizontalPad),
                  child: Text(
                    'No picks found.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPicks,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppTheme.horizontalPad),
        itemCount: filtered.length,
        itemBuilder: (context, i) {
          final item = filtered[i];
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
                    Text('Qty: ${item.requiredQty} | Picked: ${item.pickedQty}'),
                    const SizedBox(height: 2),
                    Text('Suggested Lot: ${item.suggestedLot ?? 'N/A'}'),
                  ],
                ),
                trailing: isClaimable
                    ? (widget.screen.can('claim')
                        ? ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(80, 36),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                            onPressed: _submitting ? null : () => _claimItem(item.name),
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
      ),
    );
  }

  Widget _buildPickFormBody() {
    final item = _selectedPick!;
    return WillPopScope(
      onWillPop: () async {
        _selectedItemDismiss();
        return false;
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.horizontalPad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _selectedItemDismiss,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to list'),
              ),
            ),
            const SizedBox(height: 8),

            // Details Card
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
                    Text(item.itemName ?? '', style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
                    const Divider(height: 24),
                    Text('Target Warehouse: ${item.warehouse ?? ''}'),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Text('Suggested Lot: '),
                        if (item.suggestedLot != null && item.suggestedLot!.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _lotCtrl.text = item.suggestedLot!;
                              });
                              _qtyFocus.requestFocus();
                            },
                            child: Chip(
                              label: Text(
                                item.suggestedLot!,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                              backgroundColor: AppTheme.primary,
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            ),
                          )
                        else
                          const Text('None', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Required: ${item.requiredQty}  |  Picked: ${item.pickedQty}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Scanning Form
            ScanInputField(
              controller: _lotCtrl,
              focusNode: _lotFocus,
              labelText: 'Scan Lot',
              hintText: 'Scan Lot to pick from',
              prefixIcon: Icons.qr_code_scanner,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => _qtyFocus.requestFocus(),
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
      ),
    );
  }
}
