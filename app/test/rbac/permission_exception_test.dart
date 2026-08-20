import 'package:flutter_test/flutter_test.dart';

import 'package:muaman_store/rbac/permission_exception.dart';

void main() {
  group('CloudPermissionException', () {
    test('fromRpcError maps unauthenticated', () {
      final ex = CloudPermissionException.fromRpcError('unauthenticated');
      expect(ex.error, CloudPermissionError.unauthenticated);
    });

    test('fromRpcError maps not_member', () {
      final ex = CloudPermissionException.fromRpcError('not_member');
      expect(ex.error, CloudPermissionError.notMember);
    });

    test('fromRpcError maps permission_denied', () {
      final ex = CloudPermissionException.fromRpcError(
          'permission_denied: inventory.edit');
      expect(ex.error, CloudPermissionError.permissionDenied);
      expect(ex.detail, 'permission_denied: inventory.edit');
    });

    test('fromRpcError maps license_required', () {
      final ex = CloudPermissionException.fromRpcError('license_required');
      expect(ex.error, CloudPermissionError.licenseRequired);
    });

    test('fromRpcError maps owner_required', () {
      final ex = CloudPermissionException.fromRpcError('owner_required');
      expect(ex.error, CloudPermissionError.ownerRequired);
    });

    test('fromRpcError maps override_violation', () {
      final ex =
          CloudPermissionException.fromRpcError('override_violation: test');
      expect(ex.error, CloudPermissionError.overrideViolation);
    });

    test('fromRpcError maps null to serverError', () {
      final ex = CloudPermissionException.fromRpcError(null);
      expect(ex.error, CloudPermissionError.serverError);
    });

    test('fromRpcError maps unknown message to serverError', () {
      final ex = CloudPermissionException.fromRpcError('some unknown error');
      expect(ex.error, CloudPermissionError.serverError);
    });

    test('userMessage returns Arabic text for each error type', () {
      for (final error in CloudPermissionError.values) {
        final ex = CloudPermissionException(error);
        expect(ex.userMessage, isNotEmpty);
        // Verify it's Arabic text (contains Arabic characters)
        expect(ex.userMessage.codeUnits.any((c) => c >= 0x0600 && c <= 0x06FF),
            true,
            reason: '${error.name} userMessage should contain Arabic text');
      }
    });

    test('toString includes error type', () {
      final ex = CloudPermissionException(
        CloudPermissionError.permissionDenied,
        message: 'test message',
      );
      expect(ex.toString(), contains('CloudPermissionException'));
      expect(ex.toString(), contains('permissionDenied'));
    });
  });
}
