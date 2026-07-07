import 'package:flutter_test/flutter_test.dart';
import 'package:universal_app/core/api/api_exceptions.dart';
import 'package:universal_app/core/errors/error_codes.dart';
import 'package:universal_app/core/errors/error_mapper.dart';

void main() {
  group('ErrorMapper Tests', () {
    test('messageFor maps known error codes correctly', () {
      expect(
        messageFor(const ApiException(PdtErrorCode.binFull, 'Full')),
        equals('That bin is full.'),
      );
      expect(
        messageFor(const ApiException(PdtErrorCode.notReadyForAlloc, 'Not ready')),
        equals('Lab/finance not cleared yet.'),
      );
      expect(
        messageFor(const ApiException(PdtErrorCode.overPendingQty, 'Too much')),
        contains('more than what is pending'),
      );
      expect(
        messageFor(const ApiException(PdtErrorCode.noActiveWorkspace, 'No ws')),
        equals('Select a workspace first.'),
      );
      expect(
        messageFor(const ApiException(PdtErrorCode.forbidden, 'Forbidden')),
        equals('You are not permitted to do that.'),
      );
      expect(
        messageFor(const ApiException(PdtErrorCode.duplicateRequest, 'Duplicate')),
        equals('Already submitted.'),
      );
    });

    test('messageFor returns dynamic message for validation and unknown errors', () {
      // Unknown validation messages pass through sanitized
      expect(
        messageFor(const ApiException(PdtErrorCode.validation, 'Item not found in bin')),
        equals('Item not found in bin'),
      );
      expect(
        messageFor(const ApiException('UNKNOWN_ERROR_CODE', 'Custom backend error')),
        equals('Custom backend error'),
      );
    });

    test('messageFor maps currency validation to user-friendly message', () {
      expect(
        messageFor(const ApiException(PdtErrorCode.validation,
            "currency must be equal to 'USD'")),
        contains('Currency mismatch'),
      );
      expect(
        messageFor(const ApiException(PdtErrorCode.validation,
            "currency must be equal to 'USD'")),
        contains('USD'),
      );
    });

    test('messageFor maps qty exceeds validation to user-friendly message', () {
      expect(
        messageFor(const ApiException(PdtErrorCode.validation,
            'Qty cannot be greater than ordered qty')),
        contains('receive quantity exceeds'),
      );
    });

    test('messageFor strips HTML tags from unknown messages', () {
      expect(
        messageFor(const ApiException(PdtErrorCode.validation,
            '<b>Some error</b> happened')),
        equals('Some error happened'),
      );
    });

    test('messageFor handles mandatory field errors', () {
      expect(
        messageFor(const ApiException(PdtErrorCode.validation,
            'Warehouse is mandatory')),
        contains('required field'),
      );
    });

    test('isFatal identifies blocking error codes correctly', () {
      expect(isFatal(PdtErrorCode.forbidden), isTrue);
      expect(isFatal(PdtErrorCode.unauthenticated), isTrue);
      expect(isFatal(PdtErrorCode.noActiveWorkspace), isTrue);
      expect(isFatal(PdtErrorCode.binFull), isFalse);
      expect(isFatal(PdtErrorCode.validation), isFalse);
    });

    test('isSilentSuccess identifies duplicate request correctly', () {
      expect(isSilentSuccess(PdtErrorCode.duplicateRequest), isTrue);
      expect(isSilentSuccess(PdtErrorCode.binFull), isFalse);
    });
  });
}
