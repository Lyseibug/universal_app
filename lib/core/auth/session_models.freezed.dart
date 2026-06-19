// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'session_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

WorkspaceModel _$WorkspaceModelFromJson(Map<String, dynamic> json) {
  return _WorkspaceModel.fromJson(json);
}

/// @nodoc
mixin _$WorkspaceModel {
  String get assignment => throw _privateConstructorUsedError;
  String get label => throw _privateConstructorUsedError;
  String get warehouse => throw _privateConstructorUsedError;
  String get supervisor =>
      throw _privateConstructorUsedError; // ignore: invalid_annotation_target
  @JsonKey(name: 'supervisor_name')
  String get supervisorName => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $WorkspaceModelCopyWith<WorkspaceModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WorkspaceModelCopyWith<$Res> {
  factory $WorkspaceModelCopyWith(
          WorkspaceModel value, $Res Function(WorkspaceModel) then) =
      _$WorkspaceModelCopyWithImpl<$Res, WorkspaceModel>;
  @useResult
  $Res call(
      {String assignment,
      String label,
      String warehouse,
      String supervisor,
      @JsonKey(name: 'supervisor_name') String supervisorName});
}

/// @nodoc
class _$WorkspaceModelCopyWithImpl<$Res, $Val extends WorkspaceModel>
    implements $WorkspaceModelCopyWith<$Res> {
  _$WorkspaceModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? assignment = null,
    Object? label = null,
    Object? warehouse = null,
    Object? supervisor = null,
    Object? supervisorName = null,
  }) {
    return _then(_value.copyWith(
      assignment: null == assignment
          ? _value.assignment
          : assignment // ignore: cast_nullable_to_non_nullable
              as String,
      label: null == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      warehouse: null == warehouse
          ? _value.warehouse
          : warehouse // ignore: cast_nullable_to_non_nullable
              as String,
      supervisor: null == supervisor
          ? _value.supervisor
          : supervisor // ignore: cast_nullable_to_non_nullable
              as String,
      supervisorName: null == supervisorName
          ? _value.supervisorName
          : supervisorName // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$WorkspaceModelImplCopyWith<$Res>
    implements $WorkspaceModelCopyWith<$Res> {
  factory _$$WorkspaceModelImplCopyWith(_$WorkspaceModelImpl value,
          $Res Function(_$WorkspaceModelImpl) then) =
      __$$WorkspaceModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String assignment,
      String label,
      String warehouse,
      String supervisor,
      @JsonKey(name: 'supervisor_name') String supervisorName});
}

/// @nodoc
class __$$WorkspaceModelImplCopyWithImpl<$Res>
    extends _$WorkspaceModelCopyWithImpl<$Res, _$WorkspaceModelImpl>
    implements _$$WorkspaceModelImplCopyWith<$Res> {
  __$$WorkspaceModelImplCopyWithImpl(
      _$WorkspaceModelImpl _value, $Res Function(_$WorkspaceModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? assignment = null,
    Object? label = null,
    Object? warehouse = null,
    Object? supervisor = null,
    Object? supervisorName = null,
  }) {
    return _then(_$WorkspaceModelImpl(
      assignment: null == assignment
          ? _value.assignment
          : assignment // ignore: cast_nullable_to_non_nullable
              as String,
      label: null == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      warehouse: null == warehouse
          ? _value.warehouse
          : warehouse // ignore: cast_nullable_to_non_nullable
              as String,
      supervisor: null == supervisor
          ? _value.supervisor
          : supervisor // ignore: cast_nullable_to_non_nullable
              as String,
      supervisorName: null == supervisorName
          ? _value.supervisorName
          : supervisorName // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WorkspaceModelImpl implements _WorkspaceModel {
  const _$WorkspaceModelImpl(
      {required this.assignment,
      required this.label,
      this.warehouse = '',
      this.supervisor = '',
      @JsonKey(name: 'supervisor_name') this.supervisorName = ''});

  factory _$WorkspaceModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$WorkspaceModelImplFromJson(json);

  @override
  final String assignment;
  @override
  final String label;
  @override
  @JsonKey()
  final String warehouse;
  @override
  @JsonKey()
  final String supervisor;
// ignore: invalid_annotation_target
  @override
  @JsonKey(name: 'supervisor_name')
  final String supervisorName;

  @override
  String toString() {
    return 'WorkspaceModel(assignment: $assignment, label: $label, warehouse: $warehouse, supervisor: $supervisor, supervisorName: $supervisorName)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WorkspaceModelImpl &&
            (identical(other.assignment, assignment) ||
                other.assignment == assignment) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.warehouse, warehouse) ||
                other.warehouse == warehouse) &&
            (identical(other.supervisor, supervisor) ||
                other.supervisor == supervisor) &&
            (identical(other.supervisorName, supervisorName) ||
                other.supervisorName == supervisorName));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, assignment, label, warehouse, supervisor, supervisorName);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$WorkspaceModelImplCopyWith<_$WorkspaceModelImpl> get copyWith =>
      __$$WorkspaceModelImplCopyWithImpl<_$WorkspaceModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WorkspaceModelImplToJson(
      this,
    );
  }
}

