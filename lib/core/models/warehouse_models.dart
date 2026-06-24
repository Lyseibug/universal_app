import 'package:freezed_annotation/freezed_annotation.dart';

part 'warehouse_models.freezed.dart';
part 'warehouse_models.g.dart';

@freezed
class ReceivedItemLine with _$ReceivedItemLine {
  const factory ReceivedItemLine({
    required String name,
    required String parent,
    @JsonKey(name: 'item_code') required String itemCode,
    @JsonKey(name: 'item_name') String? itemName,
    @JsonKey(name: 'pending_qty') required double pendingQty,
    String? uom,
    String? warehouse,
    @JsonKey(name: 'lot_no') String? lotNo,
    @JsonKey(name: 'production_date') String? productionDate,
    @JsonKey(name: 'expiry_date') String? expiryDate,
    @JsonKey(name: 'batch_no') String? batchNo,
    @JsonKey(name: 'received_qty') double? receivedQty,
    @JsonKey(name: 'batch_qty_created') double? batchQtyCreated,
    @JsonKey(name: 'pending_batch_qty') double? pendingBatchQty,
    @JsonKey(name: 'bin_allocated_quantity') double? binAllocatedQuantity,
    @JsonKey(name: 'receipt_date') String? receiptDate,
    @JsonKey(name: 'upc_code') String? upcCode,
  }) = _ReceivedItemLine;

  factory ReceivedItemLine.fromJson(Map<String, dynamic> json) =>
      _$ReceivedItemLineFromJson(json);
}

@freezed
class GrnBatch with _$GrnBatch {
  const factory GrnBatch({
    @JsonKey(name: 'batch_no') required String batchNo,
    @JsonKey(name: 'production_date') String? productionDate,
    @JsonKey(name: 'expiry_date') String? expiryDate,
    @JsonKey(name: 'available_qty') required double availableQty,
  }) = _GrnBatch;

  factory GrnBatch.fromJson(Map<String, dynamic> json) =>
      _$GrnBatchFromJson(json);
}

@freezed
class LotSuggestion with _$LotSuggestion {
  const factory LotSuggestion({
    required String lot,
    @Default(0) @JsonKey(name: 'available_qty') double availableQty,
    String? reason,
    String? warehouse,
    String? zone,
    String? aisle,
    String? level,
  }) = _LotSuggestion;

  factory LotSuggestion.fromJson(Map<String, dynamic> json) =>
      _$LotSuggestionFromJson(json);
}

@freezed
class LotStockLine with _$LotStockLine {
  const factory LotStockLine({
    @JsonKey(name: 'item_code') required String itemCode,
    @JsonKey(name: 'item_name') String? itemName,
    @JsonKey(name: 'upc_code') String? upcCode,
    @JsonKey(name: 'batch_no') String? batchNo,
    @JsonKey(name: 'fifo_date') String? fifoDate,
    @JsonKey(name: 'production_date') String? productionDate,
    @JsonKey(name: 'expiry_date') String? expiryDate,
    required double qty,
    String? uom,
  }) = _LotStockLine;

  factory LotStockLine.fromJson(Map<String, dynamic> json) =>
      _$LotStockLineFromJson(json);
}

@freezed
class WarehouseLot with _$WarehouseLot {
  const factory WarehouseLot({
    required String name,
    String? warehouse,
    String? zone,
    @JsonKey(name: 'is_empty') @Default(1) int isEmptyFlag,
    @Default([]) List<LotStockLine> items,
  }) = _WarehouseLot;

  factory WarehouseLot.fromJson(Map<String, dynamic> json) =>
      _$WarehouseLotFromJson(json);
}

@freezed
class PickItem with _$PickItem {
  const factory PickItem({
    required String name,
    @JsonKey(name: 'item_code') required String itemCode,
    @JsonKey(name: 'item_name') String? itemName,
    String? warehouse,
    @JsonKey(name: 'required_qty') @Default(0) double requiredQty,
    @JsonKey(name: 'picked_qty') @Default(0) double pickedQty,
    @JsonKey(name: 'suggested_lot') String? suggestedLot,
    required String status,
  }) = _PickItem;

  factory PickItem.fromJson(Map<String, dynamic> json) =>
      _$PickItemFromJson(json);
}
