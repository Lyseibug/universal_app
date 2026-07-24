import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_exceptions.dart';
import '../../core/errors/error_mapper.dart';
import '../../core/menu/menu_models.dart';
import '../../core/models/maintenance_request_models.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/pdt_scaffold.dart';
import '../../widgets/status_chip.dart';
import 'maintenance_repository.dart';

/// The shared maintenance queue -- restricted screen (screen_key:
/// maintenance_team), seeded System Manager only until the admin adds the
/// real maintenance role(s). Requests are raised from the separate
/// raise_maintenance_request_screen.dart.
class MaintenanceTeamScreen extends ConsumerStatefulWidget {
  final MenuScreen screen;
  const MaintenanceTeamScreen({required this.screen, super.key});

  @override
  ConsumerState<MaintenanceTeamScreen> createState() => _MaintenanceTeamScreenState();
}

enum _View { list, detail }

class _MaintenanceTeamScreenState extends ConsumerState<MaintenanceTeamScreen> {
  _View _view = _View.list;

  bool _loading = true;
  String? _error;
  List<MaintenanceRequestSummary> _requests = [];
  String? _statusFilter;

  MaintenanceRequestSummary? _selected;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _loadList();
  }

  Future<void> _loadList() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _requests = await ref.read(maintenanceRepositoryProvider).listRequests(status: _statusFilter);
      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _error = 'Failed to load requests.';
        _loading = false;
      });
    }
  }

  void _openDetail(MaintenanceRequestSummary req) {
    setState(() {
      _selected = req;
      _view = _View.detail;
    });
  }

  Future<void> _updateStatus(String status) async {
    if (_selected == null) return;
    setState(() => _updating = true);
    try {
      await ref.read(maintenanceRepositoryProvider).updateStatus(_selected!.name, status);
      if (!mounted) return;
      setState(() {
        _view = _View.list;
        _selected = null;
      });
      _loadList();
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
      if (mounted) setState(() => _updating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _view == _View.list,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _view == _View.detail) {
          setState(() {
            _view = _View.list;
            _selected = null;
          });
        }
      },
      child: PdtScaffold(
        title: _view == _View.list ? widget.screen.label : (_selected?.name ?? 'Detail'),
        body: _view == _View.list ? _buildListBody() : _buildDetailBody(),
      ),
    );
  }

  // ─── List ──────────────────────────────────────────────────────────────

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
              _filterChip('Open', 'Open'),
              _filterChip('In Progress', 'In Progress'),
              _filterChip('Completed', 'Completed'),
              _filterChip('Cancelled', 'Cancelled'),
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
                                    child: Text('No maintenance requests found.',
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

  Widget _buildRequestCard(MaintenanceRequestSummary req) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          onTap: () => _openDetail(req),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(req.machine,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                    StatusChip(status: req.status),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${req.category.isNotEmpty ? '${req.category} · ' : ''}${req.issueType}',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
                if (req.raisedBy != null) ...[
                  const SizedBox(height: 6),
                  Text('Raised by ${req.raisedBy}',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Detail ────────────────────────────────────────────────────────────

  Widget _buildDetailBody() {
    final req = _selected;
    if (req == null) return const SizedBox.shrink();

    return ListView(
      padding: const EdgeInsets.all(AppTheme.horizontalPad),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(req.machine, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            StatusChip(status: req.status),
          ],
        ),
        const SizedBox(height: 16),
        _detailRow('Category', req.category),
        _detailRow('Issue', req.issueType),
        if (req.description.isNotEmpty) _detailRow('Description', req.description),
        if (req.urgency.isNotEmpty) _detailRow('Priority', req.urgency),
        if (req.raisedBy != null) _detailRow('Raised By', req.raisedBy!),
        if (req.raisedOn != null) _detailRow('Raised On', req.raisedOn!),
        if (req.completedBy != null) _detailRow('Completed By', req.completedBy!),
        if (req.completedOn != null) _detailRow('Completed On', req.completedOn!),
        const SizedBox(height: 28),
        if (req.status == 'Open')
          CustomButton(
            text: 'Start Work',
            isLoading: _updating,
            onPressed: () => _updateStatus('In Progress'),
          ),
        if (req.status == 'In Progress') ...[
          CustomButton(
            text: 'Mark Completed',
            isLoading: _updating,
            onPressed: () => _updateStatus('Completed'),
          ),
        ],
        if (req.status == 'Open' || req.status == 'In Progress') ...[
          const SizedBox(height: 10),
          CustomButton(
            text: 'Cancel Request',
            outlined: true,
            isLoading: _updating,
            onPressed: () => _updateStatus('Cancelled'),
          ),
        ],
      ],
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
