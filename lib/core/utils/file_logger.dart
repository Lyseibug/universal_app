import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Rotating on-disk log sink.
///
/// Writes append to `logs/app.log` under the app's documents directory.
/// Once the active file would exceed [maxBytes] the file is rotated:
/// app.log -> app.log.1 -> app.log.2 ... up to [maxBackups], oldest dropped.
/// Writes are serialized through a single Future chain so callers never
/// need to await file I/O, and a failure here can never crash the app.
class FileLogger {
  FileLogger._(this._logDir);

  static const int maxBytes = 5 * 1024 * 1024; // 5MB
  static const int maxBackups = 3; // app.log.1 .. app.log.3 (~20MB total)

  static FileLogger? _instance;

  final Directory _logDir;
  Future<void> _writeChain = Future<void>.value();

  File get _activeFile => File('${_logDir.path}/app.log');

  /// Must be called once (e.g. in `main()`) before [instance] is used.
  static Future<FileLogger> init() async {
    if (_instance != null) return _instance!;
    final docsDir = await getApplicationDocumentsDirectory();
    final logDir = Directory('${docsDir.path}/logs');
    if (!await logDir.exists()) {
      await logDir.create(recursive: true);
    }
    final logger = FileLogger._(logDir);
    _instance = logger;
    return logger;
  }

  /// Available once [init] has completed; null before that (writes are
  /// silently dropped so early-boot logging never throws).
  static FileLogger? get instance => _instance;

  /// Directory holding the active log file and its rotated backups.
  String get directoryPath => _logDir.path;

  /// Queue a line for the active log file. Never throws.
  void log(String level, String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    final entry = _format(level, message, tag: tag, error: error, stackTrace: stackTrace);
    // Chain writes so concurrent log calls don't interleave or race on rotation.
    _writeChain = _writeChain.then((_) => _write(entry)).catchError((_) {});
  }

  String _format(String level, String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    final ts = DateTime.now().toIso8601String();
    final buffer = StringBuffer('$ts [$level]${tag != null ? '[$tag]' : ''} $message\n');
    if (error != null) buffer.write('  Error: $error\n');
    if (stackTrace != null) buffer.write('  StackTrace: $stackTrace\n');
    return buffer.toString();
  }

  Future<void> _write(String entry) async {
    final bytes = utf8.encode(entry);
    final file = _activeFile;
    final currentLength = await file.exists() ? await file.length() : 0;
    if (currentLength + bytes.length > maxBytes) {
      await _rotate();
    }
    await file.writeAsBytes(bytes, mode: FileMode.append, flush: false);
  }

  Future<void> _rotate() async {
    for (var i = maxBackups; i >= 1; i--) {
      final src = i == 1 ? _activeFile : File('${_logDir.path}/app.log.${i - 1}');
      final dst = File('${_logDir.path}/app.log.$i');
      if (await src.exists()) {
        if (await dst.exists()) await dst.delete();
        await src.rename(dst.path);
      }
    }
  }
}
