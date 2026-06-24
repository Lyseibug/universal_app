// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'manufacturing_mr_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ManufacturingMR _$ManufacturingMRFromJson(Map<String, dynamic> json) {
  return _ManufacturingMR.fromJson(json);
}

/// @nodoc
mixin _$ManufacturingMR {
  String get name => throw _privateConstructorUsedError;
  @JsonKey(name: 'request_type')
  String? get requestType => throw _privateConstructorUsedError;
  @JsonKey(name: 'compound_type')
  String? get compoundType => throw _privateConstructorUsedError;
  @JsonKey(name: 'formula_code')
  String? get formulaCode => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  @JsonKey(name: 'pick_list')
  String? get pickList => throw _privateConstructorUsedError;
  String? get remarks => throw _privateConstructorUsedError;
  String? get creation => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_by_user')
  String? get createdByUser => throw _privateConstructorUsedError;
  @JsonKey(name: 'item_count')
  int get itemCount => throw _privateConstructorUsedError;
  @JsonKey(name: 'picked_count')
  int get pickedCount => throw _privateConstructorUsedError;
  @JsonKey(name: 'total_required')
  double get totalRequired => throw _privateConstructorUsedError;
  @JsonKey(name: 'total_picked')
  double get totalPicked => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ManufacturingMRCopyWith<ManufacturingMR> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ManufacturingMRCopyWith<$Res> {
  factory $ManufacturingMRCopyWith(
          ManufacturingMR value, $Res Function(ManufacturingMR) then) =
      _$ManufacturingMRCopyWithImpl<$Res, ManufacturingMR>;
  @useResult
  $Res call(
      {String name,
      @JsonKey(name: 'request_type') String? requestType,
      @JsonKey(name: 'compound_type') String? compoundType,
      @JsonKey(name: 'formula_code') String? formulaCode,
      String status,
      @JsonKey(name: 'pick_list') String? pickList,
      String? remarks,
      String? creation,
      @JsonKey(name: 'created_by_user') String? createdByUser,
      @JsonKey(name: 'item_count') int itemCount,
      @JsonKey(name: 'picked_count') int pickedCount,
      @JsonKey(name: 'total_required') double totalRequired,
      @JsonKey(name: 'total_picked') double totalPicked});
}

/// @nodoc
class _$ManufacturingMRCopyWithImpl<$Res, $Val extends ManufacturingMR>
    implements $ManufacturingMRCopyWith<$Res> {
  _$ManufacturingMRCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? requestType = freezed,
    Object? compoundType = freezed,
    Object? formulaCode = freezed,
    Object? status = null,
    Object? pickList = freezed,
    Object? remarks = freezed,
    Object? creation = freezed,
    Object? createdByUser = freezed,
    Object? itemCount = null,
    Object? pickedCount = null,
    Object? totalRequired = null,
    Object? totalPicked = null,
  }) {
    return _then(_value.copyWith(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      requestType: freezed == requestType
          ? _value.requestType
          : requestType // ignore: cast_nullable_to_non_nullable
              as String?,
      compoundType: freezed == compoundType
          ? _value.compoundType
          : compoundType // ignore: cast_nullable_to_non_nullable
              as String?,
      formulaCode: freezed == formulaCode
          ? _value.formulaCode
          : formulaCode // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      pickList: freezed == pickList
          ? _value.pickList
          : pickList // ignore: cast_nullable_to_non_nullable
              as String?,
      remarks: freezed == remarks
          ? _value.remarks
          : remarks // ignore: cast_nullable_to_non_nullable
              as String?,
      creation: freezed == creation
          ? _value.creation
          : creation // ignore: cast_nullable_to_non_nullable
              as String?,
      createdByUser: freezed == createdByUser
          ? _value.createdByUser
          : createdByUser // ignore: cast_nullable_to_non_nullable
              as String?,
      itemCount: null == itemCount
          ? _value.itemCount
          : itemCount // ignore: cast_nullable_to_non_nullable
              as int,
      pickedCount: null == pickedCount
          ? _value.pickedCount
          : pickedCount // ignore: cast_nullable_to_non_nullable
              as int,
      totalRequired: null == totalRequired
          ? _value.totalRequired
          : totalRequired // ignore: cast_nullable_to_non_nullable
              as double,
      totalPicked: null == totalPicked
          ? _value.totalPicked
          : totalPicked // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ManufacturingMRImplCopyWith<$Res>
    implements $ManufacturingMRCopyWith<$Res> {
  factory _$$ManufacturingMRImplCopyWith(_$ManufacturingMRImpl value,
          $Res Function(_$ManufacturingMRImpl) then) =
      __$$ManufacturingMRImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String name,
      @JsonKey(name: 'request_type') String? requestType,
      @JsonKey(name: 'compound_type') String? compoundType,
      @JsonKey(name: 'formula_code') String? formulaCode,
      String status,
      @JsonKey(name: 'pick_list') String? pickList,
      String? remarks,
      String? creation,
      @JsonKey(name: 'created_by_user') String? createdByUser,
      @JsonKey(name: 'item_count') int itemCount,
      @JsonKey(name: 'picked_count') int pickedCount,
      @JsonKey(name: 'total_required') double totalRequired,
      @JsonKey(name: 'total_picked') double totalPicked});
}

/// @nodoc
class __$$ManufacturingMRImplCopyWithImpl<$Res>
    extends _$ManufacturingMRCopyWithImpl<$Res, _$ManufacturingMRImpl>
    implements _$$ManufacturingMRImplCopyWith<$Res> {
  __$$ManufacturingMRImplCopyWithImpl(
      _$ManufacturingMRImpl _value, $Res Function(_$ManufacturingMRImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? requestType = freezed,
    Object? compoundType = freezed,
    Object? formulaCode = freezed,
    Object? status = null,
    Object? pickList = freezed,
    Object? remarks = freezed,
    Object? creation = freezed,
    Object? createdByUser = freezed,
    Object? itemCount = null,
    Object? pickedCount = null,
    Object? totalRequired = null,
    Object? totalPicked = null,
  }) {
    return _then(_$ManufacturingMRImpl(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      requestType: freezed == requestType
          ? _value.requestType
          : requestType // ignore: cast_nullable_to_non_nullable
              as String?,
      compoundType: freezed == compoundType
          ? _value.compoundType
          : compoundType // ignore: cast_nullable_to_non_nullable
              as String?,
      formulaCode: freezed == formulaCode
          ? _value.formulaCode
          : formulaCode // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      pickList: freezed == pickList
          ? _value.pickList
          : pickList // ignore: cast_nullable_to_non_nullable
              as String?,
      remarks: freezed == remarks
          ? _value.remarks
          : remarks // ignore: cast_nullable_to_non_nullable
              as String?,
      creation: freezed == creation
          ? _value.creation
          : creation // ignore: cast_nullable_to_non_nullable
              as String?,
      createdByUser: freezed == createdByUser
          ? _value.createdByUser
          : createdByUser // ignore: cast_nullable_to_non_nullable
              as String?,
      itemCount: null == itemCount
          ? _value.itemCount
          : itemCount // ignore: cast_nullable_to_non_nullable
              as int,
      pickedCount: null == pickedCount
          ? _value.pickedCount
          : pickedCount // ignore: cast_nullable_to_non_nullable
              as int,
      totalRequired: null == totalRequired
          ? _value.totalRequired
          : totalRequired // ignore: cast_nullable_to_non_nullable
              as double,
      totalPicked: null == totalPicked
          ? _value.totalPicked
          : totalPicked // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ManufacturingMRImpl implements _ManufacturingMR {
  const _$ManufacturingMRImpl(
      {required this.name,
      @JsonKey(name: 'request_type') this.requestType,
      @JsonKey(name: 'compound_type') this.compoundType,
      @JsonKey(name: 'formula_code') this.formulaCode,
      required this.status,
      @JsonKey(name: 'pick_list') this.pickList,
      this.remarks,
      this.creation,
      @JsonKey(name: 'created_by_user') this.createdByUser,
      @JsonKey(name: 'item_count') this.itemCount = 0,
      @JsonKey(name: 'picked_count') this.pickedCount = 0,
      @JsonKey(name: 'total_required') this.totalRequired = 0,
      @JsonKey(name: 'total_picked') this.totalPicked = 0});

  factory _$ManufacturingMRImpl.fromJson(Map<String, dynamic> json) =>
      _$$ManufacturingMRImplFromJson(json);

  @override
  final String name;
  @override
  @JsonKey(name: 'request_type')
  final String? requestType;
  @override
  @JsonKey(name: 'compound_type')
  final String? compoundType;
  @override
  @JsonKey(name: 'formula_code')
  final String? formulaCode;
  @override
  final String status;
  @override
  @JsonKey(name: 'pick_list')
  final String? pickList;
  @override
  final String? remarks;
  @override
  final String? creation;
  @override
  @JsonKey(name: 'created_by_user')
  final String? createdByUser;
  @override
  @JsonKey(name: 'item_count')
  final int itemCount;
  @override
  @JsonKey(name: 'picked_count')
  final int pickedCount;
  @override
  @JsonKey(name: 'total_required')
  final double totalRequired;
  @override
  @JsonKey(name: 'total_picked')
  final double totalPicked;

  @override
  String toString() {
    return 'ManufacturingMR(name: $name, requestType: $requestType, compoundType: $compoundType, formulaCode: $formulaCode, status: $status, pickList: $pickList, remarks: $remarks, creation: $creation, createdByUser: $createdByUser, itemCount: $itemCount, pickedCount: $pickedCount, totalRequired: $totalRequired, totalPicked: $totalPicked)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ManufacturingMRImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.requestType, requestType) ||
                other.requestType == requestType) &&
            (identical(other.compoundType, compoundType) ||
                other.compoundType == compoundType) &&
            (identical(other.formulaCode, formulaCode) ||
                other.formulaCode == formulaCode) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.pickList, pickList) ||
                other.pickList == pickList) &&
            (identical(other.remarks, remarks) || other.remarks == remarks) &&
            (identical(other.creation, creation) ||
                other.creation == creation) &&
            (identical(other.createdByUser, createdByUser) ||
                other.createdByUser == createdByUser) &&
            (identical(other.itemCount, itemCount) ||
                other.itemCount == itemCount) &&
            (identical(other.pickedCount, pickedCount) ||
                other.pickedCount == pickedCount) &&
            (identical(other.totalRequired, totalRequired) ||
                other.totalRequired == totalRequired) &&
            (identical(other.totalPicked, totalPicked) ||
                other.totalPicked == totalPicked));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      name,
      requestType,
      compoundType,
      formulaCode,
      status,
      pickList,
      remarks,
      creation,
      createdByUser,
      itemCount,
      pickedCount,
      totalRequired,
      totalPicked);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ManufacturingMRImplCopyWith<_$ManufacturingMRImpl> get copyWith =>
      __$$ManufacturingMRImplCopyWithImpl<_$ManufacturingMRImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ManufacturingMRImplToJson(
      this,
    );
  }
}

