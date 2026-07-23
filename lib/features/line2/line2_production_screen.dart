import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_exceptions.dart';
import '../../core/errors/error_mapper.dart';
import '../../core/menu/menu_models.dart';
import '../../core/models/tool_request_models.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/service_providers.dart';
import '../../widgets/pdt_scaffold.dart';
import '../../widgets/scan_input_field.dart';
import '../tool_requests/tool_requests_screen.dart';
import 'line2_repository.dart';
import 'widgets/production_station_layout.dart';

/// Metadata for a tool-capable flowchart step (Building needs a Mold, Curing
/// needs an Airbag). Every other step uses the measurement/scrap form below.
class _ToolStepInfo {
  final String toolType;
  final IconData icon;
  const _ToolStepInfo(this.toolType, this.icon);
}

const _toolSteps = {
  'BUILDING': _ToolStepInfo('Mold', Icons.category_outlined),
  'CURING': _ToolStepInfo('Airbag', Icons.sports_motorsports_outlined),
};

/// Steps where pieces are physically lost and must be recorded as scrap
/// with a reason code — see line2_building.complete_step.
const _scrapCapableSteps = {'CUTTING', 'RIB_GRINDING', 'TWO_PIECE_CUTTING'};

/// One screen for the whole Sleeve-Building-through-Processing run
/// (Building, Curing, Grinding, Cutting, Rib Grinding). Which input form it
/// shows is entirely driven by the scanned flowchart's current_step —
/// there's no station-type screen to pick, the operator scans and the
/// screen adapts. Backing PDT Screens (line2_building/line2_curing/
/// line2_processing) still gate independently (see api/line2.py
/// STEP_TO_SCREEN + PDT Settings.line2_step_roles) — this only unifies the
/// UI, not the permission model.
///
/// Passing [_selectedWorkstation] into scan_flowchart is what makes the
/// backend's existing "this station doesn't run this step" check actually
/// fire — see line2_building._find_or_create_job_card. A mismatch comes
/// back as a normal scan error, so no input form ever renders for it.
class Line2ProductionScreen extends ConsumerStatefulWidget {
  final MenuScreen screen;
  /// Pre-resolved scan_flowchart payload — used by Active Jobs' "resume"
  /// action to open this screen already loaded on an in-progress job,
  /// without requiring a fresh barcode scan.
  final Map<String, dynamic>? resumeJob;
  const Line2ProductionScreen({required this.screen, this.resumeJob, super.key});

  @override
  ConsumerState<Line2ProductionScreen> createState() => _Line2ProductionScreenState();
}

class _Line2ProductionScreenState extends ConsumerState<Line2ProductionScreen> {
  final _flowchartCtrl = TextEditingController();
  final _flowchartFocus = FocusNode();
  final _processScrapQtyCtrl = TextEditingController();
  final _rejectionQtyCtrl = TextEditingController();

  bool _scanning = false;
  bool _assigningTool = false;
  bool _completing = false;
  bool _returningToStore = false;
  String? _error;

  Map<String, dynamic>? _scanResult;
  bool _toolAssigned = false;
  String? _assignedToolId;
  DateTime? _timerStart;

  List<String> _workstations = [];
  List<String> _assignedStations = [];
  String? _selectedWorkstation;

  bool _loadingStaged = false;
  List<StagedTool> _stagedTools = [];

  List<_MeasurementField> _measurements = [];
  /// Every reason code available for this production type, each tagged
  /// with a scrap_category ('Process Scrap' = routine/expected station
  /// loss, e.g. trim waste; 'Rejection' = a quality defect). Physically
  /// both end up in the same scrap warehouse — the split is purely so the
  /// operator (and later, reporting) can tell them apart.
  List<Map<String, dynamic>> _reasonCodes = [];
  String? _selectedProcessScrapReason;
  String? _selectedRejectionReason;
  /// Added scrap rows for this completion — {'reason_code', 'description',
  /// 'qty', 'category'}. Multiple pieces can be scrapped for different
  /// reasons, across both categories, in one step completion.
  final List<Map<String, dynamic>> _scrapEntries = [];

