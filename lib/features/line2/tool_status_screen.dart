import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/menu/menu_models.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/service_providers.dart';
import '../../widgets/pdt_scaffold.dart';
import '../../widgets/status_chip.dart';
import 'line2_repository.dart';

class ToolStatusScreen extends ConsumerStatefulWidget {
  final MenuScreen screen;
  const ToolStatusScreen({required this.screen, super.key});

  @override
  ConsumerState<ToolStatusScreen> createState() => _ToolStatusScreenState();
}

class _ToolStatusScreenState extends ConsumerState<ToolStatusScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _tools = [];

  String? _filterType;
  String? _filterStatus;

  final List<String> _toolTypes = [
    'All',
    'Mold',
    'Airbag',
    'Grinding Wheel',
    'Curing Pot',
    'Liner',
    'Cylinder',
    'Other',
  ];
  final List<String> _statusOptions = [
    'All',
    'Available',
    'Staged',
    'In Use',
    'Under Maintenance',
    'Retired',
    'Pending Conversion',
  ];

  String? _returningToolId;

  @override
  void initState() {
    super.initState();
    _loadTools();
  }

  Future<void> _loadTools() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ref.read(apiClientProvider).call(
            'line2.get_tool_status',
            body: {
              if (_filterType != null) 'tool_type': _filterType,
              if (_filterStatus != null) 'status': _filterStatus,
            },
          );
      setState(() {
        _tools = (data is List)
            ? data.map((e) => Map<String, dynamic>.from(e)).toList()
            : <Map<String, dynamic>>[];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load tools';
        _loading = false;
      });
    }
  }

  void _showUpdateWeightDialog(Map<String, dynamic> tool) {
    final weightCtrl = TextEditingController();
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
            Text('Update Airbag Weight',
                style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(tool['tool_name']?.toString() ?? tool['tool_code']?.toString() ?? ''),
            const SizedBox(height: 16),
            TextField(
              controller: weightCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Weight (Kg)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: () async {
                final weight = double.tryParse(weightCtrl.text.trim());
                if (weight == null || weight <= 0) {
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                    content: Text('Enter a valid weight'),
                    backgroundColor: AppTheme.danger,
                  ));
                  return;
                }
                Navigator.pop(ctx);
                try {
                  await ref.read(line2RepositoryProvider).updateAirbagWeight(
                        toolId: tool['tool_code']?.toString() ?? '',
                        weightKg: weight,
                      );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Weight updated'),
                      backgroundColor: AppTheme.success,
                    ));
                    _loadTools();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: AppTheme.danger,
                    ));
                  }
                }
              },
              child: const Text('Update Weight'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PdtScaffold(
      title: widget.screen.label,
      body: Column(
        children: [
          // Filters
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _filterType ?? 'All',
                    decoration: const InputDecoration(
                      labelText: 'Type',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: _toolTypes
                        .map((t) =>
                            DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) {
                      setState(() =>
                          _filterType = (v == 'All') ? null : v);
                      _loadTools();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _filterStatus ?? 'All',
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: _statusOptions
                        .map((s) =>
                            DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) {
                      setState(() =>
                          _filterStatus = (v == 'All') ? null : v);
                      _loadTools();
                    },
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: AppTheme.danger)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadTools, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_tools.isEmpty) {
      return const Center(child: Text('No tools found'));
    }

    return RefreshIndicator(
      onRefresh: _loadTools,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: _tools.length,
        itemBuilder: (context, index) {
          final tool = _tools[index];
          return _buildToolTile(tool);
        },
      ),
    );
  }

  Widget _buildToolTile(Map<String, dynamic> tool) {
    final toolCode = tool['tool_code']?.toString() ?? '';
    final toolName = tool['tool_name']?.toString() ?? toolCode;
    final toolType = tool['tool_type']?.toString() ?? '';
    final status = tool['status']?.toString() ?? 'Available';
    final currentJc = tool['current_job_card']?.toString();
    final currentWorkstation = tool['current_workstation']?.toString();
    final isPendingConversion = status == 'Pending Conversion';
    final isAirbag = toolType.toLowerCase() == 'airbag';
    final weight = (tool['current_weight_kg'] as num?)?.toDouble();
    final threshold = (tool['weight_conversion_threshold_kg'] as num?)?.toDouble();
    final isStaged = status == 'Staged';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isPendingConversion
          ? AppTheme.warningLight
          : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (isPendingConversion)
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child:
                        Icon(Icons.warning_amber, color: AppTheme.warning, size: 18),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(toolName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(toolCode,
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    StatusChip(status: status),
                    const SizedBox(height: 4),
                    Text(toolType,
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 11)),
                  ],
                ),
              ],
            ),
            if (currentJc != null) ...[
              const SizedBox(height: 6),
              Text('JC: $currentJc',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12)),
            ],
            if (currentWorkstation != null && currentWorkstation.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('At: $currentWorkstation',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12)),
            ],
            if (isAirbag && weight != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Weight: ${weight.toStringAsFixed(1)} Kg'
                          '${threshold != null ? ' / ${threshold.toStringAsFixed(1)} Kg' : ''}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        if (threshold != null && threshold > 0)
                          LinearProgressIndicator(
                            value: (weight / threshold).clamp(0.0, 1.0),
                            backgroundColor: AppTheme.bgBorder,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              weight / threshold > 0.9
                                  ? AppTheme.danger
                                  : weight / threshold > 0.7
                                      ? AppTheme.warning
                                      : AppTheme.success,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 32,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                      onPressed: () => _showUpdateWeightDialog(tool),
                      child: const Text('Update Weight'),
                    ),
                  ),
                ],
              ),
            ],
            if (isStaged) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: _returningToolId == toolCode
                      ? null
                      : () => _returnToolToStore(toolCode),
                  icon: _returningToolId == toolCode
                      ? const SizedBox(
                          width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.undo, size: 16),
                  label: const Text('Return to Store', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _returnToolToStore(String toolCode) async {
    setState(() => _returningToolId = toolCode);
    try {
      await ref.read(line2RepositoryProvider).returnToolToStore(toolId: toolCode);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$toolCode returned to store'),
          backgroundColor: AppTheme.success,
        ));
        _loadTools();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.danger,
        ));
      }
    } finally {
      if (mounted) setState(() => _returningToolId = null);
    }
  }
}
