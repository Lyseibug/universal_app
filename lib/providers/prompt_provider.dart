import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/models/worker_prompt.dart';
import '../core/utils/logger.dart';
import '../data/repositories/prompt_repository.dart';
import 'auth_provider.dart';

/// Polls for a pending idle/overrun worker prompt, same cadence pattern as
/// UnreadNotificationCountNotifier. The root app widget listens to this and
/// shows a blocking dialog asking the worker for a reason when non-null.
class WorkerPromptNotifier extends StateNotifier<WorkerPrompt?> {
  final PromptRepository _repo;
  final Ref _ref;
  Timer? _timer;

  WorkerPromptNotifier(this._repo, this._ref) : super(null) {
    _init();
  }

  void _init() {
    _ref.listen<AuthState>(
      authProvider,
      (previous, next) {
        if (next.isAuthenticated) {
          startPolling();
        } else {
          stopPolling();
        }
      },
      fireImmediately: true,
    );
  }

  void startPolling() {
    _timer?.cancel();
    fetchPrompt();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => fetchPrompt());
  }

  void stopPolling() {
    _timer?.cancel();
    _timer = null;
    state = null;
  }

  Future<void> fetchPrompt() async {
    final auth = _ref.read(authProvider);
    if (!auth.isAuthenticated) return;

    try {
      final prompt = await _repo.getPendingPrompt();
      if (mounted) state = prompt;
    } catch (e) {
      AppLogger.warning('Failed to poll worker prompt: $e', tag: 'WorkerPromptNotifier');
    }
  }

  Future<void> respond(String response) async {
    await _repo.submitResponse(response);
    if (mounted) state = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final workerPromptProvider =
    StateNotifierProvider<WorkerPromptNotifier, WorkerPrompt?>((ref) {
  final repo = ref.watch(promptRepositoryProvider);
  return WorkerPromptNotifier(repo, ref);
});
