import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class ProductDetailsCard extends StatelessWidget {
  final String itemName;
  final String lotNo;
  final String category;
  final String? workOrder;
  final double? qty;
  /// Before the step that splits a bulk-planned unit into individual
  /// pieces (Cutting/Two-Piece Cutting), qty is a sleeve-equivalent count,
  /// not a raw belt count — see line2_building._display_qty. This label
  /// (e.g. "Sleeve" vs "Belt") makes that unambiguous instead of showing a
  /// bare number.
  final String? qtyUom;
  final bool verified;

  const ProductDetailsCard({
    required this.itemName,
    required this.lotNo,
    required this.category,
    this.workOrder,
    this.qty,
    this.qtyUom,
    this.verified = true,
    super.key,
  });

  factory ProductDetailsCard.fromScanResult(Map<String, dynamic> data) {
    return ProductDetailsCard(
      itemName: data['item_name']?.toString() ?? data['production_item']?.toString() ?? '',
      lotNo: data['flowchart_barcode']?.toString() ?? data['work_order']?.toString() ?? '',
      category: data['category']?.toString() ?? data['production_type']?.toString() ?? '',
      workOrder: data['work_order']?.toString(),
      qty: (data['qty'] as num?)?.toDouble(),
      qtyUom: data['qty_uom']?.toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'PRODUCT DETAILS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                    letterSpacing: 1.0,
                  ),
                ),
                const Spacer(),
                if (verified)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.successLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 14, color: AppTheme.success),
                        SizedBox(width: 4),
                        Text('Verified',
                            style: TextStyle(fontSize: 11, color: AppTheme.success, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              itemName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 6),
            _infoRow('Lot No', lotNo),
            _infoRow('Category', category),
            if (workOrder != null) _infoRow('Work Order', workOrder!),
            if (qty != null)
              _infoRow(
                'Qty',
                '${qty!.toStringAsFixed(qty! == qty!.roundToDouble() ? 0 : 2)}'
                '${qtyUom != null && qtyUom!.isNotEmpty ? ' $qtyUom' : ''}',
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
          ),
        ],
      ),
    );
  }
}