  List<Map<String, dynamic>> get _processScrapCodes =>
      _reasonCodes.where((r) => r['scrap_category']?.toString() == 'Process Scrap').toList();
  List<Map<String, dynamic>> get _rejectionCodes =>
      _reasonCodes.where((r) => r['scrap_category']?.toString() != 'Process Scrap').toList();
  List<Map<String, dynamic>> get _processScrapEntries =>
      _scrapEntries.where((e) => e['category'] == 'Process Scrap').toList();
  List<Map<String, dynamic>> get _rejectionEntries =>
      _scrapEntries.where((e) => e['category'] != 'Process Scrap').toList();

  String? get _currentStep => _scanResult?['current_step']?.toString();
  _ToolStepInfo? get _toolStepInfo => _toolSteps[_currentStep];
  bool get _isScrapCapableStep => _scrapCapableSteps.contains(_currentStep);

  @override
  void initState() {
    super.initState();
    _loadWorkerStations().then((_) async {
      if (widget.resumeJob != null && mounted) {
        _applyScanResult(widget.resumeJob!);
        await _afterScanLoaded(widget.resumeJob!);
      }
    });
  }

  DateTime _timerStartFromScan(Map<String, dynamic> scan) {
    final elapsed = (scan['elapsed_seconds'] as num?)?.toInt() ?? 0;
    return DateTime.now().subtract(Duration(seconds: elapsed));
  }

  @override
  void dispose() {
    _flowchartCtrl.dispose();
    _flowchartFocus.dispose();
    _processScrapQtyCtrl.dispose();
    _rejectionQtyCtrl.dispose();
    for (final m in _measurements) {
      m.dispose();
    }
    super.dispose();
  }

