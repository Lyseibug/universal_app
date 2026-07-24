/// Plain Dart (no Freezed/codegen) — see line2_models.dart for precedent.

/// A single selectable issue within a category, from `Down Time Reason`.
class DownTimeIssue {
  final String name;
  final String issue;

  const DownTimeIssue({required this.name, required this.issue});

  factory DownTimeIssue.fromJson(Map<String, dynamic> json) => DownTimeIssue(
        name: json['name']?.toString() ?? '',
        issue: json['issue']?.toString() ?? '',
      );
}

/// One category's worth of issues, as grouped by
/// maintenance_requests.resolve_issue_types.
class DownTimeIssueGroup {
  final String category;
  final List<DownTimeIssue> issues;

  const DownTimeIssueGroup({required this.category, this.issues = const []});

  factory DownTimeIssueGroup.fromJson(Map<String, dynamic> json) => DownTimeIssueGroup(
        category: json['category']?.toString() ?? '',
        issues: (json['issues'] as List?)
                ?.map((j) => DownTimeIssue.fromJson(Map<String, dynamic>.from(j)))
                .toList() ??
            const [],
      );
}

class MaintenanceRequestSummary {
  final String name;
  final String machine;
  final String issueType;
  final String category;
  final String description;
  final String urgency;
  final String status;
  final String? raisedBy;
  final String? raisedOn;
  final String? completedBy;
  final String? completedOn;

  const MaintenanceRequestSummary({
    required this.name,
    required this.machine,
    required this.issueType,
    this.category = '',
    this.description = '',
    this.urgency = '',
    this.status = 'Open',
    this.raisedBy,
    this.raisedOn,
    this.completedBy,
    this.completedOn,
  });

  factory MaintenanceRequestSummary.fromJson(Map<String, dynamic> json) => MaintenanceRequestSummary(
        name: json['name']?.toString() ?? '',
        machine: json['machine']?.toString() ?? '',
        issueType: json['issue_type']?.toString() ?? '',
        category: json['category']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        urgency: json['urgency']?.toString() ?? '',
        status: json['status']?.toString() ?? 'Open',
        raisedBy: json['raised_by']?.toString(),
        raisedOn: json['raised_on']?.toString(),
        completedBy: json['completed_by']?.toString(),
        completedOn: json['completed_on']?.toString(),
      );
}
