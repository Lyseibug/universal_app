import 'package:flutter/services.dart';

class KioskService {
  static const MethodChannel _channel = MethodChannel('app.kiosk/mode');

  /// Opens the system Home app selection settings so an admin can change
  /// the default launcher. Useful for a non-MDM fallback kiosk flow.
  static Future<bool> openHomeSettings() async {
    try {
      final res = await _channel.invokeMethod<bool>('openHomeSettings');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Returns true if this app is currently the system default launcher.
  static Future<bool> isDefaultLauncher() async {
    try {
      final res = await _channel.invokeMethod<bool>('isDefaultLauncher');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }
}
