/// Model for version check API response.
class VersionModel {
  final String currentVersion;
  final String minimumSupportedVersion;
  final String updateUrl;

  const VersionModel({
    required this.currentVersion,
    required this.minimumSupportedVersion,
    required this.updateUrl,
  });

  factory VersionModel.fromJson(Map<String, dynamic> json) {
    return VersionModel(
      currentVersion: json['current_version'] as String? ?? '1.0.0',
      minimumSupportedVersion:
          json['minimum_supported_version'] as String? ?? '1.0.0',
      updateUrl: json['update_url'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current_version': currentVersion,
      'minimum_supported_version': minimumSupportedVersion,
      'update_url': updateUrl,
    };
  }
}

/// Enum representing the result of version comparison.
enum VersionStatus {
  /// App is up to date.
  upToDate,

  /// A new optional update is available.
  updateAvailable,

  /// App version is below minimum; force update required.
  forceUpdate,
}
