import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class StatusChip extends StatelessWidget {
  final String status;

  const StatusChip({required this.status, super.key});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    String label = status.toUpperCase();

    switch (status.toLowerCase()) {
      case 'pending':
      case 'open':
      case 'unassigned':
        bgColor = AppTheme.bgBorder;
        textColor = AppTheme.textSecondary;
        break;
      case 'in progress':
      case 'claiming':
      case 'progress':
        bgColor = AppTheme.warningLight;
        textColor = AppTheme.warning;
        break;
      case 'completed':
      case 'synced':
      case 'success':
        bgColor = AppTheme.successLight;
        textColor = AppTheme.success;
        break;
      case 'failed':
      case 'error':
        bgColor = AppTheme.dangerLight;
        textColor = AppTheme.danger;
        break;
      default:
        bgColor = AppTheme.bgElevated;
        textColor = AppTheme.textPrimary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
