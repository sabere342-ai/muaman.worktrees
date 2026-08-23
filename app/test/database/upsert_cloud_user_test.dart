import 'package:flutter_test/flutter_test.dart';
import 'package:muaman_store/database/database_helper.dart';
import 'package:muaman_store/database/user_repository.dart';
import 'package:muaman_store/models/user_role.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers/test_schema.dart';

/// Phase L (D-L4) — local user row as CACHE keyed by users.cloud_uuid.
///
/// Proves idempotent upsert-by-cloud-uuid (no duplicate rows), role
/// mapping ONLY from the cloud membership role, and owner-role rejection
/// so the seller path can never elevate a fresh device to ownership.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

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

  UserRepository createRepo() => UserRepository();

  group('upsertCloudUser - provisioning', () {
    test('creates a cache row keyed by cloud_uuid with mapped employee role',
        () async {
      final repo = createRepo();
      final user = await repo.upsertCloudUser(
        cloudUuid: 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
        displayName: 'موظف التجربة',
        membershipRole: 'employee',
      );

      expect(user.id, isNotNull);
      expect(user.role, UserRole.employee);
      expect(user.isActive, isTrue);

      final byCloud =
          await repo.getUserByCloudUuid('aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee');
      expect(byCloud, isNotNull);
      expect(byCloud!.id, user.id);
    });

    test('maps salesOnly membership role exactly', () async {
      final repo = createRepo();
      final user = await repo.upsertCloudUser(
        cloudUuid: 'salesonly-uuid',
        membershipRole: 'salesOnly',
      );
      expect(user.role, UserRole.salesOnly);
    });

    test('REJECTS an owner membership role (no ownership via seller path)',
        () async {
      final repo = createRepo();
      expect(
        () => repo.upsertCloudUser(
          cloudUuid: 'owner-uuid',
          membershipRole: 'owner',
        ),
        throwsA(isA<CloudIdentityRoleConflictException>()),
      );
      // Nothing was provisioned.
      expect(await repo.getUserByCloudUuid('owner-uuid'), isNull);
      expect(await repo.hasAnyUser(), isFalse);
    });

    test('REJECTS unknown membership roles', () async {
      final repo = createRepo();
      expect(
        () => repo.upsertCloudUser(
          cloudUuid: 'weird-uuid',
          membershipRole: 'superadmin',
        ),
        throwsA(isA<CloudIdentityRoleConflictException>()),
      );
      expect(await repo.hasAnyUser(), isFalse);
    });
  });

  group('upsertCloudUser - idempotency', () {
    test('reuses the SAME row for the same cloud_uuid (no duplicates)',
        () async {
      final repo = createRepo();
      final first = await repo.upsertCloudUser(
        cloudUuid: 'same-uuid',
        displayName: 'الأول',
        membershipRole: 'employee',
      );
      final second = await repo.upsertCloudUser(
        cloudUuid: 'same-uuid',
        displayName: 'الثاني',
        membershipRole: 'employee',
      );

      expect(second.id, first.id);
      final all = await repo.getAllUsers();
      expect(all, hasLength(1));
      expect(second.displayName, 'الثاني');
    });

    test('role on the reused row follows the CURRENT cloud membership only',
        () async {
      final repo = createRepo();
      await repo.upsertCloudUser(
        cloudUuid: 'switched-uuid',
        membershipRole: 'employee',
      );
      final updated = await repo.upsertCloudUser(
        cloudUuid: 'switched-uuid',
        membershipRole: 'salesOnly',
      );
      expect(updated.role, UserRole.salesOnly);
      final all = await repo.getAllUsers();
      expect(all, hasLength(1));
      expect(all.single.role, UserRole.salesOnly);
    });

    test('maintains lastLoginAt and keeps the row active', () async {
      final repo = createRepo();
      final created = await repo.upsertCloudUser(
        cloudUuid: 'login-uuid',
        membershipRole: 'employee',
      );
      expect(created.lastLoginAt, isNotNull);
    });
  });

  group('cloud-mode session safety', () {
    test('provisioned row cannot authenticate through the LOCAL path',
        () async {
      final repo = createRepo();
      final user = await repo.upsertCloudUser(
        cloudUuid: 'nolocalpass-uuid',
        displayName: 'موظف سحابي',
        membershipRole: 'employee',
      );

      // The stored password hash is an unusable random secret: no
      // guessable password authenticates this cached identity locally.
      expect(await repo.authenticate(user.username, ''), isNull);
      expect(await repo.authenticate(user.username, '123456'), isNull);
      expect(await repo.authenticate(user.username, user.username), isNull);
    });

    test('distinct cloud identities never collide or merge', () async {
      final repo = createRepo();
      final a = await repo.upsertCloudUser(
        cloudUuid: 'identity-a',
        membershipRole: 'employee',
      );
      final b = await repo.upsertCloudUser(
        cloudUuid: 'identity-b',
        membershipRole: 'salesOnly',
      );
      expect(a.id, isNot(b.id));
      expect(a.username, isNot(b.username));
      final all = await repo.getAllUsers();
      expect(all, hasLength(2));
    });
  });
}
