import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/sync/write_queue.dart';
import '../../providers/service_providers.dart';

/// Repository for the Fabric Stitching station — deliberately the simplest
/// station in the system: no flowchart, no Job Card, just a daily stitch
/// count per line.
class FabricStitchingRepository {
  final ApiClient _api;
  final WriteQueue _writeQueue;

  FabricStitchingRepository({required ApiClient api, required WriteQueue writeQueue})
      : _api = api,
        _writeQueue = writeQueue;

  Future<List<String>> listLines() async {
    final data = await _api.call('fabric_stitching.list_lines', body: {});
    if (data is List) {
      return data.map((e) => e.toString()).toList();
    }
    return const [];
  }

  Future<Map<String, dynamic>> recordStitchCount({
    required String workstationLine,
    required int stitchCount,
    String? remarks,
  }) async {
    final result = await _writeQueue.run('fabric_stitching.record_stitch_count', {
      'workstation_line': workstationLine,
      'stitch_count': stitchCount,
      if (remarks != null) 'remarks': remarks,
    });
    return Map<String, dynamic>.from(result);
  }

  Future<List<Map<String, dynamic>>> getTodayStitchLogs({String? workstationLine}) async {
    final data = await _api.call('fabric_stitching.get_today_stitch_logs', body: {
      if (workstationLine != null) 'workstation_line': workstationLine,
    });
    if (data is List) {
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return const [];
  }
}

final fabricStitchingRepositoryProvider = Provider<FabricStitchingRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  final writeQueue = ref.watch(writeQueueProvider);
  return FabricStitchingRepository(api: api, writeQueue: writeQueue);
});
