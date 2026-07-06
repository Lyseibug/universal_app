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
    @JsonKey(name: 'compound_type') @Default('FMB') String compoundType,
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

// ── Calendering Models (plain Dart — no code generation needed) ─────────

class CalenderingFmb {
  final String batchNo;
  final String itemCode;
  final String? itemName;
  final double qty;
  final String labStatus;
  final String? manufacturingDate;

  const CalenderingFmb({
    required this.batchNo,
    required this.itemCode,
    this.itemName,
    this.qty = 0,
    this.labStatus = 'Pass',
    this.manufacturingDate,
  });

  factory CalenderingFmb.fromJson(Map<String, dynamic> json) => CalenderingFmb(
        batchNo: json['batch_no']?.toString() ?? '',
        itemCode: json['item_code']?.toString() ?? '',
        itemName: json['item_name']?.toString(),
        qty: (json['qty'] as num?)?.toDouble() ?? 0,
        labStatus: json['lab_status']?.toString() ?? 'Pass',
        manufacturingDate: json['manufacturing_date']?.toString(),
      );
}

class RollStock {
  final String itemCode;
  final String? itemName;
  final String rollType; // 'Liner' | 'Cylinder'
  final double availableQty;
  final double inUseQty;

  const RollStock({
    required this.itemCode,
    this.itemName,
    this.rollType = 'Liner',
    this.availableQty = 0,
    this.inUseQty = 0,
  });

  factory RollStock.fromJson(Map<String, dynamic> json) => RollStock(
        itemCode: json['item_code']?.toString() ?? '',
        itemName: json['item_name']?.toString(),
        rollType: json['roll_type']?.toString() ?? 'Liner',
        availableQty: (json['available_qty'] as num?)?.toDouble() ?? 0,
        inUseQty: (json['in_use_qty'] as num?)?.toDouble() ?? 0,
      );
}

class CalenderingSheet {
  final String itemCode;
  final double qty;
  final double thicknessMm;
  final double widthInMm;
  final double lengthInMm;
  final String? batchNo;

  const CalenderingSheet({
    required this.itemCode,
    this.qty = 0,
    this.thicknessMm = 0,
    this.widthInMm = 0,
    this.lengthInMm = 0,
    this.batchNo,
  });

  factory CalenderingSheet.fromJson(Map<String, dynamic> json) =>
      CalenderingSheet(
        itemCode: json['item_code']?.toString() ?? '',
        qty: (json['qty'] as num?)?.toDouble() ?? 0,
        thicknessMm: (json['thickness_mm'] as num?)?.toDouble() ?? 0,
        widthInMm: (json['width_in_mm'] as num?)?.toDouble() ?? 0,
        lengthInMm: (json['length_in_mm'] as num?)?.toDouble() ?? 0,
        batchNo: json['batch_no']?.toString(),
      );
}

class CalenderingRun {
  final String name;
  final String fmbBatch;
  final String? fmbItem;
  final String? itemName;
  final String status;
  final String? operator;
  final String? startTime;
  final String? endTime;
  final double fmbInputQty;
  final double totalSheetOutputQty;
  final double linerReturnQty;
  final String? linerReturnBatch;
  final double calendarReturnQty;
  final String? calendarReturnBatch;
  final double excruderSludgeQty;
  final String? inputStockEntry;
  final String? outputStockEntry;
  final String? returnStockEntry;
  final List<CalenderingSheet> sheets;

  const CalenderingRun({
    required this.name,
    required this.fmbBatch,
    this.fmbItem,
    this.itemName,
    this.status = 'Draft',
    this.operator,
    this.startTime,
    this.endTime,
    this.fmbInputQty = 0,
    this.totalSheetOutputQty = 0,
    this.linerReturnQty = 0,
    this.linerReturnBatch,
    this.calendarReturnQty = 0,
    this.calendarReturnBatch,
    this.excruderSludgeQty = 0,
    this.inputStockEntry,
    this.outputStockEntry,
    this.returnStockEntry,
    this.sheets = const [],
  });

