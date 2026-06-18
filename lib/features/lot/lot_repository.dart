import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/models/warehouse_models.dart';
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
  Future<List<WarehouseLot>> browse({
    String? warehouse,
    String? zone,
    String? item,
    bool onlyOccupied = true,
    int limit = 50,
    int start = 0,
  }) async {
    final data = await _api.call('lot.browse', body: {
      if (warehouse != null && warehouse.isNotEmpty) 'warehouse': warehouse,
      if (zone != null && zone.isNotEmpty) 'zone': zone,
      if (item != null && item.isNotEmpty) 'item': item,
      'only_occupied': onlyOccupied ? 1 : 0,
      'limit': limit,
      'start': start,
    });
    if (data is List) {
      return data.map((json) => WarehouseLot.fromJson(Map<String, dynamic>.from(json))).toList();
    }
    return const [];
  }

  /// Get specific details for a single Lot/Bin.
  Future<WarehouseLot> get(String lot) async {
    final data = await _api.call('lot.get', body: {'lot': lot});
    return WarehouseLot.fromJson(Map<String, dynamic>.from(data));
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
