import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_exceptions.dart';
import '../../core/errors/error_mapper.dart';
import '../../core/menu/menu_models.dart';
import '../../core/scanner/scan_service.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/service_providers.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'lot_repository.dart';

class LotBrowserScreen extends ConsumerStatefulWidget {
  final MenuScreen screen;

  const LotBrowserScreen({required this.screen, super.key});

  @override
  ConsumerState<LotBrowserScreen> createState() => _LotBrowserScreenState();
}

class _LotBrowserScreenState extends ConsumerState<LotBrowserScreen> {
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  
  bool _loading = false;
  Map<String, dynamic>? _lotDetail;
  String? _error;

  late StreamSubscription<String> _scanSubscription;

  @override
  void initState() {
    super.initState();
    _searchFocus.requestFocus();

    _scanSubscription = ref.read(keyboardScanServiceProvider).scans.listen((barcode) {
      if (_searchFocus.hasFocus) {
        _searchCtrl.text = barcode;
        _searchLot(barcode);
      } else {
        _searchCtrl.text = barcode;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _scanSubscription.cancel();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _searchLot(String lot) async {
    final cleanLot = lot.trim();
    if (cleanLot.isEmpty) return;

    setState(() {
      _loading = true;
      _lotDetail = null;
      _error = null;
    });

    try {
      final detail = await ref.read(lotRepositoryProvider).get(cleanLot);
      setState(() {
        _lotDetail = detail;
        _loading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _error = messageFor(e);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'An error occurred while fetching details.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardWedgeScanWidget(
      service: ref.read(keyboardScanServiceProvider),
      child: Scaffold(
        backgroundColor: AppTheme.bgScaffold,
        appBar: AppBar(
          title: const Text('LOT Browser'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(AppTheme.horizontalPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Search Input
              CustomTextField(
                controller: _searchCtrl,
                focusNode: _searchFocus,
                labelText: 'Scan or Enter Lot/Bin',
                hintText: 'Scan barcode location',
                prefixIcon: const Icon(Icons.qr_code_scanner),
                textStyle: AppTheme.scanValueStyle,
                textInputAction: TextInputAction.search,
                onSubmitted: _searchLot,
              ),
              const SizedBox(height: 14),
              CustomButton(
                text: 'Search Location',
                isLoading: _loading,
                icon: Icons.search,
                onPressed: () => _searchLot(_searchCtrl.text),
              ),
              const SizedBox(height: 24),
              
              // Result Display
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? _buildErrorView()
                        : _lotDetail != null
                            ? _buildDetailView()
                            : _buildPlaceholderView(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_outlined, size: 72, color: AppTheme.textDisabled.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          const Text(
            'Ready to Browse',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Scan or search a valid Lot number to view its warehouse zone, items, and FIFO quantities.',
            style: TextStyle(fontSize: 14, color: AppTheme.textDisabled),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.dangerLight,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppTheme.danger, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _error!,
                style: const TextStyle(color: AppTheme.danger, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailView() {
    final detail = _lotDetail!;
    final items = detail['items'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Location Info
        Card(
          color: AppTheme.primary.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lot/Bin: ${detail['name']}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppTheme.primary),
                ),
                const SizedBox(height: 8),
                Text('Warehouse: ${detail['warehouse'] ?? 'N/A'}'),
                Text('Zone: ${detail['zone'] ?? 'N/A'}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        const Text(
          'OCCUPIED ITEMS',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary, fontSize: 12, letterSpacing: 1.0),
        ),
        const SizedBox(height: 8),
        
        // Items List
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Text(
                    'No items in this location',
                    style: TextStyle(color: AppTheme.textDisabled, fontStyle: FontStyle.italic),
                  ),
                )
              : ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final item = Map<String, dynamic>.from(items[i]);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Card(
                        child: ListTile(
                          title: Text(
                            '${item['item_code']}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (item['batch_no'] != null && item['batch_no'].toString().isNotEmpty)
                                Text('Batch/Lot: ${item['batch_no']}'),
                              if (item['fifo_date'] != null)
                                Text('FIFO Date: ${item['fifo_date']}'),
                            ],
                          ),
                          trailing: Text(
                            '${item['qty']} ${item['uom'] ?? ''}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primary),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
