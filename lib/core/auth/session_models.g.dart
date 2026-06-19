// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$WorkspaceModelImpl _$$WorkspaceModelImplFromJson(Map<String, dynamic> json) =>
    _$WorkspaceModelImpl(
      assignment: json['assignment'] as String,
      label: json['label'] as String,
      warehouse: json['warehouse'] as String? ?? '',
      supervisor: json['supervisor'] as String? ?? '',
      supervisorName: json['supervisor_name'] as String? ?? '',
    );

Map<String, dynamic> _$$WorkspaceModelImplToJson(
        _$WorkspaceModelImpl instance) =>
    <String, dynamic>{
      'assignment': instance.assignment,
      'label': instance.label,
      'warehouse': instance.warehouse,
      'supervisor': instance.supervisor,
      'supervisor_name': instance.supervisorName,
    };

_$SessionInfoImpl _$$SessionInfoImplFromJson(Map<String, dynamic> json) =>
    _$SessionInfoImpl(
      employee: json['employee'] as String,
      employeeName: json['employee_name'] as String,
      roles:
          (json['roles'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      workspace: json['workspace'] as String?,
      workspaceLabel: json['workspace_label'] as String?,
    );

Map<String, dynamic> _$$SessionInfoImplToJson(_$SessionInfoImpl instance) =>
    <String, dynamic>{
      'employee': instance.employee,
      'employee_name': instance.employeeName,
      'roles': instance.roles,
      'workspace': instance.workspace,
      'workspace_label': instance.workspaceLabel,
    };