  factory CalenderingRun.fromJson(Map<String, dynamic> json) => CalenderingRun(
        name: json['name']?.toString() ?? '',
        fmbBatch: json['fmb_batch']?.toString() ?? '',
        fmbItem: json['fmb_item']?.toString(),
        itemName: json['item_name']?.toString(),
        status: json['status']?.toString() ?? 'Draft',
        operator: json['operator']?.toString(),
        startTime: json['start_time']?.toString(),
        endTime: json['end_time']?.toString(),
        fmbInputQty: (json['fmb_input_qty'] as num?)?.toDouble() ?? 0,
        totalSheetOutputQty:
            (json['total_sheet_output_qty'] as num?)?.toDouble() ?? 0,
        linerReturnQty: (json['liner_return_qty'] as num?)?.toDouble() ?? 0,
        linerReturnBatch: json['liner_return_batch']?.toString(),
        calendarReturnQty:
            (json['calendar_return_qty'] as num?)?.toDouble() ?? 0,
        calendarReturnBatch: json['calendar_return_batch']?.toString(),
        excruderSludgeQty:
            (json['excruder_sludge_qty'] as num?)?.toDouble() ?? 0,
        inputStockEntry: json['input_stock_entry']?.toString(),
        outputStockEntry: json['output_stock_entry']?.toString(),
        returnStockEntry: json['return_stock_entry']?.toString(),
        sheets: (json['sheets'] as List?)
                ?.map((e) =>
                    CalenderingSheet.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            const [],
      );
}

class CalenderingStartResult {
  final String name;
  final String fmbBatch;
  final String? fmbItem;
  final double inputQty;
  final String status;
  final String? inputStockEntry;

  const CalenderingStartResult({
    required this.name,
    required this.fmbBatch,
    this.fmbItem,
    this.inputQty = 0,
    this.status = 'In Progress',
    this.inputStockEntry,
  });

  factory CalenderingStartResult.fromJson(Map<String, dynamic> json) =>
      CalenderingStartResult(
        name: json['name']?.toString() ?? '',
        fmbBatch: json['fmb_batch']?.toString() ?? '',
        fmbItem: json['fmb_item']?.toString(),
        inputQty: (json['input_qty'] as num?)?.toDouble() ?? 0,
        status: json['status']?.toString() ?? 'In Progress',
        inputStockEntry: json['input_stock_entry']?.toString(),
      );
}

class CalenderingCompleteResult {
  final String name;
  final String status;
  final String? outputStockEntry;
  final String? returnStockEntry;
  final int sheetCount;
  final double totalSheetQty;
  final double linerReturnQty;
  final String? linerReturnBatch;
  final double calendarReturnQty;
  final String? calendarReturnBatch;
  final double excruderSludgeQty;

  const CalenderingCompleteResult({
    required this.name,
    this.status = 'Completed',
    this.outputStockEntry,
    this.returnStockEntry,
    this.sheetCount = 0,
    this.totalSheetQty = 0,
    this.linerReturnQty = 0,
    this.linerReturnBatch,
    this.calendarReturnQty = 0,
    this.calendarReturnBatch,
    this.excruderSludgeQty = 0,
  });

  factory CalenderingCompleteResult.fromJson(Map<String, dynamic> json) =>
      CalenderingCompleteResult(
        name: json['name']?.toString() ?? '',
        status: json['status']?.toString() ?? 'Completed',
        outputStockEntry: json['output_stock_entry']?.toString(),
        returnStockEntry: json['return_stock_entry']?.toString(),
        sheetCount: (json['sheet_count'] as num?)?.toInt() ?? 0,
        totalSheetQty: (json['total_sheet_qty'] as num?)?.toDouble() ?? 0,
        linerReturnQty: (json['liner_return_qty'] as num?)?.toDouble() ?? 0,
        linerReturnBatch: json['liner_return_batch']?.toString(),
        calendarReturnQty:
            (json['calendar_return_qty'] as num?)?.toDouble() ?? 0,
        calendarReturnBatch: json['calendar_return_batch']?.toString(),
        excruderSludgeQty:
            (json['excruder_sludge_qty'] as num?)?.toDouble() ?? 0,
      );
}
