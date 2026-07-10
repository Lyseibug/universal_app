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

  Future<List<CalenderingFmb>> listFmbInCalenderingWh() async {
    final data =
        await _api.call('line1_calendering.list_fmb_in_calendering_wh');
    if (data is List) {
      return data
          .map((j) => CalenderingFmb.fromJson(Map<String, dynamic>.from(j)))
          .toList();
    }
    return const [];
  }

  Future<FmbScanResult> resolveFmbScan(String batchNo) async {
    final data = await _api.call('line1_calendering.resolve_fmb_scan',
        body: {'batch_no': batchNo});
    return FmbScanResult.fromJson(Map<String, dynamic>.from(data));
  }

  Future<CalenderingStartResult> startRunFromBatches(
      List<Map<String, dynamic>> fmbBatches) async {
    final result = await _writeQueue.run(
        'line1_calendering.start_run_from_batches',
        {'fmb_batches': fmbBatches});
    return CalenderingStartResult.fromJson(Map<String, dynamic>.from(result));
  }

  Future<CalenderingStartResult> addFmbBatchToRun({
    required String runName,
    required String batchNo,
    required double qty,
  }) async {
    final result = await _writeQueue.run('line1_calendering.add_fmb_batch', {
      'run_name': runName,
      'batch_no': batchNo,
      'qty': qty,
    });
    return CalenderingStartResult.fromJson(Map<String, dynamic>.from(result));
  }

  Future<CalenderingRun> getCalenderingRun(String name) async {
    final data =
        await _api.call('line1_calendering.get_run', body: {'name': name});
    return CalenderingRun.fromJson(Map<String, dynamic>.from(data));
  }

  Future<List<CalenderingEligibleSheet>> listSheetsForFmb(
      String fmbBatch) async {
    final data = await _api.call('line1_calendering.list_sheets_for_fmb',
        body: {'fmb_batch': fmbBatch});
    if (data is List) {
      return data
          .map((j) =>
              CalenderingEligibleSheet.fromJson(Map<String, dynamic>.from(j)))
          .toList();
    }
    return const [];
  }

  Future<RollMatchResult> matchRolls(List<Map<String, dynamic>> sheets) async {
    final data = await _api
        .call('line1_calendering.match_rolls', body: {'sheets': sheets});
    return RollMatchResult.fromJson(Map<String, dynamic>.from(data));
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

  /// The calendering line's Workstation — used to target a Tool Request
  /// raised from a Rolls-step shortfall, without hardcoding it client-side.
  Future<String?> getCalenderingWorkstation() async {
    final data = await _api.call('line1_calendering.get_calendering_workstation');
    return data?.toString();
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

  // ── Cutting & Splicing ──────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> listEligibleCutSourceBatches(
      {String? sourceItem}) async {
    final data = await _api.call('line1_cutting.list_eligible_source_batches',
        body: {
          if (sourceItem != null) 'source_item': sourceItem,
        });
    return _parseMapList(data);
  }

  Future<Map<String, dynamic>> performCut({
    required String sourceBatch,
    required String targetItem,
    required double inputQty,
    required double outputQty,
  }) async {
    final result = await _writeQueue.run('line1_cutting.perform_cut', {
      'source_batch': sourceBatch,
      'target_item': targetItem,
      'input_qty': inputQty,
      'output_qty': outputQty,
    });
    return Map<String, dynamic>.from(result);
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
