import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/models/warehouse_models.dart';
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
  Future<List<ReceivedItemLine>> listPending() async {
    final data = await _api.call('grn.list_pending');
    if (data is List) {
      return data.map((json) => ReceivedItemLine.fromJson(Map<String, dynamic>.from(json))).toList();
    }
    return const [];
  }

  /// Fetches specific details of a received GRN item line.
  Future<ReceivedItemLine> getReceivedItem(String receivedItem) async {
    final data = await _api.call('grn.get', body: {'received_item': receivedItem});
    return ReceivedItemLine.fromJson(Map<String, dynamic>.from(data));
  }

  /// Fetches bin recommendation for a pending GRN line.
  Future<LotSuggestion?> suggestLot(String receivedItemLine) async {
    try {
      final data = await _api.call('grn.suggest_lot', body: {'received_item_line': receivedItemLine});
      if (data is Map<String, dynamic> && data.isNotEmpty) {
        return LotSuggestion.fromJson(data);
      }
    } catch (_) {
      // Gracefully handle if suggestions are empty/not found on server
    }
    return null;
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
