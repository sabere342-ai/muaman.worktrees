import 'package:flutter_test/flutter_test.dart';
import 'package:muaman_store/database/database_helper.dart';
import 'package:muaman_store/database/user_repository.dart';
import 'package:muaman_store/models/user_role.dart';
import 'package:muaman_store/services/seller_session_provisioning.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers/test_schema.dart';

/// Phase L (D-L3) — fresh-device seller bootstrap.
///
/// Proves the AuthGate branching predicate and that a NON-OWNER cloud
/// login on a fresh device provisions its own local cache row (flipping
/// hasAnyUser) WITHOUT being able to create or elevate ownership, while
/// an owner-role cloud identity is rejected leaving the device untouched.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfiNoIsolate;

  late Database testDb;

  setUp(() async {
    testDb =
        await databaseFactoryFfiNoIsolate.openDatabase(inMemoryDatabasePath);
    await createTestSchema(testDb);
    DatabaseHelper.setTestDatabase(testDb);
  });

  tearDown(() async {
    await testDb.close();
    DatabaseHelper.resetForTest();
  });

  group('fresh-device gate predicate', () {
    test('offers bootstrap only when Supabase is configured AND no users', () {
      expect(
        offersFreshDeviceCloudBootstrap(
            hasLocalUsers: false, supabaseConfigured: true),
        isTrue,
      );
      // Historical behavior preserved without Supabase configuration:
      expect(
          offersFreshDeviceCloudBootstrap(
              hasLocalUsers: false, supabaseConfigured: false),
          isFalse,
          reason: 'offline fresh device must keep the owner-setup-only path');
      // Existing installs with local users never see the chooser:
      expect(
        offersFreshDeviceCloudBootstrap(
            hasLocalUsers: true, supabaseConfigured: true),
        isFalse,
      );
      expect(
        offersFreshDeviceCloudBootstrap(
            hasLocalUsers: true, supabaseConfigured: false),
        isFalse,
      );
    });
  });

  group('fresh-device seller provisioning', () {
    test(
        'non-owner cloud login provisions a cache row and flips '
        'hasAnyUser without granting ownership', () async {
      final repo = UserRepository();
      expect(await repo.hasAnyUser(), isFalse);

      // Exactly what AuthGate's onSellerAuthenticated flow relies on:
      // provisioning creates the row so the normal login/shell flow takes
      // over; the role stays seller-grade.
      final user = await repo.upsertCloudUser(
        cloudUuid: 'fresh-seller-uuid',
        displayName: 'بائع جديد',
        membershipRole: 'employee',
      );

      expect(await repo.hasAnyUser(), isTrue);
      expect(user.role, UserRole.employee);
      expect(user.role, isNot(UserRole.owner));
      expect(await repo.getUserByCloudUuid('fresh-seller-uuid'), isNotNull);
    });

    test(
        'owner-role cloud identity CANNOT claim the fresh device — no row, '
        'no users', () async {
      final repo = UserRepository();
      expect(await repo.hasAnyUser(), isFalse);

      expect(
        () => repo.upsertCloudUser(
          cloudUuid: 'hijacker-owner-uuid',
          displayName: 'مالك؟',
          membershipRole: 'owner',
        ),
        throwsA(isA<CloudIdentityRoleConflictException>()),
      );

      expect(await repo.hasAnyUser(), isFalse,
          reason: 'a rejected owner cloud login must leave the fresh '
              'device untouched');
      expect(await repo.getAllUsers(), isEmpty);
    });

    test('salesOnly membership maps to the frozen salesOnly permission set',
        () async {
      final repo = UserRepository();
      final user = await repo.upsertCloudUser(
        cloudUuid: 'fresh-sales-uuid',
        membershipRole: 'salesOnly',
      );
      expect(user.role, UserRole.salesOnly);
    });
  });
}
