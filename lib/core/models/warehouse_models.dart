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
  }) = _ReceivedItemLine;

  factory ReceivedItemLine.fromJson(Map<String, dynamic> json) =>
      _$ReceivedItemLineFromJson(json);
}

@freezed
class LotSuggestion with _$LotSuggestion {
  const factory LotSuggestion({
    required String lot,
    @JsonKey(name: 'available_qty') required double availableQty,
  }) = _LotSuggestion;

  factory LotSuggestion.fromJson(Map<String, dynamic> json) =>
      _$LotSuggestionFromJson(json);
}

@freezed
class LotStockLine with _$LotStockLine {
  const factory LotStockLine({
    @JsonKey(name: 'item_code') required String itemCode,
    @JsonKey(name: 'batch_no') String? batchNo,
    @JsonKey(name: 'fifo_date') String? fifoDate,
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
    required double qty,
    @JsonKey(name: 'suggested_lot') String? suggestedLot,
    required String status,
  }) = _PickItem;

  factory PickItem.fromJson(Map<String, dynamic> json) =>
      _$PickItemFromJson(json);
}
