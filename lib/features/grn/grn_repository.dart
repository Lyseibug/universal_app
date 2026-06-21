import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exceptions.dart';
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
  Future<LotSuggestion?> suggestLot(String receivedItemLine, {double? qty}) async {
    try {
      final body = <String, dynamic>{'received_item_line': receivedItemLine};
      if (qty != null) body['qty'] = qty;
      final data = await _api.call('grn.suggest_lot', body: body);
      if (data is Map<String, dynamic> && data.isNotEmpty && data['lot'] != null) {
        return LotSuggestion.fromJson(data);
      }
    } catch (_) {
      // Gracefully handle if suggestions are empty/not found on server
    }
    return null;
  }

  /// Creates a new production batch for a received item line.
  Future<Map<String, dynamic>> createBatch({
    required String receivedItemLine,
    required double qty,
    required String productionDate,
    String? expiryDate,
  }) async {
    final response = await _writeQueue.run('grn.create_batch', {
      'received_item_line': receivedItemLine,
      'qty': qty,
      'production_date': productionDate,
      if (expiryDate != null) 'expiry_date': expiryDate,
    });
    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }
    throw const ApiException('VALIDATION', 'Invalid response from server');
  }

  /// Queues a label print job on the ERPNext server.
  Future<dynamic> printLabel({
    required String referenceDoctype,
    required String referenceName,
    required String printFormat,
    String? printer,
  }) async {
    return _writeQueue.run('grn.print_label', {
      'reference_doctype': referenceDoctype,
      'reference_name': referenceName,
      'print_format': printFormat,
      if (printer != null && printer.isNotEmpty) 'printer': printer,
    });
  }

  /// Fetches a list of created batches for a received item line.
  Future<List<GrnBatch>> listCreatedBatches(String receivedItemLine) async {
    final data = await _api.call('grn.list_created_batches', body: {
      'received_item_line': receivedItemLine,
    });
    if (data is List) {
      return data.map((json) => GrnBatch.fromJson(Map<String, dynamic>.from(json))).toList();
    }
    return const [];
  }

  /// Allocates a batch to a bin location.
  Future<dynamic> allocateToBin({
    required String receivedItemLine,
    required String lot,
    required double qty,
    required String batchNo,
    bool forceCapacity = false,
    String? suggestedLot,
  }) async {
    return _writeQueue.run('grn.allocate_to_bin', {
      'received_item_line': receivedItemLine,
      'lot': lot,
      'qty': qty,
      'batch_no': batchNo,
      'force_capacity': forceCapacity ? 1 : 0,
      if (suggestedLot != null) 'suggested_lot': suggestedLot,
    });
  }
}

/// Provider for GrnRepository.
final grnRepositoryProvider = Provider<GrnRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  final writeQueue = ref.watch(writeQueueProvider);
  return GrnRepository(api: api, writeQueue: writeQueue);
});
