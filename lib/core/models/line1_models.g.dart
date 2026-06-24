// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'line1_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$StockItemImpl _$$StockItemImplFromJson(Map<String, dynamic> json) =>
    _$StockItemImpl(
      itemCode: json['item_code'] as String,
      itemName: json['item_name'] as String?,
      batchNo: json['batch_no'] as String?,
      qty: (json['qty'] as num?)?.toDouble() ?? 0,
      productionDate: json['production_date'] as String?,
      stream: json['stream'] as String?,
    );

Map<String, dynamic> _$$StockItemImplToJson(_$StockItemImpl instance) =>
    <String, dynamic>{
      'item_code': instance.itemCode,
      'item_name': instance.itemName,
      'batch_no': instance.batchNo,
      'qty': instance.qty,
      'production_date': instance.productionDate,
      'stream': instance.stream,
    };

_$LoadResultImpl _$$LoadResultImplFromJson(Map<String, dynamic> json) =>
    _$LoadResultImpl(
      stockEntry: json['stock_entry'] as String?,
      qty: (json['qty'] as num?)?.toDouble() ?? 0,
      batchNo: json['batch_no'] as String?,
      boxBarcode: json['box_barcode'] as String?,
      stream: json['stream'] as String?,
    );

Map<String, dynamic> _$$LoadResultImplToJson(_$LoadResultImpl instance) =>
    <String, dynamic>{
      'stock_entry': instance.stockEntry,
      'qty': instance.qty,
      'batch_no': instance.batchNo,
      'box_barcode': instance.boxBarcode,
      'stream': instance.stream,
    };

_$BagItemImpl _$$BagItemImplFromJson(Map<String, dynamic> json) =>
    _$BagItemImpl(
      batchNo: json['batch_no'] as String,
      itemCode: json['item_code'] as String,
      itemName: json['item_name'] as String?,
      qty: (json['qty'] as num?)?.toDouble() ?? 0,
      formulaName: json['formula_name'] as String?,
      productionDatetime: json['production_datetime'] as String?,
      machineProductionRecord: json['machine_production_record'] as String?,
    );

Map<String, dynamic> _$$BagItemImplToJson(_$BagItemImpl instance) =>
    <String, dynamic>{
      'batch_no': instance.batchNo,
      'item_code': instance.itemCode,
      'item_name': instance.itemName,
      'qty': instance.qty,
      'formula_name': instance.formulaName,
      'production_datetime': instance.productionDatetime,
      'machine_production_record': instance.machineProductionRecord,
    };