abstract class _ManufacturingMR implements ManufacturingMR {
  const factory _ManufacturingMR(
          {required final String name,
          @JsonKey(name: 'request_type') final String? requestType,
          @JsonKey(name: 'compound_type') final String? compoundType,
          @JsonKey(name: 'formula_code') final String? formulaCode,
          required final String status,
          @JsonKey(name: 'pick_list') final String? pickList,
          final String? remarks,
          final String? creation,
          @JsonKey(name: 'created_by_user') final String? createdByUser,
          @JsonKey(name: 'item_count') final int itemCount,
          @JsonKey(name: 'picked_count') final int pickedCount,
          @JsonKey(name: 'total_required') final double totalRequired,
          @JsonKey(name: 'total_picked') final double totalPicked}) =
      _$ManufacturingMRImpl;

  factory _ManufacturingMR.fromJson(Map<String, dynamic> json) =
      _$ManufacturingMRImpl.fromJson;

  @override
  String get name;
  @override
  @JsonKey(name: 'request_type')
  String? get requestType;
  @override
  @JsonKey(name: 'compound_type')
  String? get compoundType;
  @override
  @JsonKey(name: 'formula_code')
  String? get formulaCode;
  @override
  String get status;
  @override
  @JsonKey(name: 'pick_list')
  String? get pickList;
  @override
  String? get remarks;
  @override
  String? get creation;
  @override
  @JsonKey(name: 'created_by_user')
  String? get createdByUser;
  @override
  @JsonKey(name: 'item_count')
  int get itemCount;
  @override
  @JsonKey(name: 'picked_count')
  int get pickedCount;
  @override
  @JsonKey(name: 'total_required')
  double get totalRequired;
  @override
  @JsonKey(name: 'total_picked')
  double get totalPicked;
  @override
  @JsonKey(ignore: true)
  _$$ManufacturingMRImplCopyWith<_$ManufacturingMRImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ManufacturingMRDetail _$ManufacturingMRDetailFromJson(
    Map<String, dynamic> json) {
  return _ManufacturingMRDetail.fromJson(json);
}

/// @nodoc
mixin _$ManufacturingMRDetail {
  String get name => throw _privateConstructorUsedError;
  @JsonKey(name: 'request_type')
  String? get requestType => throw _privateConstructorUsedError;
  @JsonKey(name: 'compound_type')
  String? get compoundType => throw _privateConstructorUsedError;
  @JsonKey(name: 'formula_code')
  String? get formulaCode => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  @JsonKey(name: 'pick_list')
  String? get pickList => throw _privateConstructorUsedError;
  String? get remarks => throw _privateConstructorUsedError;
  String? get creation => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_by_user')
  String? get createdByUser => throw _privateConstructorUsedError;
  List<ManufacturingMRItem> get items => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ManufacturingMRDetailCopyWith<ManufacturingMRDetail> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ManufacturingMRDetailCopyWith<$Res> {
  factory $ManufacturingMRDetailCopyWith(ManufacturingMRDetail value,
          $Res Function(ManufacturingMRDetail) then) =
      _$ManufacturingMRDetailCopyWithImpl<$Res, ManufacturingMRDetail>;
  @useResult
  $Res call(
      {String name,
      @JsonKey(name: 'request_type') String? requestType,
      @JsonKey(name: 'compound_type') String? compoundType,
      @JsonKey(name: 'formula_code') String? formulaCode,
      String status,
      @JsonKey(name: 'pick_list') String? pickList,
      String? remarks,
      String? creation,
      @JsonKey(name: 'created_by_user') String? createdByUser,
      List<ManufacturingMRItem> items});
}

/// @nodoc
class _$ManufacturingMRDetailCopyWithImpl<$Res,
        $Val extends ManufacturingMRDetail>
    implements $ManufacturingMRDetailCopyWith<$Res> {
  _$ManufacturingMRDetailCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? requestType = freezed,
    Object? compoundType = freezed,
    Object? formulaCode = freezed,
    Object? status = null,
    Object? pickList = freezed,
    Object? remarks = freezed,
    Object? creation = freezed,
    Object? createdByUser = freezed,
    Object? items = null,
  }) {
    return _then(_value.copyWith(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      requestType: freezed == requestType
          ? _value.requestType
          : requestType // ignore: cast_nullable_to_non_nullable
              as String?,
      compoundType: freezed == compoundType
          ? _value.compoundType
          : compoundType // ignore: cast_nullable_to_non_nullable
              as String?,
      formulaCode: freezed == formulaCode
          ? _value.formulaCode
          : formulaCode // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      pickList: freezed == pickList
          ? _value.pickList
          : pickList // ignore: cast_nullable_to_non_nullable
              as String?,
      remarks: freezed == remarks
          ? _value.remarks
          : remarks // ignore: cast_nullable_to_non_nullable
              as String?,
      creation: freezed == creation
          ? _value.creation
          : creation // ignore: cast_nullable_to_non_nullable
              as String?,
      createdByUser: freezed == createdByUser
          ? _value.createdByUser
          : createdByUser // ignore: cast_nullable_to_non_nullable
              as String?,
      items: null == items
          ? _value.items
          : items // ignore: cast_nullable_to_non_nullable
              as List<ManufacturingMRItem>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ManufacturingMRDetailImplCopyWith<$Res>
    implements $ManufacturingMRDetailCopyWith<$Res> {
  factory _$$ManufacturingMRDetailImplCopyWith(
          _$ManufacturingMRDetailImpl value,
          $Res Function(_$ManufacturingMRDetailImpl) then) =
      __$$ManufacturingMRDetailImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String name,
      @JsonKey(name: 'request_type') String? requestType,
      @JsonKey(name: 'compound_type') String? compoundType,
      @JsonKey(name: 'formula_code') String? formulaCode,
      String status,
      @JsonKey(name: 'pick_list') String? pickList,
      String? remarks,
      String? creation,
      @JsonKey(name: 'created_by_user') String? createdByUser,
      List<ManufacturingMRItem> items});
}

/// @nodoc
class __$$ManufacturingMRDetailImplCopyWithImpl<$Res>
    extends _$ManufacturingMRDetailCopyWithImpl<$Res,
        _$ManufacturingMRDetailImpl>
    implements _$$ManufacturingMRDetailImplCopyWith<$Res> {
  __$$ManufacturingMRDetailImplCopyWithImpl(_$ManufacturingMRDetailImpl _value,
      $Res Function(_$ManufacturingMRDetailImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? requestType = freezed,
    Object? compoundType = freezed,
    Object? formulaCode = freezed,
    Object? status = null,
    Object? pickList = freezed,
    Object? remarks = freezed,
    Object? creation = freezed,
    Object? createdByUser = freezed,
    Object? items = null,
  }) {
    return _then(_$ManufacturingMRDetailImpl(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      requestType: freezed == requestType
          ? _value.requestType
          : requestType // ignore: cast_nullable_to_non_nullable
              as String?,
      compoundType: freezed == compoundType
          ? _value.compoundType
          : compoundType // ignore: cast_nullable_to_non_nullable
              as String?,
      formulaCode: freezed == formulaCode
          ? _value.formulaCode
          : formulaCode // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      pickList: freezed == pickList
          ? _value.pickList
          : pickList // ignore: cast_nullable_to_non_nullable
              as String?,
      remarks: freezed == remarks
          ? _value.remarks
          : remarks // ignore: cast_nullable_to_non_nullable
              as String?,
      creation: freezed == creation
          ? _value.creation
          : creation // ignore: cast_nullable_to_non_nullable
              as String?,
      createdByUser: freezed == createdByUser
          ? _value.createdByUser
          : createdByUser // ignore: cast_nullable_to_non_nullable
              as String?,
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<ManufacturingMRItem>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ManufacturingMRDetailImpl implements _ManufacturingMRDetail {
  const _$ManufacturingMRDetailImpl(
      {required this.name,
      @JsonKey(name: 'request_type') this.requestType,
      @JsonKey(name: 'compound_type') this.compoundType,
      @JsonKey(name: 'formula_code') this.formulaCode,
      required this.status,
      @JsonKey(name: 'pick_list') this.pickList,
      this.remarks,
      this.creation,
      @JsonKey(name: 'created_by_user') this.createdByUser,
      final List<ManufacturingMRItem> items = const []})
      : _items = items;

  factory _$ManufacturingMRDetailImpl.fromJson(Map<String, dynamic> json) =>
      _$$ManufacturingMRDetailImplFromJson(json);

  @override
  final String name;
  @override
  @JsonKey(name: 'request_type')
  final String? requestType;
  @override
  @JsonKey(name: 'compound_type')
  final String? compoundType;
  @override
  @JsonKey(name: 'formula_code')
  final String? formulaCode;
  @override
  final String status;
  @override
  @JsonKey(name: 'pick_list')
  final String? pickList;
  @override
  final String? remarks;
  @override
  final String? creation;
  @override
  @JsonKey(name: 'created_by_user')
  final String? createdByUser;
  final List<ManufacturingMRItem> _items;
  @override
  @JsonKey()
  List<ManufacturingMRItem> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  String toString() {
    return 'ManufacturingMRDetail(name: $name, requestType: $requestType, compoundType: $compoundType, formulaCode: $formulaCode, status: $status, pickList: $pickList, remarks: $remarks, creation: $creation, createdByUser: $createdByUser, items: $items)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ManufacturingMRDetailImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.requestType, requestType) ||
                other.requestType == requestType) &&
            (identical(other.compoundType, compoundType) ||
                other.compoundType == compoundType) &&
            (identical(other.formulaCode, formulaCode) ||
                other.formulaCode == formulaCode) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.pickList, pickList) ||
                other.pickList == pickList) &&
            (identical(other.remarks, remarks) || other.remarks == remarks) &&
            (identical(other.creation, creation) ||
                other.creation == creation) &&
            (identical(other.createdByUser, createdByUser) ||
                other.createdByUser == createdByUser) &&
            const DeepCollectionEquality().equals(other._items, _items));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      name,
      requestType,
      compoundType,
      formulaCode,
      status,
      pickList,
      remarks,
      creation,
      createdByUser,
      const DeepCollectionEquality().hash(_items));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ManufacturingMRDetailImplCopyWith<_$ManufacturingMRDetailImpl>
      get copyWith => __$$ManufacturingMRDetailImplCopyWithImpl<
          _$ManufacturingMRDetailImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ManufacturingMRDetailImplToJson(
      this,
    );
  }
}

abstract class _ManufacturingMRDetail implements ManufacturingMRDetail {
  const factory _ManufacturingMRDetail(
      {required final String name,
      @JsonKey(name: 'request_type') final String? requestType,
      @JsonKey(name: 'compound_type') final String? compoundType,
      @JsonKey(name: 'formula_code') final String? formulaCode,
      required final String status,
      @JsonKey(name: 'pick_list') final String? pickList,
      final String? remarks,
      final String? creation,
      @JsonKey(name: 'created_by_user') final String? createdByUser,
      final List<ManufacturingMRItem> items}) = _$ManufacturingMRDetailImpl;

