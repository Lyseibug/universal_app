import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/menu/menu_models.dart';
import '../../core/models/line1_models.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/pdt_scaffold.dart';
import 'line1_repository.dart';

class CompoundLabTestScreen extends ConsumerStatefulWidget {
  final MenuScreen screen;
  const CompoundLabTestScreen({required this.screen, super.key});

  @override
  ConsumerState<CompoundLabTestScreen> createState() =>
      _CompoundLabTestScreenState();
}

class _CompoundLabTestScreenState extends ConsumerState<CompoundLabTestScreen> {
  // ── List view ──
  bool _loading = true;
  String? _error;
  List<FmbBatch> _fmbBatches = [];
  String? _statusFilter;

  // ── Detail / Test view ──
  FmbDetail? _detail;
  bool _loadingDetail = false;
  bool _submitting = false;
  final _remarksCtrl = TextEditingController();

  final Map<String, TextEditingController> _paramControllers = {};
  final Map<String, TextEditingController> _minControllers = {};
  final Map<String, TextEditingController> _maxControllers = {};

  static const _paramNames = ['ML', 'MH', 'ts2', 't90', 'Mooney'];

  @override
  void initState() {
    super.initState();
    for (final p in _paramNames) {
      _paramControllers[p] = TextEditingController();
      _minControllers[p] = TextEditingController();
      _maxControllers[p] = TextEditingController();
    }
    _loadList();
  }

  @override
  void dispose() {
    _remarksCtrl.dispose();
    for (final c in _paramControllers.values) c.dispose();
    for (final c in _minControllers.values) c.dispose();
    for (final c in _maxControllers.values) c.dispose();
    super.dispose();
  }

  Future<void> _loadList() async {
    setState(() { _loading = true; _error = null; });
    try {
      _fmbBatches = await ref.read(line1RepositoryProvider).listFmb(status: _statusFilter);
      setState(() => _loading = false);
    } catch (e) {
      setState(() { _error = 'Failed to load FMB batches'; _loading = false; });
    }
  }