_$BagDetailImpl _$$BagDetailImplFromJson(Map<String, dynamic> json) =>
    _$BagDetailImpl(
      batchNo: json['batch_no'] as String,
      itemCode: json['item_code'] as String,
      itemName: json['item_name'] as String?,
      qty: (json['qty'] as num?)?.toDouble() ?? 0,
      formulaName: json['formula_name'] as String?,
      manufacturingDate: json['manufacturing_date'] as String?,
      machineProductionRecord: json['machine_production_record'] as String?,
      consumeItems: (json['consume_items'] as List<dynamic>?)
              ?.map((e) => ConsumeItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$BagDetailImplToJson(_$BagDetailImpl instance) =>
    <String, dynamic>{
      'batch_no': instance.batchNo,
      'item_code': instance.itemCode,
      'item_name': instance.itemName,
      'qty': instance.qty,
      'formula_name': instance.formulaName,
      'manufacturing_date': instance.manufacturingDate,
      'machine_production_record': instance.machineProductionRecord,
      'consume_items': instance.consumeItems,
    };

_$ConsumeItemImpl _$$ConsumeItemImplFromJson(Map<String, dynamic> json) =>
    _$ConsumeItemImpl(
      itemCode: json['item_code'] as String,
      itemName: json['item_name'] as String?,
      batchNo: json['batch_no'] as String?,
      qty: (json['qty'] as num?)?.toDouble() ?? 0,
      warehouse: json['warehouse'] as String?,
    );

Map<String, dynamic> _$$ConsumeItemImplToJson(_$ConsumeItemImpl instance) =>
    <String, dynamic>{
      'item_code': instance.itemCode,
      'item_name': instance.itemName,
      'batch_no': instance.batchNo,
      'qty': instance.qty,
      'warehouse': instance.warehouse,
    };

_$FmbBatchImpl _$$FmbBatchImplFromJson(Map<String, dynamic> json) =>
    _$FmbBatchImpl(
      batchNo: json['batch_no'] as String,
      itemCode: json['item_code'] as String,
      itemName: json['item_name'] as String?,
      qty: (json['qty'] as num?)?.toDouble() ?? 0,
      labStatus: json['lab_status'] as String? ?? 'Pending',
      manufacturingDate: json['manufacturing_date'] as String?,
      formulaName: json['formula_name'] as String?,
      formulaCode: json['formula_code'] as String?,
    );

Map<String, dynamic> _$$FmbBatchImplToJson(_$FmbBatchImpl instance) =>
    <String, dynamic>{
      'batch_no': instance.batchNo,
      'item_code': instance.itemCode,
      'item_name': instance.itemName,
      'qty': instance.qty,
      'lab_status': instance.labStatus,
      'manufacturing_date': instance.manufacturingDate,
      'formula_name': instance.formulaName,
      'formula_code': instance.formulaCode,
    };

_$FmbDetailImpl _$$FmbDetailImplFromJson(Map<String, dynamic> json) =>
    _$FmbDetailImpl(
      batchNo: json['batch_no'] as String,
      itemCode: json['item_code'] as String,
      itemName: json['item_name'] as String?,
      qty: (json['qty'] as num?)?.toDouble() ?? 0,
      labStatus: json['lab_status'] as String? ?? 'Pending',
      manufacturingDate: json['manufacturing_date'] as String?,
      formulaName: json['formula_name'] as String?,
      formulaCode: json['formula_code'] as String?,
      labTest: json['lab_test'] == null
          ? null
          : LabTestInfo.fromJson(json['lab_test'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$FmbDetailImplToJson(_$FmbDetailImpl instance) =>
    <String, dynamic>{
      'batch_no': instance.batchNo,
      'item_code': instance.itemCode,
      'item_name': instance.itemName,
      'qty': instance.qty,
      'lab_status': instance.labStatus,
      'manufacturing_date': instance.manufacturingDate,
      'formula_name': instance.formulaName,
      'formula_code': instance.formulaCode,
      'lab_test': instance.labTest,
    };

_$LabTestInfoImpl _$$LabTestInfoImplFromJson(Map<String, dynamic> json) =>
    _$LabTestInfoImpl(
      name: json['name'] as String,
      result: json['result'] as String? ?? 'Pending',
      testedBy: json['tested_by'] as String?,
      testedOn: json['tested_on'] as String?,
      docstatus: (json['docstatus'] as num?)?.toInt() ?? 0,
      parameters: (json['parameters'] as List<dynamic>?)
              ?.map((e) => LabTestParameter.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$LabTestInfoImplToJson(_$LabTestInfoImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'result': instance.result,
      'tested_by': instance.testedBy,
      'tested_on': instance.testedOn,
      'docstatus': instance.docstatus,
      'parameters': instance.parameters,
    };

_$LabTestParameterImpl _$$LabTestParameterImplFromJson(
        Map<String, dynamic> json) =>
    _$LabTestParameterImpl(
      parameterName: json['parameter_name'] as String,
      expectedMin: (json['expected_min'] as num?)?.toDouble() ?? 0,
      expectedMax: (json['expected_max'] as num?)?.toDouble() ?? 0,
      resultValue: (json['result_value'] as num?)?.toDouble() ?? 0,
      isPass: json['is_pass'] == null ? false : _intToBool(json['is_pass']),
    );

Map<String, dynamic> _$$LabTestParameterImplToJson(
        _$LabTestParameterImpl instance) =>
    <String, dynamic>{
      'parameter_name': instance.parameterName,
      'expected_min': instance.expectedMin,
      'expected_max': instance.expectedMax,
      'result_value': instance.resultValue,
      'is_pass': instance.isPass,
    };

_$LabTestResultImpl _$$LabTestResultImplFromJson(Map<String, dynamic> json) =>
    _$LabTestResultImpl(
      labTest: json['lab_test'] as String,
      result: json['result'] as String,
      fmbBatch: json['fmb_batch'] as String,
      parameters: (json['parameters'] as List<dynamic>?)
              ?.map((e) =>
                  LabTestParameterResult.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$LabTestResultImplToJson(_$LabTestResultImpl instance) =>
    <String, dynamic>{
      'lab_test': instance.labTest,
      'result': instance.result,
      'fmb_batch': instance.fmbBatch,
      'parameters': instance.parameters,
    };

_$LabTestParameterResultImpl _$$LabTestParameterResultImplFromJson(
        Map<String, dynamic> json) =>
    _$LabTestParameterResultImpl(
      parameterName: json['parameter_name'] as String,
      resultValue: (json['result_value'] as num?)?.toDouble() ?? 0,
      isPass: json['is_pass'] == null ? false : _intToBool(json['is_pass']),
    );

Map<String, dynamic> _$$LabTestParameterResultImplToJson(
        _$LabTestParameterResultImpl instance) =>
    <String, dynamic>{
      'parameter_name': instance.parameterName,
      'result_value': instance.resultValue,
      'is_pass': instance.isPass,
    };
