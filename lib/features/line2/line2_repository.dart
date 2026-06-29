import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/models/line2_models.dart';
import '../../core/sync/write_queue.dart';
import '../../providers/service_providers.dart';

class Line2Repository {
  final ApiClient _api;
  final WriteQueue _writeQueue;

  Line2Repository({required ApiClient api, required WriteQueue writeQueue})
      : _api = api,
        _writeQueue = writeQueue;

  // ── Flowchart / Scanning ────────────────────────────────────────────────

  Future<FlowchartScanResult> scanFlowchart(String barcode) async {
    final data = await _api.call('line2.scan_flowchart',
        body: {'barcode': barcode});
    return FlowchartScanResult.fromJson(Map<String, dynamic>.from(data));
  }

  Future<List<ActiveJobCard>> getActiveJobs({String? workstation}) async {
    final data = await _api.call('line2.get_active_jobs', body: {
      if (workstation != null) 'workstation': workstation,
    });
    if (data is List) {
      return data
          .map((j) => ActiveJobCard.fromJson(Map<String, dynamic>.from(j)))
          .toList();
    }
    return const [];
  }

  Future<List<LayerItem>> getLayeringChecklist(String jobCard) async {
    final data = await _api.call('line2.get_layering_checklist',
        body: {'job_card': jobCard});
    if (data is List) {
      return data
          .map((j) => LayerItem.fromJson(Map<String, dynamic>.from(j)))
          .toList();
    }
    return const [];
  }

  // ── Step Completion ─────────────────────────────────────────────────────

  Future<StepCompleteResult> completeStep({
    required String jobCard,
    List<Map<String, dynamic>>? measurements,
    String? remarks,
  }) async {
    final result = await _writeQueue.run('line2.complete_step', {
      'job_card': jobCard,
      if (measurements != null) 'measurements': measurements,
      if (remarks != null) 'remarks': remarks,
    });
    return StepCompleteResult.fromJson(Map<String, dynamic>.from(result));
  }

  // ── Tool Management ─────────────────────────────────────────────────────

  Future<ToolAssignResult> assignTool({
    required String toolId,
    required String jobCard,
  }) async {
    final result = await _writeQueue.run('line2.assign_tool', {
      'tool_id': toolId,
      'job_card': jobCard,
    });
    return ToolAssignResult.fromJson(Map<String, dynamic>.from(result));
  }

  Future<ToolAssignResult> releaseTool({
    required String toolId,
    String? jobCard,
  }) async {
    final result = await _writeQueue.run('line2.release_tool', {
      'tool_id': toolId,
      if (jobCard != null) 'job_card': jobCard,
    });
    return ToolAssignResult.fromJson(Map<String, dynamic>.from(result));
  }

  Future<ToolInfo> getToolStatus(String toolId) async {
    final data = await _api.call('line2.get_tool_status',
        body: {'tool_id': toolId});
    return ToolInfo.fromJson(Map<String, dynamic>.from(data));
  }

