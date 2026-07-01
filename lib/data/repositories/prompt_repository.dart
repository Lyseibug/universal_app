import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/models/worker_prompt.dart';
import '../../providers/service_providers.dart';

class PromptRepository {
  final ApiClient _api;

  PromptRepository({required ApiClient api}) : _api = api;

  /// Returns null when no prompt is currently pending for the active session.
  Future<WorkerPrompt?> getPendingPrompt() async {
    final dynamic data = await _api.call('prompt.get_pending_prompt');
    if (data == null || data is! Map || data['pending'] != true) {
      return null;
    }
    return WorkerPrompt.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> submitResponse(String response) async {
    await _api.call('prompt.submit_prompt_response', body: {'response': response});
  }
}

final promptRepositoryProvider = Provider<PromptRepository>((ref) {
  return PromptRepository(api: ref.watch(apiClientProvider));
});
