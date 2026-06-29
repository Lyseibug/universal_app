import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/menu/menu_models.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/pdt_scaffold.dart';
import '../../widgets/status_chip.dart';
import 'line2_repository.dart';

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
        _jobs = List<Map<String, dynamic>>.from(data);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load active jobs';
        _loading = false;
      });
    }
  }

  String _formatElapsed(String? startTime) {
    if (startTime == null) return '--:--:--';
    try {
      final start = DateTime.parse(startTime);
      final diff = DateTime.now().difference(start);
      final h = diff.inHours.toString().padLeft(2, '0');
      final m = (diff.inMinutes % 60).toString().padLeft(2, '0');
      final s = (diff.inSeconds % 60).toString().padLeft(2, '0');
      return '$h:$m:$s';
    } catch (_) {
      return '--:--:--';
    }
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
            _detailRow('Step', job['step']?.toString() ?? ''),
            _detailRow('Status', job['status']?.toString() ?? ''),
            _detailRow('Elapsed', _formatElapsed(job['start_time']?.toString())),
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
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () => _showJobDetail(job),
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
                            '${job['operation'] ?? ''} / ${job['step'] ?? ''}',
                            style: const TextStyle(
                                color: AppTheme.textSecondary, fontSize: 13),
                          ),
                        ),
                        const Icon(Icons.timer, size: 14,
                            color: AppTheme.primary),
                        const SizedBox(width: 4),
                        Text(
                          _formatElapsed(job['start_time']?.toString()),
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
