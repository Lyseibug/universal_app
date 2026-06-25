// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'po_reception_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PurchaseOrderSummaryImpl _$$PurchaseOrderSummaryImplFromJson(
        Map<String, dynamic> json) =>
    _$PurchaseOrderSummaryImpl(
      name: json['name'] as String,
      supplier: json['supplier'] as String?,
      supplierName: json['supplier_name'] as String?,
      transactionDate: json['transaction_date'] as String?,
      grandTotal: (json['grand_total'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String?,
      itemCount: (json['item_count'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$PurchaseOrderSummaryImplToJson(
        _$PurchaseOrderSummaryImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'supplier': instance.supplier,
      'supplier_name': instance.supplierName,
      'transaction_date': instance.transactionDate,
      'grand_total': instance.grandTotal,
      'currency': instance.currency,
      'item_count': instance.itemCount,
    };

_$PurchaseOrderDetailImpl _$$PurchaseOrderDetailImplFromJson(
        Map<String, dynamic> json) =>
    _$PurchaseOrderDetailImpl(
      name: json['name'] as String,
      supplier: json['supplier'] as String?,
      supplierName: json['supplier_name'] as String?,
      transactionDate: json['transaction_date'] as String?,
      grandTotal: (json['grand_total'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String?,
      inboundWarehouse: json['inbound_warehouse'] as String?,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) =>
                  PurchaseOrderItemLine.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$PurchaseOrderDetailImplToJson(
        _$PurchaseOrderDetailImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'supplier': instance.supplier,
      'supplier_name': instance.supplierName,
      'transaction_date': instance.transactionDate,
      'grand_total': instance.grandTotal,
      'currency': instance.currency,
      'inbound_warehouse': instance.inboundWarehouse,
      'items': instance.items,
    };

_$PurchaseOrderItemLineImpl _$$PurchaseOrderItemLineImplFromJson(
        Map<String, dynamic> json) =>
    _$PurchaseOrderItemLineImpl(
      name: json['name'] as String,
      itemCode: json['item_code'] as String,
      itemName: json['item_name'] as String?,
      uom: json['uom'] as String?,
      upcCode: json['upc_code'] as String?,
      orderedQty: (json['ordered_qty'] as num?)?.toDouble() ?? 0,
      receivedQty: (json['received_qty'] as num?)?.toDouble() ?? 0,
      pendingQty: (json['pending_qty'] as num?)?.toDouble() ?? 0,
      rate: (json['rate'] as num?)?.toDouble() ?? 0,
      warehouse: json['warehouse'] as String?,
    );

Map<String, dynamic> _$$PurchaseOrderItemLineImplToJson(
        _$PurchaseOrderItemLineImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'item_code': instance.itemCode,
      'item_name': instance.itemName,
      'uom': instance.uom,
      'upc_code': instance.upcCode,
      'ordered_qty': instance.orderedQty,
      'received_qty': instance.receivedQty,
      'pending_qty': instance.pendingQty,
      'rate': instance.rate,
      'warehouse': instance.warehouse,
    };
