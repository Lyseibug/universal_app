import 'package:hive/hive.dart';

part 'write_queue_entry.g.dart';

/// Status values for a queued write operation.
class QueueStatus {
  static const String pending = 'pending';
  static const String synced  = 'synced';
  static const String failed  = 'failed';
}

/// A persisted write operation waiting to be sent to the server.
///
/// Each entry stores:
///  - [id]       — a UUID v4 used both as the Hive key and as [request_id]
///                 in the API body (enables server-side deduplication).
///  - [method]   — the ERPNext method string, e.g. `grn.put_away`
///  - [bodyJson] — JSON-encoded body map; always contains `request_id`
///  - [status]   — one of [QueueStatus] constants
@HiveType(typeId: 10)
class WriteQueueEntry extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String method;

  @HiveField(2)
  String bodyJson;

  @HiveField(3)
  String status;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  DateTime? syncedAt;

  @HiveField(6)
  String? errorMessage;

  WriteQueueEntry({
    required this.id,
    required this.method,
    required this.bodyJson,
    this.status = QueueStatus.pending,
    required this.createdAt,
    this.syncedAt,
    this.errorMessage,
  });
}
