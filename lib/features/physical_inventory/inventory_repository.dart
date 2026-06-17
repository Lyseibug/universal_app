import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/sync/write_queue.dart';
import '../../providers/service_providers.dart';

/// Repository for Physical Inventory / Stock Count operations.
class InventoryRepository {
  final ApiClient _api;
  final WriteQueue _writeQueue;

  InventoryRepository({required ApiClient api, required WriteQueue writeQueue})
      : _api = api,
        _writeQueue = writeQueue;

  /// Starts a count session for a specific Lot/Bin and returns expected system stock.
  Future<List<dynamic>> startSession(String lot) async {
    final data = await _api.call('physical_inventory.start', body: {'lot': lot});
    return data is List ? data : const [];
  }

  /// Submits stock counts for a specific Lot/Bin via the idempotent WriteQueue.
  ///
  /// [counts] is a list of maps containing: item_code, batch_no, counted_qty.
  Future<dynamic> submitCounts({
    required String lot,
    required List<Map<String, dynamic>> counts,
  }) async {
    return _writeQueue.run('physical_inventory.submit', {
      'lot': lot,
      'counts': jsonEncode(counts),
    });
  }
}

/// Provider for InventoryRepository.
final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  final writeQueue = ref.watch(writeQueueProvider);
  return InventoryRepository(api: api, writeQueue: writeQueue);
});
