import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/models/tool_request_models.dart';
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

  /// [workstation], when given, is validated server-side against this step's
  /// actual allowed workstations for the item's production type — a mismatch
  /// raises instead of silently opening the Job Card at a different station.
  Future<Map<String, dynamic>> scanFlowchart(String barcode, {String? workstation}) async {
    final data = await _api.call('line2.scan_flowchart', body: {
      'barcode': barcode,
      if (workstation != null && workstation.isNotEmpty) 'workstation': workstation,
    });
    return Map<String, dynamic>.from(data);
  }

  /// mine_only defaults true server-side — this is a personal "what's
  /// still running for me" view, not an unscoped supervisor one.
  Future<List<Map<String, dynamic>>> getActiveJobs({String? buildingLine}) async {
    final data = await _api.call('line2.get_active_jobs', body: {
      if (buildingLine != null) 'building_line': buildingLine,
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
    double? scrapQty,
    String? scrapReasonCode,
  }) async {
    final result = await _writeQueue.run('line2.complete_step', {
      'job_card': jobCard,
      if (measurements != null) 'measurements': measurements,
      if (remarks != null) 'remarks': remarks,
      if (scrapQty != null && scrapQty > 0) 'scrap_qty': scrapQty,
      if (scrapReasonCode != null) 'scrap_reason_code': scrapReasonCode,
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

  Future<Map<String, dynamic>> changeGrindingWheel({
    required String toolId,
    required double feedingSpeed,
  }) async {
    final result = await _writeQueue.run('line2.change_grinding_wheel', {
      'tool_id': toolId,
      'feeding_speed': feedingSpeed,
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

  /// Manual, operator-triggered Staged -> Available. Never called
  /// automatically — releaseTool only ever lands a tool back on Staged.
  Future<Map<String, dynamic>> returnToolToStore({
    required String toolId,
  }) async {
    final result = await _writeQueue.run('line2.return_tool_to_store', {
      'tool_id': toolId,
    });
    return Map<String, dynamic>.from(result);
  }

  /// Tools actually Staged at [workstation] — the source for the
  /// station-side "pick from what's staged here" selector (not a blind
  /// scan against every tool in the system).
  Future<List<StagedTool>> listStagedTools({
    required String toolType,
    required String workstation,
  }) async {
    final data = await _api.call('line2.list_staged_tools', body: {
      'tool_type': toolType,
      'workstation': workstation,
    });
    if (data is List) {
      return data
          .map((j) => StagedTool.fromJson(Map<String, dynamic>.from(j)))
          .toList();
    }
    return const [];
  }

  // ── Rejection ───────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> createRejection({
    required String workOrder,
    required String jobCard,
    required String rejectionType,
    String? reason,
    double? qty,
    String? returnToStep,
  }) async {
    final result = await _writeQueue.run('line2.create_rejection', {
      'wo_name': workOrder,
      'job_card': jobCard,
      'rejection_type': rejectionType,
      if (reason != null) 'reason_code': reason,
      if (qty != null) 'qty': qty,
      if (returnToStep != null) 'return_to_step': returnToStep,
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

  /// Whether QC Final should show/require the flowchart photo capture step
  /// — driven by Job Card.custom_flowchart_photo's Hidden state in Desk
  /// Customize Form, so this can be toggled without an app release.
  Future<bool> isFlowchartPhotoRequired() async {
    final data = await _api.call('line2_qc.flowchart_photo_required', body: {});
    return (data is Map && data['required'] == true);
  }

  /// Employees eligible to be picked as the actual submitter on a shared QC
  /// login (see submitMeasurement/submitQcResult `inspector`) — anyone whose
  /// User holds the Quality Inspector role.
  Future<List<Map<String, dynamic>>> listInspectors() async {
    final data = await _api.call('line2_qc.list_inspectors', body: {});
    if (data is List) {
      return data.map((j) => Map<String, dynamic>.from(j)).toList();
    }
    return const [];
  }

  Future<Map<String, dynamic>> submitMeasurement({
    required String workOrder,
    required String jobCard,
    required List<Map<String, dynamic>> measurements,
    String? inspector,
  }) async {
    final result = await _writeQueue.run('line2_qc.submit_measurement', {
      'work_order': workOrder,
      'job_card': jobCard,
      'measurements': measurements,
      if (inspector != null && inspector.isNotEmpty) 'inspector': inspector,
    });
    return Map<String, dynamic>.from(result);
  }

  Future<Map<String, dynamic>> submitQcResult({
    required String workOrder,
    required String result,
    String? jobCard,
    double? acceptedQty,
    String? remarks,
    String? inspector,
  }) async {
    final data = await _writeQueue.run('line2_qc.submit_qc_result', {
      'work_order': workOrder,
      'result': result,
      if (jobCard != null) 'job_card': jobCard,
      if (acceptedQty != null) 'accepted_qty': acceptedQty,
      if (remarks != null) 'remarks': remarks,
      if (inspector != null && inspector.isNotEmpty) 'inspector': inspector,
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

  // ── Dispatch receiving ──────────────────────────────────────────────────

  /// Warehouse scans a finished flowchart and records how much was actually
  /// received vs. what QC accepted (line2_packing.receive_flowchart).
  Future<Map<String, dynamic>> receiveFlowchart({
    required String barcode,
    required double receivedQty,
  }) async {
    final result = await _writeQueue.run('packing.receive_flowchart', {
      'barcode': barcode,
      'received_qty': receivedQty,
    });
    return Map<String, dynamic>.from(result);
  }

  /// Items received at the warehouse for a Sales Order that still need
  /// packing into a box/pallet (line2_packing.get_dispatch_pick_list).
  Future<List<Map<String, dynamic>>> getDispatchPickList(String salesOrder) async {
    final data = await _api.call('packing.get_dispatch_pick_list',
        body: {'sales_order': salesOrder});
    final items = (data is Map) ? data['items'] : null;
    if (items is List) {
      return items.map((j) => Map<String, dynamic>.from(j)).toList();
    }
    return const [];
  }

  // ── Packing ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> createBox({
    required String salesOrder,
  }) async {
    final result = await _writeQueue.run('packing.create_box', {
      'sales_order': salesOrder,
    });
    return Map<String, dynamic>.from(result);
  }

  /// itemBarcode is a Batch barcode (Batch.name doubles as the scannable
  /// code throughout this system) — the server resolves it to an item_code
  /// via packing.add_to_box's caller in the mobile API layer.
  Future<Map<String, dynamic>> addToBox({
    required String boxBarcode,
    required String itemBarcode,
    required double qty,
  }) async {
    final result = await _writeQueue.run('packing.add_to_box', {
      'box_barcode': boxBarcode,
      'batch_barcode': itemBarcode,
      'qty': qty,
    });
    return Map<String, dynamic>.from(result);
  }

  Future<Map<String, dynamic>> sealBox(
    String boxBarcode, {
    double? netWeight,
    double? grossWeight,
  }) async {
    final result = await _writeQueue.run('packing.seal_box', {
      'box_barcode': boxBarcode,
      if (netWeight != null) 'net_weight': netWeight,
      if (grossWeight != null) 'gross_weight': grossWeight,
    });
    return Map<String, dynamic>.from(result);
  }

  Future<Map<String, dynamic>> createPallet({
    required String salesOrder,
    String palletType = 'Belt',
  }) async {
    final result = await _writeQueue.run('packing.create_pallet', {
      'sales_order': salesOrder,
      'pallet_type': palletType,
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

  /// Direct sleeve-onto-pallet packing (pallet_type == "Sleeve" only).
  /// itemBarcode is a Batch barcode, same as addToBox.
  Future<Map<String, dynamic>> addItemToPallet({
    required String palletBarcode,
    required String itemBarcode,
    required double qty,
  }) async {
    final result = await _writeQueue.run('packing.add_item_to_pallet', {
      'pallet_barcode': palletBarcode,
      'batch_barcode': itemBarcode,
      'qty': qty,
    });
    return Map<String, dynamic>.from(result);
  }

  Future<Map<String, dynamic>> sealPallet(
    String palletBarcode, {
    double? netWeight,
    double? grossWeight,
  }) async {
    final result = await _writeQueue.run('packing.seal_pallet', {
      'pallet_barcode': palletBarcode,
      if (netWeight != null) 'net_weight': netWeight,
      if (grossWeight != null) 'gross_weight': grossWeight,
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