  Future<ToolInfo> updateAirbagWeight({
    required String toolId,
    required double weightKg,
  }) async {
    final result = await _writeQueue.run('line2.update_airbag_weight', {
      'tool_id': toolId,
      'weight_kg': weightKg,
    });
    return ToolInfo.fromJson(Map<String, dynamic>.from(result));
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

  Future<RejectionResult> createRejection({
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
    return RejectionResult.fromJson(Map<String, dynamic>.from(result));
  }

  // ── QC ──────────────────────────────────────────────────────────────────

  Future<QcInfo> getQcInfo({
    required String workOrder,
    String? jobCard,
  }) async {
    final data = await _api.call('line2_qc.get_qc_info', body: {
      'work_order': workOrder,
      if (jobCard != null) 'job_card': jobCard,
    });
    return QcInfo.fromJson(Map<String, dynamic>.from(data));
  }

  Future<QcMeasurementResult> submitMeasurement({
    required String jobCard,
    required List<Map<String, dynamic>> measurements,
  }) async {
    final result = await _writeQueue.run('line2_qc.submit_measurement', {
      'job_card': jobCard,
      'measurements': measurements,
    });
    return QcMeasurementResult.fromJson(Map<String, dynamic>.from(result));
  }

  Future<QcResult> submitQcResult({
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
    return QcResult.fromJson(Map<String, dynamic>.from(data));
  }

  Future<WoCompleteResult> completeWo({
    required String workOrder,
    double? qty,
  }) async {
    final result = await _writeQueue.run('line2_qc.complete_wo', {
      'work_order': workOrder,
      if (qty != null) 'qty': qty,
    });
    return WoCompleteResult.fromJson(Map<String, dynamic>.from(result));
  }

  // ── Sleeves ─────────────────────────────────────────────────────────────

  Future<SleeveCreationResult> createSleeves({
    required String workOrder,
    required int sleeveCount,
  }) async {
    final result = await _writeQueue.run('line2_sleeve.create_sleeves', {
      'work_order': workOrder,
      'sleeve_count': sleeveCount,
    });
    return SleeveCreationResult.fromJson(Map<String, dynamic>.from(result));
  }

  Future<List<LayerItem>> getLayeringSequence(String productionItem) async {
    final data = await _api.call('line2_sleeve.get_layering_sequence',
        body: {'production_item': productionItem});
    if (data is List) {
      return data
          .map((j) => LayerItem.fromJson(Map<String, dynamic>.from(j)))
          .toList();
    }
    return const [];
  }

  // ── Packing ─────────────────────────────────────────────────────────────

  Future<BoxInfo> createBox({
    String? salesOrder,
  }) async {
    final result = await _writeQueue.run('packing.create_box', {
      if (salesOrder != null) 'sales_order': salesOrder,
    });
    return BoxInfo.fromJson(Map<String, dynamic>.from(result));
  }

  Future<BoxInfo> addToBox({
    required String boxBarcode,
    required String itemBarcode,
    double? qty,
  }) async {
    final result = await _writeQueue.run('packing.add_to_box', {
      'box_barcode': boxBarcode,
      'item_barcode': itemBarcode,
      if (qty != null) 'qty': qty,
    });
    return BoxInfo.fromJson(Map<String, dynamic>.from(result));
  }

  Future<BoxInfo> sealBox(String boxBarcode) async {
    final result = await _writeQueue.run('packing.seal_box', {
      'box_barcode': boxBarcode,
    });
    return BoxInfo.fromJson(Map<String, dynamic>.from(result));
  }

  Future<PalletInfo> createPallet({
    String? palletType,
    String? salesOrder,
  }) async {
    final result = await _writeQueue.run('packing.create_pallet', {
      if (palletType != null) 'pallet_type': palletType,
      if (salesOrder != null) 'sales_order': salesOrder,
    });
    return PalletInfo.fromJson(Map<String, dynamic>.from(result));
  }

  Future<PalletInfo> addBoxToPallet({
    required String palletBarcode,
    required String boxBarcode,
  }) async {
    final result = await _writeQueue.run('packing.add_box_to_pallet', {
      'pallet_barcode': palletBarcode,
      'box_barcode': boxBarcode,
    });
    return PalletInfo.fromJson(Map<String, dynamic>.from(result));
  }

  Future<PalletInfo> addItemToPallet({
    required String palletBarcode,
    required String itemBarcode,
    double? qty,
  }) async {
    final result = await _writeQueue.run('packing.add_item_to_pallet', {
      'pallet_barcode': palletBarcode,
      'item_barcode': itemBarcode,
      if (qty != null) 'qty': qty,
    });
    return PalletInfo.fromJson(Map<String, dynamic>.from(result));
  }

  Future<PalletInfo> sealPallet(String palletBarcode) async {
    final result = await _writeQueue.run('packing.seal_pallet', {
      'pallet_barcode': palletBarcode,
    });
    return PalletInfo.fromJson(Map<String, dynamic>.from(result));
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
