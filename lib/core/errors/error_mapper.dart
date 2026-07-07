import '../api/api_exceptions.dart';
import 'error_codes.dart';

/// Maps a PDT [ApiException] to a user-facing message string.
String messageFor(ApiException e) {
  switch (e.code) {
    case PdtErrorCode.notReadyForAlloc:
      return 'Lab/finance not cleared yet.';
    case PdtErrorCode.overPendingQty:
      return 'The quantity you entered is more than what is pending to receive. '
          'Please reduce the quantity and try again.';
    case PdtErrorCode.binFull:
      return 'That bin is full.';
    case PdtErrorCode.noActiveWorkspace:
      return 'Select a workspace first.';
    case PdtErrorCode.forbidden:
      return 'You are not permitted to do that.';
    case PdtErrorCode.duplicateRequest:
      return 'Already submitted.';
    case PdtErrorCode.validation:
      return _friendlyValidation(e.message);
    case PdtErrorCode.noStock:
      return 'No stock found in this location.';
    case PdtErrorCode.insufficientQty:
      return 'Insufficient quantity available.';
    case PdtErrorCode.poNotReceivable:
      return 'This Purchase Order cannot be received. '
          'It may already be fully received or cancelled.';
    default:
      return _sanitize(e.message);
  }
}

/// Converts common Frappe/ERPNext validation messages into user-friendly text.
String _friendlyValidation(String raw) {
  final lower = raw.toLowerCase();

  // Currency mismatch
  if (lower.contains('currency must be equal to') ||
      lower.contains('currency mismatch')) {
    // Extract the expected currency if present
    final match = RegExp(r"currency must be equal to '(\w+)'", caseSensitive: false)
        .firstMatch(raw);
    if (match != null) {
      return 'Currency mismatch — this order uses ${match.group(1)}. '
          'Please check the Purchase Order currency settings.';
    }
    return 'Currency mismatch. Please check the Purchase Order currency settings.';
  }

  // Quantity exceeds ordered/pending
  if (lower.contains('cannot be greater than') && lower.contains('qty')) {
    return 'The receive quantity exceeds what is allowed. '
        'Please reduce the quantity and try again.';
  }

  // Mandatory field missing
  if (lower.contains('mandatory') || lower.contains('is required')) {
    return 'A required field is missing. Please fill in all required fields and try again.';
  }

  // Duplicate entry
  if (lower.contains('duplicate') && lower.contains('name')) {
    return 'A receipt for this has already been created.';
  }

  // Already submitted/cancelled
  if (lower.contains('already submitted') || lower.contains('already cancelled')) {
    return 'This document has already been processed.';
  }

  // Warehouse not set
  if (lower.contains('warehouse') && (lower.contains('not set') || lower.contains('required'))) {
    return 'Warehouse is not configured. Please contact your administrator.';
  }

  // Rate or price missing
  if (lower.contains('rate') && (lower.contains('required') || lower.contains('cannot be 0'))) {
    return 'Item rate/price is missing. Please check the Purchase Order pricing.';
  }

  // Fall through — clean up the raw message
  return _sanitize(raw);
}

/// Strips HTML tags and trims the message for display.
String _sanitize(String message) {
  // Remove HTML tags that Frappe sometimes includes
  final cleaned = message.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  if (cleaned.isEmpty) return 'An unexpected error occurred. Please try again.';
  // Capitalize first letter
  return cleaned[0].toUpperCase() + cleaned.substring(1);
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
