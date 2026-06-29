import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class SupportHelpSection extends StatelessWidget {
  final VoidCallback? onRaiseIssue;
  final VoidCallback? onCallSupervisor;

  const SupportHelpSection({
    this.onRaiseIssue,
    this.onCallSupervisor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SUPPORT & HELP',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onRaiseIssue ?? () {
                  Scaffold.of(context).openEndDrawer();
                },
                icon: const Icon(Icons.help_outline, size: 18),
                label: const Text('Raise an issue'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  foregroundColor: AppTheme.info,
                  side: const BorderSide(color: AppTheme.info),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onCallSupervisor ?? () {
                  Scaffold.of(context).openEndDrawer();
                },
                icon: const Icon(Icons.phone_outlined, size: 18),
                label: const Text('Call supervisor'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  foregroundColor: AppTheme.warning,
                  side: const BorderSide(color: AppTheme.warning),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
