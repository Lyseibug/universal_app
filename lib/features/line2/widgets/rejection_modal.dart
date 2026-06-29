import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../widgets/custom_button.dart';

class RejectionEntry {
  final String code;
  final String description;
  final int qty;
  final String? reworkStep;
  final bool isFullScrap;

  const RejectionEntry({
    required this.code,
    required this.description,
    required this.qty,
    this.reworkStep,
    this.isFullScrap = false,
  });
}

class RejectionModal extends StatefulWidget {
  final List<Map<String, dynamic>> rejectionCodes;
  final int maxQty;
  final ValueChanged<RejectionEntry> onSubmit;

  const RejectionModal({
    required this.rejectionCodes,
    required this.maxQty,
    required this.onSubmit,
    super.key,
  });

  static Future<RejectionEntry?> show(
    BuildContext context, {
    required List<Map<String, dynamic>> rejectionCodes,
    required int maxQty,
  }) {
    return showModalBottomSheet<RejectionEntry>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        RejectionEntry? result;
        return RejectionModal(
          rejectionCodes: rejectionCodes,
          maxQty: maxQty,
          onSubmit: (entry) {
            result = entry;
            Navigator.of(ctx).pop(result);
          },
        );
      },
    );
  }

  @override
  State<RejectionModal> createState() => _RejectionModalState();
}

class _RejectionModalState extends State<RejectionModal> {
  Map<String, dynamic>? _selectedCode;
  int _qty = 1;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 20 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.bgBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'ADD REJECTION',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          const Text('REASON CODE',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary, letterSpacing: 1.0)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _selectedCode?['code']?.toString(),
            decoration: const InputDecoration(hintText: 'Select reason code'),
            items: widget.rejectionCodes.map((c) {
              final code = c['code']?.toString() ?? '';
              final desc = c['description']?.toString() ?? '';
              return DropdownMenuItem<String>(
                value: code,
                child: Text('$code - $desc', overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: (val) {
              setState(() {
                _selectedCode = widget.rejectionCodes.firstWhere(
                  (c) => c['code']?.toString() == val,
                  orElse: () => {},
                );
              });
            },
          ),

          if (_selectedCode != null) ...[
            const SizedBox(height: 12),
            const Text('REASON DESCRIPTION',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary, letterSpacing: 1.0)),
            const SizedBox(height: 4),
            Text(
              _selectedCode!['description']?.toString() ?? '',
              style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
            ),
          ],

          const SizedBox(height: 16),
          const Text('REJECTED QTY',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary, letterSpacing: 1.0)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filled(
                onPressed: _qty > 1 ? () => setState(() => _qty--) : null,
                icon: const Icon(Icons.remove),
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.bgElevated,
                  foregroundColor: AppTheme.textPrimary,
                  disabledBackgroundColor: AppTheme.bgBorder,
                ),
              ),
              const SizedBox(width: 24),
              Text(
                '$_qty',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
              ),
              const SizedBox(width: 24),
              IconButton.filled(
                onPressed: _qty < widget.maxQty ? () => setState(() => _qty++) : null,
                icon: const Icon(Icons.add),
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.bgElevated,
                  foregroundColor: AppTheme.textPrimary,
                  disabledBackgroundColor: AppTheme.bgBorder,
                ),
              ),
            ],
          ),
          Text(
            'Max: ${widget.maxQty}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),

          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Cancel',
                  outlined: true,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  text: 'Submit',
                  backgroundColor: AppTheme.danger,
                  textColor: Colors.white,
                  onPressed: _selectedCode == null
                      ? null
                      : () {
                          widget.onSubmit(RejectionEntry(
                            code: _selectedCode!['code']?.toString() ?? '',
                            description: _selectedCode!['description']?.toString() ?? '',
                            qty: _qty,
                            reworkStep: _selectedCode!['default_rework_step']?.toString(),
                            isFullScrap: (_selectedCode!['is_full_scrap'] ?? 0) == 1,
                          ));
                        },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
