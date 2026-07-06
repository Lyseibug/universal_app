import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_exceptions.dart';
import '../../core/errors/error_mapper.dart';
import '../../core/menu/menu_models.dart';
import '../../core/models/manufacturing_mr_models.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/service_providers.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/pdt_scaffold.dart';
import '../../widgets/scan_input_field.dart';
import '../../widgets/status_chip.dart';
import '../pick/pick_list_screen.dart';
import 'manufacturing_mr_repository.dart';

enum _View { list, detail, create }

class ManufacturingMRScreen extends ConsumerStatefulWidget {
  final MenuScreen screen;
  const ManufacturingMRScreen({required this.screen, super.key});

  @override
  ConsumerState<ManufacturingMRScreen> createState() =>
      _ManufacturingMRScreenState();
}

class _ManufacturingMRScreenState
    extends ConsumerState<ManufacturingMRScreen> {
  _View _view = _View.list;

  // ── List ──
  bool _loading = true;
  String? _error;
  List<ManufacturingMR> _mrs = [];
  String? _statusFilter;

  // ── Detail ──
  ManufacturingMRDetail? _detail;
  bool _loadingDetail = false;

  // ── Create ──
  final List<_ItemRow> _newItems = [];
  final _remarksCtrl = TextEditingController();
  bool _submitting = false;

  // ── Edit (Draft detail) ──
  bool _editing = false;
  final List<_ItemRow> _editItems = [];
  final _editRemarksCtrl = TextEditingController();
  final _editFormulaCodeCtrl = TextEditingController();
  final _editBomCtrl = TextEditingController();
  final _editReqQtyCtrl = TextEditingController();
  String _editCompoundType = 'CMB';
  String _editRequestType = 'Manual';
  bool _saving = false;
  bool _submittingMR = false;
  bool _creatingPickList = false;

  @override
  void initState() {
    super.initState();
    _loadList();
  }

  @override
  void dispose() {
    _remarksCtrl.dispose();
    for (final r in _newItems) {
      r.dispose();
    }
    _editRemarksCtrl.dispose();
    _editFormulaCodeCtrl.dispose();
    _editBomCtrl.dispose();
    _editReqQtyCtrl.dispose();
    for (final r in _editItems) {
      r.dispose();
    }
    super.dispose();
  }

  // ─── Data Loading ──────────────────────────────────────────────────────────

  Future<void> _loadList() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _mrs = await ref
          .read(manufacturingMRRepositoryProvider)
          .listMRs(status: _statusFilter);
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
      _editing = false;
    });
    try {
      _detail =
          await ref.read(manufacturingMRRepositoryProvider).getMR(name);
    } catch (e) {
      _detail = null;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to load detail: $e'),
              backgroundColor: AppTheme.danger),
        );
      }
    }
    if (mounted) setState(() => _loadingDetail = false);
  }

  // ─── Create Submit ─────────────────────────────────────────────────────────

  Future<void> _submitCreate() async {
    final valid = _newItems
        .where((r) => r.itemCode.isNotEmpty && r.qty > 0)
        .toList();
    if (valid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one item with qty > 0.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final result = await ref
          .read(manufacturingMRRepositoryProvider)
          .create(
            items: valid.map((r) => r.toJson()).toList(),
            remarks: _remarksCtrl.text.trim().isNotEmpty
                ? _remarksCtrl.text.trim()
                : null,
          );

      if (!mounted) return;

      final mrName = result is Map ? (result['name'] ?? '') : '';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Created $mrName'),
          backgroundColor: AppTheme.success,
        ),
      );

      _clearCreateForm();
      _loadDetail(mrName.toString());
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(messageFor(e)),
              backgroundColor: AppTheme.danger),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: AppTheme.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _clearCreateForm() {
    for (final r in _newItems) {
      r.dispose();
    }
    _newItems.clear();
    _remarksCtrl.clear();
  }

  void _addItemRow(List<_ItemRow> list) {
    setState(() => list.add(_ItemRow()));
  }

  void _removeItemRow(List<_ItemRow> list, int index) {
    setState(() {
      list[index].dispose();
      list.removeAt(index);
    });
  }

  // ─── Edit Mode ─────────────────────────────────────────────────────────────

  void _initEditMode() {
    final d = _detail!;
    _editRemarksCtrl.text = d.remarks ?? '';
    _editCompoundType = d.compoundType ?? 'CMB';
    _editFormulaCodeCtrl.text = d.formulaCode ?? '';
    _editBomCtrl.text = d.bom ?? '';
    _editReqQtyCtrl.text =
        d.requestedCompoundQty > 0 ? d.requestedCompoundQty.toString() : '';
    _editRequestType = d.requestType ?? 'Manual';

    for (final r in _editItems) {
      r.dispose();
    }
    _editItems.clear();
    for (final item in d.items) {
      final row = _ItemRow();
      row.itemCtrl.text = item.itemCode;
      row.qtyCtrl.text = item.requiredQty.toStringAsFixed(1);
      row.targetStream = item.targetStream;
      _editItems.add(row);
    }

    setState(() => _editing = true);
  }

  Future<void> _saveEdit() async {
    final valid = _editItems
        .where((r) => r.itemCode.isNotEmpty && r.qty > 0)
        .toList();
    if (valid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one item with qty > 0.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final updated =
          await ref.read(manufacturingMRRepositoryProvider).update(
                name: _detail!.name,
                items: valid.map((r) => r.toJson()).toList(),
                remarks: _editRemarksCtrl.text.trim(),
                compoundType: _editCompoundType,
                formulaCode: _editFormulaCodeCtrl.text.trim(),
                bom: _editBomCtrl.text.trim(),
                requestedCompoundQty:
                    double.tryParse(_editReqQtyCtrl.text) ?? 0,
                requestType: _editRequestType,
              );

      if (!mounted) return;
      setState(() {
        _detail = updated;
        _editing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Saved'), backgroundColor: AppTheme.success),
      );
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(messageFor(e)),
              backgroundColor: AppTheme.danger),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: AppTheme.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _submitMR() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Submit Material Request'),
        content: const Text(
            'This will create the Material Request and Pick List. You will not be able to edit after submitting.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Submit')),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _submittingMR = true);
    try {
      await ref
          .read(manufacturingMRRepositoryProvider)
          .submitMR(_detail!.name);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Submitted successfully'),
            backgroundColor: AppTheme.success),
      );
      _loadDetail(_detail!.name);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(messageFor(e)),
              backgroundColor: AppTheme.danger),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: AppTheme.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _submittingMR = false);
    }
  }

  Future<void> _createPickList() async {
    setState(() => _creatingPickList = true);
    try {
      await ref
          .read(manufacturingMRRepositoryProvider)
          .createPickList(_detail!.name);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Pick list created'),
            backgroundColor: AppTheme.success),
      );
      _loadDetail(_detail!.name);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(messageFor(e)),
              backgroundColor: AppTheme.danger),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: AppTheme.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _creatingPickList = false);
    }
  }

  // ─── Navigation ────────────────────────────────────────────────────────────

  void _openCreate() {
    if (_newItems.isEmpty) _addItemRow(_newItems);
    setState(() => _view = _View.create);
  }

  void _goToPickList() {
    if (_detail?.pickList == null) return;

    final menuAsync = ref.read(menuProvider);
    MenuScreen? pickScreen;
    menuAsync.whenData((menu) {
      if (menu == null) return;
      for (final mod in menu.menu) {
        for (final s in mod.screens) {
          if (s.screenKey == 'pick_list') {
            pickScreen = s;
            return;
          }
        }
      }
    });

    pickScreen ??= const MenuScreen(
      screenKey: 'pick_list',
      label: 'Pick List',
      route: '/pick-list',
      apiModule: 'pick',
      actions: ['claim', 'pick', 'override_suggested_lot'],
    );

    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PickListScreen(
        screen: pickScreen!,
        pickingType: 'Compound',
      ),
    ));
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    String title;
    switch (_view) {
      case _View.list:
        title = widget.screen.label;
        break;
      case _View.detail:
        title = _editing
            ? 'Edit ${_detail?.name ?? ''}'
            : (_detail?.name ?? 'Detail');
        break;
      case _View.create:
        title = 'New Material Request';
        break;
    }

    return PopScope(
      canPop: _view == _View.list,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          if (_view == _View.create) {
            setState(() => _view = _View.list);
          } else if (_view == _View.detail && _editing) {
            setState(() => _editing = false);
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
        floatingActionButton: _view == _View.list &&
                widget.screen.can('create')
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

  // ─── List View ─────────────────────────────────────────────────────────────

  Widget _buildListBody() {
    return Column(
      children: [
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding:
                const EdgeInsets.symmetric(horizontal: AppTheme.horizontalPad),
            children: [
              _filterChip('All', null),
              _filterChip('Draft', 'Draft'),
              _filterChip('Picking', 'Picking'),
              _filterChip('Picked', 'Picked'),
              _filterChip('Completed', 'Completed'),
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
                          Text(_error!,
                              style:
                                  const TextStyle(color: AppTheme.danger)),
                          const SizedBox(height: 16),
                          ElevatedButton(
                              onPressed: _loadList,
                              child: const Text('Retry')),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadList,
                      child: _mrs.isEmpty
                          ? ListView(
                              physics:
                                  const AlwaysScrollableScrollPhysics(),
                              children: const [
                                SizedBox(
                                  height: 200,
                                  child: Center(
                                      child: Text('No requests found.',
                                          style: TextStyle(
                                              color:
                                                  AppTheme.textSecondary))),
                                ),
                              ],
                            )
                          : ListView.builder(
                              physics:
                                  const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(
                                  AppTheme.horizontalPad),
                              itemCount: _mrs.length,
                              itemBuilder: (_, i) =>
                                  _buildMRCard(_mrs[i]),
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

  Widget _buildMRCard(ManufacturingMR mr) {
    final progress = mr.itemCount > 0
        ? mr.pickedCount / mr.itemCount
        : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          onTap: () => _loadDetail(mr.name),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        mr.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    StatusChip(status: mr.status),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${mr.itemCount} items  ·  ${mr.totalRequired.toStringAsFixed(1)} KG',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: AppTheme.bgElevated,
                    color: progress >= 1.0
                        ? AppTheme.success
                        : AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${mr.pickedCount}/${mr.itemCount} items picked  ·  ${mr.totalPicked.toStringAsFixed(1)}/${mr.totalRequired.toStringAsFixed(1)} KG',
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Detail View ───────────────────────────────────────────────────────────

  Widget _buildDetailBody() {
    if (_loadingDetail) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_detail == null) {
      return const Center(child: Text('Failed to load.'));
    }

    final d = _detail!;
    final isDraft = d.status == 'Draft';

    if (isDraft && _editing) {
      return _buildEditBody();
    }

    final totalReq =
        d.items.fold<double>(0, (s, i) => s + i.requiredQty);
    final totalPicked =
        d.items.fold<double>(0, (s, i) => s + i.pickedQty);
    final progress = totalReq > 0 ? totalPicked / totalReq : 0.0;
    final pickedCount =
        d.items.where((i) => i.pickedQty >= i.requiredQty).length;

    return RefreshIndicator(
      onRefresh: () => _loadDetail(d.name),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppTheme.horizontalPad),
        children: [
          // Header card
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
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                      StatusChip(status: d.status),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _detailField('Request Type', d.requestType),
                  _detailField('Compound Type', d.compoundType),
                  _detailField('Formula Code', d.formulaCode),
                  _detailField('BOM', d.bom),
                  if (d.requestedCompoundQty > 0)
                    _detailField('Requested Qty',
                        d.requestedCompoundQty.toStringAsFixed(1)),
                  if (d.materialRequest != null)
                    _detailField('Material Request', d.materialRequest),
                  if (d.remarks != null && d.remarks!.isNotEmpty)
                    _detailField('Remarks', d.remarks),
                  if (!isDraft) ...[
                    const SizedBox(height: 12),
                    Text(
                      '$pickedCount / ${d.items.length} items picked',
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor: AppTheme.bgBorder,
                        color: progress >= 1.0
                            ? AppTheme.success
                            : AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${totalPicked.toStringAsFixed(1)} / ${totalReq.toStringAsFixed(1)} KG',
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Item cards
          ...d.items.map(_buildDetailItemCard),
          const SizedBox(height: 16),

          // Draft actions
          if (isDraft) ...[
            CustomButton(
              text: 'Edit',
              icon: Icons.edit,
              onPressed: _initEditMode,
              outlined: true,
            ),
            const SizedBox(height: 12),
            CustomButton(
              text: 'Submit',
              icon: Icons.send,
              isLoading: _submittingMR,
              onPressed: _submitMR,
            ),
          ],

          // Pick list button
          if (!isDraft && d.pickList != null && d.status == 'Picking')
            CustomButton(
              text: 'Go to Pick List',
              icon: Icons.assignment_outlined,
              onPressed: _goToPickList,
            ),

          // Recovery: submitted MR without a pick list (normally created on submit)
          if (!isDraft &&
              d.pickList == null &&
              widget.screen.can('create_pick_list'))
            CustomButton(
              text: 'Create Pick List',
              icon: Icons.playlist_add,
              isLoading: _creatingPickList,
              onPressed: _createPickList,
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
            child: Text(label,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItemCard(ManufacturingMRItem item) {
    final done = item.pickedQty >= item.requiredQty;
    final streamColor = _streamColor(item.targetStream);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.itemCode,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    if (item.itemName != null)
                      Text(item.itemName!,
                          style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12)),
                    const SizedBox(height: 6),
                    Text(
                      '${item.requiredQty.toStringAsFixed(1)} ${item.uom ?? 'KG'}  ·  picked: ${item.pickedQty.toStringAsFixed(1)}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: streamColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  item.targetStream,
                  style: TextStyle(
                      color: streamColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 11),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                done ? Icons.check_circle : Icons.hourglass_top,
                color: done ? AppTheme.success : AppTheme.textDisabled,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _streamColor(String stream) {
    switch (stream) {
      case 'Silo':
        return AppTheme.info;
      case 'Oil':
        return AppTheme.warning;
      case 'Weighing':
        return AppTheme.success;
      default:
        return AppTheme.textSecondary;
    }
  }

  // ─── Edit Body (Draft) ─────────────────────────────────────────────────────

  Widget _buildEditBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.horizontalPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header fields
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Details',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: AppTheme.textSecondary)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _editRequestType,
                          decoration: const InputDecoration(
                            labelText: 'Request Type',
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 16),
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: 'Manual', child: Text('Manual')),
                            DropdownMenuItem(
                                value: 'Formula Based',
                                child: Text('Formula Based')),
                          ],
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => _editRequestType = v);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _editCompoundType,
                          decoration: const InputDecoration(
                            labelText: 'Compound Type',
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 16),
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: 'CMB', child: Text('CMB')),
                            DropdownMenuItem(
                                value: 'FMB', child: Text('FMB')),
                          ],
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => _editCompoundType = v);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: _editFormulaCodeCtrl,
                          labelText: 'Formula Code',
                          hintText: 'e.g. F-001',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: CustomTextField(
                          controller: _editBomCtrl,
                          labelText: 'BOM',
                          hintText: 'BOM reference',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  CustomTextField(
                    controller: _editReqQtyCtrl,
                    labelText: 'Requested Compound Qty',
                    hintText: '0',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 10),
                  CustomTextField(
                    controller: _editRemarksCtrl,
                    labelText: 'Remarks',
                    hintText: 'Notes for this request...',
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Item rows
          ..._editItems.asMap().entries.map(
              (e) => _buildItemRowCard(e.key, e.value, _editItems)),
          const SizedBox(height: 8),

          OutlinedButton.icon(
            onPressed: () => _addItemRow(_editItems),
            icon: const Icon(Icons.add),
            label: const Text('Add Item'),
          ),
          const SizedBox(height: 24),

          // Save & Submit buttons
          CustomButton(
            text: 'Save',
            icon: Icons.save,
            isLoading: _saving,
            onPressed: _saveEdit,
            outlined: true,
          ),
          const SizedBox(height: 12),
          CustomButton(
            text: 'Submit',
            icon: Icons.send,
            isLoading: _submittingMR,
            onPressed: _submitMR,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ─── Create View ───────────────────────────────────────────────────────────

  Widget _buildCreateBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.horizontalPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Item rows
          ..._newItems.asMap().entries.map(
              (e) => _buildItemRowCard(e.key, e.value, _newItems)),
          const SizedBox(height: 8),

          // Add item button
          OutlinedButton.icon(
            onPressed: () => _addItemRow(_newItems),
            icon: const Icon(Icons.add),
            label: const Text('Add Item'),
          ),
          const SizedBox(height: 16),

          // Remarks
          CustomTextField(
            controller: _remarksCtrl,
            labelText: 'Remarks (optional)',
            hintText: 'Notes for this request...',
            maxLines: 2,
          ),
          const SizedBox(height: 24),

          // Submit
          CustomButton(
            text: 'Create Material Request',
            icon: Icons.add_circle_outline,
            isLoading: _submitting,
            onPressed: _submitCreate,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildItemRowCard(int index, _ItemRow row, List<_ItemRow> itemList) {
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
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: AppTheme.textSecondary)),
                  const Spacer(),
                  if (itemList.length > 1)
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: AppTheme.danger, size: 20),
                      onPressed: () => _removeItemRow(itemList, index),
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              ScanInputField(
                controller: row.itemCtrl,
                focusNode: row.itemFocus,
                labelText: 'Item Code',
                hintText: 'Scan or type item code',
                prefixIcon: Icons.qr_code_scanner,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => row.qtyFocus.requestFocus(),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: CustomTextField(
                      controller: row.qtyCtrl,
                      focusNode: row.qtyFocus,
                      labelText: 'Qty (KG)',
                      hintText: '0',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<String>(
                      value: row.targetStream,
                      decoration: const InputDecoration(
                        labelText: 'Stream',
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 12, vertical: 16),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'Silo', child: Text('Silo')),
                        DropdownMenuItem(
                            value: 'Oil', child: Text('Oil')),
                        DropdownMenuItem(
                            value: 'Weighing',
                            child: Text('Weighing')),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          setState(() => row.targetStream = v);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Mutable item row for create / edit forms ────────────────────────────────

class _ItemRow {
  final itemCtrl = TextEditingController();
  final qtyCtrl = TextEditingController();
  final itemFocus = FocusNode();
  final qtyFocus = FocusNode();
  String targetStream = 'Silo';

  String get itemCode => itemCtrl.text.trim();
  double get qty => double.tryParse(qtyCtrl.text) ?? 0;

  Map<String, dynamic> toJson() => {
        'item_code': itemCode,
        'required_qty': qty,
        'target_stream': targetStream,
      };

  void dispose() {
    itemCtrl.dispose();
    qtyCtrl.dispose();
    itemFocus.dispose();
    qtyFocus.dispose();
  }
}
