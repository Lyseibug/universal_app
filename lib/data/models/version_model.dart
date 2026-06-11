/// Model for version check response.
///
/// URL: https://universaltest.lyseibug.com/files/mobile-updates/version.json
///
/// Expected JSON format:
/// {
///   "latest_version": "1.0.2",
///   "minimum_version": "1.0.0",
///   "force_update": false,
///   "apk_url": "https://universaltest.lyseibug.com/files/mobile-updates/app-release.apk",
///   "message": "A new version is available with bug fixes."
/// }
///
/// Also supports legacy field names for backward compatibility:
/// - "current_version" → mapped to latestVersion
/// - "minimum_supported_version" → mapped to minimumVersion
/// - "update_url" → mapped to apkUrl
class VersionModel {
  /// The latest available version on the server.
  final String latestVersion;

  /// The minimum version the app must be to function.
  /// If installed version < minimumVersion → force update.
  final String minimumVersion;

  /// Whether the server explicitly requires a force update.
  final bool forceUpdate;

  /// Direct download URL for the APK file.
  final String apkUrl;

  /// Optional human-readable update message from the server.
  final String? message;

  const VersionModel({
    required this.latestVersion,
    required this.minimumVersion,
    required this.forceUpdate,
    required this.apkUrl,
    this.message,
  });

  /// Parse from server JSON response.
  /// Supports both new field names (latest_version, apk_url) and
  /// legacy field names (current_version, update_url).
  factory VersionModel.fromJson(Map<String, dynamic> json) {
    // Support both field naming conventions
    final latestVersion = _parseVersionString(
      json['latest_version'] ?? json['current_version'],
    );
    final minimumVersion = _parseVersionString(
      json['minimum_version'] ?? json['minimum_supported_version'],
    );
    final apkUrl = (json['apk_url'] ?? json['update_url'] ?? '') as String;

    return VersionModel(
      latestVersion: latestVersion,
      minimumVersion: minimumVersion,
      forceUpdate: json['force_update'] as bool? ?? false,
      apkUrl: apkUrl,
      message: json['message'] as String?,
    );
  }

  /// Safely parse a version string, falling back to "0.0.0" if invalid.
  static String _parseVersionString(dynamic value) {
    if (value == null) return '0.0.0';
    final str = value.toString().trim();
    if (str.isEmpty) return '0.0.0';
    // Validate it looks like a version (digits and dots)
    final versionRegex = RegExp(r'^\d+(\.\d+)*$');
    if (!versionRegex.hasMatch(str)) return '0.0.0';
    return str;
  }

  Map<String, dynamic> toJson() {
    return {
      'latest_version': latestVersion,
      'minimum_version': minimumVersion,
      'force_update': forceUpdate,
      'apk_url': apkUrl,
      'message': message,
    };
  }

  @override
  String toString() {
    return 'VersionModel(latest: $latestVersion, min: $minimumVersion, '
        'force: $forceUpdate, apkUrl: $apkUrl)';
  }
}

/// Enum representing the result of version comparison.
enum VersionStatus {
  /// App is up to date — no action needed.
  upToDate,

  /// A new optional update is available.
  updateAvailable,

  /// App version is below minimum — force update required.
  forceUpdate,
}
