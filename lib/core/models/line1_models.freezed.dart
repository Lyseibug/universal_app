// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'line1_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

StockItem _$StockItemFromJson(Map<String, dynamic> json) {
  return _StockItem.fromJson(json);
}

/// @nodoc
mixin _$StockItem {
  @JsonKey(name: 'item_code')
  String get itemCode => throw _privateConstructorUsedError;
  @JsonKey(name: 'item_name')
  String? get itemName => throw _privateConstructorUsedError;
  @JsonKey(name: 'batch_no')
  String? get batchNo => throw _privateConstructorUsedError;
  double get qty => throw _privateConstructorUsedError;
  @JsonKey(name: 'production_date')
  String? get productionDate => throw _privateConstructorUsedError;
  String? get stream => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $StockItemCopyWith<StockItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StockItemCopyWith<$Res> {
  factory $StockItemCopyWith(StockItem value, $Res Function(StockItem) then) =
      _$StockItemCopyWithImpl<$Res, StockItem>;
  @useResult
  $Res call(
      {@JsonKey(name: 'item_code') String itemCode,
      @JsonKey(name: 'item_name') String? itemName,
      @JsonKey(name: 'batch_no') String? batchNo,
      double qty,
      @JsonKey(name: 'production_date') String? productionDate,
      String? stream});
}

/// @nodoc
class _$StockItemCopyWithImpl<$Res, $Val extends StockItem>
    implements $StockItemCopyWith<$Res> {
  _$StockItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? itemCode = null,
    Object? itemName = freezed,
    Object? batchNo = freezed,
    Object? qty = null,
    Object? productionDate = freezed,
    Object? stream = freezed,
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
      batchNo: freezed == batchNo
          ? _value.batchNo
          : batchNo // ignore: cast_nullable_to_non_nullable
              as String?,
      qty: null == qty
          ? _value.qty
          : qty // ignore: cast_nullable_to_non_nullable
              as double,
      productionDate: freezed == productionDate
          ? _value.productionDate
          : productionDate // ignore: cast_nullable_to_non_nullable
              as String?,
      stream: freezed == stream
          ? _value.stream
          : stream // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$StockItemImplCopyWith<$Res>
    implements $StockItemCopyWith<$Res> {
  factory _$$StockItemImplCopyWith(
          _$StockItemImpl value, $Res Function(_$StockItemImpl) then) =
      __$$StockItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'item_code') String itemCode,
      @JsonKey(name: 'item_name') String? itemName,
      @JsonKey(name: 'batch_no') String? batchNo,
      double qty,
      @JsonKey(name: 'production_date') String? productionDate,
      String? stream});
}

