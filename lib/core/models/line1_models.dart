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
