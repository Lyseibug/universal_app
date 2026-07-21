import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/menu/menu_models.dart';
import '../../core/models/tool_request_models.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/service_providers.dart';
import '../../widgets/pdt_scaffold.dart';
import '../../widgets/scan_input_field.dart';
import '../tool_requests/tool_requests_screen.dart';
import 'line2_repository.dart';
import 'widgets/production_station_layout.dart';

class SleeveBuildingScreen extends ConsumerStatefulWidget {
  final MenuScreen screen;
  /// Pre-resolved scan_flowchart payload — used by Active Jobs' "resume"
  /// action to open this screen already loaded on an in-progress job,
  /// without requiring a fresh barcode scan.
  final Map<String, dynamic>? resumeJob;
  const SleeveBuildingScreen({required this.screen, this.resumeJob, super.key});

  @override
  ConsumerState<SleeveBuildingScreen> createState() =>
      _SleeveBuildingScreenState();
}

class _SleeveBuildingScreenState extends ConsumerState<SleeveBuildingScreen> {
  final _flowchartCtrl = TextEditingController();
  final _flowchartFocus = FocusNode();

  bool _scanning = false;
  bool _assigningTool = false;
  bool _completing = false;
  bool _returningToStore = false;
  String? _error;

  Map<String, dynamic>? _scanResult;
  bool _moldAssigned = false;
  String? _assignedToolId;
  DateTime? _timerStart;

  // Workstation
  List<String> _workstations = [];
  List<String> _assignedStations = [];
  String? _selectedWorkstation;

  bool _loadingStaged = false;
  List<StagedTool> _stagedMolds = [];

  @override
  void initState() {
    super.initState();
    _loadWorkerStations().then((_) {
      if (widget.resumeJob != null && mounted) {
        final data = widget.resumeJob!;
        setState(() {
          _scanResult = data;
          _timerStart = _timerStartFromScan(data);
        });
        _loadStagedMolds();
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
    super.dispose();
  }

  Future<void> _loadWorkerStations() async {
    try {
      final stations = await ref.read(line2RepositoryProvider).getWorkerStations();
      if (stations.isNotEmpty && mounted) {
        final all = <String>[];
        for (final s in stations) {
          final ws = s['workstations'];
          if (ws is List) all.addAll(ws.map((w) => w.toString()));
        }
        final buildingStations = all.where((w) => w.contains('B')).toList();
        setState(() {
          _assignedStations = all;
          _workstations = buildingStations.isNotEmpty ? buildingStations : all;
          if (_workstations.isNotEmpty) _selectedWorkstation = _workstations.first;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadStagedMolds() async {
    if (_selectedWorkstation == null) return;
    setState(() => _loadingStaged = true);
    try {
      final staged = await ref.read(line2RepositoryProvider).listStagedTools(
            toolType: 'Mold',
            workstation: _selectedWorkstation!,
          );
      if (mounted) setState(() => _stagedMolds = staged);
    } catch (_) {
      if (mounted) setState(() => _stagedMolds = []);
    } finally {
      if (mounted) setState(() => _loadingStaged = false);
    }
  }

  Future<void> _onFlowchartScanned(String barcode) async {
    final trimmed = barcode.trim();
    if (trimmed.isEmpty) return;

    setState(() {
      _scanning = true;
      _error = null;
      _scanResult = null;
      _moldAssigned = false;
      _assignedToolId = null;
      _timerStart = null;
    });

    try {
      final data = await ref.read(line2RepositoryProvider).scanFlowchart(trimmed);
      setState(() {
        _scanResult = data;
        _scanning = false;
        _timerStart = _timerStartFromScan(data);
      });
      await _loadStagedMolds();
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
  Future<void> _onMoldSelected(String toolId) async {
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
        _moldAssigned = true;
        _assignedToolId = toolId;
        _assigningTool = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Mold assigned successfully'),
          backgroundColor: AppTheme.success,
        ));
      }
    } catch (e) {
      setState(() {
        _error = 'Tool assignment failed: $e';
        _assigningTool = false;
      });
    }
  }

  Future<void> _finishStep() async {
    setState(() => _completing = true);
    try {
      await ref.read(line2RepositoryProvider).completeStep(
            jobCard: _scanResult!['job_card']?.toString() ?? '',
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_selectedWorkstation != null
              ? 'Sleeve building step completed - mold staged at $_selectedWorkstation'
              : 'Sleeve building step completed - mold staged'),
          backgroundColor: AppTheme.success,
        ));
        final toolId = _assignedToolId;
        _resetForm();
        setState(() => _assignedToolId = toolId);
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

  Future<void> _returnToolToStore() async {
    if (_assignedToolId == null) return;
    setState(() => _returningToStore = true);
    try {
      await ref.read(line2RepositoryProvider).returnToolToStore(toolId: _assignedToolId!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Mold returned to store'), backgroundColor: AppTheme.success));
        setState(() => _assignedToolId = null);
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
    setState(() {
      _scanResult = null;
      _moldAssigned = false;
      _assignedToolId = null;
      _stagedMolds = [];
      _error = null;
      _timerStart = null;
      _flowchartCtrl.clear();
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select Mold (Staged here)',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textSecondary)),
        const SizedBox(height: 8),
        if (_loadingStaged)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(),
          )
        else if (_moldAssigned)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: AppTheme.success, size: 20),
                const SizedBox(width: 8),
                Text('Mold assigned: ${_assignedToolId ?? ''}',
                    style: const TextStyle(color: AppTheme.success, fontWeight: FontWeight.w600)),
              ],
            ),
          )
        else if (_stagedMolds.isEmpty)
          Card(
            color: AppTheme.warningLight,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('No molds staged at this workstation.',
                      style: TextStyle(color: AppTheme.warning, fontWeight: FontWeight.w600)),
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
              children: _stagedMolds
                  .map((t) => ListTile(
                        dense: true,
                        leading: const Icon(Icons.category_outlined),
                        title: Text(t.toolCode),
                        subtitle: t.toolName != null ? Text(t.toolName!) : null,
                        onTap: _assigningTool ? null : () => _onMoldSelected(t.toolCode),
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

  @override
  Widget build(BuildContext context) {
    // Post-completion state: job scan cleared, but a just-used tool is still
    // known and can be manually returned to the store.
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
                  leading: const Icon(Icons.category_outlined, color: AppTheme.success),
                  title: Text('Mold $_assignedToolId'),
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

    return PdtScaffold(
      title: widget.screen.label,
      body: ProductionStationLayout(
        title: widget.screen.label,
        availableWorkstations: _workstations,
        selectedWorkstation: _selectedWorkstation,
        onWorkstationChanged: (ws) {
          setState(() => _selectedWorkstation = ws);
          _loadStagedMolds();
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
        onFinish: _moldAssigned ? _finishStep : null,
        onBack: _resetForm,
        finishing: _completing,
        error: _error,
        onDismissError: () => setState(() => _error = null),
      ),
    );
  }
}
