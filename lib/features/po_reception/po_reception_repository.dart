import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exceptions.dart';
import '../../core/sync/write_queue.dart';
import '../../providers/service_providers.dart';
import 'po_reception_models.dart';

class PoReceptionRepository {
  final ApiClient _api;
  final WriteQueue _writeQueue;

  PoReceptionRepository({required ApiClient api, required WriteQueue writeQueue})
      : _api = api,
        _writeQueue = writeQueue;

  Future<List<PurchaseOrderSummary>> listPending() async {
    final data = await _api.call('po_reception.list_pending');
    if (data is List) {
      return data
          .map((json) =>
              PurchaseOrderSummary.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    }
    return const [];
  }

  Future<List<PurchaseOrderSummary>> search(String query) async {
    final data = await _api.call('po_reception.search', body: {'query': query});
    if (data is List) {
      return data
          .map((json) =>
              PurchaseOrderSummary.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    }
    return const [];
  }

  Future<PurchaseOrderDetail> get(String purchaseOrder) async {
    final data = await _api.call('po_reception.get',
        body: {'purchase_order': purchaseOrder});
    return PurchaseOrderDetail.fromJson(Map<String, dynamic>.from(data));
  }

  Future<Map<String, dynamic>> submitReception({
    required String purchaseOrder,
    required List<Map<String, dynamic>> items,
  }) async {
    final response = await _writeQueue.run('po_reception.submit_reception', {
      'purchase_order': purchaseOrder,
      'items': items,
    });
    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }
    throw const ApiException('VALIDATION', 'Invalid response from server');
  }
}

final poReceptionRepositoryProvider = Provider<PoReceptionRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  final writeQueue = ref.watch(writeQueueProvider);
  return PoReceptionRepository(api: api, writeQueue: writeQueue);
});
