/// A workstation assignment the employee can select at login.
///
/// Plain Dart (no Freezed/codegen) — see line2_models.dart for precedent.
class WorkspaceModel {
  final String assignment;
  final String productionLine;
  final List<String> workstations;
  final String supervisor;
  final String supervisorName;

  const WorkspaceModel({
    required this.assignment,
    this.productionLine = '',
    this.workstations = const [],
    this.supervisor = '',
    this.supervisorName = '',
  });

  /// Human-readable label for this assignment, e.g. "Line L1".
  String get label =>
      productionLine.isNotEmpty ? 'Line $productionLine' : (workstations.isNotEmpty ? workstations.first : assignment);

  factory WorkspaceModel.fromJson(Map<String, dynamic> json) => WorkspaceModel(
        assignment: json['assignment']?.toString() ?? json['name']?.toString() ?? '',
        productionLine: json['production_line']?.toString() ?? '',
        workstations: (json['workstations'] as List?)?.map((w) => w.toString()).toList() ?? const [],
        supervisor: json['supervisor']?.toString() ?? '',
        supervisorName: json['supervisor_name']?.toString() ?? '',
      );
}

/// Session information returned after login + workstation selection.
class SessionInfo {
  final String? employee;
  final String? employeeName;
  final List<String> roles;
  final String? workspace;
  final String? workspaceLabel;
  final String? productionLine;
  final List<String> assignedStations;
  /// PDT screen to auto-open for the selected workstation (e.g.
  /// 'line2_curing') — null/empty means no auto-routing, land on the tile
  /// menu as before.
  final String? screenKey;
  /// True when PDT Settings.skip_workstation_roles includes one of this
  /// user's roles — they land on Home directly, bypassing /workspace.
  final bool skipWorkstation;

  const SessionInfo({
    this.employee,
    this.employeeName,
    this.roles = const [],
    this.workspace,
    this.workspaceLabel,
    this.productionLine,
    this.assignedStations = const [],
    this.screenKey,
    this.skipWorkstation = false,
  });

  factory SessionInfo.fromJson(Map<String, dynamic> json) => SessionInfo(
        employee: json['employee']?.toString(),
        employeeName: json['employee_name']?.toString(),
        roles: (json['roles'] as List?)?.map((r) => r.toString()).toList() ?? const [],
        workspace: json['workspace']?.toString(),
        workspaceLabel: json['workspace_label']?.toString(),
        productionLine: json['production_line']?.toString(),
        assignedStations: (json['assigned_stations'] as List?)?.map((s) => s.toString()).toList() ?? const [],
        screenKey: json['screen_key']?.toString(),
        skipWorkstation: json['skip_workstation'] == true,
      );

  Map<String, dynamic> toJson() => {
        'employee': employee,
        'employee_name': employeeName,
        'roles': roles,
        'workspace': workspace,
        'workspace_label': workspaceLabel,
        'production_line': productionLine,
        'assigned_stations': assignedStations,
        'screen_key': screenKey,
        'skip_workstation': skipWorkstation,
      };
}
