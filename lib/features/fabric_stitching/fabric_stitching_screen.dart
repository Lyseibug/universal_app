import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/menu/menu_models.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/pdt_scaffold.dart';
import 'fabric_stitching_repository.dart';

class FabricStitchingScreen extends ConsumerStatefulWidget {
  final MenuScreen screen;
  const FabricStitchingScreen({required this.screen, super.key});

  @override
  ConsumerState<FabricStitchingScreen> createState() => _FabricStitchingScreenState();
}

class _FabricStitchingScreenState extends ConsumerState<FabricStitchingScreen> {
  final _stitchCountCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();

  List<String> _lines = [];
  String? _selectedLine;
  List<Map<String, dynamic>> _todayLogs = [];

  bool _loadingLines = true;
  bool _loadingLogs = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadLines();
  }

  @override
  void dispose() {
    _stitchCountCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadLines() async {
    setState(() => _loadingLines = true);
    try {
      final lines = await ref.read(fabricStitchingRepositoryProvider).listLines();
      setState(() {
        _lines = lines;
        _selectedLine = lines.isNotEmpty ? lines.first : null;
        _loadingLines = false;
      });
      await _loadTodayLogs();
    } catch (e) {
      setState(() => _loadingLines = false);
    }
  }

  Future<void> _loadTodayLogs() async {
    if (_selectedLine == null) return;
    setState(() => _loadingLogs = true);
    try {
      final logs = await ref
          .read(fabricStitchingRepositoryProvider)
          .getTodayStitchLogs(workstationLine: _selectedLine);
      if (mounted) setState(() { _todayLogs = logs; _loadingLogs = false; });
    } catch (e) {
      if (mounted) setState(() => _loadingLogs = false);
    }
  }

  Future<void> _save() async {
    final count = int.tryParse(_stitchCountCtrl.text.trim());
    if (_selectedLine == null) {
      _showError('Select a line');
      return;
    }
    if (count == null || count <= 0) {
      _showError('Enter a stitch count greater than 0');
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(fabricStitchingRepositoryProvider).recordStitchCount(
            workstationLine: _selectedLine!,
            stitchCount: count,
            remarks: _remarksCtrl.text.trim().isEmpty ? null : _remarksCtrl.text.trim(),
          );
      if (mounted) {
        // No toast — the form clearing and today's log list refreshing
        // below is confirmation enough for this per-entry action.
        _stitchCountCtrl.clear();
        _remarksCtrl.clear();
      }
      await _loadTodayLogs();
    } catch (e) {
      _showError('Error: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message), backgroundColor: AppTheme.danger));
  }

  int get _todayTotal => _todayLogs.fold(0, (sum, l) => sum + ((l['stitch_count'] as num?)?.toInt() ?? 0));

  @override
  Widget build(BuildContext context) {
    return PdtScaffold(
      title: widget.screen.label,
      body: _loadingLines
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedLine,
                  decoration: const InputDecoration(
                    labelText: 'Line',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: _lines
                      .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                      .toList(),
                  onChanged: (v) {
                    setState(() => _selectedLine = v);
                    _loadTodayLogs();
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _stitchCountCtrl,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Stitch Count',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _remarksCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Remarks (optional)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 16),
                CustomButton(
                  text: _saving ? 'Saving...' : 'Log Stitch Count',
                  icon: Icons.save,
                  isLoading: _saving,
                  backgroundColor: AppTheme.primary,
                  textColor: Colors.white,
                  onPressed: _saving ? null : _save,
                ),
                const SizedBox(height: 24),
                Text('Today — $_selectedLine (Total: $_todayTotal)',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                if (_loadingLogs)
                  const Center(child: CircularProgressIndicator())
                else if (_todayLogs.isEmpty)
                  const Text('No entries yet today', style: TextStyle(color: Colors.grey))
                else
                  ..._todayLogs.map((l) => Card(
                        child: ListTile(
                          dense: true,
                          title: Text('${l['stitch_count']} stitches'),
                          subtitle: l['remarks'] != null && l['remarks'].toString().isNotEmpty
                              ? Text(l['remarks'].toString())
                              : null,
                          trailing: Text(l['entered_by']?.toString() ?? '',
                              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                        ),
                      )),
              ],
            ),
    );
  }
}
