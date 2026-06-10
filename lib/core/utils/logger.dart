import 'package:flutter/foundation.dart';

/// Simple application logger utility.
/// In production, this can be replaced with a logging framework.
class AppLogger {
  AppLogger._();

  static void info(String message, {String? tag}) {
    if (kDebugMode) {
      print('[INFO]${tag != null ? '[$tag]' : ''} $message');
    }
  }

  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? tag,
  }) {
    if (kDebugMode) {
      print('[ERROR]${tag != null ? '[$tag]' : ''} $message');
      if (error != null) print('  Error: $error');
      if (stackTrace != null) print('  StackTrace: $stackTrace');
    }
  }

  static void warning(String message, {String? tag}) {
    if (kDebugMode) {
      print('[WARN]${tag != null ? '[$tag]' : ''} $message');
    }
  }

  static void debug(String message, {String? tag}) {
    if (kDebugMode) {
      print('[DEBUG]${tag != null ? '[$tag]' : ''} $message');
    }
  }
}
