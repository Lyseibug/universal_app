import '../api/api_exceptions.dart';
import 'error_codes.dart';

/// Maps a PDT [ApiException] to a user-facing message string.
String messageFor(ApiException e) {
  switch (e.code) {
    case PdtErrorCode.notReadyForAlloc:
      return 'Lab/finance not cleared yet.';
    case PdtErrorCode.overPendingQty:
      return 'Quantity exceeds what is pending.';
    case PdtErrorCode.binFull:
      return 'That bin is full.';
    case PdtErrorCode.noActiveWorkspace:
      return 'Select a workspace first.';
    case PdtErrorCode.forbidden:
      return 'You are not permitted to do that.';
    case PdtErrorCode.duplicateRequest:
      return 'Already submitted.';
    case PdtErrorCode.validation:
      return e.message;
    case PdtErrorCode.noStock:
      return 'No stock found in this location.';
    case PdtErrorCode.insufficientQty:
      return 'Insufficient quantity available.';
    default:
      return e.message;
  }
}

/// Returns `true` if this code should block the current operation entirely.
///
/// A fatal error shows a blocking dialog rather than a transient snackbar.
bool isFatal(String code) {
  return code == PdtErrorCode.forbidden ||
      code == PdtErrorCode.unauthenticated ||
      code == PdtErrorCode.noActiveWorkspace;
}

/// Returns `true` if this code can be silently treated as success.
bool isSilentSuccess(String code) =>
    code == PdtErrorCode.duplicateRequest;
