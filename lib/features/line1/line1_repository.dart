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

  // ── Silo / Oil ──────────────────────────────────────────────────────────

  Future<List<StockItem>> listOutsideStock(String warehouseType) async {
    final data = await _api.call('line1_silo.list_outside_stock',
        body: {'warehouse_type': warehouseType});
    return _parseStockList(data);
  }

  Future<List<StockItem>> listInsideStock(String warehouseType) async {
    final data = await _api.call('line1_silo.list_inside_stock',
        body: {'warehouse_type': warehouseType});
    return _parseStockList(data);
  }

  Future<LoadResult> siloLoad({
    required String itemCode,
    required double qty,
  }) async {
    final result = await _writeQueue.run('line1_silo.silo_load', {
      'item_code': itemCode,
      'qty': qty,
    });
    return LoadResult.fromJson(Map<String, dynamic>.from(result));
  }

  Future<LoadResult> oilLoad({
    required String itemCode,
    required double qty,
  }) async {
    final result = await _writeQueue.run('line1_silo.oil_load', {
      'item_code': itemCode,
      'qty': qty,
    });
    return LoadResult.fromJson(Map<String, dynamic>.from(result));
  }

  // ── Weighing ────────────────────────────────────────────────────────────

  Future<LoadResult> weighingLoad({
    required String boxBarcode,
    required String itemCode,
    required double qty,
  }) async {
    final result = await _writeQueue.run('line1_weighing.weighing_load', {
      'box_barcode': boxBarcode,
      'item_code': itemCode,
      'qty': qty,
    });
    return LoadResult.fromJson(Map<String, dynamic>.from(result));
  }

  Future<List<StockItem>> listBoxes() async {
    final data = await _api.call('line1_weighing.list_boxes');
    return _parseStockList(data);
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