  factory _ManufacturingMRDetail.fromJson(Map<String, dynamic> json) =
      _$ManufacturingMRDetailImpl.fromJson;

  @override
  String get name;
  @override
  @JsonKey(name: 'request_type')
  String? get requestType;
  @override
  @JsonKey(name: 'compound_type')
  String? get compoundType;
  @override
  @JsonKey(name: 'formula_code')
  String? get formulaCode;
  @override
  String get status;
  @override
  @JsonKey(name: 'pick_list')
  String? get pickList;
  @override
  String? get remarks;
  @override
  String? get creation;
  @override
  @JsonKey(name: 'created_by_user')
  String? get createdByUser;
  @override
  List<ManufacturingMRItem> get items;
  @override
  @JsonKey(ignore: true)
  _$$ManufacturingMRDetailImplCopyWith<_$ManufacturingMRDetailImpl>
      get copyWith => throw _privateConstructorUsedError;
}

ManufacturingMRItem _$ManufacturingMRItemFromJson(Map<String, dynamic> json) {
  return _ManufacturingMRItem.fromJson(json);
}

/// @nodoc
mixin _$ManufacturingMRItem {
  String get name => throw _privateConstructorUsedError;
  @JsonKey(name: 'item_code')
  String get itemCode => throw _privateConstructorUsedError;
  @JsonKey(name: 'item_name')
  String? get itemName => throw _privateConstructorUsedError;
  @JsonKey(name: 'required_qty')
  double get requiredQty => throw _privateConstructorUsedError;
  @JsonKey(name: 'picked_qty')
  double get pickedQty => throw _privateConstructorUsedError;
  @JsonKey(name: 'loaded_qty')
  double get loadedQty => throw _privateConstructorUsedError;
  @JsonKey(name: 'target_stream')
  String get targetStream => throw _privateConstructorUsedError;
  @JsonKey(name: 'target_warehouse')
  String? get targetWarehouse => throw _privateConstructorUsedError;
  String? get uom => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_completed')
  bool get isCompleted => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ManufacturingMRItemCopyWith<ManufacturingMRItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ManufacturingMRItemCopyWith<$Res> {
  factory $ManufacturingMRItemCopyWith(
          ManufacturingMRItem value, $Res Function(ManufacturingMRItem) then) =
      _$ManufacturingMRItemCopyWithImpl<$Res, ManufacturingMRItem>;
  @useResult
  $Res call(
      {String name,
      @JsonKey(name: 'item_code') String itemCode,
      @JsonKey(name: 'item_name') String? itemName,
      @JsonKey(name: 'required_qty') double requiredQty,
      @JsonKey(name: 'picked_qty') double pickedQty,
      @JsonKey(name: 'loaded_qty') double loadedQty,
      @JsonKey(name: 'target_stream') String targetStream,
      @JsonKey(name: 'target_warehouse') String? targetWarehouse,
      String? uom,
      @JsonKey(name: 'is_completed') bool isCompleted});
}

/// @nodoc
class _$ManufacturingMRItemCopyWithImpl<$Res, $Val extends ManufacturingMRItem>
    implements $ManufacturingMRItemCopyWith<$Res> {
  _$ManufacturingMRItemCopyWithImpl(this._value, this._then);

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
    Object? requiredQty = null,
    Object? pickedQty = null,
    Object? loadedQty = null,
    Object? targetStream = null,
    Object? targetWarehouse = freezed,
    Object? uom = freezed,
    Object? isCompleted = null,
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
      requiredQty: null == requiredQty
          ? _value.requiredQty
          : requiredQty // ignore: cast_nullable_to_non_nullable
              as double,
      pickedQty: null == pickedQty
          ? _value.pickedQty
          : pickedQty // ignore: cast_nullable_to_non_nullable
              as double,
      loadedQty: null == loadedQty
          ? _value.loadedQty
          : loadedQty // ignore: cast_nullable_to_non_nullable
              as double,
      targetStream: null == targetStream
          ? _value.targetStream
          : targetStream // ignore: cast_nullable_to_non_nullable
              as String,
      targetWarehouse: freezed == targetWarehouse
          ? _value.targetWarehouse
          : targetWarehouse // ignore: cast_nullable_to_non_nullable
              as String?,
      uom: freezed == uom
          ? _value.uom
          : uom // ignore: cast_nullable_to_non_nullable
              as String?,
      isCompleted: null == isCompleted
          ? _value.isCompleted
          : isCompleted // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ManufacturingMRItemImplCopyWith<$Res>
    implements $ManufacturingMRItemCopyWith<$Res> {
  factory _$$ManufacturingMRItemImplCopyWith(_$ManufacturingMRItemImpl value,
          $Res Function(_$ManufacturingMRItemImpl) then) =
      __$$ManufacturingMRItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String name,
      @JsonKey(name: 'item_code') String itemCode,
      @JsonKey(name: 'item_name') String? itemName,
      @JsonKey(name: 'required_qty') double requiredQty,
      @JsonKey(name: 'picked_qty') double pickedQty,
      @JsonKey(name: 'loaded_qty') double loadedQty,
      @JsonKey(name: 'target_stream') String targetStream,
      @JsonKey(name: 'target_warehouse') String? targetWarehouse,
      String? uom,
      @JsonKey(name: 'is_completed') bool isCompleted});
}

/// @nodoc
class __$$ManufacturingMRItemImplCopyWithImpl<$Res>
    extends _$ManufacturingMRItemCopyWithImpl<$Res, _$ManufacturingMRItemImpl>
    implements _$$ManufacturingMRItemImplCopyWith<$Res> {
  __$$ManufacturingMRItemImplCopyWithImpl(_$ManufacturingMRItemImpl _value,
      $Res Function(_$ManufacturingMRItemImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? itemCode = null,
    Object? itemName = freezed,
    Object? requiredQty = null,
    Object? pickedQty = null,
    Object? loadedQty = null,
    Object? targetStream = null,
    Object? targetWarehouse = freezed,
    Object? uom = freezed,
    Object? isCompleted = null,
  }) {
    return _then(_$ManufacturingMRItemImpl(
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
      requiredQty: null == requiredQty
          ? _value.requiredQty
          : requiredQty // ignore: cast_nullable_to_non_nullable
              as double,
      pickedQty: null == pickedQty
          ? _value.pickedQty
          : pickedQty // ignore: cast_nullable_to_non_nullable
              as double,
      loadedQty: null == loadedQty
          ? _value.loadedQty
          : loadedQty // ignore: cast_nullable_to_non_nullable
              as double,
      targetStream: null == targetStream
          ? _value.targetStream
          : targetStream // ignore: cast_nullable_to_non_nullable
              as String,
      targetWarehouse: freezed == targetWarehouse
          ? _value.targetWarehouse
          : targetWarehouse // ignore: cast_nullable_to_non_nullable
              as String?,
      uom: freezed == uom
          ? _value.uom
          : uom // ignore: cast_nullable_to_non_nullable
              as String?,
      isCompleted: null == isCompleted
          ? _value.isCompleted
          : isCompleted // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ManufacturingMRItemImpl implements _ManufacturingMRItem {
  const _$ManufacturingMRItemImpl(
      {required this.name,
      @JsonKey(name: 'item_code') required this.itemCode,
      @JsonKey(name: 'item_name') this.itemName,
      @JsonKey(name: 'required_qty') required this.requiredQty,
      @JsonKey(name: 'picked_qty') this.pickedQty = 0,
      @JsonKey(name: 'loaded_qty') this.loadedQty = 0,
      @JsonKey(name: 'target_stream') required this.targetStream,
      @JsonKey(name: 'target_warehouse') this.targetWarehouse,
      this.uom,
      @JsonKey(name: 'is_completed') this.isCompleted = false});

  factory _$ManufacturingMRItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$ManufacturingMRItemImplFromJson(json);

  @override
  final String name;
  @override
  @JsonKey(name: 'item_code')
  final String itemCode;
  @override
  @JsonKey(name: 'item_name')
  final String? itemName;
  @override
  @JsonKey(name: 'required_qty')
  final double requiredQty;
  @override
  @JsonKey(name: 'picked_qty')
  final double pickedQty;
  @override
  @JsonKey(name: 'loaded_qty')
  final double loadedQty;
  @override
  @JsonKey(name: 'target_stream')
  final String targetStream;
  @override
  @JsonKey(name: 'target_warehouse')
  final String? targetWarehouse;
  @override
  final String? uom;
  @override
  @JsonKey(name: 'is_completed')
  final bool isCompleted;

  @override
  String toString() {
    return 'ManufacturingMRItem(name: $name, itemCode: $itemCode, itemName: $itemName, requiredQty: $requiredQty, pickedQty: $pickedQty, loadedQty: $loadedQty, targetStream: $targetStream, targetWarehouse: $targetWarehouse, uom: $uom, isCompleted: $isCompleted)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ManufacturingMRItemImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.itemCode, itemCode) ||
                other.itemCode == itemCode) &&
            (identical(other.itemName, itemName) ||
                other.itemName == itemName) &&
            (identical(other.requiredQty, requiredQty) ||
                other.requiredQty == requiredQty) &&
            (identical(other.pickedQty, pickedQty) ||
                other.pickedQty == pickedQty) &&
            (identical(other.loadedQty, loadedQty) ||
                other.loadedQty == loadedQty) &&
            (identical(other.targetStream, targetStream) ||
                other.targetStream == targetStream) &&
            (identical(other.targetWarehouse, targetWarehouse) ||
                other.targetWarehouse == targetWarehouse) &&
            (identical(other.uom, uom) || other.uom == uom) &&
            (identical(other.isCompleted, isCompleted) ||
                other.isCompleted == isCompleted));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      name,
      itemCode,
      itemName,
      requiredQty,
      pickedQty,
      loadedQty,
      targetStream,
      targetWarehouse,
      uom,
      isCompleted);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ManufacturingMRItemImplCopyWith<_$ManufacturingMRItemImpl> get copyWith =>
      __$$ManufacturingMRItemImplCopyWithImpl<_$ManufacturingMRItemImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ManufacturingMRItemImplToJson(
      this,
    );
  }
}

abstract class _ManufacturingMRItem implements ManufacturingMRItem {
  const factory _ManufacturingMRItem(
          {required final String name,
          @JsonKey(name: 'item_code') required final String itemCode,
          @JsonKey(name: 'item_name') final String? itemName,
          @JsonKey(name: 'required_qty') required final double requiredQty,
          @JsonKey(name: 'picked_qty') final double pickedQty,
          @JsonKey(name: 'loaded_qty') final double loadedQty,
          @JsonKey(name: 'target_stream') required final String targetStream,
          @JsonKey(name: 'target_warehouse') final String? targetWarehouse,
          final String? uom,
          @JsonKey(name: 'is_completed') final bool isCompleted}) =
      _$ManufacturingMRItemImpl;

  factory _ManufacturingMRItem.fromJson(Map<String, dynamic> json) =
      _$ManufacturingMRItemImpl.fromJson;

  @override
  String get name;
  @override
  @JsonKey(name: 'item_code')
  String get itemCode;
  @override
  @JsonKey(name: 'item_name')
  String? get itemName;
  @override
  @JsonKey(name: 'required_qty')
  double get requiredQty;
  @override
  @JsonKey(name: 'picked_qty')
  double get pickedQty;
  @override
  @JsonKey(name: 'loaded_qty')
  double get loadedQty;
  @override
  @JsonKey(name: 'target_stream')
  String get targetStream;
  @override
  @JsonKey(name: 'target_warehouse')
  String? get targetWarehouse;
  @override
  String? get uom;
  @override
  @JsonKey(name: 'is_completed')
  bool get isCompleted;
  @override
  @JsonKey(ignore: true)
  _$$ManufacturingMRItemImplCopyWith<_$ManufacturingMRItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
