import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

import '../api/api_client.dart';
import '../api/api_exceptions.dart';
import '../utils/logger.dart';
import 'request_id.dart';
import 'write_queue_entry.dart';

const _tag = 'WriteQueue';

/// Offline-safe write queue backed by Hive.
///
/// Implements immediate write attempts and background flushes for idempotency.
class WriteQueue {
  final ApiClient _apiClient;
  final Box<WriteQueueEntry> _box;

  WriteQueue({required ApiClient apiClient, required Box<WriteQueueEntry> box})
      : _apiClient = apiClient,
        _box = box;

  /// Pending entries sorted by creation time (oldest first).
  List<WriteQueueEntry> get pendingEntries => _box.values
      .where((e) => e.status == QueueStatus.pending)
      .toList()
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  /// All entries (for status display in UI).
  List<WriteQueueEntry> get allEntries => _box.values.toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  /// Enqueue and try immediately; safe to retry with the SAME requestId.
  ///
  /// Generates a UUID v4 as [request_id] and persists the entry to Hive.
  /// Bubbles errors up to the UI, but keeps the record in the queue for retry/flushing.
  Future<dynamic> run(String method, Map<String, dynamic> body) async {
    final id = body['request_id']?.toString() ?? newRequestId();
    final bodyWithId = Map<String, dynamic>.from(body)..['request_id'] = id;

    final entry = WriteQueueEntry(
      id: id,
      method: method,
      bodyJson: jsonEncode(bodyWithId),
      createdAt: DateTime.now(),
      status: QueueStatus.pending,
    );

    await _box.put(id, entry);
    AppLogger.info('Enqueued write $method (id=$id)', tag: _tag);

    try {
      final data = await _apiClient.call(method, body: bodyWithId);
      entry.status = QueueStatus.synced;
      entry.syncedAt = DateTime.now();
      entry.errorMessage = null;
      await entry.save();
      AppLogger.info('Synced write $method (id=$id) immediately', tag: _tag);
      return data;
    } on ApiException catch (e) {
      if (e.code == 'DUPLICATE_REQUEST') {
        entry.status = QueueStatus.synced;
        entry.syncedAt = DateTime.now();
        entry.errorMessage = null;
        await entry.save();
        AppLogger.info('DUPLICATE_REQUEST received immediately (id=$id) — treated as synced', tag: _tag);
        return null;
      }
      entry.status = QueueStatus.failed;
      entry.errorMessage = e.message;
      await entry.save();
      rethrow; // surface to UI
    } catch (e) {
      // Network/transport error: keep as pending in the queue, but rethrow
      entry.errorMessage = e.toString();
      await entry.save();
      rethrow;
    }
  }

  /// Flush all pending entries in order.
  ///
  /// Safe to call repeatedly. Handles server-side duplicate request responses.
  Future<void> flush() async {
    final pending = pendingEntries;
    if (pending.isEmpty) return;

    AppLogger.info('Flushing ${pending.length} pending writes', tag: _tag);

    for (final entry in pending) {
      try {
        final body = jsonDecode(entry.bodyJson) as Map<String, dynamic>;
        await _apiClient.call(entry.method, body: body);
        entry
          ..status = QueueStatus.synced
          ..syncedAt = DateTime.now()
          ..errorMessage = null;
        await entry.save();
        AppLogger.info('Synced ${entry.method} (id=${entry.id}) during flush', tag: _tag);
      } on ApiException catch (e) {
        if (e.code == 'DUPLICATE_REQUEST') {
          entry
            ..status = QueueStatus.synced
            ..syncedAt = DateTime.now()
            ..errorMessage = null;
          await entry.save();
          AppLogger.info('DUPLICATE_REQUEST treated as synced (id=${entry.id}) during flush', tag: _tag);
        } else {
          entry
            ..status = QueueStatus.failed
            ..errorMessage = e.message;
          await entry.save();
          AppLogger.warning('Failed ${entry.method}: ${e.message} (id=${entry.id}) during flush', tag: _tag);
        }
      } catch (e) {
        entry.errorMessage = e.toString();
        await entry.save();
        AppLogger.warning('Network/server error while flushing ${entry.method}: $e', tag: _tag);
        break; // stop on transport error to preserve sequence order
      }
    }
  }

  /// Manually retry a specific failed entry.
  Future<void> retry(String id) async {
    final entry = _box.get(id);
    if (entry == null) return;
    entry.status = QueueStatus.pending;
    await entry.save();
    await flush();
  }

  /// Clear all synced entries (housekeeping).
  Future<void> clearSynced() async {
    final synced = _box.values
        .where((e) => e.status == QueueStatus.synced)
        .map((e) => e.key)
        .toList();
    await _box.deleteAll(synced);
  }
}
