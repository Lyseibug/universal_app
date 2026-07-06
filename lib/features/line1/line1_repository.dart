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

  Future<List<TankStatus>> listTankStatus() async {
    final data = await _api.call('line1_loading.list_tank_status');
    if (data is List) {
      return data
          .map((j) => TankStatus.fromJson(Map<String, dynamic>.from(j)))
          .toList();
    }
    return const [];
  }

  // ── Mixer Loading (staging → Mixer WIP) ─────────────────────────────────

  Future<List<Map<String, dynamic>>> listMixerStageable() async {
    final data = await _api.call('line1_mixer.list_stageable');
    return _parseMapList(data);
  }

  Future<List<Map<String, dynamic>>> listMixerWip() async {
    final data = await _api.call('line1_mixer.list_wip');
    return _parseMapList(data);
  }

  Future<Map<String, dynamic>> resolveMixerScan(String code) async {
    final data = await _api.call('line1_mixer.resolve', body: {'code': code});
    return Map<String, dynamic>.from(data);
  }

  Future<Map<String, dynamic>> loadToMixer({
    required String itemCode,
    required double qty,
    String? batchNo,
    String? sourceWarehouse,
  }) async {
    final result = await _writeQueue.run('line1_mixer.load', {
      'item_code': itemCode,
      'qty': qty,
      if (batchNo != null) 'batch_no': batchNo,
      if (sourceWarehouse != null) 'source_warehouse': sourceWarehouse,
    });
    return Map<String, dynamic>.from(result);
  }

  // ── Weighing (Outside → Inside Weighing Machine WH) ─────────────────────

  Future<List<StockItem>> listWeighingOutsideStock() async {
    final data = await _api.call('line1_weighing.list_outside_stock');
    return _parseStockList(data);
  }

  Future<List<StockItem>> listBoxes() async {
    final data = await _api.call('line1_weighing.list_boxes');
    return _parseStockList(data);
  }

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

  // ── Calendering ─────────────────────────────────────────────────────────

  Future<List<CalenderingFmb>> listFmbForCalendering() async {
    final data =
        await _api.call('line1_calendering.list_fmb_for_calendering');
    if (data is List) {
      return data
          .map((j) => CalenderingFmb.fromJson(Map<String, dynamic>.from(j)))
          .toList();
    }
    return const [];
  }

  Future<CalenderingStartResult> startCalenderingRun({
    required String fmbBatch,
    required double inputQty,
  }) async {
    final result = await _writeQueue.run('line1_calendering.start_run', {
      'fmb_batch': fmbBatch,
      'input_qty': inputQty,
    });
    return CalenderingStartResult.fromJson(Map<String, dynamic>.from(result));
  }

  Future<CalenderingRun> getCalenderingRun(String name) async {
    final data =
        await _api.call('line1_calendering.get_run', body: {'name': name});
    return CalenderingRun.fromJson(Map<String, dynamic>.from(data));
  }

  Future<CalenderingCompleteResult> completeCalenderingRun({
    required String name,
    required List<Map<String, dynamic>> sheets,
    required double linerReturnQty,
    required double calendarReturnQty,
    required double excruderSludgeQty,
  }) async {
    final result = await _writeQueue.run('line1_calendering.complete_run', {
      'name': name,
      'sheets': sheets,
      'liner_return_qty': linerReturnQty,
      'calendar_return_qty': calendarReturnQty,
      'excruder_sludge_qty': excruderSludgeQty,
    });
    return CalenderingCompleteResult.fromJson(
        Map<String, dynamic>.from(result));
  }

  Future<List<RollStock>> listRollStock() async {
    final data = await _api.call('line1_calendering.list_roll_stock');
    if (data is List) {
      return data
          .map((j) => RollStock.fromJson(Map<String, dynamic>.from(j)))
          .toList();
    }
    return const [];
  }

  Future<List<CalenderingRun>> listCalenderingRuns({String? status}) async {
    final data = await _api.call('line1_calendering.list_runs', body: {
      if (status != null) 'status': status,
    });
    if (data is List) {
      return data
          .map((j) => CalenderingRun.fromJson(Map<String, dynamic>.from(j)))
          .toList();
    }
    return const [];
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

  List<Map<String, dynamic>> _parseMapList(dynamic data) {
    if (data is List) {
      return data.map((j) => Map<String, dynamic>.from(j)).toList();
    }
    return const [];
  }
}

final line1RepositoryProvider = Provider<Line1Repository>((ref) {
  final api = ref.watch(apiClientProvider);
  final writeQueue = ref.watch(writeQueueProvider);
  return Line1Repository(api: api, writeQueue: writeQueue);
});
