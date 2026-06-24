import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/menu/menu_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/warehouse_models.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/pdt_scaffold.dart';
import '../../widgets/lot_card.dart';
import 'lot_repository.dart';

class LotBrowserScreen extends ConsumerStatefulWidget {
  final MenuScreen screen;

  const LotBrowserScreen({required this.screen, super.key});

  @override
  ConsumerState<LotBrowserScreen> createState() => _LotBrowserScreenState();
}

class _LotBrowserScreenState extends ConsumerState<LotBrowserScreen> {
  final _scrollController = ScrollController();

  // Filters
  final _warehouseCtrl = TextEditingController();
  final _zoneCtrl = TextEditingController();
  final _itemCtrl = TextEditingController();
  bool _onlyOccupied = true;
  bool _showFilterPanel = false;

  // Pagination states
  List<WarehouseLot> _allLots = []; // Full data loaded from API
  List<WarehouseLot> _lots = []; // Filtered view displayed in UI
  bool _loadingList = false;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _start = 0;
  final int _limit = 50;

  @override
  void initState() {
    super.initState();
    _loadLots(refresh: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _warehouseCtrl.dispose();
    _zoneCtrl.dispose();
    _itemCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadLots();
    }
  }

  /// Whether any local filter is currently active.
  bool get _isFilterActive =>
      _warehouseCtrl.text.trim().isNotEmpty ||
      _zoneCtrl.text.trim().isNotEmpty ||
      _itemCtrl.text.trim().isNotEmpty;

  /// Filters `_allLots` locally based on the filter panel fields.
  /// Matches against lot name, warehouse, zone, and item fields.
  /// Case-insensitive, partial matching.
  void _applyLocalFilter() {
    final warehouseQuery = _warehouseCtrl.text.trim().toLowerCase();
    final zoneQuery = _zoneCtrl.text.trim().toLowerCase();
    final itemQuery = _itemCtrl.text.trim().toLowerCase();

    if (warehouseQuery.isEmpty && zoneQuery.isEmpty && itemQuery.isEmpty) {
      setState(() {
        _lots = List.from(_allLots);
      });
    } else {
      setState(() {
        _lots = _allLots.where((lot) {
          final warehouse = (lot.warehouse ?? '').toLowerCase();
          final zone = (lot.zone ?? '').toLowerCase();
          final name = lot.name.toLowerCase();

          bool matches = true;
          if (warehouseQuery.isNotEmpty) {
            matches = matches && warehouse.contains(warehouseQuery);
          }
          if (zoneQuery.isNotEmpty) {
            matches =
                matches &&
                (zone.contains(zoneQuery) || name.contains(zoneQuery));
          }
          if (itemQuery.isNotEmpty) {
            // Search item codes/names within the lot's items
            final hasItem = lot.items.any((item) {
              final code = (item.itemCode).toLowerCase();
              final itemName = (item.itemName ?? '').toLowerCase();
              return code.contains(itemQuery) || itemName.contains(itemQuery);
            });
            matches = matches && hasItem;
          }
          return matches;
        }).toList();
      });
    }
  }

