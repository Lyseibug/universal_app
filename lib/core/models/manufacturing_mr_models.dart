import 'package:freezed_annotation/freezed_annotation.dart';

part 'manufacturing_mr_models.freezed.dart';
part 'manufacturing_mr_models.g.dart';

@freezed
class ManufacturingMR with _$ManufacturingMR {
  const factory ManufacturingMR({
    required String name,
    @JsonKey(name: 'request_type') String? requestType,
    @JsonKey(name: 'compound_type') String? compoundType,
    @JsonKey(name: 'formula_code') String? formulaCode,
    required String status,
    @JsonKey(name: 'pick_list') String? pickList,
    String? remarks,
    String? creation,
    @JsonKey(name: 'created_by_user') String? createdByUser,
    @JsonKey(name: 'item_count') @Default(0) int itemCount,
    @JsonKey(name: 'picked_count') @Default(0) int pickedCount,
    @JsonKey(name: 'total_required') @Default(0) double totalRequired,
    @JsonKey(name: 'total_picked') @Default(0) double totalPicked,
  }) = _ManufacturingMR;

  factory ManufacturingMR.fromJson(Map<String, dynamic> json) =>
      _$ManufacturingMRFromJson(json);
}

@freezed
class ManufacturingMRDetail with _$ManufacturingMRDetail {
  const factory ManufacturingMRDetail({
    required String name,
    @JsonKey(name: 'request_type') String? requestType,
    @JsonKey(name: 'compound_type') String? compoundType,
    @JsonKey(name: 'formula_code') String? formulaCode,
    required String status,
    @JsonKey(name: 'pick_list') String? pickList,
    String? remarks,
    String? creation,
    @JsonKey(name: 'created_by_user') String? createdByUser,
    @Default([]) List<ManufacturingMRItem> items,
  }) = _ManufacturingMRDetail;

  factory ManufacturingMRDetail.fromJson(Map<String, dynamic> json) =>
      _$ManufacturingMRDetailFromJson(json);
}

@freezed
class ManufacturingMRItem with _$ManufacturingMRItem {
  const factory ManufacturingMRItem({
    required String name,
    @JsonKey(name: 'item_code') required String itemCode,
    @JsonKey(name: 'item_name') String? itemName,
    @JsonKey(name: 'required_qty') required double requiredQty,
    @JsonKey(name: 'picked_qty') @Default(0) double pickedQty,
    @JsonKey(name: 'loaded_qty') @Default(0) double loadedQty,
    @JsonKey(name: 'target_stream') required String targetStream,
    @JsonKey(name: 'target_warehouse') String? targetWarehouse,
    String? uom,
    @JsonKey(name: 'is_completed') @Default(false) bool isCompleted,
  }) = _ManufacturingMRItem;

  factory ManufacturingMRItem.fromJson(Map<String, dynamic> json) =>
      _$ManufacturingMRItemFromJson(json);
}
