bool _intToBool(dynamic value) {
  if (value is bool) return value;
  if (value is int) return value != 0;
  if (value is String) return value == '1' || value.toLowerCase() == 'true';
  return false;
}

// ── Flowchart / Step Models ───────────────────────────────────────────────

class FlowchartScanResult {
  final String workOrder;
  final String productionItem;
  final String? itemName;
  final double qty;
  final String? productionType;
  final String currentStep;
  final String? stepName;
  final String? stepCategory;
  final String jobCard;
  final String? jobCardStatus;
  final bool requiresTool;
  final bool requiresMeasurements;
  final List<MeasurementParam> measurementParams;
  final int targetTimeMinutes;
  final int bufferTimeMinutes;
  final String? buildingLine;
  final String? flowchartBarcode;
  final int reworkCount;
  final bool isRework;
  final List<LayerItem> layeringSequence;

  FlowchartScanResult({
    required this.workOrder,
    required this.productionItem,
    this.itemName,
    this.qty = 0,
    this.productionType,
    required this.currentStep,
    this.stepName,
    this.stepCategory,
    required this.jobCard,
    this.jobCardStatus,
    this.requiresTool = false,
    this.requiresMeasurements = false,
    this.measurementParams = const [],
    this.targetTimeMinutes = 0,
    this.bufferTimeMinutes = 0,
    this.buildingLine,
    this.flowchartBarcode,
    this.reworkCount = 0,
    this.isRework = false,
    this.layeringSequence = const [],
  });

