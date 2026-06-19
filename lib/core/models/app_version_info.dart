/// Model for the version check response from ERPNext.
///
/// Matches the JSON shape returned by:
///   /api/method/universal_mobile_api.api.app_update.get_version_info
///
/// Response envelope from Frappe:
///   { "message": { "latest_version": ..., "minimum_version": ..., ... } }
class AppVersionInfo {
  final String latestVersion;
  final String minimumVersion;
  final bool forceUpdate;

  /// Full URL to the APK file, e.g. https://erp.example.com/files/app-release-v1.1.0.apk
  final String apkUrl;

  /// Human-readable release notes shown in the update dialog.
  final String message;

  const AppVersionInfo({
    required this.latestVersion,
    required this.minimumVersion,
    required this.forceUpdate,
    required this.apkUrl,
    required this.message,
  });

  factory AppVersionInfo.fromJson(Map<String, dynamic> json) {
    return AppVersionInfo(
      latestVersion: (json['latest_version'] ?? '').toString(),
      minimumVersion: (json['minimum_version'] ?? '').toString(),
      forceUpdate: json['force_update'] == true || json['force_update'] == 1,
      apkUrl: (json['apk_url'] ?? '').toString(),
      message: (json['message'] ?? 'A new version is available.').toString(),
    );
  }
}

/// The result of comparing the running app version against [AppVersionInfo].
enum UpdateStatus {
  /// App is at the latest version — no action needed.
  upToDate,

  /// A new version is available but not mandatory. Show a dismissible reminder.
  updateAvailable,

  /// Running version is below [AppVersionInfo.minimumVersion] OR
  /// [AppVersionInfo.forceUpdate] is true. Show a non-dismissible reminder.
  forceUpdate,
}
