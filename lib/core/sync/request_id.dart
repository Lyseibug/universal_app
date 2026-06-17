import 'package:uuid/uuid.dart';

/// Generates a unique Request ID (UUID v4) for idempotent API calls.
String newRequestId() => const Uuid().v4();
