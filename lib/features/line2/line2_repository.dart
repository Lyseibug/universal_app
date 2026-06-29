import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/sync/write_queue.dart';
import '../../providers/service_providers.dart';

class Line2Repository {
  final ApiClient _api;
  final WriteQueue _writeQueue;

  Line2Repository({required ApiClient api, required WriteQueue writeQueue})
      : _api = api,
        _writeQueue = writeQueue;

  // ── Worker Stations & Config ────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getWorkerStations() async {
    final data = await _api.call('line2.get_worker_stations', body: {});
    if (data is List) {
      return data.map((j) => Map<String, dynamic>.from(j)).toList();
    }
    return const [];
  }

  Future<List<Map<String, dynamic>>> getRejectionCodes(String productionType) async {
    final data = await _api.call('line2.get_rejection_codes',
        body: {'production_type': productionType});
    if (data is List) {
      return data.map((j) => Map<String, dynamic>.from(j)).toList();
    }
    return const [];
  }

  // ── Flowchart / Scanning ────────────────────────────────────────────────

  Future<Map<String, dynamic>> scanFlowchart(String barcode) async {
    final data = await _api.call('line2.scan_flowchart',
        body: {'barcode': barcode});
    return Map<String, dynamic>.from(data);
  }

  Future<List<Map<String, dynamic>>> getActiveJobs({String? workstation}) async {
    final data = await _api.call('line2.get_active_jobs', body: {
      if (workstation != null) 'workstation': workstation,
    });
    if (data is List) {
      return data
          .map((j) => Map<String, dynamic>.from(j))
          .toList();
    }
    return const [];
  }

  Future<List<Map<String, dynamic>>> getLayeringChecklist(String jobCard) async {
    final data = await _api.call('line2.get_layering_checklist',
        body: {'job_card': jobCard});
    if (data is List) {
      return data
          .map((j) => Map<String, dynamic>.from(j))
          .toList();
    }
    return const [];
  }

  // ── Step Completion ─────────────────────────────────────────────────────

  Future<Map<String, dynamic>> completeStep({
    required String jobCard,
    List<Map<String, dynamic>>? measurements,
    String? remarks,
  }) async {
    final result = await _writeQueue.run('line2.complete_step', {
      'job_card': jobCard,
      if (measurements != null) 'measurements': measurements,
      if (remarks != null) 'remarks': remarks,
    });
    return Map<String, dynamic>.from(result);
  }

  // ── Tool Management ─────────────────────────────────────────────────────

  Future<Map<String, dynamic>> assignTool({
    required String toolId,
    required String jobCard,
  }) async {
    final result = await _writeQueue.run('line2.assign_tool', {
      'tool_id': toolId,
      'job_card': jobCard,
    });
    return Map<String, dynamic>.from(result);
  }

  Future<Map<String, dynamic>> releaseTool({
    required String toolId,
    String? jobCard,
  }) async {
    final result = await _writeQueue.run('line2.release_tool', {
      'tool_id': toolId,
      if (jobCard != null) 'job_card': jobCard,
    });
    return Map<String, dynamic>.from(result);
  }

  Future<Map<String, dynamic>> getToolStatus(String toolId) async {
    final data = await _api.call('line2.get_tool_status',
        body: {'tool_id': toolId});
    return Map<String, dynamic>.from(data);
  }

  Future<Map<String, dynamic>> updateAirbagWeight({
    required String toolId,
    required double weightKg,
  }) async {
    final result = await _writeQueue.run('line2.update_airbag_weight', {
      'tool_id': toolId,
      'weight_kg': weightKg,
    });
    return Map<String, dynamic>.from(result);
  }

  Future<Map<String, dynamic>> convertAirbag({
    required String toolId,
  }) async {
    final result = await _writeQueue.run('line2.convert_airbag', {
      'tool_id': toolId,
    });
    return Map<String, dynamic>.from(result);
  }

  // ── Rejection ───────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> createRejection({
    required String jobCard,
    required String rejectionType,
    String? reason,
    double? qty,
  }) async {
    final result = await _writeQueue.run('line2.create_rejection', {
      'job_card': jobCard,
      'rejection_type': rejectionType,
      if (reason != null) 'reason': reason,
      if (qty != null) 'qty': qty,
    });
    return Map<String, dynamic>.from(result);
  }

  // ── QC ──────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getQcInfo({
    required String workOrder,
    String? jobCard,
  }) async {
    final data = await _api.call('line2_qc.get_qc_info', body: {
      'work_order': workOrder,
      if (jobCard != null) 'job_card': jobCard,
    });
    return Map<String, dynamic>.from(data);
  }

  Future<Map<String, dynamic>> submitMeasurement({
    required String jobCard,
    required List<Map<String, dynamic>> measurements,
  }) async {
    final result = await _writeQueue.run('line2_qc.submit_measurement', {
      'job_card': jobCard,
      'measurements': measurements,
    });
    return Map<String, dynamic>.from(result);
  }

  Future<Map<String, dynamic>> submitQcResult({
    required String workOrder,
    required String result,
    String? jobCard,
    double? acceptedQty,
    String? remarks,
  }) async {
    final data = await _writeQueue.run('line2_qc.submit_qc_result', {
      'work_order': workOrder,
      'result': result,
      if (jobCard != null) 'job_card': jobCard,
      if (acceptedQty != null) 'accepted_qty': acceptedQty,
      if (remarks != null) 'remarks': remarks,
    });
    return Map<String, dynamic>.from(data);
  }

  Future<Map<String, dynamic>> completeWo({
    required String workOrder,
    double? qty,
  }) async {
    final result = await _writeQueue.run('line2_qc.complete_wo', {
      'work_order': workOrder,
      if (qty != null) 'qty': qty,
    });
    return Map<String, dynamic>.from(result);
  }

  // ── Sleeves ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> createSleeves({
    required String workOrder,
    required int sleeveCount,
  }) async {
    final result = await _writeQueue.run('line2_sleeve.create_sleeves', {
      'work_order': workOrder,
      'sleeve_count': sleeveCount,
    });
    return Map<String, dynamic>.from(result);
  }

  Future<List<Map<String, dynamic>>> getLayeringSequence(String productionItem) async {
    final data = await _api.call('line2_sleeve.get_layering_sequence',
        body: {'production_item': productionItem});
    if (data is List) {
      return data
          .map((j) => Map<String, dynamic>.from(j))
          .toList();
    }
    return const [];
  }

  // ── Packing ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> createBox({
    String? salesOrder,
  }) async {
    final result = await _writeQueue.run('packing.create_box', {
      if (salesOrder != null) 'sales_order': salesOrder,
    });
    return Map<String, dynamic>.from(result);
  }

  Future<Map<String, dynamic>> addToBox({
    required String boxBarcode,
    required String itemBarcode,
    double? qty,
  }) async {
    final result = await _writeQueue.run('packing.add_to_box', {
      'box_barcode': boxBarcode,
      'item_barcode': itemBarcode,
      if (qty != null) 'qty': qty,
    });
    return Map<String, dynamic>.from(result);
  }

  Future<Map<String, dynamic>> sealBox(String boxBarcode) async {
    final result = await _writeQueue.run('packing.seal_box', {
      'box_barcode': boxBarcode,
    });
    return Map<String, dynamic>.from(result);
  }

  Future<Map<String, dynamic>> createPallet({
    String? palletType,
    String? salesOrder,
  }) async {
    final result = await _writeQueue.run('packing.create_pallet', {
      if (palletType != null) 'pallet_type': palletType,
      if (salesOrder != null) 'sales_order': salesOrder,
    });
    return Map<String, dynamic>.from(result);
  }

  Future<Map<String, dynamic>> addBoxToPallet({
    required String palletBarcode,
    required String boxBarcode,
  }) async {
    final result = await _writeQueue.run('packing.add_box_to_pallet', {
      'pallet_barcode': palletBarcode,
      'box_barcode': boxBarcode,
    });
    return Map<String, dynamic>.from(result);
  }

  Future<Map<String, dynamic>> addItemToPallet({
    required String palletBarcode,
    required String itemBarcode,
    double? qty,
  }) async {
    final result = await _writeQueue.run('packing.add_item_to_pallet', {
      'pallet_barcode': palletBarcode,
      'item_barcode': itemBarcode,
      if (qty != null) 'qty': qty,
    });
    return Map<String, dynamic>.from(result);
  }

  Future<Map<String, dynamic>> sealPallet(String palletBarcode) async {
    final result = await _writeQueue.run('packing.seal_pallet', {
      'pallet_barcode': palletBarcode,
    });
    return Map<String, dynamic>.from(result);
  }

  Future<Map<String, dynamic>> printLabel({
    required String barcode,
    required String labelType,
  }) async {
    final result = await _writeQueue.run('packing.print_label', {
      'barcode': barcode,
      'label_type': labelType,
    });
    return Map<String, dynamic>.from(result);
  }
}

final line2RepositoryProvider = Provider<Line2Repository>((ref) {
  final api = ref.watch(apiClientProvider);
  final writeQueue = ref.watch(writeQueueProvider);
  return Line2Repository(api: api, writeQueue: writeQueue);
});
