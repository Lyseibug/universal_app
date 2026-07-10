import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_exceptions.dart';
import '../../core/errors/error_mapper.dart';
import '../../core/menu/menu_models.dart';
import '../../core/models/tool_request_models.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/pdt_scaffold.dart';
import '../../widgets/scan_input_field.dart';
import '../../widgets/status_chip.dart';
import 'tool_request_repository.dart';

const _kToolTypes = [
  'Mold',
  'Airbag',
  'Grinding Wheel',
  'Curing Pot',
  'Liner',
  'Cylinder',
  'Other',
];

bool _isRollType(String toolType) => toolType == 'Liner' || toolType == 'Cylinder';

enum _View { list, detail, create }

class ToolRequestsScreen extends ConsumerStatefulWidget {
  final MenuScreen screen;
  const ToolRequestsScreen({required this.screen, super.key});

  @override
  ConsumerState<ToolRequestsScreen> createState() => _ToolRequestsScreenState();
}

class _ToolRequestsScreenState extends ConsumerState<ToolRequestsScreen> {
  _View _view = _View.list;

  // ── List ──
  bool _loading = true;
  String? _error;
  List<ToolRequest> _requests = [];
  String? _statusFilter;

  // ── Detail ──
  ToolRequestDetail? _detail;
  bool _loadingDetail = false;
  bool _submittingRequest = false;
  bool _fulfilling = false;

