import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/menu/menu_models.dart';
import '../../core/models/line1_models.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/pdt_scaffold.dart';
import 'line1_repository.dart';

class CalenderingScreen extends ConsumerStatefulWidget {
  final MenuScreen screen;
  const CalenderingScreen({required this.screen, super.key});

  @override
  ConsumerState<CalenderingScreen> createState() => _CalenderingScreenState();
}

class _CalenderingScreenState extends ConsumerState<CalenderingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  // ── New Run tab ──
  bool _loadingFmb = true;
  String? _fmbError;
  List<CalenderingFmb> _eligibleFmb = [];

  // ── Active Runs tab ──
  bool _loadingRuns = true;
  String? _runsError;
  List<CalenderingRun> _runs = [];

  // ── Run Detail view ──
  CalenderingRun? _activeRun;
  bool _loadingRun = false;

  // ── Sheet entry ──
  final List<_SheetEntry> _sheetEntries = [];
  final _rReturnCtrl = TextEditingController(text: '0');
  final _cReturnCtrl = TextEditingController(text: '0');
  bool _completing = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadFmb();
    _loadRuns();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _rReturnCtrl.dispose();
    _cReturnCtrl.dispose();
    for (final e in _sheetEntries) {
      e.dispose();
    }
    super.dispose();
  }

  // ── Data loading ────────────────────────────────────────────────────────

  Future<void> _loadFmb() async {
    setState(() {
      _loadingFmb = true;
      _fmbError = null;
    });
    try {
      _eligibleFmb =
          await ref.read(line1RepositoryProvider).listFmbForCalendering();
      setState(() => _loadingFmb = false);
    } catch (e) {
      setState(() {
        _fmbError = 'Failed to load FMB batches';
        _loadingFmb = false;
      });
    }
  }

  Future<void> _loadRuns() async {
    setState(() {
      _loadingRuns = true;
      _runsError = null;
    });
    try {
      _runs = await ref.read(line1RepositoryProvider).listCalenderingRuns();
      setState(() => _loadingRuns = false);
    } catch (e) {
      setState(() {
        _runsError = 'Failed to load runs';
        _loadingRuns = false;
      });
    }
  }

  Future<void> _loadRunDetail(String name) async {
    setState(() => _loadingRun = true);
    try {
      final run =
          await ref.read(line1RepositoryProvider).getCalenderingRun(name);
      setState(() {
        _activeRun = run;
        _loadingRun = false;
        _sheetEntries.clear();
        _rReturnCtrl.text = '0';
        _cReturnCtrl.text = '0';
      });
    } catch (e) {
      setState(() => _loadingRun = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.danger,
        ));
      }
    }
  }

  // ── Actions ─────────────────────────────────────────────────────────────

  void _showStartRunDialog(CalenderingFmb fmb) {
    final qtyCtrl = TextEditingController(text: fmb.qty.toString());
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Start Calendering Run',
                style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fmb.itemName ?? fmb.itemCode,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('Batch: ${fmb.batchNo}'),
                    Text('Available: ${fmb.qty} Kg'),
                    _labStatusChip(fmb.labStatus),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: qtyCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Input Quantity (Kg)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Run'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: () async {
                final qty = double.tryParse(qtyCtrl.text);
                if (qty == null || qty <= 0) {
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                    content: Text('Enter a valid quantity'),
                    backgroundColor: AppTheme.danger,
                  ));
                  return;
                }
                Navigator.of(ctx).pop();
                await _startRun(fmb.batchNo, qty);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startRun(String fmbBatch, double qty) async {
    setState(() => _loadingRun = true);
    try {
      final result =
          await ref.read(line1RepositoryProvider).startCalenderingRun(
                fmbBatch: fmbBatch,
                inputQty: qty,
              );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Run ${result.name} started'),
          backgroundColor: AppTheme.success,
        ));
      }
      _tabCtrl.animateTo(1);
      await _loadFmb();
      await _loadRuns();
      await _loadRunDetail(result.name);
    } catch (e) {
      setState(() => _loadingRun = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.danger,
        ));
      }
    }
  }

  void _addSheetEntry() {
    setState(() {
      _sheetEntries.add(_SheetEntry());
    });
  }

  void _removeSheetEntry(int index) {
    setState(() {
      _sheetEntries[index].dispose();
      _sheetEntries.removeAt(index);
    });
  }

  double get _sheetTotal =>
      _sheetEntries.fold(0.0, (sum, e) => sum + (double.tryParse(e.qtyCtrl.text) ?? 0));

  double get _rReturn => double.tryParse(_rReturnCtrl.text) ?? 0;

  double get _cReturn => double.tryParse(_cReturnCtrl.text) ?? 0;

  double get _balance =>
      (_activeRun?.fmbInputQty ?? 0) - _sheetTotal - _rReturn - _cReturn;

  Future<void> _completeRun() async {
    if (_activeRun == null) return;

    if (_sheetEntries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Add at least one sheet output'),
        backgroundColor: AppTheme.danger,
      ));
      return;
    }

    for (int i = 0; i < _sheetEntries.length; i++) {
      final e = _sheetEntries[i];
      if (e.itemCodeCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Sheet ${i + 1}: Item code is required'),
          backgroundColor: AppTheme.danger,
        ));
        return;
      }
      final qty = double.tryParse(e.qtyCtrl.text);
      if (qty == null || qty <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Sheet ${i + 1}: Enter a valid quantity'),
          backgroundColor: AppTheme.danger,
        ));
        return;
      }
    }

    if (_balance.abs() > 0.5) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Quantity mismatch: ${_balance.toStringAsFixed(2)} Kg remaining'),
        backgroundColor: AppTheme.danger,
      ));
      return;
    }

    setState(() => _completing = true);
    try {
      final sheets = _sheetEntries.map((e) => {
            'item_code': e.itemCodeCtrl.text.trim(),
            'qty': double.tryParse(e.qtyCtrl.text) ?? 0,
            'thickness_mm': double.tryParse(e.thicknessCtrl.text) ?? 0,
            'width_in_mm': double.tryParse(e.widthCtrl.text) ?? 0,
            'length_in_mm': double.tryParse(e.lengthCtrl.text) ?? 0,
          }).toList();

      await ref.read(line1RepositoryProvider).completeCalenderingRun(
            name: _activeRun!.name,
            sheets: sheets,
            rReturnQty: _rReturn,
            cReturnQty: _cReturn,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Calendering run completed'),
          backgroundColor: AppTheme.success,
        ));
        setState(() => _activeRun = null);
        _loadRuns();
        _loadFmb();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.danger,
        ));
      }
    } finally {
      if (mounted) setState(() => _completing = false);
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_activeRun != null && _activeRun!.status == 'In Progress') {
      return PdtScaffold(
        title: 'Calendering Run',
        body: _loadingRun
            ? const Center(child: CircularProgressIndicator())
            : _buildRunDetail(),
      );
    }

    return PdtScaffold(
      title: widget.screen.label,
      body: Column(
        children: [
          TabBar(
            controller: _tabCtrl,
            labelColor: AppTheme.primary,
            tabs: const [
              Tab(text: 'New Run'),
              Tab(text: 'Runs'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildFmbList(),
                _buildRunsList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab 1: Eligible FMB batches ─────────────────────────────────────────

  Widget _buildFmbList() {
    if (_loadingFmb) return const Center(child: CircularProgressIndicator());
    if (_fmbError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_fmbError!, style: const TextStyle(color: AppTheme.danger)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadFmb, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_eligibleFmb.isEmpty) {
      return const Center(
        child: Text('No eligible FMB batches\n(need Pass or Conditional Pass)',
            textAlign: TextAlign.center),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFmb,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _eligibleFmb.length,
        itemBuilder: (context, index) {
          final fmb = _eligibleFmb[index];
          return Card(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppTheme.success,
                radius: 16,
                child: Icon(Icons.check, color: Colors.white, size: 18),
              ),
              title: Text(fmb.itemName ?? fmb.itemCode,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Batch: ${fmb.batchNo}'),
                  Text('Available: ${fmb.qty} Kg'),
                ],
              ),
              trailing: const Icon(Icons.play_arrow),
              isThreeLine: true,
              onTap: () => _showStartRunDialog(fmb),
            ),
          );
        },
      ),
    );
  }

  // ── Tab 2: Calendering runs list ────────────────────────────────────────

  Widget _buildRunsList() {
    if (_loadingRuns) return const Center(child: CircularProgressIndicator());
    if (_runsError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_runsError!, style: const TextStyle(color: AppTheme.danger)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadRuns, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_runs.isEmpty) {
      return const Center(child: Text('No calendering runs'));
    }

    return RefreshIndicator(
      onRefresh: _loadRuns,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _runs.length,
        itemBuilder: (context, index) {
          final run = _runs[index];
          final isActive = run.status == 'In Progress';
          return Card(
            color: isActive ? AppTheme.primary.withValues(alpha: 0.05) : null,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor:
                    isActive ? AppTheme.primary : AppTheme.success,
                radius: 16,
                child: Icon(
                  isActive ? Icons.sync : Icons.check,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              title: Text(run.name,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('FMB: ${run.fmbBatch}'),
                  Text('Input: ${run.fmbInputQty} Kg'),
                  if (run.status == 'Completed')
                    Text(
                        'Sheets: ${run.totalSheetOutputQty} Kg | C: ${run.cReturnQty} | R: ${run.rReturnQty}'),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _runStatusChip(run.status),
                  if (isActive) const Icon(Icons.chevron_right),
                ],
              ),
              isThreeLine: true,
              onTap: isActive ? () => _loadRunDetail(run.name) : null,
            ),
          );
        },
      ),
    );
  }

  // ── Run Detail (In Progress) ────────────────────────────────────────────

  Widget _buildRunDetail() {
    final run = _activeRun!;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _activeRun = null);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Back + header
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _activeRun = null),
              ),
              Expanded(
                child: Text(run.name,
                    style: Theme.of(context).textTheme.titleLarge),
              ),
              _runStatusChip(run.status),
            ],
          ),
          const SizedBox(height: 12),

          // FMB info card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('FMB Batch: ${run.fmbBatch}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('Item: ${run.itemName ?? run.fmbItem ?? ""}'),
                  Text('Input Qty: ${run.fmbInputQty} Kg'),
                  if (run.startTime != null) Text('Started: ${run.startTime}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Sheet outputs
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Sheet Outputs',
                  style: Theme.of(context).textTheme.titleMedium),
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Sheet'),
                onPressed: _addSheetEntry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (_sheetEntries.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text('No sheets added yet',
                      style: TextStyle(color: Colors.grey)),
                ),
              ),
            ),

          ..._sheetEntries.asMap().entries.map((entry) {
            final i = entry.key;
            final e = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text('Sheet ${i + 1}',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.delete,
                              color: AppTheme.danger, size: 20),
                          onPressed: () => _removeSheetEntry(i),
                        ),
                      ],
                    ),
                    TextField(
                      controller: e.itemCodeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Item Code',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: e.qtyCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Qty (Kg)',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: e.thicknessCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Thickness (mm)',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: e.widthCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Width (mm)',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: e.lengthCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Length (mm)',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 16),

          // Returns
          Text('Returns', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _rReturnCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'R-Return (Kg)',
                    helperText: 'Extruder residue (absorbed)',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _cReturnCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'C-Return (Kg)',
                    helperText: 'Reusable compound',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Balance indicator
          Card(
            color: _balance.abs() <= 0.5
                ? AppTheme.success.withValues(alpha: 0.1)
                : AppTheme.danger.withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Balance',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    '${_balance.toStringAsFixed(2)} Kg',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: _balance.abs() <= 0.5
                          ? AppTheme.success
                          : AppTheme.danger,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Summary row
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  _summaryRow('Input', run.fmbInputQty),
                  _summaryRow('Sheets', _sheetTotal),
                  _summaryRow('R-Return (absorbed)', _rReturn),
                  _summaryRow('C-Return (reusable)', _cReturn),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Complete button
          ElevatedButton.icon(
            icon: _completing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.check_circle),
            label: Text(_completing ? 'Completing...' : 'Complete Run'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.success,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed:
                _completing || _balance.abs() > 0.5 ? null : _completeRun,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Widgets ─────────────────────────────────────────────────────────────

  Widget _summaryRow(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text('${value.toStringAsFixed(2)} Kg',
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _labStatusChip(String status) {
    Color color;
    switch (status) {
      case 'Pass':
        color = AppTheme.success;
        break;
      case 'Conditional Pass':
        color = Colors.orange;
        break;
      default:
        color = Colors.grey;
    }
    return Chip(
      label: Text(status, style: const TextStyle(fontSize: 12)),
      backgroundColor: color.withValues(alpha: 0.15),
      side: BorderSide(color: color),
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _runStatusChip(String status) {
    final isActive = status == 'In Progress';
    return Chip(
      label: Text(status, style: const TextStyle(fontSize: 11)),
      backgroundColor: isActive
          ? AppTheme.primary.withValues(alpha: 0.15)
          : AppTheme.success.withValues(alpha: 0.15),
      side: BorderSide(color: isActive ? AppTheme.primary : AppTheme.success),
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _SheetEntry {
  final itemCodeCtrl = TextEditingController();
  final qtyCtrl = TextEditingController();
  final thicknessCtrl = TextEditingController();
  final widthCtrl = TextEditingController();
  final lengthCtrl = TextEditingController();

  void dispose() {
    itemCodeCtrl.dispose();
    qtyCtrl.dispose();
    thicknessCtrl.dispose();
    widthCtrl.dispose();
    lengthCtrl.dispose();
  }
}
