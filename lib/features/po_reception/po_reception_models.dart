import 'package:freezed_annotation/freezed_annotation.dart';

part 'po_reception_models.freezed.dart';
part 'po_reception_models.g.dart';

@freezed
class PurchaseOrderSummary with _$PurchaseOrderSummary {
  const factory PurchaseOrderSummary({
    required String name,
    String? supplier,
    @JsonKey(name: 'supplier_name') String? supplierName,
    @JsonKey(name: 'transaction_date') String? transactionDate,
    @JsonKey(name: 'grand_total') @Default(0) double grandTotal,
    String? currency,
    @JsonKey(name: 'item_count') @Default(0) int itemCount,
  }) = _PurchaseOrderSummary;

  factory PurchaseOrderSummary.fromJson(Map<String, dynamic> json) =>
      _$PurchaseOrderSummaryFromJson(json);
}

@freezed
class PurchaseOrderDetail with _$PurchaseOrderDetail {
  const factory PurchaseOrderDetail({
    required String name,
    String? supplier,
    @JsonKey(name: 'supplier_name') String? supplierName,
    @JsonKey(name: 'transaction_date') String? transactionDate,
    @JsonKey(name: 'grand_total') @Default(0) double grandTotal,
    String? currency,
    @JsonKey(name: 'inbound_warehouse') String? inboundWarehouse,
    @Default([]) List<PurchaseOrderItemLine> items,
  }) = _PurchaseOrderDetail;

  factory PurchaseOrderDetail.fromJson(Map<String, dynamic> json) =>
      _$PurchaseOrderDetailFromJson(json);
}

@freezed
class PurchaseOrderItemLine with _$PurchaseOrderItemLine {
  const factory PurchaseOrderItemLine({
    required String name,
    @JsonKey(name: 'item_code') required String itemCode,
    @JsonKey(name: 'item_name') String? itemName,
    String? uom,
    @JsonKey(name: 'stock_uom') String? stockUom,
    @JsonKey(name: 'available_uoms') @Default([]) List<dynamic> availableUoms,
    @JsonKey(name: 'upc_code') String? upcCode,
    @JsonKey(name: 'ordered_qty') @Default(0) double orderedQty,
    @JsonKey(name: 'received_qty') @Default(0) double receivedQty,
    @JsonKey(name: 'pending_qty') @Default(0) double pendingQty,
    @Default(0) double rate,
    String? warehouse,
  }) = _PurchaseOrderItemLine;

  factory PurchaseOrderItemLine.fromJson(Map<String, dynamic> json) =>
      _$PurchaseOrderItemLineFromJson(json);
}