  // ── Create ──
  final _workstationCtrl = TextEditingController();
  final _workstationFocus = FocusNode();
  final List<_ToolItemRow> _newItems = [];
  final _remarksCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadList();
  }

  @override
  void dispose() {
    _workstationCtrl.dispose();
    _workstationFocus.dispose();
    _remarksCtrl.dispose();
    for (final r in _newItems) {
      r.dispose();
    }
    super.dispose();
  }

  // ─── Data Loading ──────────────────────────────────────────────────────

  Future<void> _loadList() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _requests = await ref
          .read(toolRequestRepositoryProvider)
          .listRequests(status: _statusFilter);
      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _error = 'Failed to load requests.';
        _loading = false;
      });
    }
  }

  Future<void> _loadDetail(String name) async {
    setState(() {
      _loadingDetail = true;
      _view = _View.detail;
    });
    try {
      _detail = await ref.read(toolRequestRepositoryProvider).getRequest(name);
    } catch (e) {
      _detail = null;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load detail: $e'), backgroundColor: AppTheme.danger),
        );
      }
    }
    if (mounted) setState(() => _loadingDetail = false);
  }

  // ─── Create ────────────────────────────────────────────────────────────

  Future<void> _submitCreate() async {
    final workstation = _workstationCtrl.text.trim();
    if (workstation.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Target workstation is required.')),
      );
      return;
    }
    final valid = _newItems.where((r) => r.qty > 0).toList();
    if (valid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one item with qty > 0.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final result = await ref.read(toolRequestRepositoryProvider).create(
            targetWorkstation: workstation,
            items: valid.map((r) => r.toJson()).toList(),
            remarks: _remarksCtrl.text.trim().isNotEmpty ? _remarksCtrl.text.trim() : null,
          );

      if (!mounted) return;
      final reqName = result is Map ? (result['name'] ?? '') : '';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Created $reqName'), backgroundColor: AppTheme.success),
      );

      _clearCreateForm();
      _loadDetail(reqName.toString());
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(messageFor(e)), backgroundColor: AppTheme.danger),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _clearCreateForm() {
    _workstationCtrl.clear();
    for (final r in _newItems) {
      r.dispose();
    }
    _newItems.clear();
    _remarksCtrl.clear();
  }

  void _addItemRow() {
    setState(() => _newItems.add(_ToolItemRow()));
  }

  void _removeItemRow(int index) {
    setState(() {
      _newItems[index].dispose();
      _newItems.removeAt(index);
    });
  }

  // ─── Detail actions ────────────────────────────────────────────────────

  Future<void> _submitRequest() async {
    setState(() => _submittingRequest = true);
    try {
      await ref.read(toolRequestRepositoryProvider).submit(_detail!.name);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Submitted'), backgroundColor: AppTheme.success),
      );
      _loadDetail(_detail!.name);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(messageFor(e)), backgroundColor: AppTheme.danger),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _submittingRequest = false);
    }
  }

  Future<void> _fulfill() async {
    setState(() => _fulfilling = true);
    try {
      final result = await ref.read(toolRequestRepositoryProvider).fulfill(_detail!.name);
      if (!mounted) return;

      final anyShortfall = result.results.any((r) => r.shortfall > 0);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(anyShortfall
              ? 'Fulfilled what was Available — some lines still short.'
              : 'Fully fulfilled — tools staged.'),
          backgroundColor: anyShortfall ? AppTheme.warning : AppTheme.success,
        ),
      );
      _loadDetail(_detail!.name);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(messageFor(e)), backgroundColor: AppTheme.danger),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _fulfilling = false);
    }
  }

  // ─── Navigation ────────────────────────────────────────────────────────

  void _openCreate() {
    if (_newItems.isEmpty) _addItemRow();
    setState(() => _view = _View.create);
  }

  // ─── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    String title;
    switch (_view) {
      case _View.list:
        title = widget.screen.label;
        break;
      case _View.detail:
        title = _detail?.name ?? 'Detail';
        break;
      case _View.create:
        title = 'New Tool Request';
        break;
    }

    return PopScope(
      canPop: _view == _View.list,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          if (_view == _View.create) {
            setState(() => _view = _View.list);
          } else if (_view == _View.detail) {
            setState(() {
              _view = _View.list;
              _detail = null;
            });
            _loadList();
          }
        }
      },
      child: PdtScaffold(
        title: title,
        body: _buildBody(),
        floatingActionButton: _view == _View.list && widget.screen.can('create')
            ? FloatingActionButton.extended(
                onPressed: _openCreate,
                icon: const Icon(Icons.add),
                label: const Text('New'),
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
              )
            : null,
      ),
    );
  }

  Widget _buildBody() {
    switch (_view) {
      case _View.list:
        return _buildListBody();
      case _View.detail:
        return _buildDetailBody();
      case _View.create:
        return _buildCreateBody();
    }
  }

  // ─── List View ─────────────────────────────────────────────────────────

  Widget _buildListBody() {
    return Column(
      children: [
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.horizontalPad),
            children: [
              _filterChip('All', null),
              _filterChip('Draft', 'Draft'),
              _filterChip('Submitted', 'Submitted'),
              _filterChip('Partially Fulfilled', 'Partially Fulfilled'),
              _filterChip('Fulfilled', 'Fulfilled'),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_error!, style: const TextStyle(color: AppTheme.danger)),
                          const SizedBox(height: 16),
                          ElevatedButton(onPressed: _loadList, child: const Text('Retry')),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadList,
                      child: _requests.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: const [
                                SizedBox(
                                  height: 200,
                                  child: Center(
                                    child: Text('No tool requests found.',
                                        style: TextStyle(color: AppTheme.textSecondary)),
                                  ),
                                ),
                              ],
                            )
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(AppTheme.horizontalPad),
                              itemCount: _requests.length,
                              itemBuilder: (_, i) => _buildRequestCard(_requests[i]),
                            ),
                    ),
        ),
      ],
    );
  }

  Widget _filterChip(String label, String? value) {
    final selected = _statusFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        selectedColor: AppTheme.primary,
        labelStyle: TextStyle(
          color: selected ? Colors.white : AppTheme.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        onSelected: (_) {
          setState(() => _statusFilter = value);
          _loadList();
        },
      ),
    );
  }

  Widget _buildRequestCard(ToolRequest req) {
    final progress = req.totalRequested > 0 ? req.totalFulfilled / req.totalRequested : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          onTap: () => _loadDetail(req.name),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(req.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                    StatusChip(status: req.status),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${req.targetWorkstation ?? '—'}  ·  ${req.itemCount} item(s)',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: AppTheme.bgElevated,
                    color: progress >= 1.0 ? AppTheme.success : AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${req.totalFulfilled.toStringAsFixed(0)}/${req.totalRequested.toStringAsFixed(0)} tools staged',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Detail View ───────────────────────────────────────────────────────

  Widget _buildDetailBody() {
    if (_loadingDetail) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_detail == null) {
      return const Center(child: Text('Failed to load.'));
    }

    final d = _detail!;
    final isDraft = d.status == 'Draft';
    final canFulfill = d.status == 'Submitted' || d.status == 'Partially Fulfilled';

    return RefreshIndicator(
      onRefresh: () => _loadDetail(d.name),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppTheme.horizontalPad),
        children: [
          Card(
            color: AppTheme.bgElevated,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(d.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                      StatusChip(status: d.status),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _detailField('Workstation', d.targetWorkstation),
                  if (d.remarks != null && d.remarks!.isNotEmpty)
                    _detailField('Remarks', d.remarks),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...d.items.map((item) => _buildDetailItemCard(item, d)),
          const SizedBox(height: 16),
          if (isDraft)
            CustomButton(
              text: 'Submit',
              icon: Icons.send,
              isLoading: _submittingRequest,
              onPressed: _submitRequest,
            ),
          if (canFulfill && widget.screen.can('fulfill'))
            CustomButton(
              text: 'Fulfill',
              icon: Icons.inventory_2_outlined,
              isLoading: _fulfilling,
              onPressed: _fulfill,
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _detailField(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildDetailItemCard(ToolRequestItem item, ToolRequestDetail d) {
    final fulfilledUnits = d.fulfilledTools.where((t) => t.requestItem == item.name).toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(item.toolType,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                  Icon(
                    item.isCompleted ? Icons.check_circle : Icons.hourglass_top,
                    color: item.isCompleted ? AppTheme.success : AppTheme.textDisabled,
                    size: 22,
                  ),
                ],
              ),
              if (_isRollType(item.toolType) && (item.widthInMm > 0 || item.lengthInMm > 0))
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'min ${item.widthInMm.toStringAsFixed(0)}mm x ${item.lengthInMm.toStringAsFixed(0)}mm',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 6),
              Text('${item.fulfilledQty}/${item.qty} staged', style: const TextStyle(fontSize: 13)),
              if (fulfilledUnits.isNotEmpty) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: fulfilledUnits
                      .map((t) => Chip(
                            label: Text(t.tool, style: const TextStyle(fontSize: 11)),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ─── Create View ───────────────────────────────────────────────────────

  Widget _buildCreateBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.horizontalPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ScanInputField(
            controller: _workstationCtrl,
            focusNode: _workstationFocus,
            labelText: 'Target Workstation',
            hintText: 'Scan or type workstation',
            prefixIcon: Icons.qr_code_scanner,
          ),
          const SizedBox(height: 16),
          ..._newItems.asMap().entries.map((e) => _buildItemRowCard(e.key, e.value)),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _addItemRow,
            icon: const Icon(Icons.add),
            label: const Text('Add Item'),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _remarksCtrl,
            labelText: 'Remarks (optional)',
            hintText: 'Notes for this request...',
            maxLines: 2,
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: 'Create Tool Request',
            icon: Icons.add_circle_outline,
            isLoading: _submitting,
            onPressed: _submitCreate,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildItemRowCard(int index, _ToolItemRow row) {
    final isRoll = _isRollType(row.toolType);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Item ${index + 1}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textSecondary)),
                  const Spacer(),
                  if (_newItems.length > 1)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppTheme.danger, size: 20),
                      onPressed: () => _removeItemRow(index),
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<String>(
                      value: row.toolType,
                      decoration: const InputDecoration(
                        labelText: 'Tool Type',
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      ),
                      items: _kToolTypes
                          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => row.toolType = v);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: CustomTextField(
                      controller: row.qtyCtrl,
                      labelText: 'Qty',
                      hintText: '1',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              if (isRoll) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: row.widthCtrl,
                        labelText: 'Min. Width (mm)',
                        hintText: '0',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: CustomTextField(
                        controller: row.lengthCtrl,
                        labelText: 'Min. Length (mm)',
                        hintText: '0',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Mutable item row for the create form ─────────────────────────────────

class _ToolItemRow {
  final qtyCtrl = TextEditingController(text: '1');
  final widthCtrl = TextEditingController();
  final lengthCtrl = TextEditingController();
  String toolType = 'Mold';

  int get qty => int.tryParse(qtyCtrl.text) ?? 0;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'tool_type': toolType,
      'qty': qty,
    };
    if (_isRollType(toolType)) {
      json['width_in_mm'] = double.tryParse(widthCtrl.text) ?? 0;
      json['length_in_mm'] = double.tryParse(lengthCtrl.text) ?? 0;
    }
    return json;
  }

  void dispose() {
    qtyCtrl.dispose();
    widthCtrl.dispose();
    lengthCtrl.dispose();
  }
}
