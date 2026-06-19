import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_exceptions.dart';
import '../../core/errors/error_mapper.dart';
import '../../core/menu/menu_models.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/service_providers.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/pdt_scaffold.dart';
import '../../widgets/scan_input_field.dart';
import '../../widgets/confirm_bottom_sheet.dart';
import 'inventory_repository.dart';

class PhysicalInventoryScreen extends ConsumerStatefulWidget {
  final MenuScreen screen;

  const PhysicalInventoryScreen({required this.screen, super.key});

  @override
  ConsumerState<PhysicalInventoryScreen> createState() => _PhysicalInventoryScreenState();
}

class _PhysicalInventoryScreenState extends ConsumerState<PhysicalInventoryScreen> {
  String? _activeLot;
  bool _loading = false;
  List<Map<String, dynamic>> _counts = []; // items being counted: item_code, batch_no, system_qty, counted_qty

  // Form states for manual count adjustment
  Map<String, dynamic>? _editingItem;
  final _countCtrl = TextEditingController();
  final _countFocus = FocusNode();

  final _startLotCtrl = TextEditingController();
  final _startLotFocus = FocusNode();

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _startLotFocus.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _countCtrl.dispose();
    _countFocus.dispose();
    _startLotCtrl.dispose();
    _startLotFocus.dispose();
    super.dispose();
  }

  void _onItemScanned(String barcode) {
    final cleanBarcode = barcode.trim();
    bool found = false;

    for (int i = 0; i < _counts.length; i++) {
      if (_counts[i]['item_code'].toString().toLowerCase() == cleanBarcode.toLowerCase() ||
          _counts[i]['batch_no'].toString().toLowerCase() == cleanBarcode.toLowerCase()) {
        setState(() {
          final current = _counts[i]['counted_qty'] ?? 0.0;
          _counts[i]['counted_qty'] = current + 1.0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Incremented ${_counts[i]['item_code']} count to ${_counts[i]['counted_qty']}'),
            duration: const Duration(seconds: 1),
            backgroundColor: AppTheme.success,
          ),
        );
        found = true;
        break;
      }
    }

    if (!found) {
      // Barcode not in the system expected list - add it as a new count row
      setState(() {
        _counts.add({
          'item_code': cleanBarcode,
          'batch_no': '',
          'system_qty': 0.0,
          'counted_qty': 1.0,
        });
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added new item $cleanBarcode with count 1.0'),
          duration: const Duration(seconds: 2),
          backgroundColor: AppTheme.info,
        ),
      );
    }
  }

  Future<void> _startSession(String lot) async {
    final cleanLot = lot.trim();
    if (cleanLot.isEmpty) return;

    setState(() {
      _loading = true;
      _activeLot = null;
      _counts = [];
    });

    try {
      final items = await ref.read(inventoryRepositoryProvider).startSession(cleanLot);
      setState(() {
        _activeLot = cleanLot;
        _counts = items.map((e) {
          final m = Map<String, dynamic>.from(e);
          // Set initial counted qty equal to system qty (as per plan specs)
          m['counted_qty'] = m['counted_qty'] ?? m['system_qty'] ?? 0.0;
          return m;
        }).toList();
      });
    } on ApiException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(messageFor(e)), backgroundColor: AppTheme.danger),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.danger),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _editItemCount(Map<String, dynamic> item) {
    setState(() {
      _editingItem = item;
      _countCtrl.text = (item['counted_qty'] ?? 0.0).toString();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _countFocus.requestFocus();
      }
    });
  }

  void _saveItemCount() {
    if (_editingItem == null) return;
    final val = double.tryParse(_countCtrl.text) ?? 0.0;
    
    setState(() {
      for (var item in _counts) {
        if (item['item_code'] == _editingItem!['item_code'] &&
            item['batch_no'] == _editingItem!['batch_no']) {
          item['counted_qty'] = val;
          break;
        }
      }
      _editingItem = null;
    });
  }

  Future<void> _submitCounts() async {
    if (_activeLot == null || _counts.isEmpty) return;

    if (!widget.screen.can('submit_count')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Access denied. Action: submit_count is restricted.'), backgroundColor: AppTheme.danger),
      );
      return;
    }

    // Identify discrepancies
    final discrepancies = _counts.where((c) {
      final sys = c['system_qty'] ?? 0.0;
      final cnt = c['counted_qty'] ?? 0.0;
      return sys != cnt;
    }).toList();

    if (discrepancies.isNotEmpty) {
      final details = <String, String>{};
      for (var d in discrepancies) {
        final item = d['item_code'];
        final batch = d['batch_no'] != null && d['batch_no'].toString().isNotEmpty ? ' (${d['batch_no']})' : '';
        details['$item$batch'] = 'System: ${d['system_qty']} | Counted: ${d['counted_qty']}';
      }

      final confirmed = await ConfirmBottomSheet.show(
        context: context,
        title: 'Submit Stock Audit',
        message: 'There are ${discrepancies.length} discrepancy items in this count. Do you want to proceed with submission?',
        details: details,
        confirmText: 'Submit Audit',
        onConfirm: _submitCountsActual,
      );
      if (confirmed != true) return;
    } else {
      // No discrepancies, submit immediately
      await _submitCountsActual();
    }
  }

  Future<void> _submitCountsActual() async {
    setState(() => _submitting = true);
    
    try {
      final formattedCounts = _counts.map((c) => {
        'item_code': c['item_code'],
        'batch_no': c['batch_no'] ?? '',
        'counted_qty': c['counted_qty'] ?? 0.0,
      }).toList();

      final response = await ref.read(inventoryRepositoryProvider).submitCounts(
            lot: _activeLot!,
            counts: formattedCounts,
          );

      final recName = (response is Map && response.containsKey('name'))
          ? response['name'].toString()
          : (response is Map && response.containsKey('message') && response['message'] is Map && response['message'].containsKey('name'))
              ? response['message']['name'].toString()
              : 'Synced';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Stock audit submitted successfully! ID: $recName'),
          backgroundColor: AppTheme.success,
          duration: const Duration(seconds: 4),
        ),
      );

      setState(() {
        _activeLot = null;
        _counts = [];
      });
      _startLotCtrl.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _startLotFocus.requestFocus();
        }
      });
    } on ApiException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(messageFor(e)), backgroundColor: AppTheme.danger),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.danger),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PdtScaffold(
      title: _activeLot == null ? widget.screen.label : 'Counting Lot: $_activeLot',
      body: _activeLot == null ? _buildStartBody() : _buildCountingBody(),
    );
  }

  Widget _buildStartBody() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.horizontalPad),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.format_list_numbered_outlined, size: 72, color: AppTheme.primary),
              const SizedBox(height: 24),
              const Text(
                'Start Stock Audit',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Scan a Lot or Bin location to fetch stock records and start counting.',
                style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              ScanInputField(
                controller: _startLotCtrl,
                focusNode: _startLotFocus,
                labelText: 'Scan Location / Lot',
                hintText: 'Press trigger or scan location',
                prefixIcon: Icons.qr_code_scanner,
                textInputAction: TextInputAction.go,
                onSubmitted: _startSession,
                onScanned: _startSession,
              ),
              const SizedBox(height: 20),
              
              CustomButton(
                text: 'Fetch Location Stock',
                isLoading: _loading,
                icon: Icons.refresh,
                onPressed: () => _startSession(_startLotCtrl.text),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountingBody() {
    return WillPopScope(
      onWillPop: () async {
        setState(() {
          _activeLot = null;
          _counts = [];
        });
        return false;
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Quick instruction banner
          Container(
            color: AppTheme.primary.withValues(alpha: 0.08),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppTheme.primary, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Scan an item barcode to increment its count, or tap an item to enter count manually.',
                    style: TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),

          // Hidden item scanner hook
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: ScanInputField(
              controller: TextEditingController(),
              focusNode: FocusNode(),
              labelText: 'Scan item barcode',
              hintText: 'Ready to scan items...',
              autofocus: true,
              onScanned: _onItemScanned,
            ),
          ),

          // List of counted items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(AppTheme.horizontalPad),
              itemCount: _counts.length,
              itemBuilder: (context, i) {
                final item = _counts[i];
                final isEditing = _editingItem != null &&
                    _editingItem!['item_code'] == item['item_code'] &&
                    _editingItem!['batch_no'] == item['batch_no'];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    color: isEditing ? AppTheme.amberLight : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                      side: BorderSide(
                        color: isEditing ? AppTheme.amber : AppTheme.bgBorder,
                        width: isEditing ? 2.0 : 1.0,
                      ),
                    ),
                    child: ListTile(
                      title: Text(
                        item['item_code'].toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (item['batch_no'] != null && item['batch_no'].toString().isNotEmpty)
                            Text('Batch/Lot: ${item['batch_no']}'),
                          Text('System Stock: ${item['system_qty']}'),
                        ],
                      ),
                      trailing: isEditing
                          ? SizedBox(
                              width: 120,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _countCtrl,
                                      focusNode: _countFocus,
                                      keyboardType: TextInputType.number,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      decoration: const InputDecoration(
                                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      ),
                                      onSubmitted: (_) => _saveItemCount(),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.check, color: AppTheme.success),
                                    onPressed: _saveItemCount,
                                  ),
                                ],
                              ),
                            )
                          : Text(
                              'Counted: ${item['counted_qty']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: AppTheme.primary,
                              ),
                            ),
                      onTap: isEditing ? null : () => _editItemCount(item),
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom action bar
          Padding(
            padding: const EdgeInsets.all(AppTheme.horizontalPad),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _activeLot = null;
                        _counts = [];
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, AppTheme.buttonHeight),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    text: 'Submit Audit Count',
                    isLoading: _submitting,
                    icon: Icons.cloud_upload_outlined,
                    onPressed: widget.screen.can('submit_count') ? _submitCounts : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
