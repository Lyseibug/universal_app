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
        equals('Quantity exceeds what is pending.'),
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
      expect(
        messageFor(const ApiException(PdtErrorCode.validation, 'Item not found in bin')),
        equals('Item not found in bin'),
      );
      expect(
        messageFor(const ApiException('UNKNOWN_ERROR_CODE', 'Custom backend error')),
        equals('Custom backend error'),
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