  Future<void> _loadLots({bool refresh = false}) async {
    if (_loadingList || _loadingMore) return;
    if (refresh) {
      setState(() {
        _start = 0;
        _hasMore = true;
        _allLots = [];
        _lots = [];
        _loadingList = true;
      });
    } else {
      if (!_hasMore) return;
      setState(() {
        _loadingMore = true;
      });
    }

    try {
      final data = await ref
          .read(lotRepositoryProvider)
          .browse(onlyOccupied: _onlyOccupied, limit: _limit, start: _start);

      if (mounted) {
        setState(() {
          if (refresh) {
            _allLots = data;
          } else {
            _allLots.addAll(data);
          }
          _start += data.length;
          _hasMore = data.length == _limit;
          _loadingList = false;
          _loadingMore = false;
        });
        _applyLocalFilter();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingList = false;
          _loadingMore = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading bins: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  void _showLotDetail(WarehouseLot lot) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _LotDetailSheet(lotName: lot.name),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PdtScaffold(
      title: widget.screen.label,
      actions: [
        IconButton(
          icon: Icon(
            _showFilterPanel ? Icons.filter_list_off : Icons.filter_list,
          ),
          onPressed: () {
            setState(() {
              _showFilterPanel = !_showFilterPanel;
            });
          },
        ),
      ],
      body: Column(
        children: [
          // Filter Panel
          if (_showFilterPanel) _buildFilterPanel(),

          // Bins List
          Expanded(
            child: _loadingList
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => _loadLots(refresh: true),
                    child: _lots.isEmpty
                        ? _buildEmptyView()
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(
                              AppTheme.horizontalPad,
                            ),
                            itemCount:
                                _lots.length +
                                (_hasMore && !_isFilterActive ? 1 : 0),
                            itemBuilder: (context, i) {
                              if (i == _lots.length) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 16.0,
                                    ),
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }

                              final lot = _lots[i];
                              final isOccupied =
                                  lot.isEmptyFlag == 0 || lot.items.isNotEmpty;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: LotCard(
                                  lotName: lot.name,
                                  warehouse: lot.warehouse,
                                  zone: lot.zone,
                                  status: isOccupied ? 'Occupied' : 'Empty',
                                  onTap: () => _showLotDetail(lot),
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
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
                  controller: _warehouseCtrl,
                  labelText: 'Warehouse',
                  hintText: 'e.g. Main WH',
                  prefixIcon: const Icon(Icons.warehouse_outlined),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomTextField(
                  controller: _zoneCtrl,
                  labelText: 'Zone',
                  hintText: 'e.g. A-02',
                  prefixIcon: const Icon(Icons.grid_3x3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          CustomTextField(
            controller: _itemCtrl,
            labelText: 'Item Code',
            hintText: 'Search occupied items...',
            prefixIcon: const Icon(Icons.search),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Checkbox(
                value: _onlyOccupied,
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _onlyOccupied = val);
                  }
                },
              ),
              const Text(
                'Show Occupied Lots Only',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _warehouseCtrl.clear();
                    _zoneCtrl.clear();
                    _itemCtrl.clear();
                    setState(() {
                      _onlyOccupied = true;
                    });
                    _applyLocalFilter();
                  },
                  child: const Text('Reset'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  text: 'Apply Filters',
                  onPressed: () {
                    _applyLocalFilter();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: ListView(
        shrinkWrap: true,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32),
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 72,
            color: AppTheme.textDisabled.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Bins Found',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try adjusting your search filters or pull down to refresh.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppTheme.textDisabled),
          ),
        ],
      ),
    );
  }
}

class _LotDetailSheet extends ConsumerStatefulWidget {
  final String lotName;
  const _LotDetailSheet({required this.lotName});

  @override
  ConsumerState<_LotDetailSheet> createState() => _LotDetailSheetState();
}

class _LotDetailSheetState extends ConsumerState<_LotDetailSheet> {
  bool _loading = true;
  WarehouseLot? _detail;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    try {
      final res = await ref.read(lotRepositoryProvider).get(widget.lotName);
      if (mounted) {
        setState(() {
          _detail = res;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load details: $e';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppTheme.horizontalPad,
        right: AppTheme.horizontalPad,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
                child: Text(
                  _error!,
                  style: const TextStyle(color: AppTheme.danger),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Bin: ${_detail!.name}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('Warehouse: ${_detail!.warehouse ?? 'N/A'}'),
                  Text('Zone: ${_detail!.zone ?? 'N/A'}'),
                  const Divider(height: 24),
                  const Text(
                    'OCCUPIED ITEMS',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _detail!.items.isEmpty
                        ? const Center(
                            child: Text(
                              'No items in this location',
                              style: TextStyle(fontStyle: FontStyle.italic),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _detail!.items.length,
                            itemBuilder: (context, i) {
                              final item = _detail!.items[i];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '${item.itemCode} (${item.itemName ?? ''})',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            '${item.qty} ${item.uom ?? ''}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: AppTheme.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      if (item.upcCode != null &&
                                          item.upcCode!.isNotEmpty)
                                        Text(
                                          'UPC: ${item.upcCode}',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                      if (item.batchNo != null &&
                                          item.batchNo!.isNotEmpty)
                                        Text(
                                          'Batch: ${item.batchNo}',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                      if (item.productionDate != null)
                                        Text(
                                          'Production Date: ${item.productionDate}',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                      if (item.expiryDate != null)
                                        Text(
                                          'Expiry Date: ${item.expiryDate}',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                      if (item.fifoDate != null)
                                        Text(
                                          'FIFO Date: ${item.fifoDate}',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}
