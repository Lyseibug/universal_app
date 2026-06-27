import 'package:freezed_annotation/freezed_annotation.dart';

part 'line1_models.freezed.dart';
part 'line1_models.g.dart';

bool _intToBool(dynamic value) {
  if (value is bool) return value;
  if (value is int) return value != 0;
  if (value is String) return value == '1' || value.toLowerCase() == 'true';
  return false;
}

@freezed
class StockItem with _$StockItem {
  const factory StockItem({
    @JsonKey(name: 'item_code') required String itemCode,
    @JsonKey(name: 'item_name') String? itemName,
    @JsonKey(name: 'batch_no') String? batchNo,
    @Default(0) double qty,
    @JsonKey(name: 'production_date') String? productionDate,
    String? stream,
  }) = _StockItem;

  factory StockItem.fromJson(Map<String, dynamic> json) =>
      _$StockItemFromJson(json);
}

@freezed
class LoadResult with _$LoadResult {
  const factory LoadResult({
    @JsonKey(name: 'stock_entry') String? stockEntry,
    @Default(0) double qty,
    @JsonKey(name: 'batch_no') String? batchNo,
    @JsonKey(name: 'box_barcode') String? boxBarcode,
    String? stream,
  }) = _LoadResult;

  factory LoadResult.fromJson(Map<String, dynamic> json) =>
      _$LoadResultFromJson(json);
}

@freezed
class BagItem with _$BagItem {
  const factory BagItem({
    @JsonKey(name: 'batch_no') required String batchNo,
    @JsonKey(name: 'item_code') required String itemCode,
    @JsonKey(name: 'item_name') String? itemName,
    @Default(0) double qty,
    @JsonKey(name: 'formula_name') String? formulaName,
    @JsonKey(name: 'production_datetime') String? productionDatetime,
    @JsonKey(name: 'machine_production_record') String? machineProductionRecord,
  }) = _BagItem;

  factory BagItem.fromJson(Map<String, dynamic> json) =>
      _$BagItemFromJson(json);
}

@freezed
class BagDetail with _$BagDetail {
  const factory BagDetail({
    @JsonKey(name: 'batch_no') required String batchNo,
    @JsonKey(name: 'item_code') required String itemCode,
    @JsonKey(name: 'item_name') String? itemName,
    @Default(0) double qty,
    @JsonKey(name: 'formula_name') String? formulaName,
    @JsonKey(name: 'manufacturing_date') String? manufacturingDate,
    @JsonKey(name: 'machine_production_record') String? machineProductionRecord,
    @JsonKey(name: 'consume_items') @Default([]) List<ConsumeItem> consumeItems,
  }) = _BagDetail;

  factory BagDetail.fromJson(Map<String, dynamic> json) =>
      _$BagDetailFromJson(json);
}

@freezed
class ConsumeItem with _$ConsumeItem {
  const factory ConsumeItem({
    @JsonKey(name: 'item_code') required String itemCode,
    @JsonKey(name: 'item_name') String? itemName,
    @JsonKey(name: 'batch_no') String? batchNo,
    @Default(0) double qty,
    String? warehouse,
  }) = _ConsumeItem;

  factory ConsumeItem.fromJson(Map<String, dynamic> json) =>
      _$ConsumeItemFromJson(json);
}

@freezed
class FmbBatch with _$FmbBatch {
  const factory FmbBatch({
    @JsonKey(name: 'batch_no') required String batchNo,
    @JsonKey(name: 'item_code') required String itemCode,
    @JsonKey(name: 'item_name') String? itemName,
    @Default(0) double qty,
    @JsonKey(name: 'lab_status') @Default('Pending') String labStatus,
    @JsonKey(name: 'manufacturing_date') String? manufacturingDate,
    @JsonKey(name: 'formula_name') String? formulaName,
    @JsonKey(name: 'formula_code') String? formulaCode,
  }) = _FmbBatch;

  factory FmbBatch.fromJson(Map<String, dynamic> json) =>
      _$FmbBatchFromJson(json);
}

@freezed
class FmbDetail with _$FmbDetail {
  const factory FmbDetail({
    @JsonKey(name: 'batch_no') required String batchNo,
    @JsonKey(name: 'item_code') required String itemCode,
    @JsonKey(name: 'item_name') String? itemName,
    @Default(0) double qty,
    @JsonKey(name: 'lab_status') @Default('Pending') String labStatus,
    @JsonKey(name: 'manufacturing_date') String? manufacturingDate,
    @JsonKey(name: 'formula_name') String? formulaName,
    @JsonKey(name: 'formula_code') String? formulaCode,
    @JsonKey(name: 'lab_test') LabTestInfo? labTest,
  }) = _FmbDetail;

  factory FmbDetail.fromJson(Map<String, dynamic> json) =>
      _$FmbDetailFromJson(json);
}

@freezed
class LabTestInfo with _$LabTestInfo {
  const factory LabTestInfo({
    required String name,
    @Default('Pending') String result,
    @JsonKey(name: 'tested_by') String? testedBy,
    @JsonKey(name: 'tested_on') String? testedOn,
    @Default(0) int docstatus,
    @Default([]) List<LabTestParameter> parameters,
  }) = _LabTestInfo;

  factory LabTestInfo.fromJson(Map<String, dynamic> json) =>
      _$LabTestInfoFromJson(json);
}

