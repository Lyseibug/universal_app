import 'package:flutter/foundation.dart';

import 'file_logger.dart';

/// Simple application logger utility.
///
/// Console output (`print`) only happens in debug builds. Warnings and
/// errors are additionally persisted to a rotating on-disk log file
/// (see [FileLogger]) so they can be recovered from a release build.
class AppLogger {
  AppLogger._();

  /// Call once at app startup, before any logging, to enable file output.
  /// Safe to skip — logging still works, just without the file sink.
  static Future<void> init() => FileLogger.init();

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
    FileLogger.instance?.log('ERROR', message, tag: tag, error: error, stackTrace: stackTrace);
  }

  static void warning(String message, {String? tag}) {
    if (kDebugMode) {
      print('[WARN]${tag != null ? '[$tag]' : ''} $message');
    }
    FileLogger.instance?.log('WARN', message, tag: tag);
  }

  static void debug(String message, {String? tag}) {
    if (kDebugMode) {
      print('[DEBUG]${tag != null ? '[$tag]' : ''} $message');
    }
  }
}
