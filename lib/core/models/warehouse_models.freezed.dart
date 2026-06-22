// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'warehouse_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ReceivedItemLine _$ReceivedItemLineFromJson(Map<String, dynamic> json) {
  return _ReceivedItemLine.fromJson(json);
}

/// @nodoc
mixin _$ReceivedItemLine {
  String get name => throw _privateConstructorUsedError;
  String get parent => throw _privateConstructorUsedError;
  @JsonKey(name: 'item_code')
  String get itemCode => throw _privateConstructorUsedError;
  @JsonKey(name: 'item_name')
  String? get itemName => throw _privateConstructorUsedError;
  @JsonKey(name: 'pending_qty')
  double get pendingQty => throw _privateConstructorUsedError;
  String? get uom => throw _privateConstructorUsedError;
  String? get warehouse => throw _privateConstructorUsedError;
  @JsonKey(name: 'lot_no')
  String? get lotNo => throw _privateConstructorUsedError;
  @JsonKey(name: 'production_date')
  String? get productionDate => throw _privateConstructorUsedError;
  @JsonKey(name: 'expiry_date')
  String? get expiryDate => throw _privateConstructorUsedError;
  @JsonKey(name: 'batch_no')
  String? get batchNo => throw _privateConstructorUsedError;
  @JsonKey(name: 'received_qty')
  double? get receivedQty => throw _privateConstructorUsedError;
  @JsonKey(name: 'batch_qty_created')
  double? get batchQtyCreated => throw _privateConstructorUsedError;
  @JsonKey(name: 'pending_batch_qty')
  double? get pendingBatchQty => throw _privateConstructorUsedError;
  @JsonKey(name: 'bin_allocated_quantity')
  double? get binAllocatedQuantity => throw _privateConstructorUsedError;
  @JsonKey(name: 'receipt_date')
  String? get receiptDate => throw _privateConstructorUsedError;
  @JsonKey(name: 'upc_code')
  String? get upcCode => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ReceivedItemLineCopyWith<ReceivedItemLine> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ReceivedItemLineCopyWith<$Res> {
  factory $ReceivedItemLineCopyWith(
          ReceivedItemLine value, $Res Function(ReceivedItemLine) then) =
      _$ReceivedItemLineCopyWithImpl<$Res, ReceivedItemLine>;
  @useResult
  $Res call(
      {String name,
      String parent,
      @JsonKey(name: 'item_code') String itemCode,
      @JsonKey(name: 'item_name') String? itemName,
      @JsonKey(name: 'pending_qty') double pendingQty,
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
      @JsonKey(name: 'upc_code') String? upcCode});
}

/// @nodoc
class _$ReceivedItemLineCopyWithImpl<$Res, $Val extends ReceivedItemLine>
    implements $ReceivedItemLineCopyWith<$Res> {
  _$ReceivedItemLineCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? parent = null,
    Object? itemCode = null,
    Object? itemName = freezed,
    Object? pendingQty = null,
    Object? uom = freezed,
    Object? warehouse = freezed,
    Object? lotNo = freezed,
    Object? productionDate = freezed,
    Object? expiryDate = freezed,
    Object? batchNo = freezed,
    Object? receivedQty = freezed,
    Object? batchQtyCreated = freezed,
    Object? pendingBatchQty = freezed,
    Object? binAllocatedQuantity = freezed,
    Object? receiptDate = freezed,
    Object? upcCode = freezed,
  }) {
    return _then(_value.copyWith(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      parent: null == parent
          ? _value.parent
          : parent // ignore: cast_nullable_to_non_nullable
              as String,
      itemCode: null == itemCode
          ? _value.itemCode
          : itemCode // ignore: cast_nullable_to_non_nullable
              as String,
      itemName: freezed == itemName
          ? _value.itemName
          : itemName // ignore: cast_nullable_to_non_nullable
              as String?,
      pendingQty: null == pendingQty
          ? _value.pendingQty
          : pendingQty // ignore: cast_nullable_to_non_nullable
              as double,
      uom: freezed == uom
          ? _value.uom
          : uom // ignore: cast_nullable_to_non_nullable
              as String?,
      warehouse: freezed == warehouse
          ? _value.warehouse
          : warehouse // ignore: cast_nullable_to_non_nullable
              as String?,
      lotNo: freezed == lotNo
          ? _value.lotNo
          : lotNo // ignore: cast_nullable_to_non_nullable
              as String?,
      productionDate: freezed == productionDate
          ? _value.productionDate
          : productionDate // ignore: cast_nullable_to_non_nullable
              as String?,
      expiryDate: freezed == expiryDate
          ? _value.expiryDate
          : expiryDate // ignore: cast_nullable_to_non_nullable
              as String?,
      batchNo: freezed == batchNo
          ? _value.batchNo
          : batchNo // ignore: cast_nullable_to_non_nullable
              as String?,
      receivedQty: freezed == receivedQty
          ? _value.receivedQty
          : receivedQty // ignore: cast_nullable_to_non_nullable
              as double?,
      batchQtyCreated: freezed == batchQtyCreated
          ? _value.batchQtyCreated
          : batchQtyCreated // ignore: cast_nullable_to_non_nullable
              as double?,
      pendingBatchQty: freezed == pendingBatchQty
          ? _value.pendingBatchQty
          : pendingBatchQty // ignore: cast_nullable_to_non_nullable
              as double?,
      binAllocatedQuantity: freezed == binAllocatedQuantity
          ? _value.binAllocatedQuantity
          : binAllocatedQuantity // ignore: cast_nullable_to_non_nullable
              as double?,
      receiptDate: freezed == receiptDate
          ? _value.receiptDate
          : receiptDate // ignore: cast_nullable_to_non_nullable
              as String?,
      upcCode: freezed == upcCode
          ? _value.upcCode
          : upcCode // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ReceivedItemLineImplCopyWith<$Res>
    implements $ReceivedItemLineCopyWith<$Res> {
  factory _$$ReceivedItemLineImplCopyWith(_$ReceivedItemLineImpl value,
          $Res Function(_$ReceivedItemLineImpl) then) =
      __$$ReceivedItemLineImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String name,
      String parent,
      @JsonKey(name: 'item_code') String itemCode,
      @JsonKey(name: 'item_name') String? itemName,
      @JsonKey(name: 'pending_qty') double pendingQty,
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
      @JsonKey(name: 'upc_code') String? upcCode});
}

/// @nodoc
class __$$ReceivedItemLineImplCopyWithImpl<$Res>
    extends _$ReceivedItemLineCopyWithImpl<$Res, _$ReceivedItemLineImpl>
    implements _$$ReceivedItemLineImplCopyWith<$Res> {
  __$$ReceivedItemLineImplCopyWithImpl(_$ReceivedItemLineImpl _value,
      $Res Function(_$ReceivedItemLineImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? parent = null,
    Object? itemCode = null,
    Object? itemName = freezed,
    Object? pendingQty = null,
    Object? uom = freezed,
    Object? warehouse = freezed,
    Object? lotNo = freezed,
    Object? productionDate = freezed,
    Object? expiryDate = freezed,
    Object? batchNo = freezed,
    Object? receivedQty = freezed,
    Object? batchQtyCreated = freezed,
    Object? pendingBatchQty = freezed,
    Object? binAllocatedQuantity = freezed,
    Object? receiptDate = freezed,
    Object? upcCode = freezed,
  }) {
    return _then(_$ReceivedItemLineImpl(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      parent: null == parent
          ? _value.parent
          : parent // ignore: cast_nullable_to_non_nullable
              as String,
      itemCode: null == itemCode
          ? _value.itemCode
          : itemCode // ignore: cast_nullable_to_non_nullable
              as String,
      itemName: freezed == itemName
          ? _value.itemName
          : itemName // ignore: cast_nullable_to_non_nullable
              as String?,
      pendingQty: null == pendingQty
          ? _value.pendingQty
          : pendingQty // ignore: cast_nullable_to_non_nullable
              as double,
      uom: freezed == uom
          ? _value.uom
          : uom // ignore: cast_nullable_to_non_nullable
              as String?,
      warehouse: freezed == warehouse
          ? _value.warehouse
          : warehouse // ignore: cast_nullable_to_non_nullable
              as String?,
      lotNo: freezed == lotNo
          ? _value.lotNo
          : lotNo // ignore: cast_nullable_to_non_nullable
              as String?,
      productionDate: freezed == productionDate
          ? _value.productionDate
          : productionDate // ignore: cast_nullable_to_non_nullable
              as String?,
      expiryDate: freezed == expiryDate
          ? _value.expiryDate
          : expiryDate // ignore: cast_nullable_to_non_nullable
              as String?,
      batchNo: freezed == batchNo
          ? _value.batchNo
          : batchNo // ignore: cast_nullable_to_non_nullable
              as String?,
      receivedQty: freezed == receivedQty
          ? _value.receivedQty
          : receivedQty // ignore: cast_nullable_to_non_nullable
              as double?,
      batchQtyCreated: freezed == batchQtyCreated
          ? _value.batchQtyCreated
          : batchQtyCreated // ignore: cast_nullable_to_non_nullable
              as double?,
      pendingBatchQty: freezed == pendingBatchQty
          ? _value.pendingBatchQty
          : pendingBatchQty // ignore: cast_nullable_to_non_nullable
              as double?,
      binAllocatedQuantity: freezed == binAllocatedQuantity
          ? _value.binAllocatedQuantity
          : binAllocatedQuantity // ignore: cast_nullable_to_non_nullable
              as double?,
      receiptDate: freezed == receiptDate
          ? _value.receiptDate
          : receiptDate // ignore: cast_nullable_to_non_nullable
              as String?,
      upcCode: freezed == upcCode
          ? _value.upcCode
          : upcCode // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ReceivedItemLineImpl implements _ReceivedItemLine {
  const _$ReceivedItemLineImpl(
      {required this.name,
      required this.parent,
      @JsonKey(name: 'item_code') required this.itemCode,
      @JsonKey(name: 'item_name') this.itemName,
      @JsonKey(name: 'pending_qty') required this.pendingQty,
      this.uom,
      this.warehouse,
      @JsonKey(name: 'lot_no') this.lotNo,
      @JsonKey(name: 'production_date') this.productionDate,
      @JsonKey(name: 'expiry_date') this.expiryDate,
      @JsonKey(name: 'batch_no') this.batchNo,
      @JsonKey(name: 'received_qty') this.receivedQty,
      @JsonKey(name: 'batch_qty_created') this.batchQtyCreated,
      @JsonKey(name: 'pending_batch_qty') this.pendingBatchQty,
      @JsonKey(name: 'bin_allocated_quantity') this.binAllocatedQuantity,
      @JsonKey(name: 'receipt_date') this.receiptDate,
      @JsonKey(name: 'upc_code') this.upcCode});

  factory _$ReceivedItemLineImpl.fromJson(Map<String, dynamic> json) =>
      _$$ReceivedItemLineImplFromJson(json);

  @override
  final String name;
  @override
  final String parent;
  @override
  @JsonKey(name: 'item_code')
  final String itemCode;
  @override
  @JsonKey(name: 'item_name')
  final String? itemName;
  @override
  @JsonKey(name: 'pending_qty')
  final double pendingQty;
  @override
  final String? uom;
  @override
  final String? warehouse;
  @override
  @JsonKey(name: 'lot_no')
  final String? lotNo;
  @override
  @JsonKey(name: 'production_date')
  final String? productionDate;
  @override
  @JsonKey(name: 'expiry_date')
  final String? expiryDate;
  @override
  @JsonKey(name: 'batch_no')
  final String? batchNo;
  @override
  @JsonKey(name: 'received_qty')
  final double? receivedQty;
  @override
  @JsonKey(name: 'batch_qty_created')
  final double? batchQtyCreated;
  @override
  @JsonKey(name: 'pending_batch_qty')
  final double? pendingBatchQty;
  @override
  @JsonKey(name: 'bin_allocated_quantity')
  final double? binAllocatedQuantity;
  @override
  @JsonKey(name: 'receipt_date')
  final String? receiptDate;
  @override
  @JsonKey(name: 'upc_code')
  final String? upcCode;

  @override
  String toString() {
    return 'ReceivedItemLine(name: $name, parent: $parent, itemCode: $itemCode, itemName: $itemName, pendingQty: $pendingQty, uom: $uom, warehouse: $warehouse, lotNo: $lotNo, productionDate: $productionDate, expiryDate: $expiryDate, batchNo: $batchNo, receivedQty: $receivedQty, batchQtyCreated: $batchQtyCreated, pendingBatchQty: $pendingBatchQty, binAllocatedQuantity: $binAllocatedQuantity, receiptDate: $receiptDate, upcCode: $upcCode)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReceivedItemLineImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.parent, parent) || other.parent == parent) &&
            (identical(other.itemCode, itemCode) ||
                other.itemCode == itemCode) &&
            (identical(other.itemName, itemName) ||
                other.itemName == itemName) &&
            (identical(other.pendingQty, pendingQty) ||
                other.pendingQty == pendingQty) &&
            (identical(other.uom, uom) || other.uom == uom) &&
            (identical(other.warehouse, warehouse) ||
                other.warehouse == warehouse) &&
            (identical(other.lotNo, lotNo) || other.lotNo == lotNo) &&
            (identical(other.productionDate, productionDate) ||
                other.productionDate == productionDate) &&
            (identical(other.expiryDate, expiryDate) ||
                other.expiryDate == expiryDate) &&
            (identical(other.batchNo, batchNo) || other.batchNo == batchNo) &&
            (identical(other.receivedQty, receivedQty) ||
                other.receivedQty == receivedQty) &&
            (identical(other.batchQtyCreated, batchQtyCreated) ||
                other.batchQtyCreated == batchQtyCreated) &&
            (identical(other.pendingBatchQty, pendingBatchQty) ||
                other.pendingBatchQty == pendingBatchQty) &&
            (identical(other.binAllocatedQuantity, binAllocatedQuantity) ||
                other.binAllocatedQuantity == binAllocatedQuantity) &&
            (identical(other.receiptDate, receiptDate) ||
                other.receiptDate == receiptDate) &&
            (identical(other.upcCode, upcCode) ||
                other.upcCode == upcCode));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      name,
      parent,
      itemCode,
      itemName,
      pendingQty,
      uom,
      warehouse,
      lotNo,
      productionDate,
      expiryDate,
      batchNo,
      receivedQty,
      batchQtyCreated,
      pendingBatchQty,
      binAllocatedQuantity,
      receiptDate,
      upcCode);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ReceivedItemLineImplCopyWith<_$ReceivedItemLineImpl> get copyWith =>
      __$$ReceivedItemLineImplCopyWithImpl<_$ReceivedItemLineImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ReceivedItemLineImplToJson(
      this,
    );
  }
}

abstract class _ReceivedItemLine implements ReceivedItemLine {
  const factory _ReceivedItemLine(
      {required final String name,
      required final String parent,
      @JsonKey(name: 'item_code') required final String itemCode,
      @JsonKey(name: 'item_name') final String? itemName,
      @JsonKey(name: 'pending_qty') required final double pendingQty,
      final String? uom,
      final String? warehouse,
      @JsonKey(name: 'lot_no') final String? lotNo,
      @JsonKey(name: 'production_date') final String? productionDate,
      @JsonKey(name: 'expiry_date') final String? expiryDate,
      @JsonKey(name: 'batch_no') final String? batchNo,
      @JsonKey(name: 'received_qty') final double? receivedQty,
      @JsonKey(name: 'batch_qty_created') final double? batchQtyCreated,
      @JsonKey(name: 'pending_batch_qty') final double? pendingBatchQty,
      @JsonKey(name: 'bin_allocated_quantity')
      final double? binAllocatedQuantity,
      @JsonKey(name: 'receipt_date')
      final String? receiptDate,
      @JsonKey(name: 'upc_code')
      final String? upcCode}) = _$ReceivedItemLineImpl;

  factory _ReceivedItemLine.fromJson(Map<String, dynamic> json) =
      _$ReceivedItemLineImpl.fromJson;

  @override
  String get name;
  @override
  String get parent;
  @override
  @JsonKey(name: 'item_code')
  String get itemCode;
  @override
  @JsonKey(name: 'item_name')
  String? get itemName;
  @override
  @JsonKey(name: 'pending_qty')
  double get pendingQty;
  @override
  String? get uom;
  @override
  String? get warehouse;
  @override
  @JsonKey(name: 'lot_no')
  String? get lotNo;
  @override
  @JsonKey(name: 'production_date')
  String? get productionDate;
  @override
  @JsonKey(name: 'expiry_date')
  String? get expiryDate;
  @override
  @JsonKey(name: 'batch_no')
  String? get batchNo;
  @override
  @JsonKey(name: 'received_qty')
  double? get receivedQty;
  @override
  @JsonKey(name: 'batch_qty_created')
  double? get batchQtyCreated;
  @override
  @JsonKey(name: 'pending_batch_qty')
  double? get pendingBatchQty;
  @override
  @JsonKey(name: 'bin_allocated_quantity')
  double? get binAllocatedQuantity;
  @override
  @JsonKey(name: 'receipt_date')
  String? get receiptDate;
  @override
  @JsonKey(name: 'upc_code')
  String? get upcCode;
  @override
  @JsonKey(ignore: true)
  _$$ReceivedItemLineImplCopyWith<_$ReceivedItemLineImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

GrnBatch _$GrnBatchFromJson(Map<String, dynamic> json) {
  return _GrnBatch.fromJson(json);
}

/// @nodoc
mixin _$GrnBatch {
  @JsonKey(name: 'batch_no')
  String get batchNo => throw _privateConstructorUsedError;
  @JsonKey(name: 'production_date')
  String? get productionDate => throw _privateConstructorUsedError;
  @JsonKey(name: 'expiry_date')
  String? get expiryDate => throw _privateConstructorUsedError;
  @JsonKey(name: 'available_qty')
  double get availableQty => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $GrnBatchCopyWith<GrnBatch> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GrnBatchCopyWith<$Res> {
  factory $GrnBatchCopyWith(GrnBatch value, $Res Function(GrnBatch) then) =
      _$GrnBatchCopyWithImpl<$Res, GrnBatch>;
  @useResult
  $Res call(
      {@JsonKey(name: 'batch_no') String batchNo,
      @JsonKey(name: 'production_date') String? productionDate,
      @JsonKey(name: 'expiry_date') String? expiryDate,
      @JsonKey(name: 'available_qty') double availableQty});
}

/// @nodoc
class _$GrnBatchCopyWithImpl<$Res, $Val extends GrnBatch>
    implements $GrnBatchCopyWith<$Res> {
  _$GrnBatchCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? batchNo = null,
    Object? productionDate = freezed,
    Object? expiryDate = freezed,
    Object? availableQty = null,
  }) {
    return _then(_value.copyWith(
      batchNo: null == batchNo
          ? _value.batchNo
          : batchNo // ignore: cast_nullable_to_non_nullable
              as String,
      productionDate: freezed == productionDate
          ? _value.productionDate
          : productionDate // ignore: cast_nullable_to_non_nullable
              as String?,
      expiryDate: freezed == expiryDate
          ? _value.expiryDate
          : expiryDate // ignore: cast_nullable_to_non_nullable
              as String?,
      availableQty: null == availableQty
          ? _value.availableQty
          : availableQty // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$GrnBatchImplCopyWith<$Res>
    implements $GrnBatchCopyWith<$Res> {
  factory _$$GrnBatchImplCopyWith(
          _$GrnBatchImpl value, $Res Function(_$GrnBatchImpl) then) =
      __$$GrnBatchImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'batch_no') String batchNo,
      @JsonKey(name: 'production_date') String? productionDate,
      @JsonKey(name: 'expiry_date') String? expiryDate,
      @JsonKey(name: 'available_qty') double availableQty});
}

/// @nodoc
class __$$GrnBatchImplCopyWithImpl<$Res>
    extends _$GrnBatchCopyWithImpl<$Res, _$GrnBatchImpl>
    implements _$$GrnBatchImplCopyWith<$Res> {
  __$$GrnBatchImplCopyWithImpl(
      _$GrnBatchImpl _value, $Res Function(_$GrnBatchImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? batchNo = null,
    Object? productionDate = freezed,
    Object? expiryDate = freezed,
    Object? availableQty = null,
  }) {
    return _then(_$GrnBatchImpl(
      batchNo: null == batchNo
          ? _value.batchNo
          : batchNo // ignore: cast_nullable_to_non_nullable
              as String,
      productionDate: freezed == productionDate
          ? _value.productionDate
          : productionDate // ignore: cast_nullable_to_non_nullable
              as String?,
      expiryDate: freezed == expiryDate
          ? _value.expiryDate
          : expiryDate // ignore: cast_nullable_to_non_nullable
              as String?,
      availableQty: null == availableQty
          ? _value.availableQty
          : availableQty // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$GrnBatchImpl implements _GrnBatch {
  const _$GrnBatchImpl(
      {@JsonKey(name: 'batch_no') required this.batchNo,
      @JsonKey(name: 'production_date') this.productionDate,
      @JsonKey(name: 'expiry_date') this.expiryDate,
      @JsonKey(name: 'available_qty') required this.availableQty});

  factory _$GrnBatchImpl.fromJson(Map<String, dynamic> json) =>
      _$$GrnBatchImplFromJson(json);

  @override
  @JsonKey(name: 'batch_no')
  final String batchNo;
  @override
  @JsonKey(name: 'production_date')
  final String? productionDate;
  @override
  @JsonKey(name: 'expiry_date')
  final String? expiryDate;
  @override
  @JsonKey(name: 'available_qty')
  final double availableQty;

  @override
  String toString() {
    return 'GrnBatch(batchNo: $batchNo, productionDate: $productionDate, expiryDate: $expiryDate, availableQty: $availableQty)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GrnBatchImpl &&
            (identical(other.batchNo, batchNo) || other.batchNo == batchNo) &&
            (identical(other.productionDate, productionDate) ||
                other.productionDate == productionDate) &&
            (identical(other.expiryDate, expiryDate) ||
                other.expiryDate == expiryDate) &&
            (identical(other.availableQty, availableQty) ||
                other.availableQty == availableQty));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, batchNo, productionDate, expiryDate, availableQty);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$GrnBatchImplCopyWith<_$GrnBatchImpl> get copyWith =>
      __$$GrnBatchImplCopyWithImpl<_$GrnBatchImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GrnBatchImplToJson(
      this,
    );
  }
}

abstract class _GrnBatch implements GrnBatch {
  const factory _GrnBatch(
          {@JsonKey(name: 'batch_no') required final String batchNo,
          @JsonKey(name: 'production_date') final String? productionDate,
          @JsonKey(name: 'expiry_date') final String? expiryDate,
          @JsonKey(name: 'available_qty') required final double availableQty}) =
      _$GrnBatchImpl;

  factory _GrnBatch.fromJson(Map<String, dynamic> json) =
      _$GrnBatchImpl.fromJson;

  @override
  @JsonKey(name: 'batch_no')
  String get batchNo;
  @override
  @JsonKey(name: 'production_date')
  String? get productionDate;
  @override
  @JsonKey(name: 'expiry_date')
  String? get expiryDate;
  @override
  @JsonKey(name: 'available_qty')
  double get availableQty;
  @override
  @JsonKey(ignore: true)
  _$$GrnBatchImplCopyWith<_$GrnBatchImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

LotSuggestion _$LotSuggestionFromJson(Map<String, dynamic> json) {
  return _LotSuggestion.fromJson(json);
}

/// @nodoc
mixin _$LotSuggestion {
  String get lot => throw _privateConstructorUsedError;
  @JsonKey(name: 'available_qty')
  double get availableQty => throw _privateConstructorUsedError;
  String? get reason => throw _privateConstructorUsedError;
  String? get warehouse => throw _privateConstructorUsedError;
  String? get zone => throw _privateConstructorUsedError;
  String? get aisle => throw _privateConstructorUsedError;
  String? get level => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $LotSuggestionCopyWith<LotSuggestion> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LotSuggestionCopyWith<$Res> {
  factory $LotSuggestionCopyWith(
          LotSuggestion value, $Res Function(LotSuggestion) then) =
      _$LotSuggestionCopyWithImpl<$Res, LotSuggestion>;
  @useResult
  $Res call(
      {String lot,
      @JsonKey(name: 'available_qty') double availableQty,
      String? reason,
      String? warehouse,
      String? zone,
      String? aisle,
      String? level});
}

/// @nodoc
class _$LotSuggestionCopyWithImpl<$Res, $Val extends LotSuggestion>
    implements $LotSuggestionCopyWith<$Res> {
  _$LotSuggestionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? lot = null,
    Object? availableQty = null,
    Object? reason = freezed,
    Object? warehouse = freezed,
    Object? zone = freezed,
    Object? aisle = freezed,
    Object? level = freezed,
  }) {
    return _then(_value.copyWith(
      lot: null == lot
          ? _value.lot
          : lot // ignore: cast_nullable_to_non_nullable
              as String,
      availableQty: null == availableQty
          ? _value.availableQty
          : availableQty // ignore: cast_nullable_to_non_nullable
              as double,
      reason: freezed == reason
          ? _value.reason
          : reason // ignore: cast_nullable_to_non_nullable
              as String?,
      warehouse: freezed == warehouse
          ? _value.warehouse
          : warehouse // ignore: cast_nullable_to_non_nullable
              as String?,
      zone: freezed == zone
          ? _value.zone
          : zone // ignore: cast_nullable_to_non_nullable
              as String?,
      aisle: freezed == aisle
          ? _value.aisle
          : aisle // ignore: cast_nullable_to_non_nullable
              as String?,
      level: freezed == level
          ? _value.level
          : level // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$LotSuggestionImplCopyWith<$Res>
    implements $LotSuggestionCopyWith<$Res> {
  factory _$$LotSuggestionImplCopyWith(
          _$LotSuggestionImpl value, $Res Function(_$LotSuggestionImpl) then) =
      __$$LotSuggestionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String lot,
      @JsonKey(name: 'available_qty') double availableQty,
      String? reason,
      String? warehouse,
      String? zone,
      String? aisle,
      String? level});
}

/// @nodoc
class __$$LotSuggestionImplCopyWithImpl<$Res>
    extends _$LotSuggestionCopyWithImpl<$Res, _$LotSuggestionImpl>
    implements _$$LotSuggestionImplCopyWith<$Res> {
  __$$LotSuggestionImplCopyWithImpl(
      _$LotSuggestionImpl _value, $Res Function(_$LotSuggestionImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? lot = null,
    Object? availableQty = null,
    Object? reason = freezed,
    Object? warehouse = freezed,
    Object? zone = freezed,
    Object? aisle = freezed,
    Object? level = freezed,
  }) {
    return _then(_$LotSuggestionImpl(
      lot: null == lot
          ? _value.lot
          : lot // ignore: cast_nullable_to_non_nullable
              as String,
      availableQty: null == availableQty
          ? _value.availableQty
          : availableQty // ignore: cast_nullable_to_non_nullable
              as double,
      reason: freezed == reason
          ? _value.reason
          : reason // ignore: cast_nullable_to_non_nullable
              as String?,
      warehouse: freezed == warehouse
          ? _value.warehouse
          : warehouse // ignore: cast_nullable_to_non_nullable
              as String?,
      zone: freezed == zone
          ? _value.zone
          : zone // ignore: cast_nullable_to_non_nullable
              as String?,
      aisle: freezed == aisle
          ? _value.aisle
          : aisle // ignore: cast_nullable_to_non_nullable
              as String?,
      level: freezed == level
          ? _value.level
          : level // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LotSuggestionImpl implements _LotSuggestion {
  const _$LotSuggestionImpl(
      {required this.lot,
      @JsonKey(name: 'available_qty') this.availableQty = 0,
      this.reason,
      this.warehouse,
      this.zone,
      this.aisle,
      this.level});

  factory _$LotSuggestionImpl.fromJson(Map<String, dynamic> json) =>
      _$$LotSuggestionImplFromJson(json);

  @override
  final String lot;
  @override
  @JsonKey(name: 'available_qty')
  final double availableQty;
  @override
  final String? reason;
  @override
  final String? warehouse;
  @override
  final String? zone;
  @override
  final String? aisle;
  @override
  final String? level;

  @override
  String toString() {
    return 'LotSuggestion(lot: $lot, availableQty: $availableQty, reason: $reason, warehouse: $warehouse, zone: $zone, aisle: $aisle, level: $level)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LotSuggestionImpl &&
            (identical(other.lot, lot) || other.lot == lot) &&
            (identical(other.availableQty, availableQty) ||
                other.availableQty == availableQty) &&
            (identical(other.reason, reason) || other.reason == reason) &&
            (identical(other.warehouse, warehouse) ||
                other.warehouse == warehouse) &&
            (identical(other.zone, zone) || other.zone == zone) &&
            (identical(other.aisle, aisle) || other.aisle == aisle) &&
            (identical(other.level, level) || other.level == level));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, lot, availableQty, reason, warehouse, zone, aisle, level);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$LotSuggestionImplCopyWith<_$LotSuggestionImpl> get copyWith =>
      __$$LotSuggestionImplCopyWithImpl<_$LotSuggestionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LotSuggestionImplToJson(
      this,
    );
  }
}

abstract class _LotSuggestion implements LotSuggestion {
  const factory _LotSuggestion(
      {required final String lot,
      @JsonKey(name: 'available_qty') final double availableQty,
      final String? reason,
      final String? warehouse,
      final String? zone,
      final String? aisle,
      final String? level}) = _$LotSuggestionImpl;

  factory _LotSuggestion.fromJson(Map<String, dynamic> json) =
      _$LotSuggestionImpl.fromJson;

  @override
  String get lot;
  @override
  @JsonKey(name: 'available_qty')
  double get availableQty;
  @override
  String? get reason;
  @override
  String? get warehouse;
  @override
  String? get zone;
  @override
  String? get aisle;
  @override
  String? get level;
  @override
  @JsonKey(ignore: true)
  _$$LotSuggestionImplCopyWith<_$LotSuggestionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

LotStockLine _$LotStockLineFromJson(Map<String, dynamic> json) {
  return _LotStockLine.fromJson(json);
}

/// @nodoc
mixin _$LotStockLine {
  @JsonKey(name: 'item_code')
  String get itemCode => throw _privateConstructorUsedError;
  @JsonKey(name: 'item_name')
  String? get itemName => throw _privateConstructorUsedError;
  @JsonKey(name: 'upc_code')
  String? get upcCode => throw _privateConstructorUsedError;
  @JsonKey(name: 'batch_no')
  String? get batchNo => throw _privateConstructorUsedError;
  @JsonKey(name: 'fifo_date')
  String? get fifoDate => throw _privateConstructorUsedError;
  @JsonKey(name: 'production_date')
  String? get productionDate => throw _privateConstructorUsedError;
  @JsonKey(name: 'expiry_date')
  String? get expiryDate => throw _privateConstructorUsedError;
  double get qty => throw _privateConstructorUsedError;
  String? get uom => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $LotStockLineCopyWith<LotStockLine> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LotStockLineCopyWith<$Res> {
  factory $LotStockLineCopyWith(
          LotStockLine value, $Res Function(LotStockLine) then) =
      _$LotStockLineCopyWithImpl<$Res, LotStockLine>;
  @useResult
  $Res call(
      {@JsonKey(name: 'item_code') String itemCode,
      @JsonKey(name: 'item_name') String? itemName,
      @JsonKey(name: 'upc_code') String? upcCode,
      @JsonKey(name: 'batch_no') String? batchNo,
      @JsonKey(name: 'fifo_date') String? fifoDate,
      @JsonKey(name: 'production_date') String? productionDate,
      @JsonKey(name: 'expiry_date') String? expiryDate,
      double qty,
      String? uom});
}

/// @nodoc
class _$LotStockLineCopyWithImpl<$Res, $Val extends LotStockLine>
    implements $LotStockLineCopyWith<$Res> {
  _$LotStockLineCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? itemCode = null,
    Object? itemName = freezed,
    Object? upcCode = freezed,
    Object? batchNo = freezed,
    Object? fifoDate = freezed,
    Object? productionDate = freezed,
    Object? expiryDate = freezed,
    Object? qty = null,
    Object? uom = freezed,
  }) {
    return _then(_value.copyWith(
      itemCode: null == itemCode
          ? _value.itemCode
          : itemCode // ignore: cast_nullable_to_non_nullable
              as String,
      itemName: freezed == itemName
          ? _value.itemName
          : itemName // ignore: cast_nullable_to_non_nullable
              as String?,
      upcCode: freezed == upcCode
          ? _value.upcCode
          : upcCode // ignore: cast_nullable_to_non_nullable
              as String?,
      batchNo: freezed == batchNo
          ? _value.batchNo
          : batchNo // ignore: cast_nullable_to_non_nullable
              as String?,
      fifoDate: freezed == fifoDate
          ? _value.fifoDate
          : fifoDate // ignore: cast_nullable_to_non_nullable
              as String?,
      productionDate: freezed == productionDate
          ? _value.productionDate
          : productionDate // ignore: cast_nullable_to_non_nullable
              as String?,
      expiryDate: freezed == expiryDate
          ? _value.expiryDate
          : expiryDate // ignore: cast_nullable_to_non_nullable
              as String?,
      qty: null == qty
          ? _value.qty
          : qty // ignore: cast_nullable_to_non_nullable
              as double,
      uom: freezed == uom
          ? _value.uom
          : uom // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$LotStockLineImplCopyWith<$Res>
    implements $LotStockLineCopyWith<$Res> {
  factory _$$LotStockLineImplCopyWith(
          _$LotStockLineImpl value, $Res Function(_$LotStockLineImpl) then) =
      __$$LotStockLineImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'item_code') String itemCode,
      @JsonKey(name: 'item_name') String? itemName,
      @JsonKey(name: 'upc_code') String? upcCode,
      @JsonKey(name: 'batch_no') String? batchNo,
      @JsonKey(name: 'fifo_date') String? fifoDate,
      @JsonKey(name: 'production_date') String? productionDate,
      @JsonKey(name: 'expiry_date') String? expiryDate,
      double qty,
      String? uom});
}

/// @nodoc
class __$$LotStockLineImplCopyWithImpl<$Res>
    extends _$LotStockLineCopyWithImpl<$Res, _$LotStockLineImpl>
    implements _$$LotStockLineImplCopyWith<$Res> {
  __$$LotStockLineImplCopyWithImpl(
      _$LotStockLineImpl _value, $Res Function(_$LotStockLineImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? itemCode = null,
    Object? itemName = freezed,
    Object? upcCode = freezed,
    Object? batchNo = freezed,
    Object? fifoDate = freezed,
    Object? productionDate = freezed,
    Object? expiryDate = freezed,
    Object? qty = null,
    Object? uom = freezed,
  }) {
    return _then(_$LotStockLineImpl(
      itemCode: null == itemCode
          ? _value.itemCode
          : itemCode // ignore: cast_nullable_to_non_nullable
              as String,
      itemName: freezed == itemName
          ? _value.itemName
          : itemName // ignore: cast_nullable_to_non_nullable
              as String?,
      upcCode: freezed == upcCode
          ? _value.upcCode
          : upcCode // ignore: cast_nullable_to_non_nullable
              as String?,
      batchNo: freezed == batchNo
          ? _value.batchNo
          : batchNo // ignore: cast_nullable_to_non_nullable
              as String?,
      fifoDate: freezed == fifoDate
          ? _value.fifoDate
          : fifoDate // ignore: cast_nullable_to_non_nullable
              as String?,
      productionDate: freezed == productionDate
          ? _value.productionDate
          : productionDate // ignore: cast_nullable_to_non_nullable
              as String?,
      expiryDate: freezed == expiryDate
          ? _value.expiryDate
          : expiryDate // ignore: cast_nullable_to_non_nullable
              as String?,
      qty: null == qty
          ? _value.qty
          : qty // ignore: cast_nullable_to_non_nullable
              as double,
      uom: freezed == uom
          ? _value.uom
          : uom // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LotStockLineImpl implements _LotStockLine {
  const _$LotStockLineImpl(
      {@JsonKey(name: 'item_code') required this.itemCode,
      @JsonKey(name: 'item_name') this.itemName,
      @JsonKey(name: 'upc_code') this.upcCode,
      @JsonKey(name: 'batch_no') this.batchNo,
      @JsonKey(name: 'fifo_date') this.fifoDate,
      @JsonKey(name: 'production_date') this.productionDate,
      @JsonKey(name: 'expiry_date') this.expiryDate,
      required this.qty,
      this.uom});

  factory _$LotStockLineImpl.fromJson(Map<String, dynamic> json) =>
      _$$LotStockLineImplFromJson(json);

  @override
  @JsonKey(name: 'item_code')
  final String itemCode;
  @override
  @JsonKey(name: 'item_name')
  final String? itemName;
  @override
  @JsonKey(name: 'upc_code')
  final String? upcCode;
  @override
  @JsonKey(name: 'batch_no')
  final String? batchNo;
  @override
  @JsonKey(name: 'fifo_date')
  final String? fifoDate;
  @override
  @JsonKey(name: 'production_date')
  final String? productionDate;
  @override
  @JsonKey(name: 'expiry_date')
  final String? expiryDate;
  @override
  final double qty;
  @override
  final String? uom;

  @override
  String toString() {
    return 'LotStockLine(itemCode: $itemCode, itemName: $itemName, upcCode: $upcCode, batchNo: $batchNo, fifoDate: $fifoDate, productionDate: $productionDate, expiryDate: $expiryDate, qty: $qty, uom: $uom)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LotStockLineImpl &&
            (identical(other.itemCode, itemCode) ||
                other.itemCode == itemCode) &&
            (identical(other.itemName, itemName) ||
                other.itemName == itemName) &&
            (identical(other.upcCode, upcCode) ||
                other.upcCode == upcCode) &&
            (identical(other.batchNo, batchNo) || other.batchNo == batchNo) &&
            (identical(other.fifoDate, fifoDate) ||
                other.fifoDate == fifoDate) &&
            (identical(other.productionDate, productionDate) ||
                other.productionDate == productionDate) &&
            (identical(other.expiryDate, expiryDate) ||
                other.expiryDate == expiryDate) &&
            (identical(other.qty, qty) || other.qty == qty) &&
            (identical(other.uom, uom) || other.uom == uom));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, itemCode, itemName, upcCode, batchNo, fifoDate, productionDate, expiryDate, qty, uom);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$LotStockLineImplCopyWith<_$LotStockLineImpl> get copyWith =>
      __$$LotStockLineImplCopyWithImpl<_$LotStockLineImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LotStockLineImplToJson(
      this,
    );
  }
}

abstract class _LotStockLine implements LotStockLine {
  const factory _LotStockLine(
      {@JsonKey(name: 'item_code') required final String itemCode,
      @JsonKey(name: 'item_name') final String? itemName,
      @JsonKey(name: 'upc_code') final String? upcCode,
      @JsonKey(name: 'batch_no') final String? batchNo,
      @JsonKey(name: 'fifo_date') final String? fifoDate,
      @JsonKey(name: 'production_date') final String? productionDate,
      @JsonKey(name: 'expiry_date') final String? expiryDate,
      required final double qty,
      final String? uom}) = _$LotStockLineImpl;

  factory _LotStockLine.fromJson(Map<String, dynamic> json) =
      _$LotStockLineImpl.fromJson;

  @override
  @JsonKey(name: 'item_code')
  String get itemCode;
  @override
  @JsonKey(name: 'item_name')
  String? get itemName;
  @override
  @JsonKey(name: 'upc_code')
  String? get upcCode;
  @override
  @JsonKey(name: 'batch_no')
  String? get batchNo;
  @override
  @JsonKey(name: 'fifo_date')
  String? get fifoDate;
  @override
  @JsonKey(name: 'production_date')
  String? get productionDate;
  @override
  @JsonKey(name: 'expiry_date')
  String? get expiryDate;
  @override
  double get qty;
  @override
  String? get uom;
  @override
  @JsonKey(ignore: true)
  _$$LotStockLineImplCopyWith<_$LotStockLineImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

WarehouseLot _$WarehouseLotFromJson(Map<String, dynamic> json) {
  return _WarehouseLot.fromJson(json);
}

/// @nodoc
mixin _$WarehouseLot {
  String get name => throw _privateConstructorUsedError;
  String? get warehouse => throw _privateConstructorUsedError;
  String? get zone => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_empty')
  int get isEmptyFlag => throw _privateConstructorUsedError;
  List<LotStockLine> get items => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $WarehouseLotCopyWith<WarehouseLot> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WarehouseLotCopyWith<$Res> {
  factory $WarehouseLotCopyWith(
          WarehouseLot value, $Res Function(WarehouseLot) then) =
      _$WarehouseLotCopyWithImpl<$Res, WarehouseLot>;
  @useResult
  $Res call(
      {String name, String? warehouse, String? zone, @JsonKey(name: 'is_empty') int isEmptyFlag, List<LotStockLine> items});
}

/// @nodoc
class _$WarehouseLotCopyWithImpl<$Res, $Val extends WarehouseLot>
    implements $WarehouseLotCopyWith<$Res> {
  _$WarehouseLotCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? warehouse = freezed,
    Object? zone = freezed,
    Object? isEmptyFlag = null,
    Object? items = null,
  }) {
    return _then(_value.copyWith(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      warehouse: freezed == warehouse
          ? _value.warehouse
          : warehouse // ignore: cast_nullable_to_non_nullable
              as String?,
      zone: freezed == zone
          ? _value.zone
          : zone // ignore: cast_nullable_to_non_nullable
              as String?,
      isEmptyFlag: null == isEmptyFlag
          ? _value.isEmptyFlag
          : isEmptyFlag // ignore: cast_nullable_to_non_nullable
              as int,
      items: null == items
          ? _value.items
          : items // ignore: cast_nullable_to_non_nullable
              as List<LotStockLine>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$WarehouseLotImplCopyWith<$Res>
    implements $WarehouseLotCopyWith<$Res> {
  factory _$$WarehouseLotImplCopyWith(
          _$WarehouseLotImpl value, $Res Function(_$WarehouseLotImpl) then) =
      __$$WarehouseLotImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String name, String? warehouse, String? zone, @JsonKey(name: 'is_empty') int isEmptyFlag, List<LotStockLine> items});
}

/// @nodoc
class __$$WarehouseLotImplCopyWithImpl<$Res>
    extends _$WarehouseLotCopyWithImpl<$Res, _$WarehouseLotImpl>
    implements _$$WarehouseLotImplCopyWith<$Res> {
  __$$WarehouseLotImplCopyWithImpl(
      _$WarehouseLotImpl _value, $Res Function(_$WarehouseLotImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? warehouse = freezed,
    Object? zone = freezed,
    Object? isEmptyFlag = null,
    Object? items = null,
  }) {
    return _then(_$WarehouseLotImpl(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      warehouse: freezed == warehouse
          ? _value.warehouse
          : warehouse // ignore: cast_nullable_to_non_nullable
              as String?,
      zone: freezed == zone
          ? _value.zone
          : zone // ignore: cast_nullable_to_non_nullable
              as String?,
      isEmptyFlag: null == isEmptyFlag
          ? _value.isEmptyFlag
          : isEmptyFlag // ignore: cast_nullable_to_non_nullable
              as int,
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<LotStockLine>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WarehouseLotImpl implements _WarehouseLot {
  const _$WarehouseLotImpl(
      {required this.name,
      this.warehouse,
      this.zone,
      @JsonKey(name: 'is_empty') this.isEmptyFlag = 1,
      final List<LotStockLine> items = const []})
      : _items = items;

  factory _$WarehouseLotImpl.fromJson(Map<String, dynamic> json) =>
      _$$WarehouseLotImplFromJson(json);

  @override
  final String name;
  @override
  final String? warehouse;
  @override
  final String? zone;
  @override
  @JsonKey(name: 'is_empty')
  final int isEmptyFlag;
  final List<LotStockLine> _items;
  @override
  @JsonKey()
  List<LotStockLine> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  String toString() {
    return 'WarehouseLot(name: $name, warehouse: $warehouse, zone: $zone, isEmptyFlag: $isEmptyFlag, items: $items)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WarehouseLotImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.warehouse, warehouse) ||
                other.warehouse == warehouse) &&
            (identical(other.zone, zone) || other.zone == zone) &&
            const DeepCollectionEquality().equals(other._items, _items));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, name, warehouse, zone,
      const DeepCollectionEquality().hash(_items));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$WarehouseLotImplCopyWith<_$WarehouseLotImpl> get copyWith =>
      __$$WarehouseLotImplCopyWithImpl<_$WarehouseLotImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WarehouseLotImplToJson(
      this,
    );
  }
}

abstract class _WarehouseLot implements WarehouseLot {
  const factory _WarehouseLot(
      {required final String name,
      final String? warehouse,
      final String? zone,
      @JsonKey(name: 'is_empty') final int isEmptyFlag,
      final List<LotStockLine> items}) = _$WarehouseLotImpl;

  factory _WarehouseLot.fromJson(Map<String, dynamic> json) =
      _$WarehouseLotImpl.fromJson;

  @override
  String get name;
  @override
  String? get warehouse;
  @override
  String? get zone;
  @override
  @JsonKey(name: 'is_empty')
  int get isEmptyFlag;
  @override
  List<LotStockLine> get items;
  @override
  @JsonKey(ignore: true)
  _$$WarehouseLotImplCopyWith<_$WarehouseLotImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PickItem _$PickItemFromJson(Map<String, dynamic> json) {
  return _PickItem.fromJson(json);
}

/// @nodoc
mixin _$PickItem {
  String get name => throw _privateConstructorUsedError;
  @JsonKey(name: 'item_code')
  String get itemCode => throw _privateConstructorUsedError;
  @JsonKey(name: 'item_name')
  String? get itemName => throw _privateConstructorUsedError;
  String? get warehouse => throw _privateConstructorUsedError;
  double get qty => throw _privateConstructorUsedError;
  @JsonKey(name: 'suggested_lot')
  String? get suggestedLot => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $PickItemCopyWith<PickItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PickItemCopyWith<$Res> {
  factory $PickItemCopyWith(PickItem value, $Res Function(PickItem) then) =
      _$PickItemCopyWithImpl<$Res, PickItem>;
  @useResult
  $Res call(
      {String name,
      @JsonKey(name: 'item_code') String itemCode,
      @JsonKey(name: 'item_name') String? itemName,
      String? warehouse,
      double qty,
      @JsonKey(name: 'suggested_lot') String? suggestedLot,
      String status});
}

/// @nodoc
class _$PickItemCopyWithImpl<$Res, $Val extends PickItem>
    implements $PickItemCopyWith<$Res> {
  _$PickItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? itemCode = null,
    Object? itemName = freezed,
    Object? warehouse = freezed,
    Object? qty = null,
    Object? suggestedLot = freezed,
    Object? status = null,
  }) {
    return _then(_value.copyWith(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      itemCode: null == itemCode
          ? _value.itemCode
          : itemCode // ignore: cast_nullable_to_non_nullable
              as String,
      itemName: freezed == itemName
          ? _value.itemName
          : itemName // ignore: cast_nullable_to_non_nullable
              as String?,
      warehouse: freezed == warehouse
          ? _value.warehouse
          : warehouse // ignore: cast_nullable_to_non_nullable
              as String?,
      qty: null == qty
          ? _value.qty
          : qty // ignore: cast_nullable_to_non_nullable
              as double,
      suggestedLot: freezed == suggestedLot
          ? _value.suggestedLot
          : suggestedLot // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PickItemImplCopyWith<$Res>
    implements $PickItemCopyWith<$Res> {
  factory _$$PickItemImplCopyWith(
          _$PickItemImpl value, $Res Function(_$PickItemImpl) then) =
      __$$PickItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String name,
      @JsonKey(name: 'item_code') String itemCode,
      @JsonKey(name: 'item_name') String? itemName,
      String? warehouse,
      double qty,
      @JsonKey(name: 'suggested_lot') String? suggestedLot,
      String status});
}

/// @nodoc
class __$$PickItemImplCopyWithImpl<$Res>
    extends _$PickItemCopyWithImpl<$Res, _$PickItemImpl>
    implements _$$PickItemImplCopyWith<$Res> {
  __$$PickItemImplCopyWithImpl(
      _$PickItemImpl _value, $Res Function(_$PickItemImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? itemCode = null,
    Object? itemName = freezed,
    Object? warehouse = freezed,
    Object? qty = null,
    Object? suggestedLot = freezed,
    Object? status = null,
  }) {
    return _then(_$PickItemImpl(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      itemCode: null == itemCode
          ? _value.itemCode
          : itemCode // ignore: cast_nullable_to_non_nullable
              as String,
      itemName: freezed == itemName
          ? _value.itemName
          : itemName // ignore: cast_nullable_to_non_nullable
              as String?,
      warehouse: freezed == warehouse
          ? _value.warehouse
          : warehouse // ignore: cast_nullable_to_non_nullable
              as String?,
      qty: null == qty
          ? _value.qty
          : qty // ignore: cast_nullable_to_non_nullable
              as double,
      suggestedLot: freezed == suggestedLot
          ? _value.suggestedLot
          : suggestedLot // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PickItemImpl implements _PickItem {
  const _$PickItemImpl(
      {required this.name,
      @JsonKey(name: 'item_code') required this.itemCode,
      @JsonKey(name: 'item_name') this.itemName,
      this.warehouse,
      required this.qty,
      @JsonKey(name: 'suggested_lot') this.suggestedLot,
      required this.status});

  factory _$PickItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$PickItemImplFromJson(json);

  @override
  final String name;
  @override
  @JsonKey(name: 'item_code')
  final String itemCode;
  @override
  @JsonKey(name: 'item_name')
  final String? itemName;
  @override
  final String? warehouse;
  @override
  final double qty;
  @override
  @JsonKey(name: 'suggested_lot')
  final String? suggestedLot;
  @override
  final String status;

  @override
  String toString() {
    return 'PickItem(name: $name, itemCode: $itemCode, itemName: $itemName, warehouse: $warehouse, qty: $qty, suggestedLot: $suggestedLot, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PickItemImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.itemCode, itemCode) ||
                other.itemCode == itemCode) &&
            (identical(other.itemName, itemName) ||
                other.itemName == itemName) &&
            (identical(other.warehouse, warehouse) ||
                other.warehouse == warehouse) &&
            (identical(other.qty, qty) || other.qty == qty) &&
            (identical(other.suggestedLot, suggestedLot) ||
                other.suggestedLot == suggestedLot) &&
            (identical(other.status, status) || other.status == status));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, name, itemCode, itemName,
      warehouse, qty, suggestedLot, status);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PickItemImplCopyWith<_$PickItemImpl> get copyWith =>
      __$$PickItemImplCopyWithImpl<_$PickItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PickItemImplToJson(
      this,
    );
  }
}

abstract class _PickItem implements PickItem {
  const factory _PickItem(
      {required final String name,
      @JsonKey(name: 'item_code') required final String itemCode,
      @JsonKey(name: 'item_name') final String? itemName,
      final String? warehouse,
      required final double qty,
      @JsonKey(name: 'suggested_lot') final String? suggestedLot,
      required final String status}) = _$PickItemImpl;

  factory _PickItem.fromJson(Map<String, dynamic> json) =
      _$PickItemImpl.fromJson;

  @override
  String get name;
  @override
  @JsonKey(name: 'item_code')
  String get itemCode;
  @override
  @JsonKey(name: 'item_name')
  String? get itemName;
  @override
  String? get warehouse;
  @override
  double get qty;
  @override
  @JsonKey(name: 'suggested_lot')
  String? get suggestedLot;
  @override
  String get status;
  @override
  @JsonKey(ignore: true)
  _$$PickItemImplCopyWith<_$PickItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
