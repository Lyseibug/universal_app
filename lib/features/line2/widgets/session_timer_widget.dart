import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class SessionTimerWidget extends StatefulWidget {
  final DateTime? startTime;
  final int? targetMinutes;

  const SessionTimerWidget({
    this.startTime,
    this.targetMinutes,
    super.key,
  });

  @override
  State<SessionTimerWidget> createState() => _SessionTimerWidgetState();
}

class _SessionTimerWidgetState extends State<SessionTimerWidget> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant SessionTimerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.startTime != oldWidget.startTime) {
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    if (widget.startTime == null) {
      setState(() => _elapsed = Duration.zero);
      return;
    }
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (!mounted) return;
    final now = DateTime.now();
    setState(() {
      _elapsed = now.difference(widget.startTime!);
      if (_elapsed.isNegative) _elapsed = Duration.zero;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _format(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h : $m : $s';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.startTime == null) return const SizedBox.shrink();

    final overTarget = widget.targetMinutes != null &&
        _elapsed.inMinutes >= widget.targetMinutes!;

    final timeStr =
        '${widget.startTime!.hour.toString().padLeft(2, '0')}:${widget.startTime!.minute.toString().padLeft(2, '0')}:${widget.startTime!.second.toString().padLeft(2, '0')}';

    return Card(
      color: overTarget ? AppTheme.dangerLight : AppTheme.bgSurface,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  'SESSION TIMER',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: overTarget ? AppTheme.danger : AppTheme.textSecondary,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: overTarget ? AppTheme.danger : AppTheme.success,
                  ),
                ),
                if (widget.targetMinutes != null) ...[
                  const Spacer(),
                  Text(
                    'Target: ${widget.targetMinutes}m',
                    style: TextStyle(
                      fontSize: 11,
                      color: overTarget ? AppTheme.danger : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _format(_elapsed),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: overTarget ? AppTheme.danger : AppTheme.textPrimary,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Started at $timeStr',
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
