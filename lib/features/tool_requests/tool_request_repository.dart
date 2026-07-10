import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/models/tool_request_models.dart';
import '../../core/sync/write_queue.dart';
import '../../providers/service_providers.dart';

/// Shared between Line 1 (Calendering rolls) and Line 2 (Mold/Airbag/
/// Grinding Wheel/Curing Pot) — tool types span both lines, so this isn't
/// nested under either feature folder.
class ToolRequestRepository {
  final ApiClient _api;
  final WriteQueue _writeQueue;

  ToolRequestRepository({required ApiClient api, required WriteQueue writeQueue})
      : _api = api,
        _writeQueue = writeQueue;

  Future<List<ToolRequest>> listRequests({String? status}) async {
    final data = await _api.call('tool_requests.list_requests', body: {
      if (status != null) 'status': status,
    });
    if (data is List) {
      return data
          .map((j) => ToolRequest.fromJson(Map<String, dynamic>.from(j)))
          .toList();
    }
    return const [];
  }

  Future<ToolRequestDetail> getRequest(String name) async {
    final data = await _api.call('tool_requests.get_request', body: {'name': name});
    return ToolRequestDetail.fromJson(Map<String, dynamic>.from(data));
  }

  Future<dynamic> create({
    required String targetWorkstation,
    required List<Map<String, dynamic>> items,
    String? remarks,
  }) async {
    return _writeQueue.run('tool_requests.create', {
      'target_workstation': targetWorkstation,
      'items': items,
      if (remarks != null) 'remarks': remarks,
    });
  }

  Future<dynamic> submit(String name) async {
    return _writeQueue.run('tool_requests.submit_request', {'name': name});
  }

  Future<ToolRequestFulfillResult> fulfill(String name) async {
    final data = await _writeQueue.run('tool_requests.fulfill', {'name': name});
    return ToolRequestFulfillResult.fromJson(Map<String, dynamic>.from(data));
  }
}

final toolRequestRepositoryProvider = Provider<ToolRequestRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  final writeQueue = ref.watch(writeQueueProvider);
  return ToolRequestRepository(api: api, writeQueue: writeQueue);
});
