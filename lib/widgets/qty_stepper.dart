import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class QtyStepper extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final double step;
  final double min;
  final double? max;

  const QtyStepper({
    required this.value,
    required this.onChanged,
    this.step = 1.0,
    this.min = 0.0,
    this.max,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        border: Border.all(color: AppTheme.bgBorder, width: AppTheme.borderWidth),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Decrement
          IconButton(
            iconSize: 28,
            padding: const EdgeInsets.all(12),
            icon: const Icon(Icons.remove, color: AppTheme.primary),
            onPressed: value > min
                ? () {
                    final newValue = value - step;
                    onChanged(newValue < min ? min : newValue);
                  }
                : null,
          ),
          Container(
            width: 80,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              border: Border(
                left: BorderSide(color: AppTheme.bgBorder, width: AppTheme.borderWidth),
                right: BorderSide(color: AppTheme.bgBorder, width: AppTheme.borderWidth),
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              value.toStringAsFixed(value % 1 == 0 ? 0 : 2),
              style: AppTheme.scanValueStyle.copyWith(fontSize: 20),
            ),
          ),
          // Increment
          IconButton(
            iconSize: 28,
            padding: const EdgeInsets.all(12),
            icon: const Icon(Icons.add, color: AppTheme.primary),
            onPressed: max == null || value < max!
                ? () {
                    final newValue = value + step;
                    onChanged(max != null && newValue > max! ? max! : newValue);
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
