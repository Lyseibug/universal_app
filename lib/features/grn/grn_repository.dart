import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/sync/write_queue.dart';
import '../../providers/service_providers.dart';

/// Repository for GRN (Goods Receipt Note) Put-Away operations.
class GrnRepository {
  final ApiClient _api;
  final WriteQueue _writeQueue;

  GrnRepository({required ApiClient api, required WriteQueue writeQueue})
      : _api = api,
        _writeQueue = writeQueue;

  /// Fetches a list of pending GRN lines ready for put-away allocation.
  Future<List<dynamic>> listPending() async {
    final data = await _api.call('grn.list_pending');
    return data is List ? data : const [];
  }

  /// Fetches specific details of a received GRN item line.
  Future<Map<String, dynamic>> getReceivedItem(String receivedItem) async {
    final data = await _api.call('grn.get', body: {'received_item': receivedItem});
    return data is Map<String, dynamic> ? data : const {};
  }

  /// Submits a put-away allocation to the server via the idempotent WriteQueue.
  Future<dynamic> putAway({
    required String receivedItemLine,
    required String lot,
    required double qty,
    String? productionDate,
    String? expiryDate,
    bool forceCapacity = false,
  }) async {
    return _writeQueue.run('grn.put_away', {
      'received_item_line': receivedItemLine,
      'lot': lot,
      'qty': qty,
      'production_date': productionDate,
      'expiry_date': expiryDate,
      'force_capacity': forceCapacity ? 1 : 0,
    });
  }
}

/// Provider for GrnRepository.
final grnRepositoryProvider = Provider<GrnRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  final writeQueue = ref.watch(writeQueueProvider);
  return GrnRepository(api: api, writeQueue: writeQueue);
});
