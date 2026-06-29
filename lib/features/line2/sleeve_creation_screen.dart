import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/menu/menu_models.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/pdt_scaffold.dart';
import '../../widgets/scan_input_field.dart';
import 'line2_repository.dart';

class SleeveCreationScreen extends ConsumerStatefulWidget {
  final MenuScreen screen;
  const SleeveCreationScreen({required this.screen, super.key});

  @override
  ConsumerState<SleeveCreationScreen> createState() =>
      _SleeveCreationScreenState();
}

class _SleeveCreationScreenState extends ConsumerState<SleeveCreationScreen> {
  final _workOrderCtrl = TextEditingController();
  final _workOrderFocus = FocusNode();
  final _sleeveCountCtrl = TextEditingController();

  bool _creating = false;
  String? _error;
  Map<String, dynamic>? _result;

  @override
  void dispose() {
    _workOrderCtrl.dispose();
    _workOrderFocus.dispose();
    _sleeveCountCtrl.dispose();
    super.dispose();
  }

  Future<void> _createSleeves() async {
    final workOrder = _workOrderCtrl.text.trim();
    final sleeveCount = int.tryParse(_sleeveCountCtrl.text.trim());

    if (workOrder.isEmpty) {
      _showError('Scan or enter work order');
      return;
    }
    if (sleeveCount == null || sleeveCount <= 0) {
      _showError('Enter a valid sleeve count');
      return;
    }

    setState(() {
      _creating = true;
      _error = null;
      _result = null;
    });

    try {
      final result = await ref.read(line2RepositoryProvider).createSleeves(
            workOrder: workOrder,
            sleeveCount: sleeveCount,
          );
      setState(() {
        _result = result;
        _creating = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Sleeves created successfully'),
          backgroundColor: AppTheme.success,
        ));
      }
    } catch (e) {
      setState(() {
        _error = 'Creation failed: $e';
        _creating = false;
      });
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppTheme.danger,
    ));
  }

  void _resetForm() {
    setState(() {
      _workOrderCtrl.clear();
      _sleeveCountCtrl.clear();
      _error = null;
      _result = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PdtScaffold(
      title: widget.screen.label,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Work order scan
          ScanInputField(
            controller: _workOrderCtrl,
            focusNode: _workOrderFocus,
            labelText: 'Work Order',
            hintText: 'Scan or enter work order',
            autofocus: true,
          ),
          const SizedBox(height: 12),

          // Sleeves count
          TextField(
            controller: _sleeveCountCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Sleeves Produced',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 16),

          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                color: AppTheme.dangerLight,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppTheme.danger),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_error!,
                          style: const TextStyle(color: AppTheme.danger))),
                    ],
                  ),
                ),
              ),
            ),

          // Result card
          if (_result != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                color: AppTheme.successLight,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.check_circle,
                              color: AppTheme.success, size: 20),
                          SizedBox(width: 8),
                          Text('Sleeves Created',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.success,
                                  fontSize: 16)),
                        ],
                      ),
                      const Divider(height: 16),
                      if (_result!['batch_no'] != null)
                        _resultRow('Batch No', _result!['batch_no'].toString()),
                      if (_result!['stock_entry'] != null)
                        _resultRow(
                            'Stock Entry', _result!['stock_entry'].toString()),
                      if (_result!['sleeve_count'] != null)
                        _resultRow('Count',
                            _result!['sleeve_count'].toString()),
                    ],
                  ),
                ),
              ),
            ),

          // Action buttons
          CustomButton(
            text: _creating ? 'Creating...' : 'Create Sleeves',
            icon: Icons.add_circle,
            isLoading: _creating,
            backgroundColor: AppTheme.primary,
            textColor: Colors.white,
            onPressed: _creating ? null : _createSleeves,
          ),
          const SizedBox(height: 8),
          CustomButton(
            text: 'Reset',
            icon: Icons.refresh,
            outlined: true,
            onPressed: _resetForm,
          ),
        ],
      ),
    );
  }

  Widget _resultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
