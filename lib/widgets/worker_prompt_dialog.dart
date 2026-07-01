import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/models/worker_prompt.dart';
import '../core/theme/app_theme.dart';
import '../providers/prompt_provider.dart';
import '../routes/app_router.dart';

/// Mounted once at the app root (see main.dart). Watches [workerPromptProvider]
/// and pops up a blocking dialog — wherever the worker currently is in the
/// app — asking them to explain an idle period or a workstation time
/// overrun. Uses [rootNavigatorKey] rather than its own BuildContext so the
/// dialog reliably has a Navigator ancestor regardless of where this widget
/// sits relative to GoRouter's Router.
class WorkerPromptListener extends ConsumerStatefulWidget {
  final Widget child;
  const WorkerPromptListener({required this.child, super.key});

  @override
  ConsumerState<WorkerPromptListener> createState() => _WorkerPromptListenerState();
}

class _WorkerPromptListenerState extends ConsumerState<WorkerPromptListener> {
  bool _dialogShowing = false;

  @override
  Widget build(BuildContext context) {
    ref.listen<WorkerPrompt?>(workerPromptProvider, (previous, next) {
      if (next != null && !_dialogShowing) {
        _showDialog(next);
      }
    });
    return widget.child;
  }

  Future<void> _showDialog(WorkerPrompt prompt) async {
    final dialogContext = rootNavigatorKey.currentContext;
    if (dialogContext == null) return;

    _dialogShowing = true;
    final ctrl = TextEditingController();
    final isOverrun = prompt.type == 'Overrun';

    bool submitting = false;
    String? error;

    await showDialog<void>(
      context: dialogContext,
      barrierDismissible: false,
      builder: (dialogCtx) => PopScope(
        canPop: false,
        child: StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              icon: Icon(
                isOverrun ? Icons.timer_off_rounded : Icons.help_outline_rounded,
                color: AppTheme.amber,
                size: 32,
              ),
              title: Text(isOverrun ? 'Workstation Time Exceeded' : 'Are You Still There?'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(prompt.message),
                  const SizedBox(height: 16),
                  TextField(
                    controller: ctrl,
                    autofocus: true,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: "What's going on?",
                      border: const OutlineInputBorder(),
                      errorText: error,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Your supervisor has already been notified.',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: submitting
                      ? null
                      : () async {
                          final text = ctrl.text.trim();
                          if (text.isEmpty) {
                            setDialogState(() => error = 'Please enter a reason');
                            return;
                          }
                          setDialogState(() {
                            submitting = true;
                            error = null;
                          });
                          try {
                            await ref.read(workerPromptProvider.notifier).respond(text);
                            if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
                          } catch (e) {
                            setDialogState(() {
                              submitting = false;
                              error = 'Failed to submit — try again';
                            });
                          }
                        },
                  child: submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Submit'),
                ),
              ],
            );
          },
        ),
      ),
    );

    _dialogShowing = false;
  }
}
