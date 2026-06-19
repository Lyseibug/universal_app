import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import 'status_chip.dart';

class LotCard extends StatelessWidget {
  final String lotName;
  final String? warehouse;
  final String? zone;
  final String status;
  final VoidCallback? onTap;

  const LotCard({
    required this.lotName,
    this.warehouse,
    this.zone,
    required this.status,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        title: Text(
          lotName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (warehouse != null) Text('Warehouse: $warehouse'),
            if (zone != null) Text('Zone: $zone'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            StatusChip(status: status),
            if (onTap != null) ...[
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.textSecondary),
            ]
          ],
        ),
      ),
    );
  }
}