abstract class _WorkspaceModel implements WorkspaceModel {
  const factory _WorkspaceModel(
          {required final String assignment,
          required final String label,
          final String warehouse,
          final String supervisor,
          @JsonKey(name: 'supervisor_name') final String supervisorName}) =
      _$WorkspaceModelImpl;

  factory _WorkspaceModel.fromJson(Map<String, dynamic> json) =
      _$WorkspaceModelImpl.fromJson;

  @override
  String get assignment;
  @override
  String get label;
  @override
  String get warehouse;
  @override
  String get supervisor;
  @override // ignore: invalid_annotation_target
  @JsonKey(name: 'supervisor_name')
  String get supervisorName;
  @override
  @JsonKey(ignore: true)
  _$$WorkspaceModelImplCopyWith<_$WorkspaceModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SessionInfo _$SessionInfoFromJson(Map<String, dynamic> json) {
  return _SessionInfo.fromJson(json);
}

/// @nodoc
mixin _$SessionInfo {
  String get employee =>
      throw _privateConstructorUsedError; // ignore: invalid_annotation_target
  @JsonKey(name: 'employee_name')
  String get employeeName => throw _privateConstructorUsedError;
  List<String> get roles => throw _privateConstructorUsedError;
  String? get workspace =>
      throw _privateConstructorUsedError; // ignore: invalid_annotation_target
  @JsonKey(name: 'workspace_label')
  String? get workspaceLabel => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $SessionInfoCopyWith<SessionInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SessionInfoCopyWith<$Res> {
  factory $SessionInfoCopyWith(
          SessionInfo value, $Res Function(SessionInfo) then) =
      _$SessionInfoCopyWithImpl<$Res, SessionInfo>;
  @useResult
  $Res call(
      {String employee,
      @JsonKey(name: 'employee_name') String employeeName,
      List<String> roles,
      String? workspace,
      @JsonKey(name: 'workspace_label') String? workspaceLabel});
}

/// @nodoc
class _$SessionInfoCopyWithImpl<$Res, $Val extends SessionInfo>
    implements $SessionInfoCopyWith<$Res> {
  _$SessionInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? employee = null,
    Object? employeeName = null,
    Object? roles = null,
    Object? workspace = freezed,
    Object? workspaceLabel = freezed,
  }) {
    return _then(_value.copyWith(
      employee: null == employee
          ? _value.employee
          : employee // ignore: cast_nullable_to_non_nullable
              as String,
      employeeName: null == employeeName
          ? _value.employeeName
          : employeeName // ignore: cast_nullable_to_non_nullable
              as String,
      roles: null == roles
          ? _value.roles
          : roles // ignore: cast_nullable_to_non_nullable
              as List<String>,
      workspace: freezed == workspace
          ? _value.workspace
          : workspace // ignore: cast_nullable_to_non_nullable
              as String?,
      workspaceLabel: freezed == workspaceLabel
          ? _value.workspaceLabel
          : workspaceLabel // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SessionInfoImplCopyWith<$Res>
    implements $SessionInfoCopyWith<$Res> {
  factory _$$SessionInfoImplCopyWith(
          _$SessionInfoImpl value, $Res Function(_$SessionInfoImpl) then) =
      __$$SessionInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String employee,
      @JsonKey(name: 'employee_name') String employeeName,
      List<String> roles,
      String? workspace,
      @JsonKey(name: 'workspace_label') String? workspaceLabel});
}

/// @nodoc
class __$$SessionInfoImplCopyWithImpl<$Res>
    extends _$SessionInfoCopyWithImpl<$Res, _$SessionInfoImpl>
    implements _$$SessionInfoImplCopyWith<$Res> {
  __$$SessionInfoImplCopyWithImpl(
      _$SessionInfoImpl _value, $Res Function(_$SessionInfoImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? employee = null,
    Object? employeeName = null,
    Object? roles = null,
    Object? workspace = freezed,
    Object? workspaceLabel = freezed,
  }) {
    return _then(_$SessionInfoImpl(
      employee: null == employee
          ? _value.employee
          : employee // ignore: cast_nullable_to_non_nullable
              as String,
      employeeName: null == employeeName
          ? _value.employeeName
          : employeeName // ignore: cast_nullable_to_non_nullable
              as String,
      roles: null == roles
          ? _value._roles
          : roles // ignore: cast_nullable_to_non_nullable
              as List<String>,
      workspace: freezed == workspace
          ? _value.workspace
          : workspace // ignore: cast_nullable_to_non_nullable
              as String?,
      workspaceLabel: freezed == workspaceLabel
          ? _value.workspaceLabel
          : workspaceLabel // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SessionInfoImpl implements _SessionInfo {
  const _$SessionInfoImpl(
      {required this.employee,
      @JsonKey(name: 'employee_name') required this.employeeName,
      final List<String> roles = const [],
      this.workspace,
      @JsonKey(name: 'workspace_label') this.workspaceLabel})
      : _roles = roles;

  factory _$SessionInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$SessionInfoImplFromJson(json);

  @override
  final String employee;
// ignore: invalid_annotation_target
  @override
  @JsonKey(name: 'employee_name')
  final String employeeName;
  final List<String> _roles;
  @override
  @JsonKey()
  List<String> get roles {
    if (_roles is EqualUnmodifiableListView) return _roles;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_roles);
  }

  @override
  final String? workspace;
// ignore: invalid_annotation_target
  @override
  @JsonKey(name: 'workspace_label')
  final String? workspaceLabel;

  @override
  String toString() {
    return 'SessionInfo(employee: $employee, employeeName: $employeeName, roles: $roles, workspace: $workspace, workspaceLabel: $workspaceLabel)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SessionInfoImpl &&
            (identical(other.employee, employee) ||
                other.employee == employee) &&
            (identical(other.employeeName, employeeName) ||
                other.employeeName == employeeName) &&
            const DeepCollectionEquality().equals(other._roles, _roles) &&
            (identical(other.workspace, workspace) ||
                other.workspace == workspace) &&
            (identical(other.workspaceLabel, workspaceLabel) ||
                other.workspaceLabel == workspaceLabel));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, employee, employeeName,
      const DeepCollectionEquality().hash(_roles), workspace, workspaceLabel);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SessionInfoImplCopyWith<_$SessionInfoImpl> get copyWith =>
      __$$SessionInfoImplCopyWithImpl<_$SessionInfoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SessionInfoImplToJson(
      this,
    );
  }
}

abstract class _SessionInfo implements SessionInfo {
  const factory _SessionInfo(
          {required final String employee,
          @JsonKey(name: 'employee_name') required final String employeeName,
          final List<String> roles,
          final String? workspace,
          @JsonKey(name: 'workspace_label') final String? workspaceLabel}) =
      _$SessionInfoImpl;

  factory _SessionInfo.fromJson(Map<String, dynamic> json) =
      _$SessionInfoImpl.fromJson;

  @override
  String get employee;
  @override // ignore: invalid_annotation_target
  @JsonKey(name: 'employee_name')
  String get employeeName;
  @override
  List<String> get roles;
  @override
  String? get workspace;
  @override // ignore: invalid_annotation_target
  @JsonKey(name: 'workspace_label')
  String? get workspaceLabel;
  @override
  @JsonKey(ignore: true)
  _$$SessionInfoImplCopyWith<_$SessionInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
