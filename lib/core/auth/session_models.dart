import 'package:freezed_annotation/freezed_annotation.dart';

part 'session_models.freezed.dart';
part 'session_models.g.dart';

/// A workspace/assignment the employee can select at login.
@freezed
class WorkspaceModel with _$WorkspaceModel {
  const factory WorkspaceModel({
    required String assignment,
    required String label,
    @Default('') String warehouse,
    @Default('') String supervisor,
    // ignore: invalid_annotation_target
    @JsonKey(name: 'supervisor_name') @Default('') String supervisorName,
  }) = _WorkspaceModel;

  factory WorkspaceModel.fromJson(Map<String, dynamic> json) =>
      _$WorkspaceModelFromJson(_preProcess(json));

  static Map<String, dynamic> _preProcess(Map<String, dynamic> json) {
    final adjusted = Map<String, dynamic>.from(json);
    adjusted['assignment'] ??= json['name'] ?? json['id'] ?? '';
    adjusted['label'] ??= json['workspace_label'] ?? json['workspace'] ?? adjusted['assignment'] ?? 'Workspace';
    return adjusted;
  }
}

/// Session information returned after login + workspace selection.
@freezed
class SessionInfo with _$SessionInfo {
  const factory SessionInfo({
    required String employee,
    // ignore: invalid_annotation_target
    @JsonKey(name: 'employee_name') required String employeeName,
    @Default([]) List<String> roles,
    String? workspace,
    // ignore: invalid_annotation_target
    @JsonKey(name: 'workspace_label') String? workspaceLabel,
  }) = _SessionInfo;

  factory SessionInfo.fromJson(Map<String, dynamic> json) =>
      _$SessionInfoFromJson(json);
}
