import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/models/maintenance_request_models.dart';
import '../../core/sync/write_queue.dart';
import '../../providers/service_providers.dart';

class MaintenanceRepository {
  final ApiClient _api;
  final WriteQueue _writeQueue;

  MaintenanceRepository({required ApiClient api, required WriteQueue writeQueue})
      : _api = api,
        _writeQueue = writeQueue;

  /// Issue types relevant to [machine]'s station type, grouped by category —
  /// backs the raise-request screen's issue picker.
  Future<List<DownTimeIssueGroup>> listIssueTypes(String machine) async {
    final data = await _api.call('maintenance_requests.list_issue_types', body: {
      'machine': machine,
    });
    if (data is List) {
      return data
          .map((j) => DownTimeIssueGroup.fromJson(Map<String, dynamic>.from(j)))
          .toList();
    }
    return const [];
  }

  Future<dynamic> create({
    required String machine,
    required String issueType,
    String? description,
    String? urgency,
  }) async {
    return _writeQueue.run('maintenance_requests.create', {
      'machine': machine,
      'issue_type': issueType,
      if (description != null && description.isNotEmpty) 'description': description,
      if (urgency != null && urgency.isNotEmpty) 'urgency': urgency,
    });
  }

  /// The shared maintenance queue — maintenance_team screen only.
  Future<List<MaintenanceRequestSummary>> listRequests({String? status}) async {
    final data = await _api.call('maintenance_requests.list_requests', body: {
      if (status != null) 'status': status,
    });
    if (data is List) {
      return data
          .map((j) => MaintenanceRequestSummary.fromJson(Map<String, dynamic>.from(j)))
          .toList();
    }
    return const [];
  }

  Future<dynamic> updateStatus(String name, String status) async {
    return _writeQueue.run('maintenance_requests.update_status', {
      'name': name,
      'status': status,
    });
  }
}

final maintenanceRepositoryProvider = Provider<MaintenanceRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  final writeQueue = ref.watch(writeQueueProvider);
  return MaintenanceRepository(api: api, writeQueue: writeQueue);
});