  Future<void> _loadWorkerStations() async {
    try {
      final stations = await ref
          .read(line2RepositoryProvider)
          .getWorkerStations(screenKey: widget.screen.screenKey);
      if (stations.isNotEmpty && mounted) {
        final all = <String>[];
        for (final s in stations) {
          final ws = s['workstations'];
          if (ws is List) all.addAll(ws.map((w) => w.toString()));
        }
        setState(() {
          _assignedStations = all;
          _workstations = all;
          if (_workstations.isNotEmpty) _selectedWorkstation = _workstations.first;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadStagedTools() async {
    final toolInfo = _toolStepInfo;
    if (toolInfo == null || _selectedWorkstation == null) return;
    setState(() => _loadingStaged = true);
    try {
      final staged = await ref.read(line2RepositoryProvider).listStagedTools(
            toolType: toolInfo.toolType,
            workstation: _selectedWorkstation!,
          );
      if (mounted) setState(() => _stagedTools = staged);
    } catch (_) {
      if (mounted) setState(() => _stagedTools = []);
    } finally {
      if (mounted) setState(() => _loadingStaged = false);
    }
  }

  Future<void> _loadReasonCodesIfNeeded(Map<String, dynamic> scan) async {
    if (!_scrapCapableSteps.contains(scan['current_step']?.toString())) return;
    final productionType = scan['production_type']?.toString();
    if (productionType == null || productionType.isEmpty) return;
    try {
      final codes = await ref.read(line2RepositoryProvider).getRejectionCodes(productionType);
      if (mounted) setState(() => _reasonCodes = codes);
    } catch (_) {
      // Non-critical — scrap qty entry without a reason will be rejected
      // server-side with a clear error rather than silently failing here.
    }
  }

  List<_MeasurementField> _parseMeasurementFields(Map<String, dynamic> scan) {
    final params = scan['measurement_params'];
    if (params is! List) return [];
    return params.map((p) {
      final param = Map<String, dynamic>.from(p);
      return _MeasurementField(
        name: param['param_name']?.toString() ?? param['name']?.toString() ?? '',
        code: param['param_code']?.toString() ?? '',
        unit: param['uom']?.toString() ?? '',
        expectedMin: (param['expected_min'] as num?)?.toDouble() ?? 0,
        expectedMax: (param['expected_max'] as num?)?.toDouble() ?? 0,
        isMandatory: (param['is_mandatory'] ?? 0) == 1,
      );
    }).toList();
  }

  void _applyScanResult(Map<String, dynamic> data) {
    setState(() {
      _scanResult = data;
      _measurements = _parseMeasurementFields(data);
      _timerStart = _timerStartFromScan(data);
    });
  }

  Future<void> _afterScanLoaded(Map<String, dynamic> data) async {
    await _loadStagedTools();
    await _loadReasonCodesIfNeeded(data);
  }

  Future<void> _onFlowchartScanned(String barcode) async {
    final trimmed = barcode.trim();
    if (trimmed.isEmpty) return;

    for (final m in _measurements) {
      m.dispose();
    }

    setState(() {
      _scanning = true;
      _error = null;
      _scanResult = null;
      _measurements = [];
      _toolAssigned = false;
      _assignedToolId = null;
      _timerStart = null;
      _reasonCodes = [];
      _selectedProcessScrapReason = null;
      _selectedRejectionReason = null;
      _processScrapQtyCtrl.clear();
      _rejectionQtyCtrl.clear();
      _scrapEntries.clear();
    });

    try {
      // Passing the operator's selected station lets the server reject a
      // scan whose current step doesn't actually run there, instead of
      // silently opening the Job Card somewhere else.
      final data = await ref.read(line2RepositoryProvider).scanFlowchart(
            trimmed,
            workstation: _selectedWorkstation,
          );
      _applyScanResult(data);
      setState(() => _scanning = false);
      await _afterScanLoaded(data);
    } on ApiException catch (e) {
      setState(() {
        _error = messageFor(e);
        _scanning = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Scan failed: $e';
        _scanning = false;
      });
    }
  }

  /// Operator selects from the Staged list — not a blind scan of any
  /// barcode in the system. A tool must already be staged at this
  /// workstation (via a fulfilled Tool Request) before it can be used.
  Future<void> _onToolSelected(String toolId) async {
    setState(() {
      _assigningTool = true;
      _error = null;
    });

    try {
      await ref.read(line2RepositoryProvider).assignTool(
            toolId: toolId,
            jobCard: _scanResult!['job_card']?.toString() ?? '',
          );
      setState(() {
        _toolAssigned = true;
        _assignedToolId = toolId;
        _assigningTool = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${_toolStepInfo?.toolType ?? 'Tool'} assigned successfully'),
          backgroundColor: AppTheme.success,
        ));
      }
    } on ApiException catch (e) {
      setState(() {
        _error = messageFor(e);
        _assigningTool = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Tool assignment failed: $e';
        _assigningTool = false;
      });
    }
  }

  Future<void> _completeStep() async {
    for (final m in _measurements) {
      final val = m.controller.text.trim();
      if (m.isMandatory && val.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Please fill in "${m.name}"'), backgroundColor: AppTheme.danger));
        return;
      }
      if (val.isNotEmpty && double.tryParse(val) == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('"${m.name}" must be a valid number'), backgroundColor: AppTheme.danger));
        return;
      }
    }

    // A qty/reason typed into an "add entry" row but never tapped + is
    // easy to lose silently — block instead of dropping it.
    if (_processScrapQtyCtrl.text.trim().isNotEmpty ||
        _selectedProcessScrapReason != null ||
        _rejectionQtyCtrl.text.trim().isNotEmpty ||
        _selectedRejectionReason != null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('You have an unsaved scrap/rejection entry — tap + to add it, or clear the fields'),
        backgroundColor: AppTheme.danger,
      ));
      return;
    }

    setState(() => _completing = true);
    try {
      final measurementData = _measurements
          .where((m) => m.controller.text.trim().isNotEmpty)
          .map((m) => {
                'parameter_name': m.name,
                'actual_value': double.tryParse(m.controller.text.trim()) ?? 0,
                'expected_min': m.expectedMin,
                'expected_max': m.expectedMax,
                'uom': m.unit,
              })
          .toList();

      await ref.read(line2RepositoryProvider).completeStep(
            jobCard: _scanResult!['job_card']?.toString() ?? '',
            measurements: measurementData,
            scrapEntries: _scrapEntries.isNotEmpty ? _scrapEntries : null,
          );

      if (mounted) {
        final stepName = _scanResult?['step_name']?.toString() ?? 'Step';
        final stationMsg = _toolStepInfo != null && _selectedWorkstation != null
            ? ' - ${_toolStepInfo!.toolType.toLowerCase()} staged at $_selectedWorkstation'
            : '';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$stepName completed$stationMsg'),
          backgroundColor: AppTheme.success,
        ));
        final toolId = _assignedToolId;
        _resetForm();
        setState(() => _assignedToolId = toolId);
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(messageFor(e)), backgroundColor: AppTheme.danger));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'), backgroundColor: AppTheme.danger));
      }
    } finally {
      if (mounted) setState(() => _completing = false);
    }
  }

  Future<void> _returnToolToStore() async {
    if (_assignedToolId == null) return;
    setState(() => _returningToStore = true);
    try {
      await ref.read(line2RepositoryProvider).returnToolToStore(toolId: _assignedToolId!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Tool returned to store'), backgroundColor: AppTheme.success));
        setState(() => _assignedToolId = null);
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(messageFor(e)), backgroundColor: AppTheme.danger));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'), backgroundColor: AppTheme.danger));
      }
    } finally {
      if (mounted) setState(() => _returningToStore = false);
    }
  }

  void _resetForm() {
    for (final m in _measurements) {
      m.dispose();
    }
    setState(() {
      _scanResult = null;
      _toolAssigned = false;
      _assignedToolId = null;
      _stagedTools = [];
      _measurements = [];
      _error = null;
      _timerStart = null;
      _flowchartCtrl.clear();
      _reasonCodes = [];
      _selectedProcessScrapReason = null;
      _selectedRejectionReason = null;
      _processScrapQtyCtrl.clear();
      _rejectionQtyCtrl.clear();
      _scrapEntries.clear();
    });
  }

  void _goToToolRequests() {
    final menuAsync = ref.read(menuProvider);
    MenuScreen? trScreen;
    menuAsync.whenData((menu) {
      if (menu == null) return;
      for (final mod in menu.menu) {
        for (final s in mod.screens) {
          if (s.screenKey == 'tool_requests') {
            trScreen = s;
            return;
          }
        }
      }
    });

    trScreen ??= const MenuScreen(
      screenKey: 'tool_requests',
      label: 'Tool Requests',
      route: '/tool-requests',
      apiModule: 'tool_requests',
      actions: ['create', 'fulfill'],
    );

    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ToolRequestsScreen(screen: trScreen!),
    ));
  }

  Widget _buildStepContent() {
    final toolInfo = _toolStepInfo;
    if (toolInfo != null) return _buildToolAssignmentContent(toolInfo);
    return _buildMeasurementScrapContent();
  }

  Widget _buildToolAssignmentContent(_ToolStepInfo toolInfo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select ${toolInfo.toolType} (Staged here)',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textSecondary)),
        const SizedBox(height: 8),
        if (_loadingStaged)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(),
          )
        else if (_toolAssigned)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: AppTheme.success, size: 20),
                const SizedBox(width: 8),
                Text('${toolInfo.toolType} assigned: ${_assignedToolId ?? ''}',
                    style: const TextStyle(color: AppTheme.success, fontWeight: FontWeight.w600)),
              ],
            ),
          )
        else if (_stagedTools.isEmpty)
          Card(
            color: AppTheme.warningLight,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('No ${toolInfo.toolType.toLowerCase()}s staged at this workstation.',
                      style: const TextStyle(color: AppTheme.warning, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _goToToolRequests,
                    child: const Text('Raise a Tool Request'),
                  ),
                ],
              ),
            ),
          )
        else
          Card(
            child: Column(
              children: _stagedTools
                  .map((t) => ListTile(
                        dense: true,
                        leading: Icon(toolInfo.icon),
                        title: Text(t.toolCode),
                        subtitle: t.toolName != null ? Text(t.toolName!) : null,
                        onTap: _assigningTool ? null : () => _onToolSelected(t.toolCode),
                      ))
                  .toList(),
            ),
          ),
        if (_assigningTool)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(),
          ),
        const SizedBox(height: 12),
      ],
    );
  }

  void _addScrapEntry({
    required String category,
    required TextEditingController qtyCtrl,
    required String? selectedReason,
    required List<Map<String, dynamic>> codes,
    required VoidCallback clearSelection,
  }) {
    final qty = double.tryParse(qtyCtrl.text.trim());
    if (qty == null || qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Enter a $category quantity greater than 0'), backgroundColor: AppTheme.danger));
      return;
    }
    if (selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Select a reason code for the $category'), backgroundColor: AppTheme.danger));
      return;
    }
    final reason = codes.firstWhere(
      (r) => r['code']?.toString() == selectedReason,
      orElse: () => {},
    );
    setState(() {
      _scrapEntries.add({
        'reason_code': selectedReason,
        'description': reason['description']?.toString() ?? '',
        'qty': qty,
        'category': category,
      });
      qtyCtrl.clear();
      clearSelection();
    });
  }

  Widget _buildScrapSection({
    required String title,
    required String category,
    required List<Map<String, dynamic>> codes,
    required List<Map<String, dynamic>> entries,
    required TextEditingController qtyCtrl,
    required String? selectedReason,
    required ValueChanged<String?> onReasonChanged,
    required VoidCallback onAdd,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(),
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary, letterSpacing: 1.0)),
          const SizedBox(height: 8),
          if (entries.isNotEmpty) ...[
            ...entries.map((entry) => Card(
                  margin: const EdgeInsets.only(bottom: 6),
                  child: ListTile(
                    dense: true,
                    title: Text('${entry['reason_code']} — ${entry['description'] ?? ''}',
                        style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${entry['qty']}',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          color: AppTheme.danger,
                          onPressed: () => setState(() => _scrapEntries.remove(entry)),
                        ),
                      ],
                    ),
                  ),
                )),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Total $title: ${entries.fold<double>(0, (sum, e) => sum + (e['qty'] as double))}',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 100,
                child: TextField(
                  controller: qtyCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Qty',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: selectedReason,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Reason',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: codes
                      .map((r) => DropdownMenuItem(
                            value: r['code']?.toString(),
                            child: Text('${r['code']} — ${r['description'] ?? ''}',
                                overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: onReasonChanged,
                ),
              ),
              const SizedBox(width: 4),
              IconButton.filled(
                icon: const Icon(Icons.add),
                onPressed: onAdd,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementScrapContent() {
    final stepName = _scanResult?['step_name']?.toString() ?? _currentStep ?? 'Processing';
    final qty = _scanResult?['qty'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step badge
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(stepName,
                  style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primary, fontSize: 13)),
            ),
            if (qty != null)
              Text('Qty at this station: $qty',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ],
        ),
        const SizedBox(height: 16),

        if (_measurements.isNotEmpty) ...[
          const Text('MEASUREMENTS',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary, letterSpacing: 1.0)),
          const SizedBox(height: 10),
          ..._measurements.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextField(
                  controller: m.controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: '${m.name}${m.isMandatory ? ' *' : ''}',
                    suffixText: m.unit,
                    helperText: m.expectedMin > 0 || m.expectedMax > 0
                        ? 'Range: ${m.expectedMin} - ${m.expectedMax} ${m.unit}'
                        : null,
                  ),
                ),
              )),
        ],

        if (_isScrapCapableStep) ...[
          const Text(
            'Process Scrap = routine/expected loss (e.g. trim waste). Rejection = a quality defect. '
            'Both are physically scrapped — recorded separately so they show up distinctly in reporting.',
            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          _buildScrapSection(
            title: 'Process Scrap',
            category: 'Process Scrap',
            codes: _processScrapCodes,
            entries: _processScrapEntries,
            qtyCtrl: _processScrapQtyCtrl,
            selectedReason: _selectedProcessScrapReason,
            onReasonChanged: (v) => setState(() => _selectedProcessScrapReason = v),
            onAdd: () => _addScrapEntry(
              category: 'Process Scrap',
              qtyCtrl: _processScrapQtyCtrl,
              selectedReason: _selectedProcessScrapReason,
              codes: _processScrapCodes,
              clearSelection: () => _selectedProcessScrapReason = null,
            ),
          ),
          _buildScrapSection(
            title: 'Rejection',
            category: 'Rejection',
            codes: _rejectionCodes,
            entries: _rejectionEntries,
            qtyCtrl: _rejectionQtyCtrl,
            selectedReason: _selectedRejectionReason,
            onReasonChanged: (v) => setState(() => _selectedRejectionReason = v),
            onAdd: () => _addScrapEntry(
              category: 'Rejection',
              qtyCtrl: _rejectionQtyCtrl,
              selectedReason: _selectedRejectionReason,
              codes: _rejectionCodes,
              clearSelection: () => _selectedRejectionReason = null,
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Post-completion state: job scan cleared, but a just-used tool (from a
    // Building/Curing step) is still known and can be manually returned to
    // the store. Processing steps never reach this — they have no tool.
    if (_scanResult == null && _assignedToolId != null) {
      return PdtScaffold(
        title: widget.screen.label,
        body: Padding(
          padding: const EdgeInsets.all(AppTheme.horizontalPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: ListTile(
                  leading: const Icon(Icons.build_outlined, color: AppTheme.success),
                  title: Text('Tool $_assignedToolId'),
                  subtitle: const Text('Staged here — scan the next flowchart, or return it'),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _returningToStore ? null : _returnToolToStore,
                icon: _returningToStore
                    ? const SizedBox(
                        width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.undo),
                label: const Text('Return to Store'),
              ),
              const SizedBox(height: 24),
              ScanInputField(
                controller: _flowchartCtrl,
                focusNode: _flowchartFocus,
                labelText: 'Scan Flowchart Barcode',
                hintText: 'Scan next job',
                onScanned: _onFlowchartScanned,
                onSubmitted: _onFlowchartScanned,
              ),
            ],
          ),
        ),
      );
    }

    // Tool-capable steps (Building/Curing) can't finish until a tool is
    // assigned; measurement/scrap steps can finish as soon as they're valid.
    final canFinish = _toolStepInfo != null ? _toolAssigned : true;

    return PdtScaffold(
      title: widget.screen.label,
      body: ProductionStationLayout(
        title: widget.screen.label,
        availableWorkstations: _workstations,
        selectedWorkstation: _selectedWorkstation,
        onWorkstationChanged: (ws) {
          // Switching stations mid-job doesn't make sense — the loaded scan
          // (Job Card, tool, timer, measurements) belongs to the *previous*
          // station. Clear back to the scan prompt instead of silently
          // leaving that station's in-progress form on screen under the
          // newly-selected station.
          final hadActiveScan = _scanResult != null;
          setState(() => _selectedWorkstation = ws);
          if (hadActiveScan) {
            _resetForm();
          } else {
            _loadStagedTools();
          }
        },
        assignedStations: _assignedStations,
        scanController: _flowchartCtrl,
        scanFocusNode: _flowchartFocus,
        onScanned: _onFlowchartScanned,
        scanning: _scanning,
        scanResult: _scanResult,
        stepContent: _scanResult != null ? _buildStepContent() : null,
        timerStartTime: _timerStart,
        targetMinutes: (_scanResult?['target_time_minutes'] as num?)?.toInt(),
        onFinish: canFinish ? _completeStep : null,
        onBack: _resetForm,
        finishing: _completing,
        finishLabel: _scanResult?['step_name']?.toString() != null
            ? 'Finish ${_scanResult!['step_name']}'
            : 'Complete Step',
        error: _error,
        onDismissError: () => setState(() => _error = null),
      ),
    );
  }
}

class _MeasurementField {
  final String name;
  final String code;
  final String unit;
  final double expectedMin;
  final double expectedMax;
  final bool isMandatory;
  final TextEditingController controller;

  _MeasurementField({
    required this.name,
    this.code = '',
    this.unit = '',
    this.expectedMin = 0,
    this.expectedMax = 0,
    this.isMandatory = false,
  }) : controller = TextEditingController();

  void dispose() {
    controller.dispose();
  }
}
