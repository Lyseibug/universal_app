import 'package:freezed_annotation/freezed_annotation.dart';

part 'line2_models.freezed.dart';
part 'line2_models.g.dart';

bool _intToBool(dynamic value) {
  if (value is bool) return value;
  if (value is int) return value != 0;
  if (value is String) return value == '1' || value.toLowerCase() == 'true';
  return false;
}

// ── Flowchart / Step Models ───────────────────────────────────────────────

@freezed
class FlowchartScanResult with _$FlowchartScanResult {
  const factory FlowchartScanResult({
    @JsonKey(name: 'work_order') required String workOrder,
    @JsonKey(name: 'production_item') required String productionItem,
    @JsonKey(name: 'item_name') String? itemName,
    @Default(0) double qty,
    @JsonKey(name: 'production_type') String? productionType,
    @JsonKey(name: 'current_step') required String currentStep,
    @JsonKey(name: 'step_name') String? stepName,
    @JsonKey(name: 'step_category') String? stepCategory,
    @JsonKey(name: 'job_card') required String jobCard,
    @JsonKey(name: 'job_card_status') String? jobCardStatus,
    @JsonKey(name: 'requires_tool', fromJson: _intToBool) @Default(false) bool requiresTool,
    @JsonKey(name: 'requires_measurements', fromJson: _intToBool) @Default(false) bool requiresMeasurements,
    @JsonKey(name: 'measurement_params') @Default([]) List<MeasurementParam> measurementParams,
    @JsonKey(name: 'target_time_minutes') @Default(0) int targetTimeMinutes,
    @JsonKey(name: 'buffer_time_minutes') @Default(0) int bufferTimeMinutes,
    @JsonKey(name: 'building_line') String? buildingLine,
    @JsonKey(name: 'flowchart_barcode') String? flowchartBarcode,
    @JsonKey(name: 'rework_count') @Default(0) int reworkCount,
    @JsonKey(name: 'is_rework', fromJson: _intToBool) @Default(false) bool isRework,
    @JsonKey(name: 'layering_sequence') @Default([]) List<LayerItem> layeringSequence,
  }) = _FlowchartScanResult;

  factory FlowchartScanResult.fromJson(Map<String, dynamic> json) =>
      _$FlowchartScanResultFromJson(json);
}

@freezed
class MeasurementParam with _$MeasurementParam {
  const factory MeasurementParam({
    @JsonKey(name: 'param_name') required String paramName,
    @JsonKey(name: 'param_code') String? paramCode,
    String? uom,
    @JsonKey(name: 'expected_min') @Default(0) double expectedMin,
    @JsonKey(name: 'expected_max') @Default(0) double expectedMax,
    @JsonKey(name: 'is_mandatory', fromJson: _intToBool) @Default(false) bool isMandatory,
  }) = _MeasurementParam;

  factory MeasurementParam.fromJson(Map<String, dynamic> json) =>
      _$MeasurementParamFromJson(json);
}

@freezed
class LayerItem with _$LayerItem {
  const factory LayerItem({
    @JsonKey(name: 'layer_sequence') @Default(0) int layerSequence,
    @JsonKey(name: 'item_code') required String itemCode,
    @JsonKey(name: 'item_name') String? itemName,
    @JsonKey(name: 'layer_count') @Default(1) int layerCount,
    @JsonKey(name: 'layer_description') String? layerDescription,
    @JsonKey(name: 'is_critical', fromJson: _intToBool) @Default(false) bool isCritical,
  }) = _LayerItem;

  factory LayerItem.fromJson(Map<String, dynamic> json) =>
      _$LayerItemFromJson(json);
}

@freezed
class StepCompleteResult with _$StepCompleteResult {
  const factory StepCompleteResult({
    @JsonKey(name: 'job_card') required String jobCard,
    required String status,
    @JsonKey(name: 'work_order') required String workOrder,
    @JsonKey(name: 'next_step') String? nextStep,
    @JsonKey(name: 'next_step_name') String? nextStepName,
  }) = _StepCompleteResult;

  factory StepCompleteResult.fromJson(Map<String, dynamic> json) =>
      _$StepCompleteResultFromJson(json);
}

// ── Active Job Card ───────────────────────────────────────────────────────

