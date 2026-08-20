import 'package:flutter_test/flutter_test.dart';
import 'package:muaman_store/models/cloud_session.dart';
import 'package:muaman_store/models/user.dart';
import 'package:muaman_store/services/session_state.dart';
import 'package:muaman_store/models/user_role.dart';

void main() {
  group('SessionState - Cloud Integration', () {
    late SessionState sessionState;

    setUp(() {
      sessionState = SessionState();
    });

    test('1. Initial state has no cloud session', () {
      expect(sessionState.cloudSession, isNull);
      expect(sessionState.isCloudLinked, false);
      expect(sessionState.isOnline, false);
      expect(sessionState.cloudUserId, isNull);
      expect(sessionState.activeShopId, isNull);
    });

    test('2. setCloudSession activates cloud context', () {
      const cloudSession = CloudSession(
        userId: 'cloud-user-1',
        activeShopId: 'shop-1',
        membershipRole: 'owner',
        membershipStatus: 'ACTIVE',
      );

      sessionState.setCloudSession(cloudSession);

      expect(sessionState.cloudSession, isNotNull);
      expect(sessionState.isCloudLinked, true);
      expect(sessionState.isOnline, true);
      expect(sessionState.cloudUserId, 'cloud-user-1');
      expect(sessionState.activeShopId, 'shop-1');
    });

    test('3. clearCloudSession removes cloud context', () {
      const cloudSession = CloudSession(
        userId: 'cloud-user-1',
        activeShopId: 'shop-1',
        membershipRole: 'owner',
        membershipStatus: 'ACTIVE',
      );

      sessionState.setCloudSession(cloudSession);
      expect(sessionState.isCloudLinked, true);

      sessionState.clearCloudSession();
      expect(sessionState.cloudSession, isNull);
      expect(sessionState.isCloudLinked, false);
    });

    test('4. logout clears both local and cloud session', () {
      final user = User(
        id: 1,
        displayName: 'Test User',
        username: 'testuser',
        passwordHash: 'hash',
        role: UserRole.owner,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
      sessionState.login(user);
      expect(sessionState.isLoggedIn, true);

      const cloudSession = CloudSession(
        userId: 'cloud-user-1',
        activeShopId: 'shop-1',
        membershipRole: 'owner',
        membershipStatus: 'ACTIVE',
      );
      sessionState.setCloudSession(cloudSession);
      expect(sessionState.isCloudLinked, true);

      sessionState.logout();
      expect(sessionState.isLoggedIn, false);
      expect(sessionState.isCloudLinked, false);
    });

    test('5. notifyListeners fires on setCloudSession', () {
      int notifyCount = 0;
      sessionState.addListener(() => notifyCount++);

      const cloudSession = CloudSession(
        userId: 'u1',
        activeShopId: 's1',
        membershipRole: 'owner',
        membershipStatus: 'ACTIVE',
      );
      sessionState.setCloudSession(cloudSession);

      expect(notifyCount, 1);
    });

    test('6. notifyListeners fires on clearCloudSession', () {
      const cloudSession = CloudSession(
        userId: 'u1',
        activeShopId: 's1',
        membershipRole: 'owner',
        membershipStatus: 'ACTIVE',
      );
      sessionState.setCloudSession(cloudSession);

      int notifyCount = 0;
      sessionState.addListener(() => notifyCount++);

      sessionState.clearCloudSession();
      expect(notifyCount, 1);
    });

    test('7. Cloud session with SUSPENDED status shows inactive', () {
      const cloudSession = CloudSession(
        userId: 'u1',
        activeShopId: 's1',
        membershipRole: 'employee',
        membershipStatus: 'SUSPENDED',
      );
      sessionState.setCloudSession(cloudSession);

      expect(sessionState.isCloudLinked, true);
      expect(sessionState.isOnline, false);
    });
  });
}
