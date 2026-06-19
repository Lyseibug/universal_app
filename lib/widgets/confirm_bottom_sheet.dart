import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import 'custom_button.dart';

class ConfirmBottomSheet extends StatelessWidget {
  final String title;
  final String message;
  final Map<String, String> details;
  final String confirmText;
  final String cancelText;
  final VoidCallback onConfirm;

  const ConfirmBottomSheet({
    required this.title,
    required this.message,
    required this.details,
    this.confirmText = 'Confirm',
    this.cancelText = 'Cancel',
    required this.onConfirm,
    super.key,
  });

  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    required Map<String, String> details,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    required VoidCallback onConfirm,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => ConfirmBottomSheet(
        title: title,
        message: message,
        details: details,
        confirmText: confirmText,
        cancelText: cancelText,
        onConfirm: () {
          Navigator.pop(ctx, true);
          onConfirm();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppTheme.horizontalPad,
        right: AppTheme.horizontalPad,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppTheme.warning, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(fontSize: 15, color: AppTheme.textSecondary),
          ),
          if (details.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.bgElevated,
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                border: Border.all(color: AppTheme.bgBorder),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: details.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${entry.key}: ',
                          style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                        ),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(cancelText),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  text: confirmText,
                  onPressed: onConfirm,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
