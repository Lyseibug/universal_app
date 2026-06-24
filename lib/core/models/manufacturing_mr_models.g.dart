// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'manufacturing_mr_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ManufacturingMRImpl _$$ManufacturingMRImplFromJson(
        Map<String, dynamic> json) =>
    _$ManufacturingMRImpl(
      name: json['name'] as String,
      requestType: json['request_type'] as String?,
      compoundType: json['compound_type'] as String?,
      formulaCode: json['formula_code'] as String?,
      status: json['status'] as String,
      pickList: json['pick_list'] as String?,
      remarks: json['remarks'] as String?,
      creation: json['creation'] as String?,
      createdByUser: json['created_by_user'] as String?,
      itemCount: (json['item_count'] as num?)?.toInt() ?? 0,
      pickedCount: (json['picked_count'] as num?)?.toInt() ?? 0,
      totalRequired: (json['total_required'] as num?)?.toDouble() ?? 0,
      totalPicked: (json['total_picked'] as num?)?.toDouble() ?? 0,
    );

Map<String, dynamic> _$$ManufacturingMRImplToJson(
        _$ManufacturingMRImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'request_type': instance.requestType,
      'compound_type': instance.compoundType,
      'formula_code': instance.formulaCode,
      'status': instance.status,
      'pick_list': instance.pickList,
      'remarks': instance.remarks,
      'creation': instance.creation,
      'created_by_user': instance.createdByUser,
      'item_count': instance.itemCount,
      'picked_count': instance.pickedCount,
      'total_required': instance.totalRequired,
      'total_picked': instance.totalPicked,
    };

_$ManufacturingMRDetailImpl _$$ManufacturingMRDetailImplFromJson(
        Map<String, dynamic> json) =>
    _$ManufacturingMRDetailImpl(
      name: json['name'] as String,
      requestType: json['request_type'] as String?,
      compoundType: json['compound_type'] as String?,
      formulaCode: json['formula_code'] as String?,
      status: json['status'] as String,
      pickList: json['pick_list'] as String?,
      materialRequest: json['material_request'] as String?,
      bom: json['bom'] as String?,
      requestedCompoundQty:
          (json['requested_compound_qty'] as num?)?.toDouble() ?? 0,
      docstatus: (json['docstatus'] as num?)?.toInt() ?? 0,
      remarks: json['remarks'] as String?,
      creation: json['creation'] as String?,
      createdByUser: json['created_by_user'] as String?,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) =>
                  ManufacturingMRItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$ManufacturingMRDetailImplToJson(
        _$ManufacturingMRDetailImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'request_type': instance.requestType,
      'compound_type': instance.compoundType,
      'formula_code': instance.formulaCode,
      'status': instance.status,
      'pick_list': instance.pickList,
      'material_request': instance.materialRequest,
      'bom': instance.bom,
      'requested_compound_qty': instance.requestedCompoundQty,
      'docstatus': instance.docstatus,
      'remarks': instance.remarks,
      'creation': instance.creation,
      'created_by_user': instance.createdByUser,
      'items': instance.items,
    };

_$ManufacturingMRItemImpl _$$ManufacturingMRItemImplFromJson(
        Map<String, dynamic> json) =>
    _$ManufacturingMRItemImpl(
      name: json['name'] as String,
      itemCode: json['item_code'] as String,
      itemName: json['item_name'] as String?,
      requiredQty: (json['required_qty'] as num).toDouble(),
      pickedQty: (json['picked_qty'] as num?)?.toDouble() ?? 0,
      loadedQty: (json['loaded_qty'] as num?)?.toDouble() ?? 0,
      targetStream: json['target_stream'] as String,
      targetWarehouse: json['target_warehouse'] as String?,
      uom: json['uom'] as String?,
      isCompleted: json['is_completed'] as bool? ?? false,
    );

Map<String, dynamic> _$$ManufacturingMRItemImplToJson(
        _$ManufacturingMRItemImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'item_code': instance.itemCode,
      'item_name': instance.itemName,
      'required_qty': instance.requiredQty,
      'picked_qty': instance.pickedQty,
      'loaded_qty': instance.loadedQty,
      'target_stream': instance.targetStream,
      'target_warehouse': instance.targetWarehouse,
      'uom': instance.uom,
      'is_completed': instance.isCompleted,
    };
