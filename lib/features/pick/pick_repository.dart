import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/sync/write_queue.dart';
import '../../providers/service_providers.dart';

/// Repository for Picking operations.
class PickRepository {
  final ApiClient _api;
  final WriteQueue _writeQueue;

  PickRepository({required ApiClient api, required WriteQueue writeQueue})
      : _api = api,
        _writeQueue = writeQueue;

  /// Fetch pick lists optionally filtered by material request or status.
  Future<List<dynamic>> listPicks({String? materialRequest, String? status}) async {
    final data = await _api.call('pick.list', body: {
      if (materialRequest != null) 'material_request': materialRequest,
      if (status != null) 'status': status,
    });
    return data is List ? data : const [];
  }

  /// Claims a pick item assignment for the logged-in worker.
  Future<void> claim(String pickItem) async {
    await _api.call('pick.claim', body: {'pick_item': pickItem});
  }

  /// Submits the picked item allocation via the idempotent WriteQueue.
  Future<dynamic> pick({
    required String pickItem,
    required String actualLot,
    required double pickedQty,
  }) async {
    return _writeQueue.run('pick.submit', {
      'pick_item': pickItem,
      'actual_lot': actualLot,
      'picked_qty': pickedQty,
    });
  }
}

/// Provider for PickRepository.
final pickRepositoryProvider = Provider<PickRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  final writeQueue = ref.watch(writeQueueProvider);
  return PickRepository(api: api, writeQueue: writeQueue);
});
