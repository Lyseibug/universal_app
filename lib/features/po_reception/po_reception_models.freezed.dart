// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'po_reception_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

PurchaseOrderSummary _$PurchaseOrderSummaryFromJson(
    Map<String, dynamic> json) {
  return _PurchaseOrderSummary.fromJson(json);
}

/// @nodoc
mixin _$PurchaseOrderSummary {
  String get name => throw _privateConstructorUsedError;
  String? get supplier => throw _privateConstructorUsedError;
  @JsonKey(name: 'supplier_name')
  String? get supplierName => throw _privateConstructorUsedError;
  @JsonKey(name: 'transaction_date')
  String? get transactionDate => throw _privateConstructorUsedError;
  @JsonKey(name: 'grand_total')
  double get grandTotal => throw _privateConstructorUsedError;
  String? get currency => throw _privateConstructorUsedError;
  @JsonKey(name: 'item_count')
  int get itemCount => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $PurchaseOrderSummaryCopyWith<PurchaseOrderSummary> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PurchaseOrderSummaryCopyWith<$Res> {
  factory $PurchaseOrderSummaryCopyWith(PurchaseOrderSummary value,
          $Res Function(PurchaseOrderSummary) then) =
      _$PurchaseOrderSummaryCopyWithImpl<$Res, PurchaseOrderSummary>;
  @useResult
  $Res call(
      {String name,
      String? supplier,
      @JsonKey(name: 'supplier_name') String? supplierName,
      @JsonKey(name: 'transaction_date') String? transactionDate,
      @JsonKey(name: 'grand_total') double grandTotal,
      String? currency,
      @JsonKey(name: 'item_count') int itemCount});
}

/// @nodoc
class _$PurchaseOrderSummaryCopyWithImpl<$Res,
        $Val extends PurchaseOrderSummary>
    implements $PurchaseOrderSummaryCopyWith<$Res> {
  _$PurchaseOrderSummaryCopyWithImpl(this._value, this._then);

  final $Val _value;
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? supplier = freezed,
    Object? supplierName = freezed,
    Object? transactionDate = freezed,
    Object? grandTotal = null,
    Object? currency = freezed,
    Object? itemCount = null,
  }) {
    return _then(_value.copyWith(
      name: null == name ? _value.name : name as String,
      supplier:
          freezed == supplier ? _value.supplier : supplier as String?,
      supplierName: freezed == supplierName
          ? _value.supplierName
          : supplierName as String?,
      transactionDate: freezed == transactionDate
          ? _value.transactionDate
          : transactionDate as String?,
      grandTotal:
          null == grandTotal ? _value.grandTotal : grandTotal as double,
      currency:
          freezed == currency ? _value.currency : currency as String?,
      itemCount:
          null == itemCount ? _value.itemCount : itemCount as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PurchaseOrderSummaryImplCopyWith<$Res>
    implements $PurchaseOrderSummaryCopyWith<$Res> {
  factory _$$PurchaseOrderSummaryImplCopyWith(
          _$PurchaseOrderSummaryImpl value,
          $Res Function(_$PurchaseOrderSummaryImpl) then) =
      __$$PurchaseOrderSummaryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String name,
      String? supplier,
      @JsonKey(name: 'supplier_name') String? supplierName,
      @JsonKey(name: 'transaction_date') String? transactionDate,
      @JsonKey(name: 'grand_total') double grandTotal,
      String? currency,
      @JsonKey(name: 'item_count') int itemCount});
}

/// @nodoc
class __$$PurchaseOrderSummaryImplCopyWithImpl<$Res>
    extends _$PurchaseOrderSummaryCopyWithImpl<$Res,
        _$PurchaseOrderSummaryImpl>
    implements _$$PurchaseOrderSummaryImplCopyWith<$Res> {
  __$$PurchaseOrderSummaryImplCopyWithImpl(_$PurchaseOrderSummaryImpl _value,
      $Res Function(_$PurchaseOrderSummaryImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? supplier = freezed,
    Object? supplierName = freezed,
    Object? transactionDate = freezed,
    Object? grandTotal = null,
    Object? currency = freezed,
    Object? itemCount = null,
  }) {
    return _then(_$PurchaseOrderSummaryImpl(
      name: null == name ? _value.name : name as String,
      supplier:
          freezed == supplier ? _value.supplier : supplier as String?,
      supplierName: freezed == supplierName
          ? _value.supplierName
          : supplierName as String?,
      transactionDate: freezed == transactionDate
          ? _value.transactionDate
          : transactionDate as String?,
      grandTotal:
          null == grandTotal ? _value.grandTotal : grandTotal as double,
      currency:
          freezed == currency ? _value.currency : currency as String?,
      itemCount:
          null == itemCount ? _value.itemCount : itemCount as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PurchaseOrderSummaryImpl implements _PurchaseOrderSummary {
  const _$PurchaseOrderSummaryImpl(
      {required this.name,
      this.supplier,
      @JsonKey(name: 'supplier_name') this.supplierName,
      @JsonKey(name: 'transaction_date') this.transactionDate,
      @JsonKey(name: 'grand_total') this.grandTotal = 0,
      this.currency,
      @JsonKey(name: 'item_count') this.itemCount = 0});

  factory _$PurchaseOrderSummaryImpl.fromJson(Map<String, dynamic> json) =>
      _$$PurchaseOrderSummaryImplFromJson(json);

  @override
  final String name;
  @override
  final String? supplier;
  @override
  @JsonKey(name: 'supplier_name')
  final String? supplierName;
  @override
  @JsonKey(name: 'transaction_date')
  final String? transactionDate;
  @override
  @JsonKey(name: 'grand_total')
  final double grandTotal;
  @override
  final String? currency;
  @override
  @JsonKey(name: 'item_count')
  final int itemCount;

  @override
  String toString() {
    return 'PurchaseOrderSummary(name: $name, supplier: $supplier, supplierName: $supplierName, transactionDate: $transactionDate, grandTotal: $grandTotal, currency: $currency, itemCount: $itemCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PurchaseOrderSummaryImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.supplier, supplier) ||
                other.supplier == supplier) &&
            (identical(other.supplierName, supplierName) ||
                other.supplierName == supplierName) &&
            (identical(other.transactionDate, transactionDate) ||
                other.transactionDate == transactionDate) &&
            (identical(other.grandTotal, grandTotal) ||
                other.grandTotal == grandTotal) &&
            (identical(other.currency, currency) ||
                other.currency == currency) &&
            (identical(other.itemCount, itemCount) ||
                other.itemCount == itemCount));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, name, supplier, supplierName,
      transactionDate, grandTotal, currency, itemCount);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PurchaseOrderSummaryImplCopyWith<_$PurchaseOrderSummaryImpl>
      get copyWith =>
          __$$PurchaseOrderSummaryImplCopyWithImpl<_$PurchaseOrderSummaryImpl>(
              this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PurchaseOrderSummaryImplToJson(this);
  }
}

abstract class _PurchaseOrderSummary implements PurchaseOrderSummary {
  const factory _PurchaseOrderSummary(
          {required final String name,
          final String? supplier,
          @JsonKey(name: 'supplier_name') final String? supplierName,
          @JsonKey(name: 'transaction_date') final String? transactionDate,
          @JsonKey(name: 'grand_total') final double grandTotal,
          final String? currency,
          @JsonKey(name: 'item_count') final int itemCount}) =
      _$PurchaseOrderSummaryImpl;

  factory _PurchaseOrderSummary.fromJson(Map<String, dynamic> json) =
      _$PurchaseOrderSummaryImpl.fromJson;

  @override
  String get name;
  @override
  String? get supplier;
  @override
  @JsonKey(name: 'supplier_name')
  String? get supplierName;
  @override
  @JsonKey(name: 'transaction_date')
  String? get transactionDate;
  @override
  @JsonKey(name: 'grand_total')
  double get grandTotal;
  @override
  String? get currency;
  @override
  @JsonKey(name: 'item_count')
  int get itemCount;
  @override
  @JsonKey(ignore: true)
  _$$PurchaseOrderSummaryImplCopyWith<_$PurchaseOrderSummaryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PurchaseOrderDetail _$PurchaseOrderDetailFromJson(Map<String, dynamic> json) {
  return _PurchaseOrderDetail.fromJson(json);
}

/// @nodoc
mixin _$PurchaseOrderDetail {
  String get name => throw _privateConstructorUsedError;
  String? get supplier => throw _privateConstructorUsedError;
  @JsonKey(name: 'supplier_name')
  String? get supplierName => throw _privateConstructorUsedError;
  @JsonKey(name: 'transaction_date')
  String? get transactionDate => throw _privateConstructorUsedError;
  @JsonKey(name: 'grand_total')
  double get grandTotal => throw _privateConstructorUsedError;
  String? get currency => throw _privateConstructorUsedError;
  @JsonKey(name: 'inbound_warehouse')
  String? get inboundWarehouse => throw _privateConstructorUsedError;
  List<PurchaseOrderItemLine> get items => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $PurchaseOrderDetailCopyWith<PurchaseOrderDetail> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PurchaseOrderDetailCopyWith<$Res> {
  factory $PurchaseOrderDetailCopyWith(
          PurchaseOrderDetail value, $Res Function(PurchaseOrderDetail) then) =
      _$PurchaseOrderDetailCopyWithImpl<$Res, PurchaseOrderDetail>;
  @useResult
  $Res call(
      {String name,
      String? supplier,
      @JsonKey(name: 'supplier_name') String? supplierName,
      @JsonKey(name: 'transaction_date') String? transactionDate,
      @JsonKey(name: 'grand_total') double grandTotal,
      String? currency,
      @JsonKey(name: 'inbound_warehouse') String? inboundWarehouse,
      List<PurchaseOrderItemLine> items});
}

/// @nodoc
class _$PurchaseOrderDetailCopyWithImpl<$Res, $Val extends PurchaseOrderDetail>
    implements $PurchaseOrderDetailCopyWith<$Res> {
  _$PurchaseOrderDetailCopyWithImpl(this._value, this._then);

  final $Val _value;
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? supplier = freezed,
    Object? supplierName = freezed,
    Object? transactionDate = freezed,
    Object? grandTotal = null,
    Object? currency = freezed,
    Object? inboundWarehouse = freezed,
    Object? items = null,
  }) {
    return _then(_value.copyWith(
      name: null == name ? _value.name : name as String,
      supplier:
          freezed == supplier ? _value.supplier : supplier as String?,
      supplierName: freezed == supplierName
          ? _value.supplierName
          : supplierName as String?,
      transactionDate: freezed == transactionDate
          ? _value.transactionDate
          : transactionDate as String?,
      grandTotal:
          null == grandTotal ? _value.grandTotal : grandTotal as double,
      currency:
          freezed == currency ? _value.currency : currency as String?,
      inboundWarehouse: freezed == inboundWarehouse
          ? _value.inboundWarehouse
          : inboundWarehouse as String?,
      items: null == items
          ? _value.items
          : items as List<PurchaseOrderItemLine>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PurchaseOrderDetailImplCopyWith<$Res>
    implements $PurchaseOrderDetailCopyWith<$Res> {
  factory _$$PurchaseOrderDetailImplCopyWith(_$PurchaseOrderDetailImpl value,
          $Res Function(_$PurchaseOrderDetailImpl) then) =
      __$$PurchaseOrderDetailImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String name,
      String? supplier,
      @JsonKey(name: 'supplier_name') String? supplierName,
      @JsonKey(name: 'transaction_date') String? transactionDate,
      @JsonKey(name: 'grand_total') double grandTotal,
      String? currency,
      @JsonKey(name: 'inbound_warehouse') String? inboundWarehouse,
      List<PurchaseOrderItemLine> items});
}

/// @nodoc
class __$$PurchaseOrderDetailImplCopyWithImpl<$Res>
    extends _$PurchaseOrderDetailCopyWithImpl<$Res, _$PurchaseOrderDetailImpl>
    implements _$$PurchaseOrderDetailImplCopyWith<$Res> {
  __$$PurchaseOrderDetailImplCopyWithImpl(_$PurchaseOrderDetailImpl _value,
      $Res Function(_$PurchaseOrderDetailImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? supplier = freezed,
    Object? supplierName = freezed,
    Object? transactionDate = freezed,
    Object? grandTotal = null,
    Object? currency = freezed,
    Object? inboundWarehouse = freezed,
    Object? items = null,
  }) {
    return _then(_$PurchaseOrderDetailImpl(
      name: null == name ? _value.name : name as String,
      supplier:
          freezed == supplier ? _value.supplier : supplier as String?,
      supplierName: freezed == supplierName
          ? _value.supplierName
          : supplierName as String?,
      transactionDate: freezed == transactionDate
          ? _value.transactionDate
          : transactionDate as String?,
      grandTotal:
          null == grandTotal ? _value.grandTotal : grandTotal as double,
      currency:
          freezed == currency ? _value.currency : currency as String?,
      inboundWarehouse: freezed == inboundWarehouse
          ? _value.inboundWarehouse
          : inboundWarehouse as String?,
      items: null == items
          ? _value._items
          : items as List<PurchaseOrderItemLine>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PurchaseOrderDetailImpl implements _PurchaseOrderDetail {
  const _$PurchaseOrderDetailImpl(
      {required this.name,
      this.supplier,
      @JsonKey(name: 'supplier_name') this.supplierName,
      @JsonKey(name: 'transaction_date') this.transactionDate,
      @JsonKey(name: 'grand_total') this.grandTotal = 0,
      this.currency,
      @JsonKey(name: 'inbound_warehouse') this.inboundWarehouse,
      final List<PurchaseOrderItemLine> items = const []})
      : _items = items;

  factory _$PurchaseOrderDetailImpl.fromJson(Map<String, dynamic> json) =>
      _$$PurchaseOrderDetailImplFromJson(json);

  @override
  final String name;
  @override
  final String? supplier;
  @override
  @JsonKey(name: 'supplier_name')
  final String? supplierName;
  @override
  @JsonKey(name: 'transaction_date')
  final String? transactionDate;
  @override
  @JsonKey(name: 'grand_total')
  final double grandTotal;
  @override
  final String? currency;
  @override
  @JsonKey(name: 'inbound_warehouse')
  final String? inboundWarehouse;
  final List<PurchaseOrderItemLine> _items;
  @override
  List<PurchaseOrderItemLine> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    return EqualUnmodifiableListView(_items);
  }

  @override
  String toString() {
    return 'PurchaseOrderDetail(name: $name, supplier: $supplier, supplierName: $supplierName, transactionDate: $transactionDate, grandTotal: $grandTotal, currency: $currency, inboundWarehouse: $inboundWarehouse, items: $items)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PurchaseOrderDetailImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.supplier, supplier) ||
                other.supplier == supplier) &&
            (identical(other.supplierName, supplierName) ||
                other.supplierName == supplierName) &&
            (identical(other.transactionDate, transactionDate) ||
                other.transactionDate == transactionDate) &&
            (identical(other.grandTotal, grandTotal) ||
                other.grandTotal == grandTotal) &&
            (identical(other.currency, currency) ||
                other.currency == currency) &&
            (identical(other.inboundWarehouse, inboundWarehouse) ||
                other.inboundWarehouse == inboundWarehouse) &&
            const DeepCollectionEquality().equals(other._items, _items));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, name, supplier, supplierName,
      transactionDate, grandTotal, currency, inboundWarehouse,
      const DeepCollectionEquality().hash(_items));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PurchaseOrderDetailImplCopyWith<_$PurchaseOrderDetailImpl> get copyWith =>
      __$$PurchaseOrderDetailImplCopyWithImpl<_$PurchaseOrderDetailImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PurchaseOrderDetailImplToJson(this);
  }
}

abstract class _PurchaseOrderDetail implements PurchaseOrderDetail {
  const factory _PurchaseOrderDetail(
      {required final String name,
      final String? supplier,
      @JsonKey(name: 'supplier_name') final String? supplierName,
      @JsonKey(name: 'transaction_date') final String? transactionDate,
      @JsonKey(name: 'grand_total') final double grandTotal,
      final String? currency,
      @JsonKey(name: 'inbound_warehouse') final String? inboundWarehouse,
      final List<PurchaseOrderItemLine> items}) = _$PurchaseOrderDetailImpl;

  factory _PurchaseOrderDetail.fromJson(Map<String, dynamic> json) =
      _$PurchaseOrderDetailImpl.fromJson;

  @override
  String get name;
  @override
  String? get supplier;
  @override
  @JsonKey(name: 'supplier_name')
  String? get supplierName;
  @override
  @JsonKey(name: 'transaction_date')
  String? get transactionDate;
  @override
  @JsonKey(name: 'grand_total')
  double get grandTotal;
  @override
  String? get currency;
  @override
  @JsonKey(name: 'inbound_warehouse')
  String? get inboundWarehouse;
  @override
  List<PurchaseOrderItemLine> get items;
  @override
  @JsonKey(ignore: true)
  _$$PurchaseOrderDetailImplCopyWith<_$PurchaseOrderDetailImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PurchaseOrderItemLine _$PurchaseOrderItemLineFromJson(
    Map<String, dynamic> json) {
  return _PurchaseOrderItemLine.fromJson(json);
}

/// @nodoc
mixin _$PurchaseOrderItemLine {
  String get name => throw _privateConstructorUsedError;
  @JsonKey(name: 'item_code')
  String get itemCode => throw _privateConstructorUsedError;
  @JsonKey(name: 'item_name')
  String? get itemName => throw _privateConstructorUsedError;
  String? get uom => throw _privateConstructorUsedError;
  @JsonKey(name: 'upc_code')
  String? get upcCode => throw _privateConstructorUsedError;
  @JsonKey(name: 'ordered_qty')
  double get orderedQty => throw _privateConstructorUsedError;
  @JsonKey(name: 'received_qty')
  double get receivedQty => throw _privateConstructorUsedError;
  @JsonKey(name: 'pending_qty')
  double get pendingQty => throw _privateConstructorUsedError;
  double get rate => throw _privateConstructorUsedError;
  String? get warehouse => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $PurchaseOrderItemLineCopyWith<PurchaseOrderItemLine> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PurchaseOrderItemLineCopyWith<$Res> {
  factory $PurchaseOrderItemLineCopyWith(PurchaseOrderItemLine value,
          $Res Function(PurchaseOrderItemLine) then) =
      _$PurchaseOrderItemLineCopyWithImpl<$Res, PurchaseOrderItemLine>;
  @useResult
  $Res call(
      {String name,
      @JsonKey(name: 'item_code') String itemCode,
      @JsonKey(name: 'item_name') String? itemName,
      String? uom,
      @JsonKey(name: 'upc_code') String? upcCode,
      @JsonKey(name: 'ordered_qty') double orderedQty,
      @JsonKey(name: 'received_qty') double receivedQty,
      @JsonKey(name: 'pending_qty') double pendingQty,
      double rate,
      String? warehouse});
}

/// @nodoc
class _$PurchaseOrderItemLineCopyWithImpl<$Res,
        $Val extends PurchaseOrderItemLine>
    implements $PurchaseOrderItemLineCopyWith<$Res> {
  _$PurchaseOrderItemLineCopyWithImpl(this._value, this._then);

  final $Val _value;
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? itemCode = null,
    Object? itemName = freezed,
    Object? uom = freezed,
    Object? upcCode = freezed,
    Object? orderedQty = null,
    Object? receivedQty = null,
    Object? pendingQty = null,
    Object? rate = null,
    Object? warehouse = freezed,
  }) {
    return _then(_value.copyWith(
      name: null == name ? _value.name : name as String,
      itemCode:
          null == itemCode ? _value.itemCode : itemCode as String,
      itemName:
          freezed == itemName ? _value.itemName : itemName as String?,
      uom: freezed == uom ? _value.uom : uom as String?,
      upcCode:
          freezed == upcCode ? _value.upcCode : upcCode as String?,
      orderedQty:
          null == orderedQty ? _value.orderedQty : orderedQty as double,
      receivedQty: null == receivedQty
          ? _value.receivedQty
          : receivedQty as double,
      pendingQty:
          null == pendingQty ? _value.pendingQty : pendingQty as double,
      rate: null == rate ? _value.rate : rate as double,
      warehouse:
          freezed == warehouse ? _value.warehouse : warehouse as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PurchaseOrderItemLineImplCopyWith<$Res>
    implements $PurchaseOrderItemLineCopyWith<$Res> {
  factory _$$PurchaseOrderItemLineImplCopyWith(
          _$PurchaseOrderItemLineImpl value,
          $Res Function(_$PurchaseOrderItemLineImpl) then) =
      __$$PurchaseOrderItemLineImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String name,
      @JsonKey(name: 'item_code') String itemCode,
      @JsonKey(name: 'item_name') String? itemName,
      String? uom,
      @JsonKey(name: 'upc_code') String? upcCode,
      @JsonKey(name: 'ordered_qty') double orderedQty,
      @JsonKey(name: 'received_qty') double receivedQty,
      @JsonKey(name: 'pending_qty') double pendingQty,
      double rate,
      String? warehouse});
}

/// @nodoc
class __$$PurchaseOrderItemLineImplCopyWithImpl<$Res>
    extends _$PurchaseOrderItemLineCopyWithImpl<$Res,
        _$PurchaseOrderItemLineImpl>
    implements _$$PurchaseOrderItemLineImplCopyWith<$Res> {
  __$$PurchaseOrderItemLineImplCopyWithImpl(
      _$PurchaseOrderItemLineImpl _value,
      $Res Function(_$PurchaseOrderItemLineImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? itemCode = null,
    Object? itemName = freezed,
    Object? uom = freezed,
    Object? upcCode = freezed,
    Object? orderedQty = null,
    Object? receivedQty = null,
    Object? pendingQty = null,
    Object? rate = null,
    Object? warehouse = freezed,
  }) {
    return _then(_$PurchaseOrderItemLineImpl(
      name: null == name ? _value.name : name as String,
      itemCode:
          null == itemCode ? _value.itemCode : itemCode as String,
      itemName:
          freezed == itemName ? _value.itemName : itemName as String?,
      uom: freezed == uom ? _value.uom : uom as String?,
      upcCode:
          freezed == upcCode ? _value.upcCode : upcCode as String?,
      orderedQty:
          null == orderedQty ? _value.orderedQty : orderedQty as double,
      receivedQty: null == receivedQty
          ? _value.receivedQty
          : receivedQty as double,
      pendingQty:
          null == pendingQty ? _value.pendingQty : pendingQty as double,
      rate: null == rate ? _value.rate : rate as double,
      warehouse:
          freezed == warehouse ? _value.warehouse : warehouse as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PurchaseOrderItemLineImpl implements _PurchaseOrderItemLine {
  const _$PurchaseOrderItemLineImpl(
      {required this.name,
      @JsonKey(name: 'item_code') required this.itemCode,
      @JsonKey(name: 'item_name') this.itemName,
      this.uom,
      @JsonKey(name: 'upc_code') this.upcCode,
      @JsonKey(name: 'ordered_qty') this.orderedQty = 0,
      @JsonKey(name: 'received_qty') this.receivedQty = 0,
      @JsonKey(name: 'pending_qty') this.pendingQty = 0,
      this.rate = 0,
      this.warehouse});

  factory _$PurchaseOrderItemLineImpl.fromJson(Map<String, dynamic> json) =>
      _$$PurchaseOrderItemLineImplFromJson(json);

  @override
  final String name;
  @override
  @JsonKey(name: 'item_code')
  final String itemCode;
  @override
  @JsonKey(name: 'item_name')
  final String? itemName;
  @override
  final String? uom;
  @override
  @JsonKey(name: 'upc_code')
  final String? upcCode;
  @override
  @JsonKey(name: 'ordered_qty')
  final double orderedQty;
  @override
  @JsonKey(name: 'received_qty')
  final double receivedQty;
  @override
  @JsonKey(name: 'pending_qty')
  final double pendingQty;
  @override
  final double rate;
  @override
  final String? warehouse;

  @override
  String toString() {
    return 'PurchaseOrderItemLine(name: $name, itemCode: $itemCode, itemName: $itemName, uom: $uom, upcCode: $upcCode, orderedQty: $orderedQty, receivedQty: $receivedQty, pendingQty: $pendingQty, rate: $rate, warehouse: $warehouse)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PurchaseOrderItemLineImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.itemCode, itemCode) ||
                other.itemCode == itemCode) &&
            (identical(other.itemName, itemName) ||
                other.itemName == itemName) &&
            (identical(other.uom, uom) || other.uom == uom) &&
            (identical(other.upcCode, upcCode) ||
                other.upcCode == upcCode) &&
            (identical(other.orderedQty, orderedQty) ||
                other.orderedQty == orderedQty) &&
            (identical(other.receivedQty, receivedQty) ||
                other.receivedQty == receivedQty) &&
            (identical(other.pendingQty, pendingQty) ||
                other.pendingQty == pendingQty) &&
            (identical(other.rate, rate) || other.rate == rate) &&
            (identical(other.warehouse, warehouse) ||
                other.warehouse == warehouse));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, name, itemCode, itemName, uom,
      upcCode, orderedQty, receivedQty, pendingQty, rate, warehouse);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PurchaseOrderItemLineImplCopyWith<_$PurchaseOrderItemLineImpl>
      get copyWith => __$$PurchaseOrderItemLineImplCopyWithImpl<
          _$PurchaseOrderItemLineImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PurchaseOrderItemLineImplToJson(this);
  }
}

abstract class _PurchaseOrderItemLine implements PurchaseOrderItemLine {
  const factory _PurchaseOrderItemLine(
      {required final String name,
      @JsonKey(name: 'item_code') required final String itemCode,
      @JsonKey(name: 'item_name') final String? itemName,
      final String? uom,
      @JsonKey(name: 'upc_code') final String? upcCode,
      @JsonKey(name: 'ordered_qty') final double orderedQty,
      @JsonKey(name: 'received_qty') final double receivedQty,
      @JsonKey(name: 'pending_qty') final double pendingQty,
      final double rate,
      final String? warehouse}) = _$PurchaseOrderItemLineImpl;

  factory _PurchaseOrderItemLine.fromJson(Map<String, dynamic> json) =
      _$PurchaseOrderItemLineImpl.fromJson;

  @override
  String get name;
  @override
  @JsonKey(name: 'item_code')
  String get itemCode;
  @override
  @JsonKey(name: 'item_name')
  String? get itemName;
  @override
  String? get uom;
  @override
  @JsonKey(name: 'upc_code')
  String? get upcCode;
  @override
  @JsonKey(name: 'ordered_qty')
  double get orderedQty;
  @override
  @JsonKey(name: 'received_qty')
  double get receivedQty;
  @override
  @JsonKey(name: 'pending_qty')
  double get pendingQty;
  @override
  double get rate;
  @override
  String? get warehouse;
  @override
  @JsonKey(ignore: true)
  _$$PurchaseOrderItemLineImplCopyWith<_$PurchaseOrderItemLineImpl>
      get copyWith => throw _privateConstructorUsedError;
}
