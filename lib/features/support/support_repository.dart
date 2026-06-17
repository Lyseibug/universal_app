import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../providers/service_providers.dart';

/// Repository for Support & Notification operations.
class SupportRepository {
  final ApiClient _api;

  SupportRepository({required ApiClient api}) : _api = api;

  /// Sends a chat message to a recipient (defaults to supervisor on the server).
  Future<void> sendChat({required String message, String? recipient}) async {
    await _api.call('notifications.chat', body: {
      'message': message,
      if (recipient != null) 'recipient': recipient,
    });
  }

  /// Raises a support ticket.
  Future<void> raiseSupport({required String supportType, Map<String, dynamic>? payload}) async {
    await _api.call('notifications.raise_support', body: {
      'support_type': supportType,
      if (payload != null) 'payload': payload,
    });
  }

  /// Submits an equipment maintenance request.
  Future<void> raiseMaintenanceRequest({
    required String equipment,
    required String issueType,
    required String description,
    required String urgency,
  }) async {
    await _api.call('notifications.maintenance_request', body: {
      'equipment': equipment,
      'issue_type': issueType,
      'description': description,
      'urgency': urgency,
    });
  }

  /// Registers the device player ID for push notifications.
  Future<void> registerDevice(String playerId) async {
    await _api.call('notifications.register_device', body: {'player_id': playerId});
  }
}

/// Provider for SupportRepository.
final supportRepositoryProvider = Provider<SupportRepository>((ref) {
  return SupportRepository(api: ref.watch(apiClientProvider));
});
