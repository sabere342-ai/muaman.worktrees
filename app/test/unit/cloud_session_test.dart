import 'package:flutter_test/flutter_test.dart';
import 'package:muaman_store/models/cloud_session.dart';

void main() {
  group('CloudSession', () {
    test('1. Create cloud session with all fields', () {
      const session = CloudSession(
        userId: 'user-123',
        activeShopId: 'shop-456',
        membershipRole: 'owner',
        membershipStatus: 'ACTIVE',
      );

      expect(session.userId, 'user-123');
      expect(session.activeShopId, 'shop-456');
      expect(session.membershipRole, 'owner');
      expect(session.membershipStatus, 'ACTIVE');
    });

    test('2. isActive returns true for ACTIVE status', () {
      const session = CloudSession(
        userId: 'u1',
        activeShopId: 's1',
        membershipRole: 'owner',
        membershipStatus: 'ACTIVE',
      );
      expect(session.isActive, true);
    });

    test('3. isActive returns false for SUSPENDED status', () {
      const session = CloudSession(
        userId: 'u1',
        activeShopId: 's1',
        membershipRole: 'employee',
        membershipStatus: 'SUSPENDED',
      );
      expect(session.isActive, false);
    });

    test('4. isOwner returns true for owner role', () {
      const session = CloudSession(
        userId: 'u1',
        activeShopId: 's1',
        membershipRole: 'owner',
        membershipStatus: 'ACTIVE',
      );
      expect(session.isOwner, true);
    });

    test('5. isOwner returns false for employee role', () {
      const session = CloudSession(
        userId: 'u1',
        activeShopId: 's1',
        membershipRole: 'employee',
        membershipStatus: 'ACTIVE',
      );
      expect(session.isOwner, false);
    });

    test('6. Equality - identical sessions are equal', () {
      const s1 = CloudSession(
        userId: 'u1',
        activeShopId: 's1',
        membershipRole: 'owner',
        membershipStatus: 'ACTIVE',
      );
      const s2 = CloudSession(
        userId: 'u1',
        activeShopId: 's1',
        membershipRole: 'owner',
        membershipStatus: 'ACTIVE',
      );
      expect(s1, equals(s2));
      expect(s1.hashCode, equals(s2.hashCode));
    });

    test('7. Equality - different sessions are not equal', () {
      const s1 = CloudSession(
        userId: 'u1',
        activeShopId: 's1',
        membershipRole: 'owner',
        membershipStatus: 'ACTIVE',
      );
      const s2 = CloudSession(
        userId: 'u2',
        activeShopId: 's1',
        membershipRole: 'owner',
        membershipStatus: 'ACTIVE',
      );
      expect(s1, isNot(equals(s2)));
    });

    test('8. toString contains all fields', () {
      const session = CloudSession(
        userId: 'u1',
        activeShopId: 's1',
        membershipRole: 'employee',
        membershipStatus: 'ACTIVE',
      );
      final str = session.toString();
      expect(str, contains('u1'));
      expect(str, contains('s1'));
      expect(str, contains('employee'));
    });
  });
}
