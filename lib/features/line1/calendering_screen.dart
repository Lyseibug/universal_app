import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/menu/menu_models.dart';
import '../../core/models/line1_models.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/pdt_scaffold.dart';
import '../../widgets/scan_input_field.dart';
import '../tool_requests/tool_request_repository.dart';
import 'line1_repository.dart';

class CalenderingScreen extends ConsumerStatefulWidget {
  final MenuScreen screen;
  const CalenderingScreen({required this.screen, super.key});

  @override
  ConsumerState<CalenderingScreen> createState() => _CalenderingScreenState();
}

enum _CompleteStep { sheets, rolls, returns }

class _CalenderingScreenState extends ConsumerState<CalenderingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  // ── New Run tab: pick a Work Order, then scan FMB batches already
  // delivered to Calendering WH ──
  List<WorkOrderSummary> _workOrders = [];
  WorkOrderSummary? _selectedWorkOrder;

  bool _loadingFmbInWh = true;
  String? _fmbInWhError;
  List<CalenderingFmb> _fmbInWh = [];

  final _scanCtrl = TextEditingController();
  final _scanFocus = FocusNode();
  bool _scanning = false;
  String? _scanError;
  FmbScanResult? _pendingScan;
  final _scanQtyCtrl = TextEditingController();
  bool _startingRun = false;

  // ── Active Runs tab ──
  bool _loadingRuns = true;
  String? _runsError;
  List<CalenderingRun> _runs = [];

  // ── Run Detail: scan-build (pre-wizard) + 3-step complete wizard ──
  CalenderingRun? _activeRun;
  bool _loadingRun = false;
  bool _inWizard = false;
  _CompleteStep _completeStep = _CompleteStep.sheets;

  final _addScanCtrl = TextEditingController();
  final _addScanFocus = FocusNode();
  bool _addScanning = false;
  String? _addScanError;
  FmbScanResult? _pendingAddScan;
  final _addScanQtyCtrl = TextEditingController();
  bool _addingBatch = false;

  // ── Sheets step ── item is fixed by the run's Work Order; only physical
  // sheet dimensions (qty/thickness/width/length) are recorded per row.
  final List<_SheetEntry> _sheetEntries = [];

  // ── Rolls step ──
  RollMatchResult? _rollMatch;
  bool _matchingRolls = false;
  String? _rollMatchError;

  // ── Returns step ──
  final _linerReturnCtrl = TextEditingController(text: '0');
  final _calendarReturnCtrl = TextEditingController(text: '0');
  final _excruderSludgeCtrl = TextEditingController(text: '0');
  bool _completing = false;

  // ── Roll stock (pooled Liner/Cylinder specs) ──
  List<RollStock> _rollStock = [];
  bool _loadingRollStock = false;
  String? _rollStockError;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadWorkOrders();
    _loadFmbInWh();
    _loadRuns();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _scanCtrl.dispose();
    _scanFocus.dispose();
    _scanQtyCtrl.dispose();
    _addScanCtrl.dispose();
    _addScanFocus.dispose();
    _addScanQtyCtrl.dispose();
    _linerReturnCtrl.dispose();
    _calendarReturnCtrl.dispose();
    _excruderSludgeCtrl.dispose();
    for (final e in _sheetEntries) {
      e.dispose();
    }
    super.dispose();
  }

  // ── Data loading ────────────────────────────────────────────────────────

  Future<void> _loadWorkOrders() async {
    try {
      final workOrders =
          await ref.read(line1RepositoryProvider).listCalenderingWorkOrders();
      if (mounted) setState(() => _workOrders = workOrders);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to load Work Orders: $e'),
          backgroundColor: AppTheme.danger,
        ));
      }
    }
  }

  Future<void> _loadFmbInWh() async {
    setState(() {
      _loadingFmbInWh = true;
      _fmbInWhError = null;
    });
    try {
      _fmbInWh = await ref.read(line1RepositoryProvider).listFmbInCalenderingWh();
      setState(() => _loadingFmbInWh = false);
    } catch (e) {
      setState(() {
        _fmbInWhError = 'Failed to load FMB in Calendering WH';
        _loadingFmbInWh = false;
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

  Future<void> _loadRollStock() async {
    setState(() {
      _loadingRollStock = true;
      _rollStockError = null;
    });
    try {
      _rollStock = await ref.read(line1RepositoryProvider).listRollStock();
      setState(() => _loadingRollStock = false);
    } catch (e) {
      setState(() {
        _rollStockError = 'Failed to load roll stock';
        _loadingRollStock = false;
      });
    }
  }

  Future<void> _loadRunDetail(String name, {required bool enterWizard}) async {
    setState(() => _loadingRun = true);
    _loadRollStock();
    try {
      final run = await ref.read(line1RepositoryProvider).getCalenderingRun(name);
      setState(() {
        _activeRun = run;
        _loadingRun = false;
        _inWizard = enterWizard;
        _completeStep = _CompleteStep.sheets;
        _rollMatch = null;
        _rollMatchError = null;
        for (final e in _sheetEntries) {
          e.dispose();
        }
        _sheetEntries.clear();
        _linerReturnCtrl.text = '0';
        _calendarReturnCtrl.text = '0';
        _excruderSludgeCtrl.text = '0';
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

  // ── Scan-to-start actions ──────────────────────────────────────────────

  void _onFmbScanned(String code) {
    final trimmed = code.trim();
    if (trimmed.isEmpty) return;
    _resolveFmbScan(trimmed);
  }

  Future<void> _resolveFmbScan(String batchNo) async {
    setState(() {
      _scanning = true;
      _scanError = null;
      _pendingScan = null;
    });
    try {
      final resolved =
          await ref.read(line1RepositoryProvider).resolveFmbScan(batchNo);
      setState(() {
        _pendingScan = resolved;
        _scanQtyCtrl.text = resolved.availableQty.toString();
        _scanning = false;
      });
    } catch (e) {
      setState(() {
        _scanError = 'Error: $e';
        _scanning = false;
      });
    }
  }

  void _cancelPendingScan() {
    setState(() {
      _pendingScan = null;
      _scanError = null;
      _scanCtrl.clear();
      _scanQtyCtrl.clear();
    });
  }

  Future<void> _confirmStartRun() async {
    if (_pendingScan == null || _selectedWorkOrder == null) return;
    final qty = double.tryParse(_scanQtyCtrl.text);
    if (qty == null || qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Enter a valid quantity'),
        backgroundColor: AppTheme.danger,
      ));
      return;
    }

    setState(() => _startingRun = true);
    try {
      final result =
          await ref.read(line1RepositoryProvider).startRunFromBatches([
        {'batch_no': _pendingScan!.batchNo, 'qty': qty},
      ], _selectedWorkOrder!.name);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Run ${result.name} started'),
          backgroundColor: AppTheme.success,
        ));
      }
      setState(() {
        _pendingScan = null;
        _scanCtrl.clear();
        _scanQtyCtrl.clear();
        _startingRun = false;
      });
      await _loadFmbInWh();
      await _loadRuns();
      await _loadRunDetail(result.name, enterWizard: false);
    } catch (e) {
      setState(() => _startingRun = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.danger,
        ));
      }
    }
  }

  // ── Scan-build actions (add more FMB batches to an already-started run) ─

  void _onAddScanned(String code) {
    final trimmed = code.trim();
    if (trimmed.isEmpty) return;
    _resolveAddScan(trimmed);
  }

  Future<void> _resolveAddScan(String batchNo) async {
    setState(() {
      _addScanning = true;
      _addScanError = null;
      _pendingAddScan = null;
    });
    try {
      final resolved =
          await ref.read(line1RepositoryProvider).resolveFmbScan(batchNo);
      if (resolved.item != _activeRun?.fmbItem) {
        setState(() {
          _addScanError =
              "Batch is item '${resolved.item}', but this run is for "
              "'${_activeRun?.fmbItem}' — can't mix FMB items";
          _addScanning = false;
        });
        return;
      }
      setState(() {
        _pendingAddScan = resolved;
        _addScanQtyCtrl.text = resolved.availableQty.toString();
        _addScanning = false;
      });
    } catch (e) {
      setState(() {
        _addScanError = 'Error: $e';
        _addScanning = false;
      });
    }
  }

  void _cancelPendingAddScan() {
    setState(() {
      _pendingAddScan = null;
      _addScanError = null;
      _addScanCtrl.clear();
      _addScanQtyCtrl.clear();
    });
  }

  Future<void> _confirmAddBatch() async {
    if (_pendingAddScan == null || _activeRun == null) return;
    final qty = double.tryParse(_addScanQtyCtrl.text);
    if (qty == null || qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Enter a valid quantity'),
        backgroundColor: AppTheme.danger,
      ));
      return;
    }

    setState(() => _addingBatch = true);
    try {
      await ref.read(line1RepositoryProvider).addFmbBatchToRun(
            runName: _activeRun!.name,
            batchNo: _pendingAddScan!.batchNo,
            qty: qty,
          );
      setState(() {
        _pendingAddScan = null;
        _addScanCtrl.clear();
        _addScanQtyCtrl.clear();
        _addingBatch = false;
      });
      await _loadRunDetail(_activeRun!.name, enterWizard: false);
    } catch (e) {
      setState(() => _addingBatch = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.danger,
        ));
      }
    }
  }

  void _proceedToWizard() {
    setState(() {
      _inWizard = true;
      _completeStep = _CompleteStep.sheets;
    });
  }

  // ── Sheets step actions ─────────────────────────────────────────────────

  void _addBlankSheetEntry() {
    setState(() => _sheetEntries.add(_SheetEntry()));
  }

  void _removeSheetEntry(int index) {
    setState(() {
      _sheetEntries[index].dispose();
      _sheetEntries.removeAt(index);
    });
  }

  bool _sheetsValid() {
    if (_sheetEntries.isEmpty) return false;
    for (final e in _sheetEntries) {
      final qty = double.tryParse(e.qtyCtrl.text);
      if (qty == null || qty <= 0) return false;
    }
    return true;
  }

  Future<void> _goToRollsStep() async {
    setState(() => _completeStep = _CompleteStep.rolls);
    await _matchRolls();
  }

  // ── Rolls step actions ─────────────────────────────────────────────────

  Future<void> _matchRolls() async {
    setState(() {
      _matchingRolls = true;
      _rollMatchError = null;
    });
    try {
      final payload = _sheetEntries
          .map((e) => {
                'width_in_mm': double.tryParse(e.widthCtrl.text) ?? 0,
                'length_in_mm': double.tryParse(e.lengthCtrl.text) ?? 0,
              })
          .toList();
      final result = await ref.read(line1RepositoryProvider).matchRolls(payload);
      setState(() {
        _rollMatch = result;
        _matchingRolls = false;
      });
    } catch (e) {
      setState(() {
        _rollMatchError = 'Error: $e';
        _matchingRolls = false;
      });
    }
  }

  bool _rollsValid() {
    if (_rollMatch == null || _rollMatch!.sheets.length < _sheetEntries.length) {
      return false;
    }
    if (_rollMatch!.shortfalls.isNotEmpty) return false;
    for (final s in _rollMatch!.sheets) {
      if (!s.liner.isMatched || !s.cylinder.isMatched) return false;
    }
    return true;
  }

  Future<void> _raiseShortfallMR(RollShortfall shortfall) async {
    final qtyCtrl =
        TextEditingController(text: shortfall.shortfallQty.toStringAsFixed(0));
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Raise Tool Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${shortfall.rollType}: ${shortfall.itemName ?? shortfall.itemCode}'),
            const SizedBox(height: 12),
            TextField(
              controller: qtyCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Quantity (Nos)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Raise')),
        ],
      ),
    );
    if (confirmed != true) return;

    final qty = int.tryParse(qtyCtrl.text) ?? shortfall.shortfallQty.round();
    try {
      final workstation =
          await ref.read(line1RepositoryProvider).getCalenderingWorkstation();
      if (workstation == null || workstation.isEmpty) {
        throw Exception('Calendering line has no Workstation configured');
      }

      final result = await ref.read(toolRequestRepositoryProvider).create(
        targetWorkstation: workstation,
        items: [
          {
            'tool_type': shortfall.rollType,
            'qty': qty,
            'width_in_mm': shortfall.width,
            'length_in_mm': shortfall.length,
          }
        ],
        remarks: 'Calendering roll shortfall for run ${_activeRun?.name}',
      );
      final reqName = result is Map ? (result['name'] ?? '') : '';
      if (reqName != '') {
        await ref.read(toolRequestRepositoryProvider).submit(reqName);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Tool Request $reqName raised — fulfill it, then Refresh'),
          backgroundColor: AppTheme.success,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.danger,
        ));
      }
    }
  }

  // ── Returns step ────────────────────────────────────────────────────────

  double get _sheetTotal =>
      _sheetEntries.fold(0.0, (sum, e) => sum + (double.tryParse(e.qtyCtrl.text) ?? 0));

  double get _linerReturn => double.tryParse(_linerReturnCtrl.text) ?? 0;

  double get _calendarReturn => double.tryParse(_calendarReturnCtrl.text) ?? 0;

  double get _excruderSludge => double.tryParse(_excruderSludgeCtrl.text) ?? 0;

  double get _balance =>
      (_activeRun?.fmbInputQty ?? 0) -
      _sheetTotal -
      _linerReturn -
      _calendarReturn -
      _excruderSludge;

  Future<void> _completeRun() async {
    if (_activeRun == null || _rollMatch == null) return;
    if (!_sheetsValid()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Add at least one valid sheet output'),
        backgroundColor: AppTheme.danger,
      ));
      return;
    }
    if (!_rollsValid()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Liner/Cylinder not fully matched — go back to the Rolls step'),
        backgroundColor: AppTheme.danger,
      ));
      return;
    }
    if (_balance.abs() > 0.5) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Quantity mismatch: ${_balance.toStringAsFixed(2)} Kg remaining'),
        backgroundColor: AppTheme.danger,
      ));
      return;
    }

    setState(() => _completing = true);
    try {
      // item_code is not sent — the produced item is fixed by the run's
      // Work Order and derived server-side. Liner/Cylinder are not sent
      // either — complete_run re-derives and claims the specific Tool
      // Master units server-side from width/length, rather than trusting a
      // client-supplied match.
      final sheets = _sheetEntries.map((e) {
        return {
          'qty': double.tryParse(e.qtyCtrl.text) ?? 0,
          'thickness_mm': double.tryParse(e.thicknessCtrl.text) ?? 0,
          'width_in_mm': double.tryParse(e.widthCtrl.text) ?? 0,
          'length_in_mm': double.tryParse(e.lengthCtrl.text) ?? 0,
        };
      }).toList();

      await ref.read(line1RepositoryProvider).completeCalenderingRun(
            name: _activeRun!.name,
            sheets: sheets,
            linerReturnQty: _linerReturn,
            calendarReturnQty: _calendarReturn,
            excruderSludgeQty: _excruderSludge,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Calendering run completed'),
          backgroundColor: AppTheme.success,
        ));
        setState(() {
          _activeRun = null;
          _inWizard = false;
        });
        _loadRuns();
        _loadFmbInWh();
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
        title: _inWizard ? 'Calendering Run' : 'Scan FMB Batches',
        body: _loadingRun
            ? const Center(child: CircularProgressIndicator())
            : PopScope(
                canPop: false,
                onPopInvokedWithResult: (didPop, _) {
                  if (!didPop) {
                    setState(() {
                      _activeRun = null;
                      _inWizard = false;
                    });
                  }
                },
                child: _inWizard ? _buildWizard() : _buildScanBuildView(),
              ),
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
                _buildScanToStartTab(),
                _buildRunsList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab 1: Scan FMB batch to start a run ────────────────────────────────

  Widget _buildScanToStartTab() {
    if (_selectedWorkOrder == null) {
      return _buildWorkOrderPicker();
    }
    return RefreshIndicator(
      onRefresh: _loadFmbInWh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSelectedWorkOrderCard(),
          const SizedBox(height: 12),
          ScanInputField(
            controller: _scanCtrl,
            focusNode: _scanFocus,
            labelText: 'Scan FMB Batch',
            hintText: 'Scan the FMB batch delivered to Calendering WH',
            onScanned: _onFmbScanned,
            onSubmitted: _onFmbScanned,
            autofocus: true,
          ),
          const SizedBox(height: 12),
          if (_scanning)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            ),
          if (_scanError != null)
            Card(
              color: AppTheme.dangerLight,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(_scanError!, style: const TextStyle(color: AppTheme.danger)),
              ),
            ),
          if (_pendingScan != null) _buildPendingScanCard(),
          const SizedBox(height: 16),
          Text('Available in Calendering WH', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (_loadingFmbInWh)
            const Center(child: CircularProgressIndicator())
          else if (_fmbInWhError != null)
            Text(_fmbInWhError!, style: const TextStyle(color: AppTheme.danger))
          else if (_fmbInWh.isEmpty)
            const Text(
              'No FMB batches delivered yet.\nRaise a "Calendering FMB" Material Request '
              'to have one moved from FMB Zone.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            )
          else
            ..._fmbInWh.map((b) => Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppTheme.success,
                      radius: 16,
                      child: Icon(Icons.check, color: Colors.white, size: 18),
                    ),
                    title: Text(b.itemName ?? b.itemCode,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Batch: ${b.batchNo}'),
                        Text('Available: ${b.qty} Kg'),
                        _labStatusChip(b.labStatus),
                      ],
                    ),
                    isThreeLine: true,
                    onTap: () {
                      _scanCtrl.text = b.batchNo;
                      _resolveFmbScan(b.batchNo);
                    },
                  ),
                )),
        ],
      ),
    );
  }

  Widget _buildWorkOrderPicker() {
    return RefreshIndicator(
      onRefresh: _loadWorkOrders,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Select a Work Order', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          const Text(
            'Pick which Work Order this run is producing sheets for. '
            'Scanned FMB batches must be a component of its BOM.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 12),
          if (_workOrders.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No open Work Orders for Calendering'),
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
      color: AppTheme.primary.withValues(alpha: 0.05),
      child: ListTile(
        dense: true,
        leading: const Icon(Icons.assignment, color: AppTheme.primary),
        title: Text(wo.itemName ?? wo.productionItem,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(wo.name),
        trailing: TextButton(
          onPressed: () => setState(() => _selectedWorkOrder = null),
          child: const Text('Change'),
        ),
      ),
    );
  }

  Widget _buildPendingScanCard() {
    final scan = _pendingScan!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(scan.itemName ?? scan.item, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Batch: ${scan.batchNo}'),
            Text('Available: ${scan.availableQty} Kg'),
            const SizedBox(height: 12),
            TextField(
              controller: _scanQtyCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Quantity to claim (Kg)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: _startingRun
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.play_arrow),
              label: Text(_startingRun ? 'Starting...' : 'Start Run'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: _startingRun ? null : _confirmStartRun,
            ),
            TextButton(
              onPressed: _startingRun ? null : _cancelPendingScan,
              child: const Text('Cancel'),
            ),
          ],
        ),
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
                  if (run.productionItemName != null || run.productionItem != null)
                    Text('Producing: ${run.productionItemName ?? run.productionItem}'),
                  Text('FMB: ${run.fmbBatch}'),
                  Text('Input: ${run.fmbInputQty} Kg'),
                  if (run.status == 'Completed')
                    Text(
                        'Sheets: ${run.totalSheetOutputQty} Kg | Calendar: ${run.calendarReturnQty} | Liner: ${run.linerReturnQty} | Sludge: ${run.excruderSludgeQty}'),
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
              onTap: isActive
                  ? () => _loadRunDetail(run.name, enterWizard: true)
                  : null,
            ),
          );
        },
      ),
    );
  }

  // ── Scan-build view: batches scanned so far, add more or proceed ───────

  Widget _buildScanBuildView() {
    final run = _activeRun!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => setState(() {
                _activeRun = null;
                _inWizard = false;
              }),
            ),
            Expanded(
              child: Text(run.name, style: Theme.of(context).textTheme.titleLarge),
            ),
            _runStatusChip(run.status),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Producing: ${run.productionItemName ?? run.productionItem ?? ""}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('FMB Compound: ${run.itemName ?? run.fmbItem ?? ""}'),
                Text('Claimed so far: ${run.fmbInputQty} Kg'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text('Scanned Batches', style: Theme.of(context).textTheme.titleMedium),
        ...run.fmbSources.map((s) => Card(
              margin: const EdgeInsets.only(top: 4),
              child: ListTile(
                dense: true,
                leading: const Icon(Icons.qr_code, size: 18),
                title: Text(s.batchNo),
                trailing: Text('${s.qty} Kg'),
              ),
            )),
        const SizedBox(height: 16),
        ScanInputField(
          controller: _addScanCtrl,
          focusNode: _addScanFocus,
          labelText: 'Scan another FMB batch (optional)',
          hintText: 'Scan to add more input to this run',
          onScanned: _onAddScanned,
          onSubmitted: _onAddScanned,
        ),
        const SizedBox(height: 8),
        if (_addScanning)
          const Center(
            child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()),
          ),
        if (_addScanError != null)
          Card(
            color: AppTheme.dangerLight,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(_addScanError!, style: const TextStyle(color: AppTheme.danger)),
            ),
          ),
        if (_pendingAddScan != null) _buildPendingAddScanCard(),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          icon: const Icon(Icons.arrow_forward),
          label: const Text('Proceed to Sheets'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.success,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(48),
          ),
          onPressed: _proceedToWizard,
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildPendingAddScanCard() {
    final scan = _pendingAddScan!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(scan.itemName ?? scan.item, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Batch: ${scan.batchNo}'),
            Text('Available: ${scan.availableQty} Kg'),
            const SizedBox(height: 12),
            TextField(
              controller: _addScanQtyCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Quantity to claim (Kg)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: _addingBatch
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.add),
              label: Text(_addingBatch ? 'Adding...' : 'Add Batch'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: _addingBatch ? null : _confirmAddBatch,
            ),
            TextButton(
              onPressed: _addingBatch ? null : _cancelPendingAddScan,
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Complete-run wizard ─────────────────────────────────────────────────

  Widget _buildWizard() {
    return Column(
      children: [
        _buildStepIndicator(),
        Expanded(
          child: switch (_completeStep) {
            _CompleteStep.sheets => _buildSheetsStep(),
            _CompleteStep.rolls => _buildRollsStep(),
            _CompleteStep.returns => _buildReturnsStep(),
          },
        ),
      ],
    );
  }

  Widget _buildStepIndicator() {
    Widget chip(String label, _CompleteStep step) {
      final active = _completeStep == step;
      return Chip(
        label: Text(label,
            style: TextStyle(fontSize: 11, color: active ? Colors.white : null)),
        backgroundColor: active ? AppTheme.primary : AppTheme.bgElevated,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: EdgeInsets.zero,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          chip('1. Sheets', _CompleteStep.sheets),
          const Icon(Icons.chevron_right, size: 16, color: AppTheme.textSecondary),
          chip('2. Rolls', _CompleteStep.rolls),
          const Icon(Icons.chevron_right, size: 16, color: AppTheme.textSecondary),
          chip('3. Returns', _CompleteStep.returns),
        ],
      ),
    );
  }

  // ── Step 1: Sheets ──────────────────────────────────────────────────────

  Widget _buildSheetsStep() {
    final run = _activeRun!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => setState(() {
                _activeRun = null;
                _inWizard = false;
              }),
            ),
            Expanded(
              child: Text(run.name, style: Theme.of(context).textTheme.titleLarge),
            ),
            _runStatusChip(run.status),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Producing: ${run.productionItemName ?? run.productionItem ?? ""}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('FMB Compound: ${run.itemName ?? run.fmbItem ?? ""}'),
                Text('Input Qty: ${run.fmbInputQty} Kg'),
                ...run.fmbSources.map((s) => Text(
                      '  • ${s.batchNo}: ${s.qty} Kg',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    )),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildRollStockPanel(),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Sheet Outputs', style: Theme.of(context).textTheme.titleMedium),
            ElevatedButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Sheet'),
              onPressed: _addBlankSheetEntry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                child: Text('No sheets added yet', style: TextStyle(color: Colors.grey)),
              ),
            ),
          ),
        ..._sheetEntries.asMap().entries.map((entry) => _buildSheetCard(entry.key, entry.value)),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          icon: const Icon(Icons.arrow_forward),
          label: const Text('Next: Liner & Cylinder'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.success,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(48),
          ),
          onPressed: _sheetsValid() ? _goToRollsStep : null,
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSheetCard(int i, _SheetEntry e) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Sheet ${i + 1}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: AppTheme.danger, size: 20),
                  onPressed: () => _removeSheetEntry(i),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: e.qtyCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Width (mm)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: e.lengthCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Length (mm)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRollStockPanel() {
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.album_outlined),
        title: const Text('Roll Stock',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(
          _rollStockError ?? 'Store / staged in WIP Calendering / in use',
          style: TextStyle(
            fontSize: 12,
            color: _rollStockError != null ? AppTheme.danger : Colors.grey[600],
          ),
        ),
        children: [
          if (_loadingRollStock)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_rollStock.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No roll specs found', style: TextStyle(color: Colors.grey)),
            )
          else
            ..._rollStock.map((r) => ListTile(
                  dense: true,
                  title: Text(r.itemName ?? r.itemCode),
                  subtitle: Text(r.rollType),
                  trailing: Text(
                    '${r.stagedQty.toStringAsFixed(0)} staged / '
                    '${r.availableQty.toStringAsFixed(0)} store',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: r.stagedQty > 0 ? AppTheme.success : AppTheme.danger,
                    ),
                  ),
                )),
          TextButton.icon(
            onPressed: _loadingRollStock ? null : _loadRollStock,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  // ── Step 2: Liner & Cylinder ─────────────────────────────────────────────

  Widget _buildRollsStep() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => setState(() => _completeStep = _CompleteStep.sheets),
            ),
            Expanded(
              child: Text('Liner & Cylinder', style: Theme.of(context).textTheme.titleLarge),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _matchingRolls ? null : _matchRolls,
            ),
          ],
        ),
        if (_matchingRolls)
          const Center(
            child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()),
          ),
        if (_rollMatchError != null)
          Card(
            color: AppTheme.dangerLight,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(_rollMatchError!, style: const TextStyle(color: AppTheme.danger)),
            ),
          ),
        if (_rollMatch != null)
          ..._sheetEntries.asMap().entries.map((entry) {
            final i = entry.key;
            final match = i < _rollMatch!.sheets.length
                ? _rollMatch!.sheets[i]
                : const SheetRollMatch();
            return _buildRollMatchCard(i, entry.value, match);
          }),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => setState(() => _completeStep = _CompleteStep.sheets),
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.success,
                  foregroundColor: Colors.white,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _rollsValid()
                    ? () => setState(() => _completeStep = _CompleteStep.returns)
                    : null,
                child: const Text('Next: Returns'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildRollMatchCard(int i, _SheetEntry e, SheetRollMatch match) {
    final shortfallItems = (_rollMatch?.shortfalls ?? const [])
        .map((s) => s.itemCode)
        .toSet();

    Widget rollTile(String label, RollMatch m) {
      if (!m.isMatched) {
        return ListTile(
          dense: true,
          leading: const Icon(Icons.error, color: AppTheme.danger),
          title: Text('$label: no matching spec'),
          subtitle: const Text('No roll wide/long enough exists', style: TextStyle(fontSize: 11)),
        );
      }
      final short = shortfallItems.contains(m.itemCode);
      return ListTile(
        dense: true,
        leading: Icon(
          short ? Icons.warning : Icons.check_circle,
          color: short ? AppTheme.warning : AppTheme.success,
        ),
        title: Text('$label: ${m.itemName ?? m.itemCode}'),
        subtitle: short
            ? const Text('Insufficient staged stock',
                style: TextStyle(fontSize: 11, color: AppTheme.warning))
            : Text('${m.availableQty.toStringAsFixed(0)} staged',
                style: const TextStyle(fontSize: 11)),
        trailing: short
            ? TextButton(
                onPressed: () => _raiseShortfallMR(
                  _rollMatch!.shortfalls.firstWhere((s) => s.itemCode == m.itemCode),
                ),
                child: const Text('Raise Tool Request', style: TextStyle(fontSize: 11)),
              )
            : null,
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Sheet ${i + 1}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            rollTile('Liner', match.liner),
            rollTile('Cylinder', match.cylinder),
          ],
        ),
      ),
    );
  }

  // ── Step 3: Returns ──────────────────────────────────────────────────────

  Widget _buildReturnsStep() {
    final run = _activeRun!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => setState(() => _completeStep = _CompleteStep.rolls),
            ),
            Expanded(
              child: Text('Returns', style: Theme.of(context).textTheme.titleLarge),
            ),
            _runStatusChip(run.status),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _linerReturnCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Liner Return (Kg)',
                  helperText: 'Reusable — new batch',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _calendarReturnCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Calendar Return (Kg)',
                  helperText: 'Reusable — new batch',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _excruderSludgeCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Excruder Sludge (Kg)',
            helperText: 'Cleaned out, scrapped — cost absorbed, no batch',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        Card(
          color: _balance.abs() <= 0.5
              ? AppTheme.success.withValues(alpha: 0.1)
              : AppTheme.danger.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Balance', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  '${_balance.toStringAsFixed(2)} Kg',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: _balance.abs() <= 0.5 ? AppTheme.success : AppTheme.danger,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _summaryRow('Input', run.fmbInputQty),
                _summaryRow('Sheets', _sheetTotal),
                _summaryRow('Liner Return (reusable)', _linerReturn),
                _summaryRow('Calendar Return (reusable)', _calendarReturn),
                _summaryRow('Excruder Sludge (absorbed)', _excruderSludge),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          icon: _completing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.check_circle),
          label: Text(_completing ? 'Completing...' : 'Complete Run'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.success,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(48),
          ),
          onPressed: _completing || _balance.abs() > 0.5 ? null : _completeRun,
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  // ── Shared widgets ──────────────────────────────────────────────────────

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
  final qtyCtrl = TextEditingController();
  final thicknessCtrl = TextEditingController();
  final widthCtrl = TextEditingController();
  final lengthCtrl = TextEditingController();

  void dispose() {
    qtyCtrl.dispose();
    thicknessCtrl.dispose();
    widthCtrl.dispose();
    lengthCtrl.dispose();
  }
}
