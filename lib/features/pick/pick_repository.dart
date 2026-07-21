import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/models/warehouse_models.dart';
import '../../core/sync/write_queue.dart';
import '../../providers/service_providers.dart';

/// A batch of stock for one item inside a bin (Warehouse LOT).
/// A bin can hold several batches of the same item at once, so the picker
/// must pick a specific batch, not just the bin.
class PickBatchOption {
  final String batchNo;
  final double qty;
  final String? productionDate;
  final String? expiryDate;
  final bool isSuggested;

  const PickBatchOption({
    required this.batchNo,
    required this.qty,
    this.productionDate,
    this.expiryDate,
    this.isSuggested = false,
  });

  factory PickBatchOption.fromJson(Map<String, dynamic> json) {
    return PickBatchOption(
      batchNo: (json['batch_no'] ?? '').toString(),
      qty: double.tryParse(json['qty']?.toString() ?? '') ?? 0.0,
      productionDate: json['production_date']?.toString(),
      expiryDate: json['expiry_date']?.toString(),
      isSuggested: json['is_suggested'] == true,
    );
  }
}

/// Repository for Picking operations.
class PickRepository {
  final ApiClient _api;
  final WriteQueue _writeQueue;

  PickRepository({required ApiClient api, required WriteQueue writeQueue})
      : _api = api,
        _writeQueue = writeQueue;

  /// Fetch pick lists optionally filtered by material request, status, or picking type.
  Future<List<PickItem>> listPicks({
    String? materialRequest,
    String? status,
    String? pickingType,
  }) async {
    final data = await _api.call('pick.list', body: {
      if (materialRequest != null) 'material_request': materialRequest,
      if (status != null) 'status': status,
      if (pickingType != null) 'picking_type': pickingType,
    });
    if (data is List) {
      return data.map((json) => PickItem.fromJson(Map<String, dynamic>.from(json))).toList();
    }
    return const [];
  }

  /// Claims a pick item assignment for the logged-in worker.
  Future<void> claim(String pickItem) async {
    await _api.call('pick.claim', body: {'pick_item': pickItem});
  }

  /// Fetches the batches of this item available in a bin (FIFO-suggested first).
  /// Pass [lot] to re-query after the picker scans a bin other than the
  /// suggested one; omit it to use the item's suggested bin.
  Future<List<PickBatchOption>> listBatches({
    required String pickItem,
    String? lot,
  }) async {
    final data = await _api.call('pick.list_batches', body: {
      'pick_item': pickItem,
      if (lot != null && lot.isNotEmpty) 'lot': lot,
    });
    final batches = data is Map ? data['batches'] : null;
    if (batches is List) {
      return batches
          .map((json) => PickBatchOption.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    }
    return const [];
  }

  /// Submits the picked item allocation via the idempotent WriteQueue.
  Future<dynamic> pick({
    required String pickItem,
    required String actualLot,
    required double pickedQty,
    String? actualBatch,
  }) async {
    return _writeQueue.run('pick.submit', {
      'pick_item': pickItem,
      'actual_lot': actualLot,
      'picked_qty': pickedQty,
      if (actualBatch != null && actualBatch.isNotEmpty) 'actual_batch': actualBatch,
    });
  }
}

/// Provider for PickRepository.
final pickRepositoryProvider = Provider<PickRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  final writeQueue = ref.watch(writeQueueProvider);
  return PickRepository(api: api, writeQueue: writeQueue);
});