@freezed
class LabTestParameter with _$LabTestParameter {
  const factory LabTestParameter({
    @JsonKey(name: 'parameter_name') required String parameterName,
    @JsonKey(name: 'expected_min') @Default(0) double expectedMin,
    @JsonKey(name: 'expected_max') @Default(0) double expectedMax,
    @JsonKey(name: 'result_value') @Default(0) double resultValue,
    @JsonKey(name: 'is_pass', fromJson: _intToBool) @Default(false) bool isPass,
  }) = _LabTestParameter;

  factory LabTestParameter.fromJson(Map<String, dynamic> json) =>
      _$LabTestParameterFromJson(json);
}

@freezed
class LabTestResult with _$LabTestResult {
  const factory LabTestResult({
    @JsonKey(name: 'lab_test') required String labTest,
    required String result,
    @JsonKey(name: 'fmb_batch') required String fmbBatch,
    @Default([]) List<LabTestParameterResult> parameters,
  }) = _LabTestResult;

  factory LabTestResult.fromJson(Map<String, dynamic> json) =>
      _$LabTestResultFromJson(json);
}

@freezed
class LabTestParameterResult with _$LabTestParameterResult {
  const factory LabTestParameterResult({
    @JsonKey(name: 'parameter_name') required String parameterName,
    @JsonKey(name: 'result_value') @Default(0) double resultValue,
    @JsonKey(name: 'is_pass', fromJson: _intToBool) @Default(false) bool isPass,
  }) = _LabTestParameterResult;

  factory LabTestParameterResult.fromJson(Map<String, dynamic> json) =>
      _$LabTestParameterResultFromJson(json);
}

// ── Calendering Models ──────────────────────────────────────────────────

@freezed
class CalenderingFmb with _$CalenderingFmb {
  const factory CalenderingFmb({
    @JsonKey(name: 'batch_no') required String batchNo,
    @JsonKey(name: 'item_code') required String itemCode,
    @JsonKey(name: 'item_name') String? itemName,
    @Default(0) double qty,
    @JsonKey(name: 'lab_status') @Default('Pass') String labStatus,
    @JsonKey(name: 'manufacturing_date') String? manufacturingDate,
  }) = _CalenderingFmb;

  factory CalenderingFmb.fromJson(Map<String, dynamic> json) =>
      _$CalenderingFmbFromJson(json);
}

@freezed
class CalenderingSheet with _$CalenderingSheet {
  const factory CalenderingSheet({
    @JsonKey(name: 'item_code') required String itemCode,
    @Default(0) double qty,
    @JsonKey(name: 'thickness_mm') @Default(0) double thicknessMm,
    @JsonKey(name: 'width_in_mm') @Default(0) double widthInMm,
    @JsonKey(name: 'length_in_mm') @Default(0) double lengthInMm,
    @JsonKey(name: 'batch_no') String? batchNo,
  }) = _CalenderingSheet;

  factory CalenderingSheet.fromJson(Map<String, dynamic> json) =>
      _$CalenderingSheetFromJson(json);
}

@freezed
class CalenderingRun with _$CalenderingRun {
  const factory CalenderingRun({
    required String name,
    @JsonKey(name: 'fmb_batch') required String fmbBatch,
    @JsonKey(name: 'fmb_item') String? fmbItem,
    @JsonKey(name: 'item_name') String? itemName,
    @Default('Draft') String status,
    String? operator,
    @JsonKey(name: 'start_time') String? startTime,
    @JsonKey(name: 'end_time') String? endTime,
    @JsonKey(name: 'fmb_input_qty') @Default(0) double fmbInputQty,
    @JsonKey(name: 'total_sheet_output_qty') @Default(0) double totalSheetOutputQty,
    @JsonKey(name: 'r_return_qty') @Default(0) double rReturnQty,
    @JsonKey(name: 'c_return_qty') @Default(0) double cReturnQty,
    @JsonKey(name: 'input_stock_entry') String? inputStockEntry,
    @JsonKey(name: 'output_stock_entry') String? outputStockEntry,
    @JsonKey(name: 'return_stock_entry') String? returnStockEntry,
    @Default([]) List<CalenderingSheet> sheets,
  }) = _CalenderingRun;

  factory CalenderingRun.fromJson(Map<String, dynamic> json) =>
      _$CalenderingRunFromJson(json);
}

@freezed
class CalenderingStartResult with _$CalenderingStartResult {
  const factory CalenderingStartResult({
    required String name,
    @JsonKey(name: 'fmb_batch') required String fmbBatch,
    @JsonKey(name: 'fmb_item') String? fmbItem,
    @JsonKey(name: 'input_qty') @Default(0) double inputQty,
    @Default('In Progress') String status,
    @JsonKey(name: 'input_stock_entry') String? inputStockEntry,
  }) = _CalenderingStartResult;

  factory CalenderingStartResult.fromJson(Map<String, dynamic> json) =>
      _$CalenderingStartResultFromJson(json);
}

@freezed
class CalenderingCompleteResult with _$CalenderingCompleteResult {
  const factory CalenderingCompleteResult({
    required String name,
    @Default('Completed') String status,
    @JsonKey(name: 'output_stock_entry') String? outputStockEntry,
    @JsonKey(name: 'return_stock_entry') String? returnStockEntry,
    @JsonKey(name: 'sheet_count') @Default(0) int sheetCount,
    @JsonKey(name: 'total_sheet_qty') @Default(0) double totalSheetQty,
    @JsonKey(name: 'r_return_qty') @Default(0) double rReturnQty,
    @JsonKey(name: 'c_return_qty') @Default(0) double cReturnQty,
  }) = _CalenderingCompleteResult;

  factory CalenderingCompleteResult.fromJson(Map<String, dynamic> json) =>
      _$CalenderingCompleteResultFromJson(json);
}
