import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/sync/write_queue.dart';
import '../../providers/service_providers.dart';

/// Repository for Lot Browser and Manual Stock Transfer operations.
class LotRepository {
  final ApiClient _api;
  final WriteQueue _writeQueue;

  LotRepository({required ApiClient api, required WriteQueue writeQueue})
      : _api = api,
        _writeQueue = writeQueue;

  /// Browse lots with filters and pagination.
  Future<List<dynamic>> browse({
    String? warehouse,
    String? zone,
    String? item,
    bool onlyOccupied = true,
    int limit = 20,
    int start = 0,
  }) async {
    final data = await _api.call('lot.browse', body: {
      if (warehouse != null) 'warehouse': warehouse,
      if (zone != null) 'zone': zone,
      if (item != null) 'item': item,
      'only_occupied': onlyOccupied ? 1 : 0,
      'limit': limit,
      'start': start,
    });
    return data is List ? data : const [];
  }

  /// Get specific details for a single Lot/Bin.
  Future<Map<String, dynamic>> get(String lot) async {
    final data = await _api.call('lot.get', body: {'lot': lot});
    return data is Map<String, dynamic> ? data : const {};
  }

  /// Execute a manual stock transfer between Bins/Lots via the WriteQueue.
  Future<dynamic> transfer({
    required String fromLot,
    required String toLot,
    required String item,
    required String batchNo,
    required double qty,
  }) async {
    return _writeQueue.run('lot.transfer', {
      'from_lot': fromLot,
      'to_lot': toLot,
      'item': item,
      'batch_no': batchNo,
      'qty': qty,
    });
  }
}

/// Provider for LotRepository.
final lotRepositoryProvider = Provider<LotRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  final writeQueue = ref.watch(writeQueueProvider);
  return LotRepository(api: api, writeQueue: writeQueue);
});