  factory FlowchartScanResult.fromJson(Map<String, dynamic> json) {
    return FlowchartScanResult(
      workOrder: json['work_order'] as String,
      productionItem: json['production_item'] as String,
      itemName: json['item_name'] as String?,
      qty: (json['qty'] as num?)?.toDouble() ?? 0,
      productionType: json['production_type'] as String?,
      currentStep: json['current_step'] as String,
      stepName: json['step_name'] as String?,
      stepCategory: json['step_category'] as String?,
      jobCard: json['job_card'] as String,
      jobCardStatus: json['job_card_status'] as String?,
      requiresTool: _intToBool(json['requires_tool']),
      requiresMeasurements: _intToBool(json['requires_measurements']),
      measurementParams: (json['measurement_params'] as List?)
              ?.map((e) =>
                  MeasurementParam.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      targetTimeMinutes: (json['target_time_minutes'] as num?)?.toInt() ?? 0,
      bufferTimeMinutes: (json['buffer_time_minutes'] as num?)?.toInt() ?? 0,
      buildingLine: json['building_line'] as String?,
      flowchartBarcode: json['flowchart_barcode'] as String?,
      reworkCount: (json['rework_count'] as num?)?.toInt() ?? 0,
      isRework: _intToBool(json['is_rework']),
      layeringSequence: (json['layering_sequence'] as List?)
              ?.map((e) => LayerItem.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'work_order': workOrder,
        'production_item': productionItem,
        'item_name': itemName,
        'qty': qty,
        'production_type': productionType,
        'current_step': currentStep,
        'step_name': stepName,
        'step_category': stepCategory,
        'job_card': jobCard,
        'job_card_status': jobCardStatus,
        'requires_tool': requiresTool,
        'requires_measurements': requiresMeasurements,
        'measurement_params':
            measurementParams.map((e) => e.toJson()).toList(),
        'target_time_minutes': targetTimeMinutes,
        'buffer_time_minutes': bufferTimeMinutes,
        'building_line': buildingLine,
        'flowchart_barcode': flowchartBarcode,
        'rework_count': reworkCount,
        'is_rework': isRework,
        'layering_sequence':
            layeringSequence.map((e) => e.toJson()).toList(),
      };
}

class MeasurementParam {
  final String paramName;
  final String? paramCode;
  final String? uom;
  final double expectedMin;
  final double expectedMax;
  final bool isMandatory;

  MeasurementParam({
    required this.paramName,
    this.paramCode,
    this.uom,
    this.expectedMin = 0,
    this.expectedMax = 0,
    this.isMandatory = false,
  });

  factory MeasurementParam.fromJson(Map<String, dynamic> json) {
    return MeasurementParam(
      paramName: json['param_name'] as String,
      paramCode: json['param_code'] as String?,
      uom: json['uom'] as String?,
      expectedMin: (json['expected_min'] as num?)?.toDouble() ?? 0,
      expectedMax: (json['expected_max'] as num?)?.toDouble() ?? 0,
      isMandatory: _intToBool(json['is_mandatory']),
    );
  }

  Map<String, dynamic> toJson() => {
        'param_name': paramName,
        'param_code': paramCode,
        'uom': uom,
        'expected_min': expectedMin,
        'expected_max': expectedMax,
        'is_mandatory': isMandatory,
      };
}

class LayerItem {
  final int layerSequence;
  final String itemCode;
  final String? itemName;
  final int layerCount;
  final String? layerDescription;
  final bool isCritical;

  LayerItem({
    this.layerSequence = 0,
    required this.itemCode,
    this.itemName,
    this.layerCount = 1,
    this.layerDescription,
    this.isCritical = false,
  });

  factory LayerItem.fromJson(Map<String, dynamic> json) {
    return LayerItem(
      layerSequence: (json['layer_sequence'] as num?)?.toInt() ?? 0,
      itemCode: json['item_code'] as String,
      itemName: json['item_name'] as String?,
      layerCount: (json['layer_count'] as num?)?.toInt() ?? 1,
      layerDescription: json['layer_description'] as String?,
      isCritical: _intToBool(json['is_critical']),
    );
  }

  Map<String, dynamic> toJson() => {
        'layer_sequence': layerSequence,
        'item_code': itemCode,
        'item_name': itemName,
        'layer_count': layerCount,
        'layer_description': layerDescription,
        'is_critical': isCritical,
      };
}

class StepCompleteResult {
  final String jobCard;
  final String status;
  final String workOrder;
  final String? nextStep;
  final String? nextStepName;

  StepCompleteResult({
    required this.jobCard,
    required this.status,
    required this.workOrder,
    this.nextStep,
    this.nextStepName,
  });

  factory StepCompleteResult.fromJson(Map<String, dynamic> json) {
    return StepCompleteResult(
      jobCard: json['job_card'] as String,
      status: json['status'] as String,
      workOrder: json['work_order'] as String,
      nextStep: json['next_step'] as String?,
      nextStepName: json['next_step_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'job_card': jobCard,
        'status': status,
        'work_order': workOrder,
        'next_step': nextStep,
        'next_step_name': nextStepName,
      };
}

// ── Active Job Card ───────────────────────────────────────────────────────

class ActiveJobCard {
  final String name;
  final String workOrder;
  final String? operation;
  final String status;
  final String? workstation;
  final double forQuantity;
  final String? creation;
  final String? flowchartStep;
  final String? toolId;
  final bool isRework;
  final String? productionItem;
  final String? itemName;
  final String? flowchartBarcode;
  final double elapsedSeconds;

  ActiveJobCard({
    required this.name,
    required this.workOrder,
    this.operation,
    required this.status,
    this.workstation,
    this.forQuantity = 0,
    this.creation,
    this.flowchartStep,
    this.toolId,
    this.isRework = false,
    this.productionItem,
    this.itemName,
    this.flowchartBarcode,
    this.elapsedSeconds = 0,
  });

  factory ActiveJobCard.fromJson(Map<String, dynamic> json) {
    return ActiveJobCard(
      name: json['name'] as String,
      workOrder: json['work_order'] as String,
      operation: json['operation'] as String?,
      status: json['status'] as String,
      workstation: json['workstation'] as String?,
      forQuantity: (json['for_quantity'] as num?)?.toDouble() ?? 0,
      creation: json['creation'] as String?,
      flowchartStep: json['custom_flowchart_step'] as String?,
      toolId: json['custom_tool_id'] as String?,
      isRework: _intToBool(json['custom_is_rework']),
      productionItem: json['production_item'] as String?,
      itemName: json['item_name'] as String?,
      flowchartBarcode: json['flowchart_barcode'] as String?,
      elapsedSeconds: (json['elapsed_seconds'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'work_order': workOrder,
        'operation': operation,
        'status': status,
        'workstation': workstation,
        'for_quantity': forQuantity,
        'creation': creation,
        'custom_flowchart_step': flowchartStep,
        'custom_tool_id': toolId,
        'custom_is_rework': isRework,
        'production_item': productionItem,
        'item_name': itemName,
        'flowchart_barcode': flowchartBarcode,
        'elapsed_seconds': elapsedSeconds,
      };
}

// ── QC Models ─────────────────────────────────────────────────────────────

class QcInfo {
  final String workOrder;
  final String productionItem;
  final String? itemName;
  final double qty;
  final String qcMode;
  final String? productionType;
  final List<MeasurementParam> parameters;
  final String? jobCard;
  final String? flowchartBarcode;

  QcInfo({
    required this.workOrder,
    required this.productionItem,
    this.itemName,
    this.qty = 0,
    required this.qcMode,
    this.productionType,
    this.parameters = const [],
    this.jobCard,
    this.flowchartBarcode,
  });

  factory QcInfo.fromJson(Map<String, dynamic> json) {
    return QcInfo(
      workOrder: json['work_order'] as String,
      productionItem: json['production_item'] as String,
      itemName: json['item_name'] as String?,
      qty: (json['qty'] as num?)?.toDouble() ?? 0,
      qcMode: json['qc_mode'] as String,
      productionType: json['production_type'] as String?,
      parameters: (json['parameters'] as List?)
              ?.map((e) =>
                  MeasurementParam.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      jobCard: json['job_card'] as String?,
      flowchartBarcode: json['flowchart_barcode'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'work_order': workOrder,
        'production_item': productionItem,
        'item_name': itemName,
        'qty': qty,
        'qc_mode': qcMode,
        'production_type': productionType,
        'parameters': parameters.map((e) => e.toJson()).toList(),
        'job_card': jobCard,
        'flowchart_barcode': flowchartBarcode,
      };
}

class QcMeasurementResult {
  final String jobCard;
  final String workOrder;
  final List<MeasurementResultItem> measurements;
  final bool allPass;

  QcMeasurementResult({
    required this.jobCard,
    required this.workOrder,
    this.measurements = const [],
    this.allPass = false,
  });

  factory QcMeasurementResult.fromJson(Map<String, dynamic> json) {
    return QcMeasurementResult(
      jobCard: json['job_card'] as String,
      workOrder: json['work_order'] as String,
      measurements: (json['measurements'] as List?)
              ?.map((e) => MeasurementResultItem.fromJson(
                  Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      allPass: _intToBool(json['all_pass']),
    );
  }

  Map<String, dynamic> toJson() => {
        'job_card': jobCard,
        'work_order': workOrder,
        'measurements': measurements.map((e) => e.toJson()).toList(),
        'all_pass': allPass,
      };
}

class MeasurementResultItem {
  final String parameterName;
  final double actualValue;
  final bool isPass;

  MeasurementResultItem({
    required this.parameterName,
    this.actualValue = 0,
    this.isPass = false,
  });

  factory MeasurementResultItem.fromJson(Map<String, dynamic> json) {
    return MeasurementResultItem(
      parameterName: json['parameter_name'] as String,
      actualValue: (json['actual_value'] as num?)?.toDouble() ?? 0,
      isPass: _intToBool(json['is_pass']),
    );
  }

  Map<String, dynamic> toJson() => {
        'parameter_name': parameterName,
        'actual_value': actualValue,
        'is_pass': isPass,
      };
}

class QcResult {
  final String workOrder;
  final String? jobCard;
  final double acceptedQty;
  final bool readyForCompletion;

  QcResult({
    required this.workOrder,
    this.jobCard,
    this.acceptedQty = 0,
    this.readyForCompletion = false,
  });

  factory QcResult.fromJson(Map<String, dynamic> json) {
    return QcResult(
      workOrder: json['work_order'] as String,
      jobCard: json['job_card'] as String?,
      acceptedQty: (json['accepted_qty'] as num?)?.toDouble() ?? 0,
      readyForCompletion: _intToBool(json['ready_for_completion']),
    );
  }

  Map<String, dynamic> toJson() => {
        'work_order': workOrder,
        'job_card': jobCard,
        'accepted_qty': acceptedQty,
        'ready_for_completion': readyForCompletion,
      };
}

// ── Work Order Completion ─────────────────────────────────────────────────

class WoCompleteResult {
  final String workOrder;
  final String stockEntry;
  final String finishedBatch;
  final double producedQty;
  final String status;
  final double? sleeveQty;
  final double? beltQty;
  final double? conversionFactor;

  WoCompleteResult({
    required this.workOrder,
    required this.stockEntry,
    required this.finishedBatch,
    this.producedQty = 0,
    required this.status,
    this.sleeveQty,
    this.beltQty,
    this.conversionFactor,
  });

  factory WoCompleteResult.fromJson(Map<String, dynamic> json) {
    return WoCompleteResult(
      workOrder: json['work_order'] as String,
      stockEntry: json['stock_entry'] as String,
      finishedBatch: json['finished_batch'] as String,
      producedQty: (json['produced_qty'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String,
      sleeveQty: (json['sleeve_qty'] as num?)?.toDouble(),
      beltQty: (json['belt_qty'] as num?)?.toDouble(),
      conversionFactor: (json['conversion_factor'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'work_order': workOrder,
        'stock_entry': stockEntry,
        'finished_batch': finishedBatch,
        'produced_qty': producedQty,
        'status': status,
        'sleeve_qty': sleeveQty,
        'belt_qty': beltQty,
        'conversion_factor': conversionFactor,
      };
}

// ── Tool Models ───────────────────────────────────────────────────────────

class ToolInfo {
  final String name;
  final String toolCode;
  final String toolName;
  final String toolType;
  final String status;
  final String? condition;
  final String? currentJobCard;
  final String? workOrder;
  final int totalUses;
  final double currentWeightKg;
  final double weightThresholdKg;
  final int maxCureCycles;
  final int potCapacity;
  final bool needsConversion;
  final String? lastMaintenanceDate;
  final String? nextMaintenanceDue;

  ToolInfo({
    required this.name,
    required this.toolCode,
    required this.toolName,
    required this.toolType,
    required this.status,
    this.condition,
    this.currentJobCard,
    this.workOrder,
    this.totalUses = 0,
    this.currentWeightKg = 0,
    this.weightThresholdKg = 0,
    this.maxCureCycles = 0,
    this.potCapacity = 0,
    this.needsConversion = false,
    this.lastMaintenanceDate,
    this.nextMaintenanceDue,
  });

  factory ToolInfo.fromJson(Map<String, dynamic> json) {
    return ToolInfo(
      name: json['name'] as String,
      toolCode: json['tool_code'] as String,
      toolName: json['tool_name'] as String,
      toolType: json['tool_type'] as String,
      status: json['status'] as String,
      condition: json['condition'] as String?,
      currentJobCard: json['current_job_card'] as String?,
      workOrder: json['work_order'] as String?,
      totalUses: (json['total_uses'] as num?)?.toInt() ?? 0,
      currentWeightKg: (json['current_weight_kg'] as num?)?.toDouble() ?? 0,
      weightThresholdKg:
          (json['weight_conversion_threshold_kg'] as num?)?.toDouble() ?? 0,
      maxCureCycles: (json['max_cure_cycles'] as num?)?.toInt() ?? 0,
      potCapacity: (json['pot_capacity'] as num?)?.toInt() ?? 0,
      needsConversion: _intToBool(json['needs_conversion']),
      lastMaintenanceDate: json['last_maintenance_date'] as String?,
      nextMaintenanceDue: json['next_maintenance_due'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'tool_code': toolCode,
        'tool_name': toolName,
        'tool_type': toolType,
        'status': status,
        'condition': condition,
        'current_job_card': currentJobCard,
        'work_order': workOrder,
        'total_uses': totalUses,
        'current_weight_kg': currentWeightKg,
        'weight_conversion_threshold_kg': weightThresholdKg,
        'max_cure_cycles': maxCureCycles,
        'pot_capacity': potCapacity,
        'needs_conversion': needsConversion,
        'last_maintenance_date': lastMaintenanceDate,
        'next_maintenance_due': nextMaintenanceDue,
      };
}

class ToolAssignResult {
  final String toolId;
  final String? toolName;
  final String? toolType;
  final String? jobCard;
  final String status;
  final int totalUses;

  ToolAssignResult({
    required this.toolId,
    this.toolName,
    this.toolType,
    this.jobCard,
    required this.status,
    this.totalUses = 0,
  });

  factory ToolAssignResult.fromJson(Map<String, dynamic> json) {
    return ToolAssignResult(
      toolId: json['tool_id'] as String,
      toolName: json['tool_name'] as String?,
      toolType: json['tool_type'] as String?,
      jobCard: json['job_card'] as String?,
      status: json['status'] as String,
      totalUses: (json['total_uses'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'tool_id': toolId,
        'tool_name': toolName,
        'tool_type': toolType,
        'job_card': jobCard,
        'status': status,
        'total_uses': totalUses,
      };
}

// ── Packing Models ────────────────────────────────────────────────────────

class BoxInfo {
  final String boxBarcode;
  final String? salesOrder;
  final String status;
  final double totalQty;
  final int itemCount;

  BoxInfo({
    required this.boxBarcode,
    this.salesOrder,
    required this.status,
    this.totalQty = 0,
    this.itemCount = 0,
  });

  factory BoxInfo.fromJson(Map<String, dynamic> json) {
    return BoxInfo(
      boxBarcode: json['box_barcode'] as String,
      salesOrder: json['sales_order'] as String?,
      status: json['status'] as String,
      totalQty: (json['total_qty'] as num?)?.toDouble() ?? 0,
      itemCount: (json['item_count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'box_barcode': boxBarcode,
        'sales_order': salesOrder,
        'status': status,
        'total_qty': totalQty,
        'item_count': itemCount,
      };
}

class PalletInfo {
  final String palletBarcode;
  final String? palletType;
  final String? salesOrder;
  final String status;
  final int totalBoxes;
  final String? lotAddress;

  PalletInfo({
    required this.palletBarcode,
    this.palletType,
    this.salesOrder,
    required this.status,
    this.totalBoxes = 0,
    this.lotAddress,
  });

  factory PalletInfo.fromJson(Map<String, dynamic> json) {
    return PalletInfo(
      palletBarcode: json['pallet_barcode'] as String,
      palletType: json['pallet_type'] as String?,
      salesOrder: json['sales_order'] as String?,
      status: json['status'] as String,
      totalBoxes: (json['total_boxes'] as num?)?.toInt() ?? 0,
      lotAddress: json['lot_address'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'pallet_barcode': palletBarcode,
        'pallet_type': palletType,
        'sales_order': salesOrder,
        'status': status,
        'total_boxes': totalBoxes,
        'lot_address': lotAddress,
      };
}

// ── Sleeve Models ─────────────────────────────────────────────────────────

class SleeveCreationResult {
  final String name;
  final String stockEntry;
  final String batchNo;
  final int sleevesProduced;

  SleeveCreationResult({
    required this.name,
    required this.stockEntry,
    required this.batchNo,
    required this.sleevesProduced,
  });

  factory SleeveCreationResult.fromJson(Map<String, dynamic> json) {
    return SleeveCreationResult(
      name: json['name'] as String,
      stockEntry: json['stock_entry'] as String,
      batchNo: json['batch_no'] as String,
      sleevesProduced: (json['sleeves_produced'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'stock_entry': stockEntry,
        'batch_no': batchNo,
        'sleeves_produced': sleevesProduced,
      };
}

// ── Rejection Models ──────────────────────────────────────────────────────

class RejectionResult {
  final String? rejectionLog;
  final String? reworkJobCard;
  final String? scrapStockEntry;

  RejectionResult({
    this.rejectionLog,
    this.reworkJobCard,
    this.scrapStockEntry,
  });

  factory RejectionResult.fromJson(Map<String, dynamic> json) {
    return RejectionResult(
      rejectionLog: json['rejection_log'] as String?,
      reworkJobCard: json['rework_job_card'] as String?,
      scrapStockEntry: json['scrap_stock_entry'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'rejection_log': rejectionLog,
        'rework_job_card': reworkJobCard,
        'scrap_stock_entry': scrapStockEntry,
      };
}
