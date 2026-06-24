import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/models/line1_models.dart';
import '../../core/sync/write_queue.dart';
import '../../providers/service_providers.dart';

class Line1Repository {
  final ApiClient _api;
  final WriteQueue _writeQueue;

  Line1Repository({required ApiClient api, required WriteQueue writeQueue})
      : _api = api,
        _writeQueue = writeQueue;

  // ── Unified Material Loading ─────────────────────────────────────────────

  Future<Map<String, dynamic>> resolveItem(String itemCode) async {
    final data = await _api.call('line1_loading.resolve',
        body: {'item_code': itemCode});
    return Map<String, dynamic>.from(data);
  }

  Future<List<StockItem>> listAllOutsideStock() async {
    final data = await _api.call('line1_loading.list_outside_stock');
    return _parseStockList(data);
  }

  Future<List<StockItem>> listAllInsideStock() async {
    final data = await _api.call('line1_loading.list_inside_stock');
    return _parseStockList(data);
  }

  Future<LoadResult> loadMaterial({
    required String itemCode,
    required double qty,
  }) async {
    final result = await _writeQueue.run('line1_loading.load', {
      'item_code': itemCode,
      'qty': qty,
    });
    return LoadResult.fromJson(Map<String, dynamic>.from(result));
  }

  // ── Bags ────────────────────────────────────────────────────────────────

  Future<List<BagItem>> listBags() async {
    final data = await _api.call('line1_weighing.list_bags');
    if (data is List) {
      return data
          .map((j) => BagItem.fromJson(Map<String, dynamic>.from(j)))
          .toList();
    }
    return const [];
  }

  Future<BagDetail> getBag(String batchNo) async {
    final data =
        await _api.call('line1_weighing.get_bag', body: {'batch_no': batchNo});
    return BagDetail.fromJson(Map<String, dynamic>.from(data));
  }

  // ── FMB / Lab Test ──────────────────────────────────────────────────────

  Future<List<FmbBatch>> listFmb({String? status}) async {
    final data = await _api.call('line1_lab.list_fmb', body: {
      if (status != null) 'status': status,
    });
    if (data is List) {
      return data
          .map((j) => FmbBatch.fromJson(Map<String, dynamic>.from(j)))
          .toList();
    }
    return const [];
  }

  Future<FmbDetail> getFmb(String batchNo) async {
    final data =
        await _api.call('line1_lab.get_fmb', body: {'batch_no': batchNo});
    return FmbDetail.fromJson(Map<String, dynamic>.from(data));
  }

  Future<LabTestResult> submitLabTest({
    required String fmbBatch,
    required List<Map<String, dynamic>> parameters,
    String? remarks,
  }) async {
    final result = await _writeQueue.run('line1_lab.submit_lab_test', {
      'fmb_batch': fmbBatch,
      'parameters': parameters,
      if (remarks != null) 'remarks': remarks,
    });
    return LabTestResult.fromJson(Map<String, dynamic>.from(result));
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  List<StockItem> _parseStockList(dynamic data) {
    if (data is List) {
      return data
          .map((j) => StockItem.fromJson(Map<String, dynamic>.from(j)))
          .toList();
    }
    return const [];
  }
}

final line1RepositoryProvider = Provider<Line1Repository>((ref) {
  final api = ref.watch(apiClientProvider);
  final writeQueue = ref.watch(writeQueueProvider);
  return Line1Repository(api: api, writeQueue: writeQueue);
});