  Future<void> _loadDetail(String batchNo) async {
    setState(() => _loadingDetail = true);
    try {
      final detail = await ref.read(line1RepositoryProvider).getFmb(batchNo);
      setState(() { _detail = detail; _loadingDetail = false; });

      if (detail.labTest != null) {
        for (final p in detail.labTest!.parameters) {
          _paramControllers[p.parameterName]?.text =
              p.resultValue != 0 ? p.resultValue.toString() : '';
          _minControllers[p.parameterName]?.text =
              p.expectedMin != 0 ? p.expectedMin.toString() : '';
          _maxControllers[p.parameterName]?.text =
              p.expectedMax != 0 ? p.expectedMax.toString() : '';
        }
      } else {
        for (final p in _paramNames) {
          _paramControllers[p]?.clear();
          _minControllers[p]?.clear();
          _maxControllers[p]?.clear();
        }
      }
    } catch (e) {
      setState(() => _loadingDetail = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.danger,
        ));
      }
    }
  }

  Future<void> _submitTest() async {
    if (_detail == null) return;

    final parameters = <Map<String, dynamic>>[];
    for (final p in _paramNames) {
      final val = double.tryParse(_paramControllers[p]?.text ?? '');
      if (val == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Enter a value for $p'),
          backgroundColor: AppTheme.danger,
        ));
        return;
      }
      parameters.add({
        'parameter_name': p,
        'expected_min': double.tryParse(_minControllers[p]?.text ?? '') ?? 0,
        'expected_max': double.tryParse(_maxControllers[p]?.text ?? '') ?? 0,
        'result_value': val,
      });
    }

    setState(() => _submitting = true);
    try {
      final result = await ref.read(line1RepositoryProvider).submitLabTest(
        fmbBatch: _detail!.batchNo,
        parameters: parameters,
        remarks: _remarksCtrl.text.isNotEmpty ? _remarksCtrl.text : null,
      );

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('Lab Test Result: ${result.result}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: result.parameters.map((p) => Row(
                children: [
                  Expanded(child: Text(p.parameterName)),
                  Text('${p.resultValue}'),
                  const SizedBox(width: 8),
                  Icon(
                    p.isPass ? Icons.check_circle : Icons.cancel,
                    color: p.isPass ? AppTheme.success : AppTheme.danger,
                    size: 20,
                  ),
                ],
              )).toList(),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  setState(() => _detail = null);
                  _loadList();
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.danger,
        ));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PdtScaffold(
      title: widget.screen.label,
      body: _detail != null ? _buildTestForm() : _buildList(),
    );
  }

  Widget _buildList() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_error!, style: const TextStyle(color: AppTheme.danger)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadList, child: const Text('Retry')),
        ],
      ));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip('All', null),
                _filterChip('Pending', 'Pending'),
                _filterChip('Pass', 'Pass'),
                _filterChip('Fail', 'Fail'),
                _filterChip('Conditional', 'Conditional Pass'),
              ],
            ),
          ),
        ),
        Expanded(
          child: _fmbBatches.isEmpty
              ? const Center(child: Text('No FMB batches'))
              : RefreshIndicator(
                  onRefresh: _loadList,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _fmbBatches.length,
                    itemBuilder: (context, index) {
                      final batch = _fmbBatches[index];
                      return Card(
                        child: ListTile(
                          leading: _statusIcon(batch.labStatus),
                          title: Text(batch.itemName ?? batch.itemCode,
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Batch: ${batch.batchNo}'),
                              Text('Qty: ${batch.qty} Kg'),
                              if (batch.formulaName != null)
                                Text('Formula: ${batch.formulaName}'),
                            ],
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          isThreeLine: true,
                          onTap: () => _loadDetail(batch.batchNo),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _filterChip(String label, String? value) {
    final selected = _statusFilter == value;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (s) {
          setState(() => _statusFilter = s ? value : null);
          _loadList();
        },
      ),
    );
  }

  Widget _statusIcon(String status) {
    switch (status) {
      case 'Pass':
        return const CircleAvatar(backgroundColor: AppTheme.success, radius: 16, child: Icon(Icons.check, color: Colors.white, size: 18));
      case 'Fail':
        return const CircleAvatar(backgroundColor: AppTheme.danger, radius: 16, child: Icon(Icons.close, color: Colors.white, size: 18));
      case 'Conditional Pass':
        return const CircleAvatar(backgroundColor: Colors.orange, radius: 16, child: Icon(Icons.warning, color: Colors.white, size: 18));
      default:
        return CircleAvatar(backgroundColor: Colors.grey[300], radius: 16, child: const Icon(Icons.hourglass_empty, color: Colors.white, size: 18));
    }
  }

  Widget _buildTestForm() {
    if (_loadingDetail) return const Center(child: CircularProgressIndicator());
    final detail = _detail!;
    final alreadySubmitted = detail.labTest?.docstatus == 1;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _detail = null);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _detail = null),
              ),
              Expanded(child: Text('Lab Test', style: Theme.of(context).textTheme.titleLarge)),
              _statusIcon(detail.labStatus),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(detail.itemName ?? detail.itemCode, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('Batch: ${detail.batchNo}'),
                  Text('Qty: ${detail.qty} Kg'),
                  if (detail.formulaName != null) Text('Formula: ${detail.formulaName}'),
                  if (detail.manufacturingDate != null) Text('Date: ${detail.manufacturingDate}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Test Parameters', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ..._paramNames.map((p) => _paramRow(p, alreadySubmitted)),
          const SizedBox(height: 16),
          TextField(
            controller: _remarksCtrl,
            decoration: const InputDecoration(
              labelText: 'Remarks (optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
            readOnly: alreadySubmitted,
          ),
          const SizedBox(height: 16),
          if (!alreadySubmitted && widget.screen.can('submit_test'))
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submitTest,
                child: _submitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Submit Lab Test', style: TextStyle(fontSize: 16)),
              ),
            )
          else
            Card(
              color: detail.labStatus == 'Pass'
                  ? Colors.green[50]
                  : detail.labStatus == 'Conditional Pass'
                      ? Colors.orange[50]
                      : Colors.red[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Result: ${detail.labStatus}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: detail.labStatus == 'Pass'
                        ? AppTheme.success
                        : detail.labStatus == 'Conditional Pass'
                            ? Colors.orange
                            : AppTheme.danger,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _paramRow(String paramName, bool readOnly) {
    final valCtrl = _paramControllers[paramName]!;
    final minCtrl = _minControllers[paramName]!;
    final maxCtrl = _maxControllers[paramName]!;

    final val = double.tryParse(valCtrl.text);
    final mn = double.tryParse(minCtrl.text);
    final mx = double.tryParse(maxCtrl.text);
    final inRange = val != null && mn != null && mx != null && val >= mn && val <= mx;
    final hasValue = val != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(paramName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const Spacer(),
                if (hasValue)
                  Icon(
                    inRange ? Icons.check_circle : Icons.cancel,
                    color: inRange ? AppTheme.success : AppTheme.danger,
                    size: 22,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: minCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Min', isDense: true, border: OutlineInputBorder()),
                    readOnly: readOnly,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: valCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Value', isDense: true, border: OutlineInputBorder()),
                    readOnly: readOnly,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: maxCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Max', isDense: true, border: OutlineInputBorder()),
                    readOnly: readOnly,
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
}