@freezed
class ActiveJobCard with _$ActiveJobCard {
  const factory ActiveJobCard({
    required String name,
    @JsonKey(name: 'work_order') required String workOrder,
    String? operation,
    required String status,
    String? workstation,
    @JsonKey(name: 'for_quantity') @Default(0) double forQuantity,
    String? creation,
    @JsonKey(name: 'custom_flowchart_step') String? flowchartStep,
    @JsonKey(name: 'custom_tool_id') String? toolId,
    @JsonKey(name: 'custom_is_rework', fromJson: _intToBool) @Default(false) bool isRework,
    @JsonKey(name: 'production_item') String? productionItem,
    @JsonKey(name: 'item_name') String? itemName,
    @JsonKey(name: 'flowchart_barcode') String? flowchartBarcode,
    @JsonKey(name: 'elapsed_seconds') @Default(0) double elapsedSeconds,
  }) = _ActiveJobCard;

  factory ActiveJobCard.fromJson(Map<String, dynamic> json) =>
      _$ActiveJobCardFromJson(json);
}

// ── QC Models ─────────────────────────────────────────────────────────────

@freezed
class QcInfo with _$QcInfo {
  const factory QcInfo({
    @JsonKey(name: 'work_order') required String workOrder,
    @JsonKey(name: 'production_item') required String productionItem,
    @JsonKey(name: 'item_name') String? itemName,
    @Default(0) double qty,
    @JsonKey(name: 'qc_mode') required String qcMode,
    @JsonKey(name: 'production_type') String? productionType,
    @Default([]) List<MeasurementParam> parameters,
    @JsonKey(name: 'job_card') String? jobCard,
    @JsonKey(name: 'flowchart_barcode') String? flowchartBarcode,
  }) = _QcInfo;

  factory QcInfo.fromJson(Map<String, dynamic> json) =>
      _$QcInfoFromJson(json);
}

@freezed
class QcMeasurementResult with _$QcMeasurementResult {
  const factory QcMeasurementResult({
    @JsonKey(name: 'job_card') required String jobCard,
    @JsonKey(name: 'work_order') required String workOrder,
    @Default([]) List<MeasurementResultItem> measurements,
    @JsonKey(name: 'all_pass', fromJson: _intToBool) @Default(false) bool allPass,
  }) = _QcMeasurementResult;

  factory QcMeasurementResult.fromJson(Map<String, dynamic> json) =>
      _$QcMeasurementResultFromJson(json);
}

@freezed
class MeasurementResultItem with _$MeasurementResultItem {
  const factory MeasurementResultItem({
    @JsonKey(name: 'parameter_name') required String parameterName,
    @JsonKey(name: 'actual_value') @Default(0) double actualValue,
    @JsonKey(name: 'is_pass', fromJson: _intToBool) @Default(false) bool isPass,
  }) = _MeasurementResultItem;

  factory MeasurementResultItem.fromJson(Map<String, dynamic> json) =>
      _$MeasurementResultItemFromJson(json);
}

@freezed
class QcResult with _$QcResult {
  const factory QcResult({
    @JsonKey(name: 'work_order') required String workOrder,
    @JsonKey(name: 'job_card') String? jobCard,
    @JsonKey(name: 'accepted_qty') @Default(0) double acceptedQty,
    @JsonKey(name: 'ready_for_completion', fromJson: _intToBool) @Default(false) bool readyForCompletion,
  }) = _QcResult;

  factory QcResult.fromJson(Map<String, dynamic> json) =>
      _$QcResultFromJson(json);
}

// ── Work Order Completion ─────────────────────────────────────────────────

@freezed
class WoCompleteResult with _$WoCompleteResult {
  const factory WoCompleteResult({
    @JsonKey(name: 'work_order') required String workOrder,
    @JsonKey(name: 'stock_entry') required String stockEntry,
    @JsonKey(name: 'finished_batch') required String finishedBatch,
    @JsonKey(name: 'produced_qty') @Default(0) double producedQty,
    required String status,
    @JsonKey(name: 'sleeve_qty') double? sleeveQty,
    @JsonKey(name: 'belt_qty') double? beltQty,
    @JsonKey(name: 'conversion_factor') double? conversionFactor,
  }) = _WoCompleteResult;

  factory WoCompleteResult.fromJson(Map<String, dynamic> json) =>
      _$WoCompleteResultFromJson(json);
}

// ── Tool Models ───────────────────────────────────────────────────────────