/// @nodoc
class __$$StockItemImplCopyWithImpl<$Res>
    extends _$StockItemCopyWithImpl<$Res, _$StockItemImpl>
    implements _$$StockItemImplCopyWith<$Res> {
  __$$StockItemImplCopyWithImpl(
      _$StockItemImpl _value, $Res Function(_$StockItemImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? itemCode = null,
    Object? itemName = freezed,
    Object? batchNo = freezed,
    Object? qty = null,
    Object? productionDate = freezed,
    Object? stream = freezed,
  }) {
    return _then(_$StockItemImpl(
      itemCode: null == itemCode
          ? _value.itemCode
          : itemCode // ignore: cast_nullable_to_non_nullable
              as String,
      itemName: freezed == itemName
          ? _value.itemName
          : itemName // ignore: cast_nullable_to_non_nullable
              as String?,
      batchNo: freezed == batchNo
          ? _value.batchNo
          : batchNo // ignore: cast_nullable_to_non_nullable
              as String?,
      qty: null == qty
          ? _value.qty
          : qty // ignore: cast_nullable_to_non_nullable
              as double,
      productionDate: freezed == productionDate
          ? _value.productionDate
          : productionDate // ignore: cast_nullable_to_non_nullable
              as String?,
      stream: freezed == stream
          ? _value.stream
          : stream // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$StockItemImpl implements _StockItem {
  const _$StockItemImpl(
      {@JsonKey(name: 'item_code') required this.itemCode,
      @JsonKey(name: 'item_name') this.itemName,
      @JsonKey(name: 'batch_no') this.batchNo,
      this.qty = 0,
      @JsonKey(name: 'production_date') this.productionDate,
      this.stream});

  factory _$StockItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$StockItemImplFromJson(json);

  @override
  @JsonKey(name: 'item_code')
  final String itemCode;
  @override
  @JsonKey(name: 'item_name')
  final String? itemName;
  @override
  @JsonKey(name: 'batch_no')
  final String? batchNo;
  @override
  @JsonKey()
  final double qty;
  @override
  @JsonKey(name: 'production_date')
  final String? productionDate;
  @override
  final String? stream;

  @override
  String toString() {
    return 'StockItem(itemCode: $itemCode, itemName: $itemName, batchNo: $batchNo, qty: $qty, productionDate: $productionDate, stream: $stream)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StockItemImpl &&
            (identical(other.itemCode, itemCode) ||
                other.itemCode == itemCode) &&
            (identical(other.itemName, itemName) ||
                other.itemName == itemName) &&
            (identical(other.batchNo, batchNo) || other.batchNo == batchNo) &&
            (identical(other.qty, qty) || other.qty == qty) &&
            (identical(other.productionDate, productionDate) ||
                other.productionDate == productionDate) &&
            (identical(other.stream, stream) || other.stream == stream));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, itemCode, itemName, batchNo, qty, productionDate, stream);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$StockItemImplCopyWith<_$StockItemImpl> get copyWith =>
      __$$StockItemImplCopyWithImpl<_$StockItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$StockItemImplToJson(
      this,
    );
  }
}

abstract class _StockItem implements StockItem {
  const factory _StockItem(
      {@JsonKey(name: 'item_code') required final String itemCode,
      @JsonKey(name: 'item_name') final String? itemName,
      @JsonKey(name: 'batch_no') final String? batchNo,
      final double qty,
      @JsonKey(name: 'production_date') final String? productionDate,
      final String? stream}) = _$StockItemImpl;

  factory _StockItem.fromJson(Map<String, dynamic> json) =
      _$StockItemImpl.fromJson;

  @override
  @JsonKey(name: 'item_code')
  String get itemCode;
  @override
  @JsonKey(name: 'item_name')
  String? get itemName;
  @override
  @JsonKey(name: 'batch_no')
  String? get batchNo;
  @override
  double get qty;
  @override
  @JsonKey(name: 'production_date')
  String? get productionDate;
  @override
  String? get stream;
  @override
  @JsonKey(ignore: true)
  _$$StockItemImplCopyWith<_$StockItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

LoadResult _$LoadResultFromJson(Map<String, dynamic> json) {
  return _LoadResult.fromJson(json);
}

/// @nodoc
mixin _$LoadResult {
  @JsonKey(name: 'stock_entry')
  String? get stockEntry => throw _privateConstructorUsedError;
  double get qty => throw _privateConstructorUsedError;
  @JsonKey(name: 'batch_no')
  String? get batchNo => throw _privateConstructorUsedError;
  @JsonKey(name: 'box_barcode')
  String? get boxBarcode => throw _privateConstructorUsedError;
  String? get stream => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $LoadResultCopyWith<LoadResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LoadResultCopyWith<$Res> {
  factory $LoadResultCopyWith(
          LoadResult value, $Res Function(LoadResult) then) =
      _$LoadResultCopyWithImpl<$Res, LoadResult>;
  @useResult
  $Res call(
      {@JsonKey(name: 'stock_entry') String? stockEntry,
      double qty,
      @JsonKey(name: 'batch_no') String? batchNo,
      @JsonKey(name: 'box_barcode') String? boxBarcode,
      String? stream});
}

/// @nodoc
class _$LoadResultCopyWithImpl<$Res, $Val extends LoadResult>
    implements $LoadResultCopyWith<$Res> {
  _$LoadResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? stockEntry = freezed,
    Object? qty = null,
    Object? batchNo = freezed,
    Object? boxBarcode = freezed,
    Object? stream = freezed,
  }) {
    return _then(_value.copyWith(
      stockEntry: freezed == stockEntry
          ? _value.stockEntry
          : stockEntry // ignore: cast_nullable_to_non_nullable
              as String?,
      qty: null == qty
          ? _value.qty
          : qty // ignore: cast_nullable_to_non_nullable
              as double,
      batchNo: freezed == batchNo
          ? _value.batchNo
          : batchNo // ignore: cast_nullable_to_non_nullable
              as String?,
      boxBarcode: freezed == boxBarcode
          ? _value.boxBarcode
          : boxBarcode // ignore: cast_nullable_to_non_nullable
              as String?,
      stream: freezed == stream
          ? _value.stream
          : stream // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$LoadResultImplCopyWith<$Res>
    implements $LoadResultCopyWith<$Res> {
  factory _$$LoadResultImplCopyWith(
          _$LoadResultImpl value, $Res Function(_$LoadResultImpl) then) =
      __$$LoadResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'stock_entry') String? stockEntry,
      double qty,
      @JsonKey(name: 'batch_no') String? batchNo,
      @JsonKey(name: 'box_barcode') String? boxBarcode,
      String? stream});
}

/// @nodoc
class __$$LoadResultImplCopyWithImpl<$Res>
    extends _$LoadResultCopyWithImpl<$Res, _$LoadResultImpl>
    implements _$$LoadResultImplCopyWith<$Res> {
  __$$LoadResultImplCopyWithImpl(
      _$LoadResultImpl _value, $Res Function(_$LoadResultImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? stockEntry = freezed,
    Object? qty = null,
    Object? batchNo = freezed,
    Object? boxBarcode = freezed,
    Object? stream = freezed,
  }) {
    return _then(_$LoadResultImpl(
      stockEntry: freezed == stockEntry
          ? _value.stockEntry
          : stockEntry // ignore: cast_nullable_to_non_nullable
              as String?,
      qty: null == qty
          ? _value.qty
          : qty // ignore: cast_nullable_to_non_nullable
              as double,
      batchNo: freezed == batchNo
          ? _value.batchNo
          : batchNo // ignore: cast_nullable_to_non_nullable
              as String?,
      boxBarcode: freezed == boxBarcode
          ? _value.boxBarcode
          : boxBarcode // ignore: cast_nullable_to_non_nullable
              as String?,
      stream: freezed == stream
          ? _value.stream
          : stream // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LoadResultImpl implements _LoadResult {
  const _$LoadResultImpl(
      {@JsonKey(name: 'stock_entry') this.stockEntry,
      this.qty = 0,
      @JsonKey(name: 'batch_no') this.batchNo,
      @JsonKey(name: 'box_barcode') this.boxBarcode,
      this.stream});

  factory _$LoadResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$LoadResultImplFromJson(json);

  @override
  @JsonKey(name: 'stock_entry')
  final String? stockEntry;
  @override
  @JsonKey()
  final double qty;
  @override
  @JsonKey(name: 'batch_no')
  final String? batchNo;
  @override
  @JsonKey(name: 'box_barcode')
  final String? boxBarcode;
  @override
  final String? stream;

  @override
  String toString() {
    return 'LoadResult(stockEntry: $stockEntry, qty: $qty, batchNo: $batchNo, boxBarcode: $boxBarcode, stream: $stream)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LoadResultImpl &&
            (identical(other.stockEntry, stockEntry) ||
                other.stockEntry == stockEntry) &&
            (identical(other.qty, qty) || other.qty == qty) &&
            (identical(other.batchNo, batchNo) || other.batchNo == batchNo) &&
            (identical(other.boxBarcode, boxBarcode) ||
                other.boxBarcode == boxBarcode) &&
            (identical(other.stream, stream) || other.stream == stream));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, stockEntry, qty, batchNo, boxBarcode, stream);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$LoadResultImplCopyWith<_$LoadResultImpl> get copyWith =>
      __$$LoadResultImplCopyWithImpl<_$LoadResultImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LoadResultImplToJson(
      this,
    );
  }
}

abstract class _LoadResult implements LoadResult {
  const factory _LoadResult(
      {@JsonKey(name: 'stock_entry') final String? stockEntry,
      final double qty,
      @JsonKey(name: 'batch_no') final String? batchNo,
      @JsonKey(name: 'box_barcode') final String? boxBarcode,
      final String? stream}) = _$LoadResultImpl;

  factory _LoadResult.fromJson(Map<String, dynamic> json) =
      _$LoadResultImpl.fromJson;

  @override
  @JsonKey(name: 'stock_entry')
  String? get stockEntry;
  @override
  double get qty;
  @override
  @JsonKey(name: 'batch_no')
  String? get batchNo;
  @override
  @JsonKey(name: 'box_barcode')
  String? get boxBarcode;
  @override
  String? get stream;
  @override
  @JsonKey(ignore: true)
  _$$LoadResultImplCopyWith<_$LoadResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

BagItem _$BagItemFromJson(Map<String, dynamic> json) {
  return _BagItem.fromJson(json);
}

/// @nodoc
mixin _$BagItem {
  @JsonKey(name: 'batch_no')
  String get batchNo => throw _privateConstructorUsedError;
  @JsonKey(name: 'item_code')
  String get itemCode => throw _privateConstructorUsedError;
  @JsonKey(name: 'item_name')
  String? get itemName => throw _privateConstructorUsedError;
  double get qty => throw _privateConstructorUsedError;
  @JsonKey(name: 'formula_name')
  String? get formulaName => throw _privateConstructorUsedError;
  @JsonKey(name: 'production_datetime')
  String? get productionDatetime => throw _privateConstructorUsedError;
  @JsonKey(name: 'machine_production_record')
  String? get machineProductionRecord => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $BagItemCopyWith<BagItem> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BagItemCopyWith<$Res> {
  factory $BagItemCopyWith(BagItem value, $Res Function(BagItem) then) =
      _$BagItemCopyWithImpl<$Res, BagItem>;
  @useResult
  $Res call(
      {@JsonKey(name: 'batch_no') String batchNo,
      @JsonKey(name: 'item_code') String itemCode,
      @JsonKey(name: 'item_name') String? itemName,
      double qty,
      @JsonKey(name: 'formula_name') String? formulaName,
      @JsonKey(name: 'production_datetime') String? productionDatetime,
      @JsonKey(name: 'machine_production_record')
      String? machineProductionRecord});
}

/// @nodoc
class _$BagItemCopyWithImpl<$Res, $Val extends BagItem>
    implements $BagItemCopyWith<$Res> {
  _$BagItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? batchNo = null,
    Object? itemCode = null,
    Object? itemName = freezed,
    Object? qty = null,
    Object? formulaName = freezed,
    Object? productionDatetime = freezed,
    Object? machineProductionRecord = freezed,
  }) {
    return _then(_value.copyWith(
      batchNo: null == batchNo
          ? _value.batchNo
          : batchNo // ignore: cast_nullable_to_non_nullable
              as String,
      itemCode: null == itemCode
          ? _value.itemCode
          : itemCode // ignore: cast_nullable_to_non_nullable
              as String,
      itemName: freezed == itemName
          ? _value.itemName
          : itemName // ignore: cast_nullable_to_non_nullable
              as String?,
      qty: null == qty
          ? _value.qty
          : qty // ignore: cast_nullable_to_non_nullable
              as double,
      formulaName: freezed == formulaName
          ? _value.formulaName
          : formulaName // ignore: cast_nullable_to_non_nullable
              as String?,
      productionDatetime: freezed == productionDatetime
          ? _value.productionDatetime
          : productionDatetime // ignore: cast_nullable_to_non_nullable
              as String?,
      machineProductionRecord: freezed == machineProductionRecord
          ? _value.machineProductionRecord
          : machineProductionRecord // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$BagItemImplCopyWith<$Res> implements $BagItemCopyWith<$Res> {
  factory _$$BagItemImplCopyWith(
          _$BagItemImpl value, $Res Function(_$BagItemImpl) then) =
      __$$BagItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'batch_no') String batchNo,
      @JsonKey(name: 'item_code') String itemCode,
      @JsonKey(name: 'item_name') String? itemName,
      double qty,
      @JsonKey(name: 'formula_name') String? formulaName,
      @JsonKey(name: 'production_datetime') String? productionDatetime,
      @JsonKey(name: 'machine_production_record')
      String? machineProductionRecord});
}

/// @nodoc
class __$$BagItemImplCopyWithImpl<$Res>
    extends _$BagItemCopyWithImpl<$Res, _$BagItemImpl>
    implements _$$BagItemImplCopyWith<$Res> {
  __$$BagItemImplCopyWithImpl(
      _$BagItemImpl _value, $Res Function(_$BagItemImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? batchNo = null,
    Object? itemCode = null,
    Object? itemName = freezed,
    Object? qty = null,
    Object? formulaName = freezed,
    Object? productionDatetime = freezed,
    Object? machineProductionRecord = freezed,
  }) {
    return _then(_$BagItemImpl(
      batchNo: null == batchNo
          ? _value.batchNo
          : batchNo // ignore: cast_nullable_to_non_nullable
              as String,
      itemCode: null == itemCode
          ? _value.itemCode
          : itemCode // ignore: cast_nullable_to_non_nullable
              as String,
      itemName: freezed == itemName
          ? _value.itemName
          : itemName // ignore: cast_nullable_to_non_nullable
              as String?,
      qty: null == qty
          ? _value.qty
          : qty // ignore: cast_nullable_to_non_nullable
              as double,
      formulaName: freezed == formulaName
          ? _value.formulaName
          : formulaName // ignore: cast_nullable_to_non_nullable
              as String?,
      productionDatetime: freezed == productionDatetime
          ? _value.productionDatetime
          : productionDatetime // ignore: cast_nullable_to_non_nullable
              as String?,
      machineProductionRecord: freezed == machineProductionRecord
          ? _value.machineProductionRecord
          : machineProductionRecord // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$BagItemImpl implements _BagItem {
  const _$BagItemImpl(
      {@JsonKey(name: 'batch_no') required this.batchNo,
      @JsonKey(name: 'item_code') required this.itemCode,
      @JsonKey(name: 'item_name') this.itemName,
      this.qty = 0,
      @JsonKey(name: 'formula_name') this.formulaName,
      @JsonKey(name: 'production_datetime') this.productionDatetime,
      @JsonKey(name: 'machine_production_record')
      this.machineProductionRecord});

  factory _$BagItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$BagItemImplFromJson(json);

  @override
  @JsonKey(name: 'batch_no')
  final String batchNo;
  @override
  @JsonKey(name: 'item_code')
  final String itemCode;
  @override
  @JsonKey(name: 'item_name')
  final String? itemName;
  @override
  @JsonKey()
  final double qty;
  @override
  @JsonKey(name: 'formula_name')
  final String? formulaName;
  @override
  @JsonKey(name: 'production_datetime')
  final String? productionDatetime;
  @override
  @JsonKey(name: 'machine_production_record')
  final String? machineProductionRecord;

  @override
  String toString() {
    return 'BagItem(batchNo: $batchNo, itemCode: $itemCode, itemName: $itemName, qty: $qty, formulaName: $formulaName, productionDatetime: $productionDatetime, machineProductionRecord: $machineProductionRecord)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BagItemImpl &&
            (identical(other.batchNo, batchNo) || other.batchNo == batchNo) &&
            (identical(other.itemCode, itemCode) ||
                other.itemCode == itemCode) &&
            (identical(other.itemName, itemName) ||
                other.itemName == itemName) &&
            (identical(other.qty, qty) || other.qty == qty) &&
            (identical(other.formulaName, formulaName) ||
                other.formulaName == formulaName) &&
            (identical(other.productionDatetime, productionDatetime) ||
                other.productionDatetime == productionDatetime) &&
            (identical(
                    other.machineProductionRecord, machineProductionRecord) ||
                other.machineProductionRecord == machineProductionRecord));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, batchNo, itemCode, itemName, qty,
      formulaName, productionDatetime, machineProductionRecord);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$BagItemImplCopyWith<_$BagItemImpl> get copyWith =>
      __$$BagItemImplCopyWithImpl<_$BagItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BagItemImplToJson(
      this,
    );
  }
}

abstract class _BagItem implements BagItem {
  const factory _BagItem(
      {@JsonKey(name: 'batch_no') required final String batchNo,
      @JsonKey(name: 'item_code') required final String itemCode,
      @JsonKey(name: 'item_name') final String? itemName,
      final double qty,
      @JsonKey(name: 'formula_name') final String? formulaName,
      @JsonKey(name: 'production_datetime') final String? productionDatetime,
      @JsonKey(name: 'machine_production_record')
      final String? machineProductionRecord}) = _$BagItemImpl;

  factory _BagItem.fromJson(Map<String, dynamic> json) = _$BagItemImpl.fromJson;

  @override
  @JsonKey(name: 'batch_no')
  String get batchNo;
  @override
  @JsonKey(name: 'item_code')
  String get itemCode;
  @override
  @JsonKey(name: 'item_name')
  String? get itemName;
  @override
  double get qty;
  @override
  @JsonKey(name: 'formula_name')
  String? get formulaName;
  @override
  @JsonKey(name: 'production_datetime')
  String? get productionDatetime;
  @override
  @JsonKey(name: 'machine_production_record')
  String? get machineProductionRecord;
  @override
  @JsonKey(ignore: true)
  _$$BagItemImplCopyWith<_$BagItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

BagDetail _$BagDetailFromJson(Map<String, dynamic> json) {
  return _BagDetail.fromJson(json);
}

/// @nodoc
mixin _$BagDetail {
  @JsonKey(name: 'batch_no')
  String get batchNo => throw _privateConstructorUsedError;
  @JsonKey(name: 'item_code')
  String get itemCode => throw _privateConstructorUsedError;
  @JsonKey(name: 'item_name')
  String? get itemName => throw _privateConstructorUsedError;
  double get qty => throw _privateConstructorUsedError;
  @JsonKey(name: 'formula_name')
  String? get formulaName => throw _privateConstructorUsedError;
  @JsonKey(name: 'manufacturing_date')
  String? get manufacturingDate => throw _privateConstructorUsedError;
  @JsonKey(name: 'machine_production_record')
  String? get machineProductionRecord => throw _privateConstructorUsedError;
  @JsonKey(name: 'consume_items')
  List<ConsumeItem> get consumeItems => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $BagDetailCopyWith<BagDetail> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BagDetailCopyWith<$Res> {
  factory $BagDetailCopyWith(BagDetail value, $Res Function(BagDetail) then) =
      _$BagDetailCopyWithImpl<$Res, BagDetail>;
  @useResult
  $Res call(
      {@JsonKey(name: 'batch_no') String batchNo,
      @JsonKey(name: 'item_code') String itemCode,
      @JsonKey(name: 'item_name') String? itemName,
      double qty,
      @JsonKey(name: 'formula_name') String? formulaName,
      @JsonKey(name: 'manufacturing_date') String? manufacturingDate,
      @JsonKey(name: 'machine_production_record')
      String? machineProductionRecord,
      @JsonKey(name: 'consume_items') List<ConsumeItem> consumeItems});
}

/// @nodoc
class _$BagDetailCopyWithImpl<$Res, $Val extends BagDetail>
    implements $BagDetailCopyWith<$Res> {
  _$BagDetailCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? batchNo = null,
    Object? itemCode = null,
    Object? itemName = freezed,
    Object? qty = null,
    Object? formulaName = freezed,
    Object? manufacturingDate = freezed,
    Object? machineProductionRecord = freezed,
    Object? consumeItems = null,
  }) {
    return _then(_value.copyWith(
      batchNo: null == batchNo
          ? _value.batchNo
          : batchNo // ignore: cast_nullable_to_non_nullable
              as String,
      itemCode: null == itemCode
          ? _value.itemCode
          : itemCode // ignore: cast_nullable_to_non_nullable
              as String,
      itemName: freezed == itemName
          ? _value.itemName
          : itemName // ignore: cast_nullable_to_non_nullable
              as String?,
      qty: null == qty
          ? _value.qty
          : qty // ignore: cast_nullable_to_non_nullable
              as double,
      formulaName: freezed == formulaName
          ? _value.formulaName
          : formulaName // ignore: cast_nullable_to_non_nullable
              as String?,
      manufacturingDate: freezed == manufacturingDate
          ? _value.manufacturingDate
          : manufacturingDate // ignore: cast_nullable_to_non_nullable
              as String?,
      machineProductionRecord: freezed == machineProductionRecord
          ? _value.machineProductionRecord
          : machineProductionRecord // ignore: cast_nullable_to_non_nullable
              as String?,
      consumeItems: null == consumeItems
          ? _value.consumeItems
          : consumeItems // ignore: cast_nullable_to_non_nullable
              as List<ConsumeItem>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$BagDetailImplCopyWith<$Res>
    implements $BagDetailCopyWith<$Res> {
  factory _$$BagDetailImplCopyWith(
          _$BagDetailImpl value, $Res Function(_$BagDetailImpl) then) =
      __$$BagDetailImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'batch_no') String batchNo,
      @JsonKey(name: 'item_code') String itemCode,
      @JsonKey(name: 'item_name') String? itemName,
      double qty,
      @JsonKey(name: 'formula_name') String? formulaName,
      @JsonKey(name: 'manufacturing_date') String? manufacturingDate,
      @JsonKey(name: 'machine_production_record')
      String? machineProductionRecord,
      @JsonKey(name: 'consume_items') List<ConsumeItem> consumeItems});
}

/// @nodoc
class __$$BagDetailImplCopyWithImpl<$Res>
    extends _$BagDetailCopyWithImpl<$Res, _$BagDetailImpl>
    implements _$$BagDetailImplCopyWith<$Res> {
  __$$BagDetailImplCopyWithImpl(
      _$BagDetailImpl _value, $Res Function(_$BagDetailImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? batchNo = null,
    Object? itemCode = null,
    Object? itemName = freezed,
    Object? qty = null,
    Object? formulaName = freezed,
    Object? manufacturingDate = freezed,
    Object? machineProductionRecord = freezed,
    Object? consumeItems = null,
  }) {
    return _then(_$BagDetailImpl(
      batchNo: null == batchNo
          ? _value.batchNo
          : batchNo // ignore: cast_nullable_to_non_nullable
              as String,
      itemCode: null == itemCode
          ? _value.itemCode
          : itemCode // ignore: cast_nullable_to_non_nullable
              as String,
      itemName: freezed == itemName
          ? _value.itemName
          : itemName // ignore: cast_nullable_to_non_nullable
              as String?,
      qty: null == qty
          ? _value.qty
          : qty // ignore: cast_nullable_to_non_nullable
              as double,
      formulaName: freezed == formulaName
          ? _value.formulaName
          : formulaName // ignore: cast_nullable_to_non_nullable
              as String?,
      manufacturingDate: freezed == manufacturingDate
          ? _value.manufacturingDate
          : manufacturingDate // ignore: cast_nullable_to_non_nullable
              as String?,
      machineProductionRecord: freezed == machineProductionRecord
          ? _value.machineProductionRecord
          : machineProductionRecord // ignore: cast_nullable_to_non_nullable
              as String?,
      consumeItems: null == consumeItems
          ? _value._consumeItems
          : consumeItems // ignore: cast_nullable_to_non_nullable
              as List<ConsumeItem>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$BagDetailImpl implements _BagDetail {
  const _$BagDetailImpl(
      {@JsonKey(name: 'batch_no') required this.batchNo,
      @JsonKey(name: 'item_code') required this.itemCode,
      @JsonKey(name: 'item_name') this.itemName,
      this.qty = 0,
      @JsonKey(name: 'formula_name') this.formulaName,
      @JsonKey(name: 'manufacturing_date') this.manufacturingDate,
      @JsonKey(name: 'machine_production_record') this.machineProductionRecord,
      @JsonKey(name: 'consume_items')
      final List<ConsumeItem> consumeItems = const []})
      : _consumeItems = consumeItems;

  factory _$BagDetailImpl.fromJson(Map<String, dynamic> json) =>
      _$$BagDetailImplFromJson(json);

  @override
  @JsonKey(name: 'batch_no')
  final String batchNo;
  @override
  @JsonKey(name: 'item_code')
  final String itemCode;
  @override
  @JsonKey(name: 'item_name')
  final String? itemName;
  @override
  @JsonKey()
  final double qty;
  @override
  @JsonKey(name: 'formula_name')
  final String? formulaName;
  @override
  @JsonKey(name: 'manufacturing_date')
  final String? manufacturingDate;
  @override
  @JsonKey(name: 'machine_production_record')
  final String? machineProductionRecord;
  final List<ConsumeItem> _consumeItems;
  @override
  @JsonKey(name: 'consume_items')
  List<ConsumeItem> get consumeItems {
    if (_consumeItems is EqualUnmodifiableListView) return _consumeItems;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_consumeItems);
  }

  @override
  String toString() {
    return 'BagDetail(batchNo: $batchNo, itemCode: $itemCode, itemName: $itemName, qty: $qty, formulaName: $formulaName, manufacturingDate: $manufacturingDate, machineProductionRecord: $machineProductionRecord, consumeItems: $consumeItems)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BagDetailImpl &&
            (identical(other.batchNo, batchNo) || other.batchNo == batchNo) &&
            (identical(other.itemCode, itemCode) ||
                other.itemCode == itemCode) &&
            (identical(other.itemName, itemName) ||
                other.itemName == itemName) &&
            (identical(other.qty, qty) || other.qty == qty) &&
            (identical(other.formulaName, formulaName) ||
                other.formulaName == formulaName) &&
            (identical(other.manufacturingDate, manufacturingDate) ||
                other.manufacturingDate == manufacturingDate) &&
            (identical(
                    other.machineProductionRecord, machineProductionRecord) ||
                other.machineProductionRecord == machineProductionRecord) &&
            const DeepCollectionEquality()
                .equals(other._consumeItems, _consumeItems));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      batchNo,
      itemCode,
      itemName,
      qty,
      formulaName,
      manufacturingDate,
      machineProductionRecord,
      const DeepCollectionEquality().hash(_consumeItems));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$BagDetailImplCopyWith<_$BagDetailImpl> get copyWith =>
      __$$BagDetailImplCopyWithImpl<_$BagDetailImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BagDetailImplToJson(
      this,
    );
  }
}

abstract class _BagDetail implements BagDetail {
  const factory _BagDetail(
      {@JsonKey(name: 'batch_no') required final String batchNo,
      @JsonKey(name: 'item_code') required final String itemCode,
      @JsonKey(name: 'item_name') final String? itemName,
      final double qty,
      @JsonKey(name: 'formula_name') final String? formulaName,
      @JsonKey(name: 'manufacturing_date') final String? manufacturingDate,
      @JsonKey(name: 'machine_production_record')
      final String? machineProductionRecord,
      @JsonKey(name: 'consume_items')
      final List<ConsumeItem> consumeItems}) = _$BagDetailImpl;

  factory _BagDetail.fromJson(Map<String, dynamic> json) =
      _$BagDetailImpl.fromJson;

  @override
  @JsonKey(name: 'batch_no')
  String get batchNo;
  @override
  @JsonKey(name: 'item_code')
  String get itemCode;
  @override
  @JsonKey(name: 'item_name')
  String? get itemName;
  @override
  double get qty;
  @override
  @JsonKey(name: 'formula_name')
  String? get formulaName;
  @override
  @JsonKey(name: 'manufacturing_date')
  String? get manufacturingDate;
  @override
  @JsonKey(name: 'machine_production_record')
  String? get machineProductionRecord;
  @override
  @JsonKey(name: 'consume_items')
  List<ConsumeItem> get consumeItems;
  @override
  @JsonKey(ignore: true)
  _$$BagDetailImplCopyWith<_$BagDetailImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ConsumeItem _$ConsumeItemFromJson(Map<String, dynamic> json) {
  return _ConsumeItem.fromJson(json);
}

/// @nodoc
mixin _$ConsumeItem {
  @JsonKey(name: 'item_code')
  String get itemCode => throw _privateConstructorUsedError;
  @JsonKey(name: 'item_name')
  String? get itemName => throw _privateConstructorUsedError;
  @JsonKey(name: 'batch_no')
  String? get batchNo => throw _privateConstructorUsedError;
  double get qty => throw _privateConstructorUsedError;
  String? get warehouse => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ConsumeItemCopyWith<ConsumeItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ConsumeItemCopyWith<$Res> {
  factory $ConsumeItemCopyWith(
          ConsumeItem value, $Res Function(ConsumeItem) then) =
      _$ConsumeItemCopyWithImpl<$Res, ConsumeItem>;
  @useResult
  $Res call(
      {@JsonKey(name: 'item_code') String itemCode,
      @JsonKey(name: 'item_name') String? itemName,
      @JsonKey(name: 'batch_no') String? batchNo,
      double qty,
      String? warehouse});
}

/// @nodoc
class _$ConsumeItemCopyWithImpl<$Res, $Val extends ConsumeItem>
    implements $ConsumeItemCopyWith<$Res> {
  _$ConsumeItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? itemCode = null,
    Object? itemName = freezed,
    Object? batchNo = freezed,
    Object? qty = null,
    Object? warehouse = freezed,
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
      batchNo: freezed == batchNo
          ? _value.batchNo
          : batchNo // ignore: cast_nullable_to_non_nullable
              as String?,
      qty: null == qty
          ? _value.qty
          : qty // ignore: cast_nullable_to_non_nullable
              as double,
      warehouse: freezed == warehouse
          ? _value.warehouse
          : warehouse // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ConsumeItemImplCopyWith<$Res>
    implements $ConsumeItemCopyWith<$Res> {
  factory _$$ConsumeItemImplCopyWith(
          _$ConsumeItemImpl value, $Res Function(_$ConsumeItemImpl) then) =
      __$$ConsumeItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'item_code') String itemCode,
      @JsonKey(name: 'item_name') String? itemName,
      @JsonKey(name: 'batch_no') String? batchNo,
      double qty,
      String? warehouse});
}

/// @nodoc
class __$$ConsumeItemImplCopyWithImpl<$Res>
    extends _$ConsumeItemCopyWithImpl<$Res, _$ConsumeItemImpl>
    implements _$$ConsumeItemImplCopyWith<$Res> {
  __$$ConsumeItemImplCopyWithImpl(
      _$ConsumeItemImpl _value, $Res Function(_$ConsumeItemImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? itemCode = null,
    Object? itemName = freezed,
    Object? batchNo = freezed,
    Object? qty = null,
    Object? warehouse = freezed,
  }) {
    return _then(_$ConsumeItemImpl(
      itemCode: null == itemCode
          ? _value.itemCode
          : itemCode // ignore: cast_nullable_to_non_nullable
              as String,
      itemName: freezed == itemName
          ? _value.itemName
          : itemName // ignore: cast_nullable_to_non_nullable
              as String?,
      batchNo: freezed == batchNo
          ? _value.batchNo
          : batchNo // ignore: cast_nullable_to_non_nullable
              as String?,
      qty: null == qty
          ? _value.qty
          : qty // ignore: cast_nullable_to_non_nullable
              as double,
      warehouse: freezed == warehouse
          ? _value.warehouse
          : warehouse // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ConsumeItemImpl implements _ConsumeItem {
  const _$ConsumeItemImpl(
      {@JsonKey(name: 'item_code') required this.itemCode,
      @JsonKey(name: 'item_name') this.itemName,
      @JsonKey(name: 'batch_no') this.batchNo,
      this.qty = 0,
      this.warehouse});

  factory _$ConsumeItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$ConsumeItemImplFromJson(json);

  @override
  @JsonKey(name: 'item_code')
  final String itemCode;
  @override
  @JsonKey(name: 'item_name')
  final String? itemName;
  @override
  @JsonKey(name: 'batch_no')
  final String? batchNo;
  @override
  @JsonKey()
  final double qty;
  @override
  final String? warehouse;

  @override
  String toString() {
    return 'ConsumeItem(itemCode: $itemCode, itemName: $itemName, batchNo: $batchNo, qty: $qty, warehouse: $warehouse)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ConsumeItemImpl &&
            (identical(other.itemCode, itemCode) ||
                other.itemCode == itemCode) &&
            (identical(other.itemName, itemName) ||
                other.itemName == itemName) &&
            (identical(other.batchNo, batchNo) || other.batchNo == batchNo) &&
            (identical(other.qty, qty) || other.qty == qty) &&
            (identical(other.warehouse, warehouse) ||
                other.warehouse == warehouse));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, itemCode, itemName, batchNo, qty, warehouse);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ConsumeItemImplCopyWith<_$ConsumeItemImpl> get copyWith =>
      __$$ConsumeItemImplCopyWithImpl<_$ConsumeItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ConsumeItemImplToJson(
      this,
    );
  }
}

abstract class _ConsumeItem implements ConsumeItem {
  const factory _ConsumeItem(
      {@JsonKey(name: 'item_code') required final String itemCode,
      @JsonKey(name: 'item_name') final String? itemName,
      @JsonKey(name: 'batch_no') final String? batchNo,
      final double qty,
      final String? warehouse}) = _$ConsumeItemImpl;

  factory _ConsumeItem.fromJson(Map<String, dynamic> json) =
      _$ConsumeItemImpl.fromJson;

  @override
  @JsonKey(name: 'item_code')
  String get itemCode;
  @override
  @JsonKey(name: 'item_name')
  String? get itemName;
  @override
  @JsonKey(name: 'batch_no')
  String? get batchNo;
  @override
  double get qty;
  @override
  String? get warehouse;
  @override
  @JsonKey(ignore: true)
  _$$ConsumeItemImplCopyWith<_$ConsumeItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

FmbBatch _$FmbBatchFromJson(Map<String, dynamic> json) {
  return _FmbBatch.fromJson(json);
}

/// @nodoc
mixin _$FmbBatch {
  @JsonKey(name: 'batch_no')
  String get batchNo => throw _privateConstructorUsedError;
  @JsonKey(name: 'item_code')
  String get itemCode => throw _privateConstructorUsedError;
  @JsonKey(name: 'item_name')
  String? get itemName => throw _privateConstructorUsedError;
  double get qty => throw _privateConstructorUsedError;
  @JsonKey(name: 'lab_status')
  String get labStatus => throw _privateConstructorUsedError;
  @JsonKey(name: 'compound_type')
  String get compoundType => throw _privateConstructorUsedError;
  @JsonKey(name: 'manufacturing_date')
  String? get manufacturingDate => throw _privateConstructorUsedError;
  @JsonKey(name: 'formula_name')
  String? get formulaName => throw _privateConstructorUsedError;
  @JsonKey(name: 'formula_code')
  String? get formulaCode => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $FmbBatchCopyWith<FmbBatch> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FmbBatchCopyWith<$Res> {
  factory $FmbBatchCopyWith(FmbBatch value, $Res Function(FmbBatch) then) =
      _$FmbBatchCopyWithImpl<$Res, FmbBatch>;
  @useResult
  $Res call(
      {@JsonKey(name: 'batch_no') String batchNo,
      @JsonKey(name: 'item_code') String itemCode,
      @JsonKey(name: 'item_name') String? itemName,
      double qty,
      @JsonKey(name: 'lab_status') String labStatus,
      @JsonKey(name: 'compound_type') String compoundType,
      @JsonKey(name: 'manufacturing_date') String? manufacturingDate,
      @JsonKey(name: 'formula_name') String? formulaName,
      @JsonKey(name: 'formula_code') String? formulaCode});
}

/// @nodoc
class _$FmbBatchCopyWithImpl<$Res, $Val extends FmbBatch>
    implements $FmbBatchCopyWith<$Res> {
  _$FmbBatchCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? batchNo = null,
    Object? itemCode = null,
    Object? itemName = freezed,
    Object? qty = null,
    Object? labStatus = null,
    Object? compoundType = null,
    Object? manufacturingDate = freezed,
    Object? formulaName = freezed,
    Object? formulaCode = freezed,
  }) {
    return _then(_value.copyWith(
      batchNo: null == batchNo
          ? _value.batchNo
          : batchNo // ignore: cast_nullable_to_non_nullable
              as String,
      itemCode: null == itemCode
          ? _value.itemCode
          : itemCode // ignore: cast_nullable_to_non_nullable
              as String,
      itemName: freezed == itemName
          ? _value.itemName
          : itemName // ignore: cast_nullable_to_non_nullable
              as String?,
      qty: null == qty
          ? _value.qty
          : qty // ignore: cast_nullable_to_non_nullable
              as double,
      labStatus: null == labStatus
          ? _value.labStatus
          : labStatus // ignore: cast_nullable_to_non_nullable
              as String,
      compoundType: null == compoundType
          ? _value.compoundType
          : compoundType // ignore: cast_nullable_to_non_nullable
              as String,
      manufacturingDate: freezed == manufacturingDate
          ? _value.manufacturingDate
          : manufacturingDate // ignore: cast_nullable_to_non_nullable
              as String?,
      formulaName: freezed == formulaName
          ? _value.formulaName
          : formulaName // ignore: cast_nullable_to_non_nullable
              as String?,
      formulaCode: freezed == formulaCode
          ? _value.formulaCode
          : formulaCode // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FmbBatchImplCopyWith<$Res>
    implements $FmbBatchCopyWith<$Res> {
  factory _$$FmbBatchImplCopyWith(
          _$FmbBatchImpl value, $Res Function(_$FmbBatchImpl) then) =
      __$$FmbBatchImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'batch_no') String batchNo,
      @JsonKey(name: 'item_code') String itemCode,
      @JsonKey(name: 'item_name') String? itemName,
      double qty,
      @JsonKey(name: 'lab_status') String labStatus,
      @JsonKey(name: 'compound_type') String compoundType,
      @JsonKey(name: 'manufacturing_date') String? manufacturingDate,
      @JsonKey(name: 'formula_name') String? formulaName,
      @JsonKey(name: 'formula_code') String? formulaCode});
}

/// @nodoc
class __$$FmbBatchImplCopyWithImpl<$Res>
    extends _$FmbBatchCopyWithImpl<$Res, _$FmbBatchImpl>
    implements _$$FmbBatchImplCopyWith<$Res> {
  __$$FmbBatchImplCopyWithImpl(
      _$FmbBatchImpl _value, $Res Function(_$FmbBatchImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? batchNo = null,
    Object? itemCode = null,
    Object? itemName = freezed,
    Object? qty = null,
    Object? labStatus = null,
    Object? compoundType = null,
    Object? manufacturingDate = freezed,
    Object? formulaName = freezed,
    Object? formulaCode = freezed,
  }) {
    return _then(_$FmbBatchImpl(
      batchNo: null == batchNo
          ? _value.batchNo
          : batchNo // ignore: cast_nullable_to_non_nullable
              as String,
      itemCode: null == itemCode
          ? _value.itemCode
          : itemCode // ignore: cast_nullable_to_non_nullable
              as String,
      itemName: freezed == itemName
          ? _value.itemName
          : itemName // ignore: cast_nullable_to_non_nullable
              as String?,
      qty: null == qty
          ? _value.qty
          : qty // ignore: cast_nullable_to_non_nullable
              as double,
      labStatus: null == labStatus
          ? _value.labStatus
          : labStatus // ignore: cast_nullable_to_non_nullable
              as String,
      compoundType: null == compoundType
          ? _value.compoundType
          : compoundType // ignore: cast_nullable_to_non_nullable
              as String,
      manufacturingDate: freezed == manufacturingDate
          ? _value.manufacturingDate
          : manufacturingDate // ignore: cast_nullable_to_non_nullable
              as String?,
      formulaName: freezed == formulaName
          ? _value.formulaName
          : formulaName // ignore: cast_nullable_to_non_nullable
              as String?,
      formulaCode: freezed == formulaCode
          ? _value.formulaCode
          : formulaCode // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FmbBatchImpl implements _FmbBatch {
  const _$FmbBatchImpl(
      {@JsonKey(name: 'batch_no') required this.batchNo,
      @JsonKey(name: 'item_code') required this.itemCode,
      @JsonKey(name: 'item_name') this.itemName,
      this.qty = 0,
      @JsonKey(name: 'lab_status') this.labStatus = 'Pending',
      @JsonKey(name: 'compound_type') this.compoundType = 'FMB',
      @JsonKey(name: 'manufacturing_date') this.manufacturingDate,
      @JsonKey(name: 'formula_name') this.formulaName,
      @JsonKey(name: 'formula_code') this.formulaCode});

  factory _$FmbBatchImpl.fromJson(Map<String, dynamic> json) =>
      _$$FmbBatchImplFromJson(json);

  @override
  @JsonKey(name: 'batch_no')
  final String batchNo;
  @override
  @JsonKey(name: 'item_code')
  final String itemCode;
  @override
  @JsonKey(name: 'item_name')
  final String? itemName;
  @override
  @JsonKey()
  final double qty;
  @override
  @JsonKey(name: 'lab_status')
  final String labStatus;
  @override
  @JsonKey(name: 'compound_type')
  final String compoundType;
  @override
  @JsonKey(name: 'manufacturing_date')
  final String? manufacturingDate;
  @override
  @JsonKey(name: 'formula_name')
  final String? formulaName;
  @override
  @JsonKey(name: 'formula_code')
  final String? formulaCode;

  @override
  String toString() {
    return 'FmbBatch(batchNo: $batchNo, itemCode: $itemCode, itemName: $itemName, qty: $qty, labStatus: $labStatus, compoundType: $compoundType, manufacturingDate: $manufacturingDate, formulaName: $formulaName, formulaCode: $formulaCode)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FmbBatchImpl &&
            (identical(other.batchNo, batchNo) || other.batchNo == batchNo) &&
            (identical(other.itemCode, itemCode) ||
                other.itemCode == itemCode) &&
            (identical(other.itemName, itemName) ||
                other.itemName == itemName) &&
            (identical(other.qty, qty) || other.qty == qty) &&
            (identical(other.labStatus, labStatus) ||
                other.labStatus == labStatus) &&
            (identical(other.compoundType, compoundType) ||
                other.compoundType == compoundType) &&
            (identical(other.manufacturingDate, manufacturingDate) ||
                other.manufacturingDate == manufacturingDate) &&
            (identical(other.formulaName, formulaName) ||
                other.formulaName == formulaName) &&
            (identical(other.formulaCode, formulaCode) ||
                other.formulaCode == formulaCode));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, batchNo, itemCode, itemName, qty,
      labStatus, compoundType, manufacturingDate, formulaName, formulaCode);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$FmbBatchImplCopyWith<_$FmbBatchImpl> get copyWith =>
      __$$FmbBatchImplCopyWithImpl<_$FmbBatchImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FmbBatchImplToJson(
      this,
    );
  }
}

abstract class _FmbBatch implements FmbBatch {
  const factory _FmbBatch(
          {@JsonKey(name: 'batch_no') required final String batchNo,
          @JsonKey(name: 'item_code') required final String itemCode,
          @JsonKey(name: 'item_name') final String? itemName,
          final double qty,
          @JsonKey(name: 'lab_status') final String labStatus,
          @JsonKey(name: 'compound_type') final String compoundType,
          @JsonKey(name: 'manufacturing_date') final String? manufacturingDate,
          @JsonKey(name: 'formula_name') final String? formulaName,
          @JsonKey(name: 'formula_code') final String? formulaCode}) =
      _$FmbBatchImpl;

  factory _FmbBatch.fromJson(Map<String, dynamic> json) =
      _$FmbBatchImpl.fromJson;

  @override
  @JsonKey(name: 'batch_no')
  String get batchNo;
  @override
  @JsonKey(name: 'item_code')
  String get itemCode;
  @override
  @JsonKey(name: 'item_name')
  String? get itemName;
  @override
  double get qty;
  @override
  @JsonKey(name: 'lab_status')
  String get labStatus;
  @override
  @JsonKey(name: 'compound_type')
  String get compoundType;
  @override
  @JsonKey(name: 'manufacturing_date')
  String? get manufacturingDate;
  @override
  @JsonKey(name: 'formula_name')
  String? get formulaName;
  @override
  @JsonKey(name: 'formula_code')
  String? get formulaCode;
  @override
  @JsonKey(ignore: true)
  _$$FmbBatchImplCopyWith<_$FmbBatchImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

FmbDetail _$FmbDetailFromJson(Map<String, dynamic> json) {
  return _FmbDetail.fromJson(json);
}

/// @nodoc
mixin _$FmbDetail {
  @JsonKey(name: 'batch_no')
  String get batchNo => throw _privateConstructorUsedError;
  @JsonKey(name: 'item_code')
  String get itemCode => throw _privateConstructorUsedError;
  @JsonKey(name: 'item_name')
  String? get itemName => throw _privateConstructorUsedError;
  double get qty => throw _privateConstructorUsedError;
  @JsonKey(name: 'lab_status')
  String get labStatus => throw _privateConstructorUsedError;
  @JsonKey(name: 'manufacturing_date')
  String? get manufacturingDate => throw _privateConstructorUsedError;
  @JsonKey(name: 'formula_name')
  String? get formulaName => throw _privateConstructorUsedError;
  @JsonKey(name: 'formula_code')
  String? get formulaCode => throw _privateConstructorUsedError;
  @JsonKey(name: 'lab_test')
  LabTestInfo? get labTest => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $FmbDetailCopyWith<FmbDetail> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FmbDetailCopyWith<$Res> {
  factory $FmbDetailCopyWith(FmbDetail value, $Res Function(FmbDetail) then) =
      _$FmbDetailCopyWithImpl<$Res, FmbDetail>;
  @useResult
  $Res call(
      {@JsonKey(name: 'batch_no') String batchNo,
      @JsonKey(name: 'item_code') String itemCode,
      @JsonKey(name: 'item_name') String? itemName,
      double qty,
      @JsonKey(name: 'lab_status') String labStatus,
      @JsonKey(name: 'manufacturing_date') String? manufacturingDate,
      @JsonKey(name: 'formula_name') String? formulaName,
      @JsonKey(name: 'formula_code') String? formulaCode,
      @JsonKey(name: 'lab_test') LabTestInfo? labTest});

  $LabTestInfoCopyWith<$Res>? get labTest;
}

/// @nodoc
class _$FmbDetailCopyWithImpl<$Res, $Val extends FmbDetail>
    implements $FmbDetailCopyWith<$Res> {
  _$FmbDetailCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? batchNo = null,
    Object? itemCode = null,
    Object? itemName = freezed,
    Object? qty = null,
    Object? labStatus = null,
    Object? manufacturingDate = freezed,
    Object? formulaName = freezed,
    Object? formulaCode = freezed,
    Object? labTest = freezed,
  }) {
    return _then(_value.copyWith(
      batchNo: null == batchNo
          ? _value.batchNo
          : batchNo // ignore: cast_nullable_to_non_nullable
              as String,
      itemCode: null == itemCode
          ? _value.itemCode
          : itemCode // ignore: cast_nullable_to_non_nullable
              as String,
      itemName: freezed == itemName
          ? _value.itemName
          : itemName // ignore: cast_nullable_to_non_nullable
              as String?,
      qty: null == qty
          ? _value.qty
          : qty // ignore: cast_nullable_to_non_nullable
              as double,
      labStatus: null == labStatus
          ? _value.labStatus
          : labStatus // ignore: cast_nullable_to_non_nullable
              as String,
      manufacturingDate: freezed == manufacturingDate
          ? _value.manufacturingDate
          : manufacturingDate // ignore: cast_nullable_to_non_nullable
              as String?,
      formulaName: freezed == formulaName
          ? _value.formulaName
          : formulaName // ignore: cast_nullable_to_non_nullable
              as String?,
      formulaCode: freezed == formulaCode
          ? _value.formulaCode
          : formulaCode // ignore: cast_nullable_to_non_nullable
              as String?,
      labTest: freezed == labTest
          ? _value.labTest
          : labTest // ignore: cast_nullable_to_non_nullable
              as LabTestInfo?,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $LabTestInfoCopyWith<$Res>? get labTest {
    if (_value.labTest == null) {
      return null;
    }

    return $LabTestInfoCopyWith<$Res>(_value.labTest!, (value) {
      return _then(_value.copyWith(labTest: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$FmbDetailImplCopyWith<$Res>
    implements $FmbDetailCopyWith<$Res> {
  factory _$$FmbDetailImplCopyWith(
          _$FmbDetailImpl value, $Res Function(_$FmbDetailImpl) then) =
      __$$FmbDetailImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'batch_no') String batchNo,
      @JsonKey(name: 'item_code') String itemCode,
      @JsonKey(name: 'item_name') String? itemName,
      double qty,
      @JsonKey(name: 'lab_status') String labStatus,
      @JsonKey(name: 'manufacturing_date') String? manufacturingDate,
      @JsonKey(name: 'formula_name') String? formulaName,
      @JsonKey(name: 'formula_code') String? formulaCode,
      @JsonKey(name: 'lab_test') LabTestInfo? labTest});

  @override
  $LabTestInfoCopyWith<$Res>? get labTest;
}

/// @nodoc
class __$$FmbDetailImplCopyWithImpl<$Res>
    extends _$FmbDetailCopyWithImpl<$Res, _$FmbDetailImpl>
    implements _$$FmbDetailImplCopyWith<$Res> {
  __$$FmbDetailImplCopyWithImpl(
      _$FmbDetailImpl _value, $Res Function(_$FmbDetailImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? batchNo = null,
    Object? itemCode = null,
    Object? itemName = freezed,
    Object? qty = null,
    Object? labStatus = null,
    Object? manufacturingDate = freezed,
    Object? formulaName = freezed,
    Object? formulaCode = freezed,
    Object? labTest = freezed,
  }) {
    return _then(_$FmbDetailImpl(
      batchNo: null == batchNo
          ? _value.batchNo
          : batchNo // ignore: cast_nullable_to_non_nullable
              as String,
      itemCode: null == itemCode
          ? _value.itemCode
          : itemCode // ignore: cast_nullable_to_non_nullable
              as String,
      itemName: freezed == itemName
          ? _value.itemName
          : itemName // ignore: cast_nullable_to_non_nullable
              as String?,
      qty: null == qty
          ? _value.qty
          : qty // ignore: cast_nullable_to_non_nullable
              as double,
      labStatus: null == labStatus
          ? _value.labStatus
          : labStatus // ignore: cast_nullable_to_non_nullable
              as String,
      manufacturingDate: freezed == manufacturingDate
          ? _value.manufacturingDate
          : manufacturingDate // ignore: cast_nullable_to_non_nullable
              as String?,
      formulaName: freezed == formulaName
          ? _value.formulaName
          : formulaName // ignore: cast_nullable_to_non_nullable
              as String?,
      formulaCode: freezed == formulaCode
          ? _value.formulaCode
          : formulaCode // ignore: cast_nullable_to_non_nullable
              as String?,
      labTest: freezed == labTest
          ? _value.labTest
          : labTest // ignore: cast_nullable_to_non_nullable
              as LabTestInfo?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FmbDetailImpl implements _FmbDetail {
  const _$FmbDetailImpl(
      {@JsonKey(name: 'batch_no') required this.batchNo,
      @JsonKey(name: 'item_code') required this.itemCode,
      @JsonKey(name: 'item_name') this.itemName,
      this.qty = 0,
      @JsonKey(name: 'lab_status') this.labStatus = 'Pending',
      @JsonKey(name: 'manufacturing_date') this.manufacturingDate,
      @JsonKey(name: 'formula_name') this.formulaName,
      @JsonKey(name: 'formula_code') this.formulaCode,
      @JsonKey(name: 'lab_test') this.labTest});

  factory _$FmbDetailImpl.fromJson(Map<String, dynamic> json) =>
      _$$FmbDetailImplFromJson(json);

  @override
  @JsonKey(name: 'batch_no')
  final String batchNo;
  @override
  @JsonKey(name: 'item_code')
  final String itemCode;
  @override
  @JsonKey(name: 'item_name')
  final String? itemName;
  @override
  @JsonKey()
  final double qty;
  @override
  @JsonKey(name: 'lab_status')
  final String labStatus;
  @override
  @JsonKey(name: 'manufacturing_date')
  final String? manufacturingDate;
  @override
  @JsonKey(name: 'formula_name')
  final String? formulaName;
  @override
  @JsonKey(name: 'formula_code')
  final String? formulaCode;
  @override
  @JsonKey(name: 'lab_test')
  final LabTestInfo? labTest;

  @override
  String toString() {
    return 'FmbDetail(batchNo: $batchNo, itemCode: $itemCode, itemName: $itemName, qty: $qty, labStatus: $labStatus, manufacturingDate: $manufacturingDate, formulaName: $formulaName, formulaCode: $formulaCode, labTest: $labTest)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FmbDetailImpl &&
            (identical(other.batchNo, batchNo) || other.batchNo == batchNo) &&
            (identical(other.itemCode, itemCode) ||
                other.itemCode == itemCode) &&
            (identical(other.itemName, itemName) ||
                other.itemName == itemName) &&
            (identical(other.qty, qty) || other.qty == qty) &&
            (identical(other.labStatus, labStatus) ||
                other.labStatus == labStatus) &&
            (identical(other.manufacturingDate, manufacturingDate) ||
                other.manufacturingDate == manufacturingDate) &&
            (identical(other.formulaName, formulaName) ||
                other.formulaName == formulaName) &&
            (identical(other.formulaCode, formulaCode) ||
                other.formulaCode == formulaCode) &&
            (identical(other.labTest, labTest) || other.labTest == labTest));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, batchNo, itemCode, itemName, qty,
      labStatus, manufacturingDate, formulaName, formulaCode, labTest);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$FmbDetailImplCopyWith<_$FmbDetailImpl> get copyWith =>
      __$$FmbDetailImplCopyWithImpl<_$FmbDetailImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FmbDetailImplToJson(
      this,
    );
  }
}

abstract class _FmbDetail implements FmbDetail {
  const factory _FmbDetail(
      {@JsonKey(name: 'batch_no') required final String batchNo,
      @JsonKey(name: 'item_code') required final String itemCode,
      @JsonKey(name: 'item_name') final String? itemName,
      final double qty,
      @JsonKey(name: 'lab_status') final String labStatus,
      @JsonKey(name: 'manufacturing_date') final String? manufacturingDate,
      @JsonKey(name: 'formula_name') final String? formulaName,
      @JsonKey(name: 'formula_code') final String? formulaCode,
      @JsonKey(name: 'lab_test') final LabTestInfo? labTest}) = _$FmbDetailImpl;

  factory _FmbDetail.fromJson(Map<String, dynamic> json) =
      _$FmbDetailImpl.fromJson;

  @override
  @JsonKey(name: 'batch_no')
  String get batchNo;
  @override
  @JsonKey(name: 'item_code')
  String get itemCode;
  @override
  @JsonKey(name: 'item_name')
  String? get itemName;
  @override
  double get qty;
  @override
  @JsonKey(name: 'lab_status')
  String get labStatus;
  @override
  @JsonKey(name: 'manufacturing_date')
  String? get manufacturingDate;
  @override
  @JsonKey(name: 'formula_name')
  String? get formulaName;
  @override
  @JsonKey(name: 'formula_code')
  String? get formulaCode;
  @override
  @JsonKey(name: 'lab_test')
  LabTestInfo? get labTest;
  @override
  @JsonKey(ignore: true)
  _$$FmbDetailImplCopyWith<_$FmbDetailImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

LabTestInfo _$LabTestInfoFromJson(Map<String, dynamic> json) {
  return _LabTestInfo.fromJson(json);
}

/// @nodoc
mixin _$LabTestInfo {
  String get name => throw _privateConstructorUsedError;
  String get result => throw _privateConstructorUsedError;
  @JsonKey(name: 'tested_by')
  String? get testedBy => throw _privateConstructorUsedError;
  @JsonKey(name: 'tested_on')
  String? get testedOn => throw _privateConstructorUsedError;
  int get docstatus => throw _privateConstructorUsedError;
  List<LabTestParameter> get parameters => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $LabTestInfoCopyWith<LabTestInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LabTestInfoCopyWith<$Res> {
  factory $LabTestInfoCopyWith(
          LabTestInfo value, $Res Function(LabTestInfo) then) =
      _$LabTestInfoCopyWithImpl<$Res, LabTestInfo>;
  @useResult
  $Res call(
      {String name,
      String result,
      @JsonKey(name: 'tested_by') String? testedBy,
      @JsonKey(name: 'tested_on') String? testedOn,
      int docstatus,
      List<LabTestParameter> parameters});
}

/// @nodoc
class _$LabTestInfoCopyWithImpl<$Res, $Val extends LabTestInfo>
    implements $LabTestInfoCopyWith<$Res> {
  _$LabTestInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? result = null,
    Object? testedBy = freezed,
    Object? testedOn = freezed,
    Object? docstatus = null,
    Object? parameters = null,
  }) {
    return _then(_value.copyWith(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      result: null == result
          ? _value.result
          : result // ignore: cast_nullable_to_non_nullable
              as String,
      testedBy: freezed == testedBy
          ? _value.testedBy
          : testedBy // ignore: cast_nullable_to_non_nullable
              as String?,
      testedOn: freezed == testedOn
          ? _value.testedOn
          : testedOn // ignore: cast_nullable_to_non_nullable
              as String?,
      docstatus: null == docstatus
          ? _value.docstatus
          : docstatus // ignore: cast_nullable_to_non_nullable
              as int,
      parameters: null == parameters
          ? _value.parameters
          : parameters // ignore: cast_nullable_to_non_nullable
              as List<LabTestParameter>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$LabTestInfoImplCopyWith<$Res>
    implements $LabTestInfoCopyWith<$Res> {
  factory _$$LabTestInfoImplCopyWith(
          _$LabTestInfoImpl value, $Res Function(_$LabTestInfoImpl) then) =
      __$$LabTestInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String name,
      String result,
      @JsonKey(name: 'tested_by') String? testedBy,
      @JsonKey(name: 'tested_on') String? testedOn,
      int docstatus,
      List<LabTestParameter> parameters});
}

/// @nodoc
class __$$LabTestInfoImplCopyWithImpl<$Res>
    extends _$LabTestInfoCopyWithImpl<$Res, _$LabTestInfoImpl>
    implements _$$LabTestInfoImplCopyWith<$Res> {
  __$$LabTestInfoImplCopyWithImpl(
      _$LabTestInfoImpl _value, $Res Function(_$LabTestInfoImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? result = null,
    Object? testedBy = freezed,
    Object? testedOn = freezed,
    Object? docstatus = null,
    Object? parameters = null,
  }) {
    return _then(_$LabTestInfoImpl(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      result: null == result
          ? _value.result
          : result // ignore: cast_nullable_to_non_nullable
              as String,
      testedBy: freezed == testedBy
          ? _value.testedBy
          : testedBy // ignore: cast_nullable_to_non_nullable
              as String?,
      testedOn: freezed == testedOn
          ? _value.testedOn
          : testedOn // ignore: cast_nullable_to_non_nullable
              as String?,
      docstatus: null == docstatus
          ? _value.docstatus
          : docstatus // ignore: cast_nullable_to_non_nullable
              as int,
      parameters: null == parameters
          ? _value._parameters
          : parameters // ignore: cast_nullable_to_non_nullable
              as List<LabTestParameter>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LabTestInfoImpl implements _LabTestInfo {
  const _$LabTestInfoImpl(
      {required this.name,
      this.result = 'Pending',
      @JsonKey(name: 'tested_by') this.testedBy,
      @JsonKey(name: 'tested_on') this.testedOn,
      this.docstatus = 0,
      final List<LabTestParameter> parameters = const []})
      : _parameters = parameters;

  factory _$LabTestInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$LabTestInfoImplFromJson(json);

  @override
  final String name;
  @override
  @JsonKey()
  final String result;
  @override
  @JsonKey(name: 'tested_by')
  final String? testedBy;
  @override
  @JsonKey(name: 'tested_on')
  final String? testedOn;
  @override
  @JsonKey()
  final int docstatus;
  final List<LabTestParameter> _parameters;
  @override
  @JsonKey()
  List<LabTestParameter> get parameters {
    if (_parameters is EqualUnmodifiableListView) return _parameters;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_parameters);
  }

  @override
  String toString() {
    return 'LabTestInfo(name: $name, result: $result, testedBy: $testedBy, testedOn: $testedOn, docstatus: $docstatus, parameters: $parameters)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LabTestInfoImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.result, result) || other.result == result) &&
            (identical(other.testedBy, testedBy) ||
                other.testedBy == testedBy) &&
            (identical(other.testedOn, testedOn) ||
                other.testedOn == testedOn) &&
            (identical(other.docstatus, docstatus) ||
                other.docstatus == docstatus) &&
            const DeepCollectionEquality()
                .equals(other._parameters, _parameters));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, name, result, testedBy, testedOn,
      docstatus, const DeepCollectionEquality().hash(_parameters));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$LabTestInfoImplCopyWith<_$LabTestInfoImpl> get copyWith =>
      __$$LabTestInfoImplCopyWithImpl<_$LabTestInfoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LabTestInfoImplToJson(
      this,
    );
  }
}

abstract class _LabTestInfo implements LabTestInfo {
  const factory _LabTestInfo(
      {required final String name,
      final String result,
      @JsonKey(name: 'tested_by') final String? testedBy,
      @JsonKey(name: 'tested_on') final String? testedOn,
      final int docstatus,
      final List<LabTestParameter> parameters}) = _$LabTestInfoImpl;

  factory _LabTestInfo.fromJson(Map<String, dynamic> json) =
      _$LabTestInfoImpl.fromJson;

  @override
  String get name;
  @override
  String get result;
  @override
  @JsonKey(name: 'tested_by')
  String? get testedBy;
  @override
  @JsonKey(name: 'tested_on')
  String? get testedOn;
  @override
  int get docstatus;
  @override
  List<LabTestParameter> get parameters;
  @override
  @JsonKey(ignore: true)
  _$$LabTestInfoImplCopyWith<_$LabTestInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

LabTestParameter _$LabTestParameterFromJson(Map<String, dynamic> json) {
  return _LabTestParameter.fromJson(json);
}

/// @nodoc
mixin _$LabTestParameter {
  @JsonKey(name: 'parameter_name')
  String get parameterName => throw _privateConstructorUsedError;
  @JsonKey(name: 'expected_min')
  double get expectedMin => throw _privateConstructorUsedError;
  @JsonKey(name: 'expected_max')
  double get expectedMax => throw _privateConstructorUsedError;
  @JsonKey(name: 'result_value')
  double get resultValue => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_pass', fromJson: _intToBool)
  bool get isPass => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $LabTestParameterCopyWith<LabTestParameter> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LabTestParameterCopyWith<$Res> {
  factory $LabTestParameterCopyWith(
          LabTestParameter value, $Res Function(LabTestParameter) then) =
      _$LabTestParameterCopyWithImpl<$Res, LabTestParameter>;
  @useResult
  $Res call(
      {@JsonKey(name: 'parameter_name') String parameterName,
      @JsonKey(name: 'expected_min') double expectedMin,
      @JsonKey(name: 'expected_max') double expectedMax,
      @JsonKey(name: 'result_value') double resultValue,
      @JsonKey(name: 'is_pass', fromJson: _intToBool) bool isPass});
}

/// @nodoc
class _$LabTestParameterCopyWithImpl<$Res, $Val extends LabTestParameter>
    implements $LabTestParameterCopyWith<$Res> {
  _$LabTestParameterCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? parameterName = null,
    Object? expectedMin = null,
    Object? expectedMax = null,
    Object? resultValue = null,
    Object? isPass = null,
  }) {
    return _then(_value.copyWith(
      parameterName: null == parameterName
          ? _value.parameterName
          : parameterName // ignore: cast_nullable_to_non_nullable
              as String,
      expectedMin: null == expectedMin
          ? _value.expectedMin
          : expectedMin // ignore: cast_nullable_to_non_nullable
              as double,
      expectedMax: null == expectedMax
          ? _value.expectedMax
          : expectedMax // ignore: cast_nullable_to_non_nullable
              as double,
      resultValue: null == resultValue
          ? _value.resultValue
          : resultValue // ignore: cast_nullable_to_non_nullable
              as double,
      isPass: null == isPass
          ? _value.isPass
          : isPass // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$LabTestParameterImplCopyWith<$Res>
    implements $LabTestParameterCopyWith<$Res> {
  factory _$$LabTestParameterImplCopyWith(_$LabTestParameterImpl value,
          $Res Function(_$LabTestParameterImpl) then) =
      __$$LabTestParameterImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'parameter_name') String parameterName,
      @JsonKey(name: 'expected_min') double expectedMin,
      @JsonKey(name: 'expected_max') double expectedMax,
      @JsonKey(name: 'result_value') double resultValue,
      @JsonKey(name: 'is_pass', fromJson: _intToBool) bool isPass});
}

/// @nodoc
class __$$LabTestParameterImplCopyWithImpl<$Res>
    extends _$LabTestParameterCopyWithImpl<$Res, _$LabTestParameterImpl>
    implements _$$LabTestParameterImplCopyWith<$Res> {
  __$$LabTestParameterImplCopyWithImpl(_$LabTestParameterImpl _value,
      $Res Function(_$LabTestParameterImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? parameterName = null,
    Object? expectedMin = null,
    Object? expectedMax = null,
    Object? resultValue = null,
    Object? isPass = null,
  }) {
    return _then(_$LabTestParameterImpl(
      parameterName: null == parameterName
          ? _value.parameterName
          : parameterName // ignore: cast_nullable_to_non_nullable
              as String,
      expectedMin: null == expectedMin
          ? _value.expectedMin
          : expectedMin // ignore: cast_nullable_to_non_nullable
              as double,
      expectedMax: null == expectedMax
          ? _value.expectedMax
          : expectedMax // ignore: cast_nullable_to_non_nullable
              as double,
      resultValue: null == resultValue
          ? _value.resultValue
          : resultValue // ignore: cast_nullable_to_non_nullable
              as double,
      isPass: null == isPass
          ? _value.isPass
          : isPass // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LabTestParameterImpl implements _LabTestParameter {
  const _$LabTestParameterImpl(
      {@JsonKey(name: 'parameter_name') required this.parameterName,
      @JsonKey(name: 'expected_min') this.expectedMin = 0,
      @JsonKey(name: 'expected_max') this.expectedMax = 0,
      @JsonKey(name: 'result_value') this.resultValue = 0,
      @JsonKey(name: 'is_pass', fromJson: _intToBool) this.isPass = false});

  factory _$LabTestParameterImpl.fromJson(Map<String, dynamic> json) =>
      _$$LabTestParameterImplFromJson(json);

  @override
  @JsonKey(name: 'parameter_name')
  final String parameterName;
  @override
  @JsonKey(name: 'expected_min')
  final double expectedMin;
  @override
  @JsonKey(name: 'expected_max')
  final double expectedMax;
  @override
  @JsonKey(name: 'result_value')
  final double resultValue;
  @override
  @JsonKey(name: 'is_pass', fromJson: _intToBool)
  final bool isPass;

  @override
  String toString() {
    return 'LabTestParameter(parameterName: $parameterName, expectedMin: $expectedMin, expectedMax: $expectedMax, resultValue: $resultValue, isPass: $isPass)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LabTestParameterImpl &&
            (identical(other.parameterName, parameterName) ||
                other.parameterName == parameterName) &&
            (identical(other.expectedMin, expectedMin) ||
                other.expectedMin == expectedMin) &&
            (identical(other.expectedMax, expectedMax) ||
                other.expectedMax == expectedMax) &&
            (identical(other.resultValue, resultValue) ||
                other.resultValue == resultValue) &&
            (identical(other.isPass, isPass) || other.isPass == isPass));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, parameterName, expectedMin,
      expectedMax, resultValue, isPass);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$LabTestParameterImplCopyWith<_$LabTestParameterImpl> get copyWith =>
      __$$LabTestParameterImplCopyWithImpl<_$LabTestParameterImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LabTestParameterImplToJson(
      this,
    );
  }
}

abstract class _LabTestParameter implements LabTestParameter {
  const factory _LabTestParameter(
          {@JsonKey(name: 'parameter_name') required final String parameterName,
          @JsonKey(name: 'expected_min') final double expectedMin,
          @JsonKey(name: 'expected_max') final double expectedMax,
          @JsonKey(name: 'result_value') final double resultValue,
          @JsonKey(name: 'is_pass', fromJson: _intToBool) final bool isPass}) =
      _$LabTestParameterImpl;

  factory _LabTestParameter.fromJson(Map<String, dynamic> json) =
      _$LabTestParameterImpl.fromJson;

  @override
  @JsonKey(name: 'parameter_name')
  String get parameterName;
  @override
  @JsonKey(name: 'expected_min')
  double get expectedMin;
  @override
  @JsonKey(name: 'expected_max')
  double get expectedMax;
  @override
  @JsonKey(name: 'result_value')
  double get resultValue;
  @override
  @JsonKey(name: 'is_pass', fromJson: _intToBool)
  bool get isPass;
  @override
  @JsonKey(ignore: true)
  _$$LabTestParameterImplCopyWith<_$LabTestParameterImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

LabTestResult _$LabTestResultFromJson(Map<String, dynamic> json) {
  return _LabTestResult.fromJson(json);
}

/// @nodoc
mixin _$LabTestResult {
  @JsonKey(name: 'lab_test')
  String get labTest => throw _privateConstructorUsedError;
  String get result => throw _privateConstructorUsedError;
  @JsonKey(name: 'fmb_batch')
  String get fmbBatch => throw _privateConstructorUsedError;
  List<LabTestParameterResult> get parameters =>
      throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $LabTestResultCopyWith<LabTestResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LabTestResultCopyWith<$Res> {
  factory $LabTestResultCopyWith(
          LabTestResult value, $Res Function(LabTestResult) then) =
      _$LabTestResultCopyWithImpl<$Res, LabTestResult>;
  @useResult
  $Res call(
      {@JsonKey(name: 'lab_test') String labTest,
      String result,
      @JsonKey(name: 'fmb_batch') String fmbBatch,
      List<LabTestParameterResult> parameters});
}

/// @nodoc
class _$LabTestResultCopyWithImpl<$Res, $Val extends LabTestResult>
    implements $LabTestResultCopyWith<$Res> {
  _$LabTestResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? labTest = null,
    Object? result = null,
    Object? fmbBatch = null,
    Object? parameters = null,
  }) {
    return _then(_value.copyWith(
      labTest: null == labTest
          ? _value.labTest
          : labTest // ignore: cast_nullable_to_non_nullable
              as String,
      result: null == result
          ? _value.result
          : result // ignore: cast_nullable_to_non_nullable
              as String,
      fmbBatch: null == fmbBatch
          ? _value.fmbBatch
          : fmbBatch // ignore: cast_nullable_to_non_nullable
              as String,
      parameters: null == parameters
          ? _value.parameters
          : parameters // ignore: cast_nullable_to_non_nullable
              as List<LabTestParameterResult>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$LabTestResultImplCopyWith<$Res>
    implements $LabTestResultCopyWith<$Res> {
  factory _$$LabTestResultImplCopyWith(
          _$LabTestResultImpl value, $Res Function(_$LabTestResultImpl) then) =
      __$$LabTestResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'lab_test') String labTest,
      String result,
      @JsonKey(name: 'fmb_batch') String fmbBatch,
      List<LabTestParameterResult> parameters});
}

/// @nodoc
class __$$LabTestResultImplCopyWithImpl<$Res>
    extends _$LabTestResultCopyWithImpl<$Res, _$LabTestResultImpl>
    implements _$$LabTestResultImplCopyWith<$Res> {
  __$$LabTestResultImplCopyWithImpl(
      _$LabTestResultImpl _value, $Res Function(_$LabTestResultImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? labTest = null,
    Object? result = null,
    Object? fmbBatch = null,
    Object? parameters = null,
  }) {
    return _then(_$LabTestResultImpl(
      labTest: null == labTest
          ? _value.labTest
          : labTest // ignore: cast_nullable_to_non_nullable
              as String,
      result: null == result
          ? _value.result
          : result // ignore: cast_nullable_to_non_nullable
              as String,
      fmbBatch: null == fmbBatch
          ? _value.fmbBatch
          : fmbBatch // ignore: cast_nullable_to_non_nullable
              as String,
      parameters: null == parameters
          ? _value._parameters
          : parameters // ignore: cast_nullable_to_non_nullable
              as List<LabTestParameterResult>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LabTestResultImpl implements _LabTestResult {
  const _$LabTestResultImpl(
      {@JsonKey(name: 'lab_test') required this.labTest,
      required this.result,
      @JsonKey(name: 'fmb_batch') required this.fmbBatch,
      final List<LabTestParameterResult> parameters = const []})
      : _parameters = parameters;

  factory _$LabTestResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$LabTestResultImplFromJson(json);

  @override
  @JsonKey(name: 'lab_test')
  final String labTest;
  @override
  final String result;
  @override
  @JsonKey(name: 'fmb_batch')
  final String fmbBatch;
  final List<LabTestParameterResult> _parameters;
  @override
  @JsonKey()
  List<LabTestParameterResult> get parameters {
    if (_parameters is EqualUnmodifiableListView) return _parameters;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_parameters);
  }

  @override
  String toString() {
    return 'LabTestResult(labTest: $labTest, result: $result, fmbBatch: $fmbBatch, parameters: $parameters)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LabTestResultImpl &&
            (identical(other.labTest, labTest) || other.labTest == labTest) &&
            (identical(other.result, result) || other.result == result) &&
            (identical(other.fmbBatch, fmbBatch) ||
                other.fmbBatch == fmbBatch) &&
            const DeepCollectionEquality()
                .equals(other._parameters, _parameters));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, labTest, result, fmbBatch,
      const DeepCollectionEquality().hash(_parameters));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$LabTestResultImplCopyWith<_$LabTestResultImpl> get copyWith =>
      __$$LabTestResultImplCopyWithImpl<_$LabTestResultImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LabTestResultImplToJson(
      this,
    );
  }
}

abstract class _LabTestResult implements LabTestResult {
  const factory _LabTestResult(
      {@JsonKey(name: 'lab_test') required final String labTest,
      required final String result,
      @JsonKey(name: 'fmb_batch') required final String fmbBatch,
      final List<LabTestParameterResult> parameters}) = _$LabTestResultImpl;

  factory _LabTestResult.fromJson(Map<String, dynamic> json) =
      _$LabTestResultImpl.fromJson;

  @override
  @JsonKey(name: 'lab_test')
  String get labTest;
  @override
  String get result;
  @override
  @JsonKey(name: 'fmb_batch')
  String get fmbBatch;
  @override
  List<LabTestParameterResult> get parameters;
  @override
  @JsonKey(ignore: true)
  _$$LabTestResultImplCopyWith<_$LabTestResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

LabTestParameterResult _$LabTestParameterResultFromJson(
    Map<String, dynamic> json) {
  return _LabTestParameterResult.fromJson(json);
}

/// @nodoc
mixin _$LabTestParameterResult {
  @JsonKey(name: 'parameter_name')
  String get parameterName => throw _privateConstructorUsedError;
  @JsonKey(name: 'result_value')
  double get resultValue => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_pass', fromJson: _intToBool)
  bool get isPass => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $LabTestParameterResultCopyWith<LabTestParameterResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LabTestParameterResultCopyWith<$Res> {
  factory $LabTestParameterResultCopyWith(LabTestParameterResult value,
          $Res Function(LabTestParameterResult) then) =
      _$LabTestParameterResultCopyWithImpl<$Res, LabTestParameterResult>;
  @useResult
  $Res call(
      {@JsonKey(name: 'parameter_name') String parameterName,
      @JsonKey(name: 'result_value') double resultValue,
      @JsonKey(name: 'is_pass', fromJson: _intToBool) bool isPass});
}

/// @nodoc
class _$LabTestParameterResultCopyWithImpl<$Res,
        $Val extends LabTestParameterResult>
    implements $LabTestParameterResultCopyWith<$Res> {
  _$LabTestParameterResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? parameterName = null,
    Object? resultValue = null,
    Object? isPass = null,
  }) {
    return _then(_value.copyWith(
      parameterName: null == parameterName
          ? _value.parameterName
          : parameterName // ignore: cast_nullable_to_non_nullable
              as String,
      resultValue: null == resultValue
          ? _value.resultValue
          : resultValue // ignore: cast_nullable_to_non_nullable
              as double,
      isPass: null == isPass
          ? _value.isPass
          : isPass // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$LabTestParameterResultImplCopyWith<$Res>
    implements $LabTestParameterResultCopyWith<$Res> {
  factory _$$LabTestParameterResultImplCopyWith(
          _$LabTestParameterResultImpl value,
          $Res Function(_$LabTestParameterResultImpl) then) =
      __$$LabTestParameterResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'parameter_name') String parameterName,
      @JsonKey(name: 'result_value') double resultValue,
      @JsonKey(name: 'is_pass', fromJson: _intToBool) bool isPass});
}

/// @nodoc
class __$$LabTestParameterResultImplCopyWithImpl<$Res>
    extends _$LabTestParameterResultCopyWithImpl<$Res,
        _$LabTestParameterResultImpl>
    implements _$$LabTestParameterResultImplCopyWith<$Res> {
  __$$LabTestParameterResultImplCopyWithImpl(
      _$LabTestParameterResultImpl _value,
      $Res Function(_$LabTestParameterResultImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? parameterName = null,
    Object? resultValue = null,
    Object? isPass = null,
  }) {
    return _then(_$LabTestParameterResultImpl(
      parameterName: null == parameterName
          ? _value.parameterName
          : parameterName // ignore: cast_nullable_to_non_nullable
              as String,
      resultValue: null == resultValue
          ? _value.resultValue
          : resultValue // ignore: cast_nullable_to_non_nullable
              as double,
      isPass: null == isPass
          ? _value.isPass
          : isPass // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LabTestParameterResultImpl implements _LabTestParameterResult {
  const _$LabTestParameterResultImpl(
      {@JsonKey(name: 'parameter_name') required this.parameterName,
      @JsonKey(name: 'result_value') this.resultValue = 0,
      @JsonKey(name: 'is_pass', fromJson: _intToBool) this.isPass = false});

  factory _$LabTestParameterResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$LabTestParameterResultImplFromJson(json);

  @override
  @JsonKey(name: 'parameter_name')
  final String parameterName;
  @override
  @JsonKey(name: 'result_value')
  final double resultValue;
  @override
  @JsonKey(name: 'is_pass', fromJson: _intToBool)
  final bool isPass;

  @override
  String toString() {
    return 'LabTestParameterResult(parameterName: $parameterName, resultValue: $resultValue, isPass: $isPass)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LabTestParameterResultImpl &&
            (identical(other.parameterName, parameterName) ||
                other.parameterName == parameterName) &&
            (identical(other.resultValue, resultValue) ||
                other.resultValue == resultValue) &&
            (identical(other.isPass, isPass) || other.isPass == isPass));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, parameterName, resultValue, isPass);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$LabTestParameterResultImplCopyWith<_$LabTestParameterResultImpl>
      get copyWith => __$$LabTestParameterResultImplCopyWithImpl<
          _$LabTestParameterResultImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LabTestParameterResultImplToJson(
      this,
    );
  }
}

abstract class _LabTestParameterResult implements LabTestParameterResult {
  const factory _LabTestParameterResult(
          {@JsonKey(name: 'parameter_name') required final String parameterName,
          @JsonKey(name: 'result_value') final double resultValue,
          @JsonKey(name: 'is_pass', fromJson: _intToBool) final bool isPass}) =
      _$LabTestParameterResultImpl;

  factory _LabTestParameterResult.fromJson(Map<String, dynamic> json) =
      _$LabTestParameterResultImpl.fromJson;

  @override
  @JsonKey(name: 'parameter_name')
  String get parameterName;
  @override
  @JsonKey(name: 'result_value')
  double get resultValue;
  @override
  @JsonKey(name: 'is_pass', fromJson: _intToBool)
  bool get isPass;
  @override
  @JsonKey(ignore: true)
  _$$LabTestParameterResultImplCopyWith<_$LabTestParameterResultImpl>
      get copyWith => throw _privateConstructorUsedError;
}
