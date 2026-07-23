import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/menu/menu_models.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/service_providers.dart';
import '../../widgets/pdt_scaffold.dart';
import '../../widgets/status_chip.dart';
import 'line2_production_screen.dart';
import 'line2_repository.dart';
import 'qc_final_screen.dart';

class ActiveJobsScreen extends ConsumerStatefulWidget {
  final MenuScreen screen;
  const ActiveJobsScreen({required this.screen, super.key});

  @override
  ConsumerState<ActiveJobsScreen> createState() => _ActiveJobsScreenState();
}

class _ActiveJobsScreenState extends ConsumerState<ActiveJobsScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _jobs = [];
  Timer? _elapsedTimer;
  bool _resuming = false;

  @override
  void initState() {
    super.initState();
    _loadJobs();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadJobs() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ref.read(line2RepositoryProvider).getActiveJobs();
      setState(() {
        // elapsed_seconds is the real server-computed elapsed time (from
        // the Job Card's open time log) — freeze it into a local DateTime
        // once per load so the 1s ticker below just re-renders, it doesn't
        // re-fetch.
        _jobs = data.map((j) {
          final elapsed = (j['elapsed_seconds'] as num?)?.toInt() ?? 0;
          j['_localStart'] = DateTime.now().subtract(Duration(seconds: elapsed));
          return j;
        }).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load active jobs';
        _loading = false;
      });
    }
  }

  String _formatElapsed(DateTime? start) {
    if (start == null) return '--:--:--';
    final diff = DateTime.now().difference(start);
    final h = diff.inHours.toString().padLeft(2, '0');
    final m = (diff.inMinutes % 60).toString().padLeft(2, '0');
    final s = (diff.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  /// Tap a job to jump straight back into its station screen, pre-loaded —
  /// re-resolves via scan_flowchart (idempotent: a rescan of an
  /// in-progress job is a safe read, it doesn't touch the running timer)
  /// rather than duplicating that whole payload shape here.
  Future<void> _resumeJob(Map<String, dynamic> job) async {
    final screenKey = job['screen_key']?.toString();
    if (screenKey == null || screenKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            "This workstation isn't set up for resume — ask your supervisor to configure its PDT screen."),
        backgroundColor: AppTheme.warning,
      ));
      return;
    }
    final barcode = job['flowchart_barcode']?.toString();
    if (barcode == null || barcode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('This job has no flowchart barcode to resume.'),
        backgroundColor: AppTheme.danger,
      ));
      return;
    }

    setState(() => _resuming = true);
    try {
      final scanResult = await ref.read(line2RepositoryProvider).scanFlowchart(barcode);
      if (!mounted) return;

      final menuScreen = _resolveMenuScreen(screenKey);
      final resumedScreen = switch (screenKey) {
        'line2_curing' ||
        'line2_building' ||
        'line2_processing' =>
          Line2ProductionScreen(screen: menuScreen, resumeJob: scanResult),
        'line2_qc_final' =>
          QcFinalScreen(screen: menuScreen, resumeJob: scanResult),
        _ => null,
      };
      if (resumedScreen == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Screen '$screenKey' isn't supported for resume."),
          backgroundColor: AppTheme.warning,
        ));
        return;
      }
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => resumedScreen));
      _loadJobs();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'), backgroundColor: AppTheme.danger));
      }
    } finally {
      if (mounted) setState(() => _resuming = false);
    }
  }

  /// Same "look up MenuScreen by key in the loaded menu, else construct a
  /// fallback literal" idiom used elsewhere in this app (e.g.
  /// line2_production_screen.dart's _goToToolRequests, manufacturing_mr_screen.dart's
  /// _goToPickList).
  MenuScreen _resolveMenuScreen(String screenKey) {
    MenuScreen? found;
    ref.read(menuProvider).whenData((menu) {
      if (menu == null) return;
      for (final mod in menu.menu) {
        for (final s in mod.screens) {
          if (s.screenKey == screenKey) {
            found = s;
            return;
          }
        }
      }
    });
    return found ??
        MenuScreen(
          screenKey: screenKey,
          label: screenKey,
          route: '/$screenKey',
          apiModule: 'line2',
          actions: const ['complete_step', 'assign_tool', 'release_tool'],
        );
  }

  void _showJobDetail(Map<String, dynamic> job) {
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
            Text('Job Details',
                style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 16),
            _detailRow('Job Card', job['name']?.toString() ?? ''),
            _detailRow('Item', job['item_name']?.toString() ?? ''),
            _detailRow('Work Order', job['work_order']?.toString() ?? ''),
            _detailRow('Operation', job['operation']?.toString() ?? ''),
            _detailRow('Step', job['step_name']?.toString() ?? ''),
            _detailRow('Workstation', job['workstation']?.toString() ?? ''),
            _detailRow('Operator', job['custom_operator']?.toString() ?? ''),
            _detailRow('Status', job['status']?.toString() ?? ''),
            _detailRow('Elapsed', _formatElapsed(job['_localStart'] as DateTime?)),
            if (job['is_rework'] == true)
              _detailRow('Rework', 'Yes'),
            if (job['remarks'] != null)
              _detailRow('Remarks', job['remarks'].toString()),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PdtScaffold(
      title: widget.screen.label,
      floatingActionButton: FloatingActionButton(
        onPressed: _loadJobs,
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
      body: _buildBody(),
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
            ElevatedButton(onPressed: _loadJobs, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_jobs.isEmpty) {
      return const Center(child: Text('No active jobs'));
    }

    return RefreshIndicator(
      onRefresh: _loadJobs,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _jobs.length,
        itemBuilder: (context, index) {
          final job = _jobs[index];
          final isRework = job['is_rework'] == true;
          final localStart = job['_localStart'] as DateTime?;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: _resuming ? null : () => _resumeJob(job),
              onLongPress: () => _showJobDetail(job),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            job['item_name']?.toString() ?? job['name']?.toString() ?? '',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                        if (isRework)
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.dangerLight,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('REWORK',
                                style: TextStyle(
                                    color: AppTheme.danger,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700)),
                          ),
                        StatusChip(
                            status: job['status']?.toString() ?? 'Open'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.settings, size: 14,
                            color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${job['operation'] ?? ''} / ${job['step_name'] ?? ''}',
                            style: const TextStyle(
                                color: AppTheme.textSecondary, fontSize: 13),
                          ),
                        ),
                        const Icon(Icons.timer, size: 14,
                            color: AppTheme.primary),
                        const SizedBox(width: 4),
                        Text(
                          _formatElapsed(localStart),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            fontFamily: 'monospace',
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
