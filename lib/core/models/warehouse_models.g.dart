// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'warehouse_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ReceivedItemLineImpl _$$ReceivedItemLineImplFromJson(
        Map<String, dynamic> json) =>
    _$ReceivedItemLineImpl(
      name: json['name'] as String,
      parent: json['parent'] as String,
      itemCode: json['item_code'] as String,
      itemName: json['item_name'] as String?,
      pendingQty: (json['pending_qty'] as num).toDouble(),
      uom: json['uom'] as String?,
      warehouse: json['warehouse'] as String?,
      lotNo: json['lot_no'] as String?,
      productionDate: json['production_date'] as String?,
      expiryDate: json['expiry_date'] as String?,
      batchNo: json['batch_no'] as String?,
      receivedQty: (json['received_qty'] as num?)?.toDouble(),
      batchQtyCreated: (json['batch_qty_created'] as num?)?.toDouble(),
      pendingBatchQty: (json['pending_batch_qty'] as num?)?.toDouble(),
      binAllocatedQuantity:
          (json['bin_allocated_quantity'] as num?)?.toDouble(),
      receiptDate: json['receipt_date'] as String?,
      upcCode: json['upc_code'] as String?,
    );

Map<String, dynamic> _$$ReceivedItemLineImplToJson(
        _$ReceivedItemLineImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'parent': instance.parent,
      'item_code': instance.itemCode,
      'item_name': instance.itemName,
      'pending_qty': instance.pendingQty,
      'uom': instance.uom,
      'warehouse': instance.warehouse,
      'lot_no': instance.lotNo,
      'production_date': instance.productionDate,
      'expiry_date': instance.expiryDate,
      'batch_no': instance.batchNo,
      'received_qty': instance.receivedQty,
      'batch_qty_created': instance.batchQtyCreated,
      'pending_batch_qty': instance.pendingBatchQty,
      'bin_allocated_quantity': instance.binAllocatedQuantity,
      'receipt_date': instance.receiptDate,
      'upc_code': instance.upcCode,
    };

_$GrnBatchImpl _$$GrnBatchImplFromJson(Map<String, dynamic> json) =>
    _$GrnBatchImpl(
      batchNo: json['batch_no'] as String,
      productionDate: json['production_date'] as String?,
      expiryDate: json['expiry_date'] as String?,
      availableQty: (json['available_qty'] as num).toDouble(),
    );

Map<String, dynamic> _$$GrnBatchImplToJson(_$GrnBatchImpl instance) =>
    <String, dynamic>{
      'batch_no': instance.batchNo,
      'production_date': instance.productionDate,
      'expiry_date': instance.expiryDate,
      'available_qty': instance.availableQty,
    };

_$LotSuggestionImpl _$$LotSuggestionImplFromJson(Map<String, dynamic> json) =>
    _$LotSuggestionImpl(
      lot: json['lot'] as String,
      availableQty: (json['available_qty'] as num?)?.toDouble() ?? 0,
      reason: json['reason'] as String?,
      warehouse: json['warehouse'] as String?,
      zone: json['zone'] as String?,
      aisle: json['aisle'] as String?,
      level: json['level'] as String?,
    );

Map<String, dynamic> _$$LotSuggestionImplToJson(_$LotSuggestionImpl instance) =>
    <String, dynamic>{
      'lot': instance.lot,
      'available_qty': instance.availableQty,
      'reason': instance.reason,
      'warehouse': instance.warehouse,
      'zone': instance.zone,
      'aisle': instance.aisle,
      'level': instance.level,
    };

_$LotStockLineImpl _$$LotStockLineImplFromJson(Map<String, dynamic> json) =>
    _$LotStockLineImpl(
      itemCode: json['item_code'] as String,
      itemName: json['item_name'] as String?,
      upcCode: json['upc_code'] as String?,
      batchNo: json['batch_no'] as String?,
      fifoDate: json['fifo_date'] as String?,
      productionDate: json['production_date'] as String?,
      expiryDate: json['expiry_date'] as String?,
      qty: (json['qty'] as num).toDouble(),
      uom: json['uom'] as String?,
    );

Map<String, dynamic> _$$LotStockLineImplToJson(_$LotStockLineImpl instance) =>
    <String, dynamic>{
      'item_code': instance.itemCode,
      'item_name': instance.itemName,
      'upc_code': instance.upcCode,
      'batch_no': instance.batchNo,
      'fifo_date': instance.fifoDate,
      'production_date': instance.productionDate,
      'expiry_date': instance.expiryDate,
      'qty': instance.qty,
      'uom': instance.uom,
    };

_$WarehouseLotImpl _$$WarehouseLotImplFromJson(Map<String, dynamic> json) =>
    _$WarehouseLotImpl(
      name: json['name'] as String,
      warehouse: json['warehouse'] as String?,
      zone: json['zone'] as String?,
      isEmptyFlag: (json['is_empty'] as num?)?.toInt() ?? 1,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => LotStockLine.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$WarehouseLotImplToJson(_$WarehouseLotImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'warehouse': instance.warehouse,
      'zone': instance.zone,
      'is_empty': instance.isEmptyFlag,
      'items': instance.items,
    };

_$PickItemImpl _$$PickItemImplFromJson(Map<String, dynamic> json) =>
    _$PickItemImpl(
      name: json['name'] as String,
      itemCode: json['item_code'] as String,
      itemName: json['item_name'] as String?,
      warehouse: json['warehouse'] as String?,
      requiredQty: (json['required_qty'] as num?)?.toDouble() ?? 0,
      pickedQty: (json['picked_qty'] as num?)?.toDouble() ?? 0,
      suggestedLot: json['suggested_lot'] as String?,
      status: json['status'] as String,
    );

Map<String, dynamic> _$$PickItemImplToJson(_$PickItemImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'item_code': instance.itemCode,
      'item_name': instance.itemName,
      'warehouse': instance.warehouse,
      'required_qty': instance.requiredQty,
      'picked_qty': instance.pickedQty,
      'suggested_lot': instance.suggestedLot,
      'status': instance.status,
    };