@freezed
class ToolInfo with _$ToolInfo {
  const factory ToolInfo({
    required String name,
    @JsonKey(name: 'tool_code') required String toolCode,
    @JsonKey(name: 'tool_name') required String toolName,
    @JsonKey(name: 'tool_type') required String toolType,
    required String status,
    String? condition,
    @JsonKey(name: 'current_job_card') String? currentJobCard,
    @JsonKey(name: 'work_order') String? workOrder,
    @JsonKey(name: 'total_uses') @Default(0) int totalUses,
    @JsonKey(name: 'current_weight_kg') @Default(0) double currentWeightKg,
    @JsonKey(name: 'weight_conversion_threshold_kg') @Default(0) double weightThresholdKg,
    @JsonKey(name: 'max_cure_cycles') @Default(0) int maxCureCycles,
    @JsonKey(name: 'pot_capacity') @Default(0) int potCapacity,
    @JsonKey(name: 'needs_conversion', fromJson: _intToBool) @Default(false) bool needsConversion,
    @JsonKey(name: 'last_maintenance_date') String? lastMaintenanceDate,
    @JsonKey(name: 'next_maintenance_due') String? nextMaintenanceDue,
  }) = _ToolInfo;

  factory ToolInfo.fromJson(Map<String, dynamic> json) =>
      _$ToolInfoFromJson(json);
}

@freezed
class ToolAssignResult with _$ToolAssignResult {
  const factory ToolAssignResult({
    @JsonKey(name: 'tool_id') required String toolId,
    @JsonKey(name: 'tool_name') String? toolName,
    @JsonKey(name: 'tool_type') String? toolType,
    @JsonKey(name: 'job_card') String? jobCard,
    required String status,
    @JsonKey(name: 'total_uses') @Default(0) int totalUses,
  }) = _ToolAssignResult;

  factory ToolAssignResult.fromJson(Map<String, dynamic> json) =>
      _$ToolAssignResultFromJson(json);
}

// ── Packing Models ────────────────────────────────────────────────────────

@freezed
class BoxInfo with _$BoxInfo {
  const factory BoxInfo({
    @JsonKey(name: 'box_barcode') required String boxBarcode,
    @JsonKey(name: 'sales_order') String? salesOrder,
    required String status,
    @JsonKey(name: 'total_qty') @Default(0) double totalQty,
    @JsonKey(name: 'item_count') @Default(0) int itemCount,
  }) = _BoxInfo;

  factory BoxInfo.fromJson(Map<String, dynamic> json) =>
      _$BoxInfoFromJson(json);
}

@freezed
class PalletInfo with _$PalletInfo {
  const factory PalletInfo({
    @JsonKey(name: 'pallet_barcode') required String palletBarcode,
    @JsonKey(name: 'pallet_type') String? palletType,
    @JsonKey(name: 'sales_order') String? salesOrder,
    required String status,
    @JsonKey(name: 'total_boxes') @Default(0) int totalBoxes,
    @JsonKey(name: 'lot_address') String? lotAddress,
  }) = _PalletInfo;

  factory PalletInfo.fromJson(Map<String, dynamic> json) =>
      _$PalletInfoFromJson(json);
}

// ── Sleeve Models ─────────────────────────────────────────────────────────

@freezed
class SleeveCreationResult with _$SleeveCreationResult {
  const factory SleeveCreationResult({
    required String name,
    @JsonKey(name: 'stock_entry') required String stockEntry,
    @JsonKey(name: 'batch_no') required String batchNo,
    @JsonKey(name: 'sleeves_produced') required int sleevesProduced,
  }) = _SleeveCreationResult;

  factory SleeveCreationResult.fromJson(Map<String, dynamic> json) =>
      _$SleeveCreationResultFromJson(json);
}

// ── Rejection Models ──────────────────────────────────────────────────────

@freezed
class RejectionResult with _$RejectionResult {
  const factory RejectionResult({
    @JsonKey(name: 'rejection_log') String? rejectionLog,
    @JsonKey(name: 'rework_job_card') String? reworkJobCard,
    @JsonKey(name: 'scrap_stock_entry') String? scrapStockEntry,
  }) = _RejectionResult;

  factory RejectionResult.fromJson(Map<String, dynamic> json) =>
      _$RejectionResultFromJson(json);
}
