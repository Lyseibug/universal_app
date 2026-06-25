/// PDT-specific error codes returned by `universal_mobile_api`.
///
/// These codes appear in the server's error envelope:
///   `{ "error": true, "code": "BIN_FULL", "message": "..." }`
abstract class PdtErrorCode {
  /// Session cookie expired or invalid — force re-login.
  static const String unauthenticated      = 'UNAUTHENTICATED';

  /// User does not have permission to perform this action.
  /// Hard stop — do not allow continuation.
  static const String forbidden            = 'FORBIDDEN';

  /// The target bin has no remaining capacity.
  static const String binFull              = 'BIN_FULL';

  /// The quantity exceeds the pending allocation.
  static const String overPendingQty       = 'OVER_PENDING_QTY';

  /// The GRN line has not been approved for allocation yet.
  static const String notReadyForAlloc     = 'NOT_READY_FOR_ALLOCATION';

  /// No active workspace is assigned to this employee.
  static const String noActiveWorkspace    = 'NO_ACTIVE_WORKSPACE';

  /// The request_id has already been processed (safe to treat as success).
  static const String duplicateRequest     = 'DUPLICATE_REQUEST';

  /// Server-side input validation failed.
  static const String validation           = 'VALIDATION';

  /// No stock found for the requested item/location.
  static const String noStock              = 'NO_STOCK';

  /// Insufficient quantity available for the operation.
  static const String insufficientQty      = 'INSUFFICIENT_QTY';

  /// PO status does not allow reception.
  static const String poNotReceivable      = 'PO_NOT_RECEIVABLE';
}
