/// Model for version check API response.
/// Matches the server JSON format:
/// {
///   "current_version": "1.1.0",
///   "minimum_supported_version": "1.0.0",
///   "force_update": false,
///   "update_url": "https://universaltest.lyseibug.com/files/universal-v1.1.0.apk",
///   "message": "A new version is available."
/// }
class VersionModel {
  final String currentVersion;
  final String minimumSupportedVersion;
  final bool forceUpdate;
  final String updateUrl;
  final String? message;

  const VersionModel({
    required this.currentVersion,
    required this.minimumSupportedVersion,
    required this.forceUpdate,
    required this.updateUrl,
    this.message,
  });

  factory VersionModel.fromJson(Map<String, dynamic> json) {
    return VersionModel(
      currentVersion: json['current_version'] as String? ?? '1.0.0',
      minimumSupportedVersion:
          json['minimum_supported_version'] as String? ?? '1.0.0',
      forceUpdate: json['force_update'] as bool? ?? false,
      updateUrl: json['update_url'] as String? ?? '',
      message: json['message'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current_version': currentVersion,
      'minimum_supported_version': minimumSupportedVersion,
      'force_update': forceUpdate,
      'update_url': updateUrl,
      'message': message,
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
