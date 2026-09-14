import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:muaman_store/database/database_helper.dart';
import 'package:muaman_store/database/user_repository.dart';
import 'package:muaman_store/models/user_role.dart';
import 'package:muaman_store/services/permission_resolver.dart';
import 'package:muaman_store/services/permissions.dart';

import '../helpers/test_schema.dart';

void main() {
  sqfliteFfiInit();

  late Database testDb;
  late UserRepository userRepo;

  setUp(() async {
    testDb =
        await databaseFactoryFfiNoIsolate.openDatabase(inMemoryDatabasePath);
    await createTestSchema(testDb);
    DatabaseHelper.setTestDatabase(testDb);

    userRepo = UserRepository();
    userRepo.permissionResolver = PermissionResolver.instance;
    PermissionResolver.instance.invalidate();
  });

  tearDown(() async {
    await testDb.close();
  });

  group('First-owner bootstrap invariant', () {
    test('A. Empty database: createFirstOwner succeeds with owner role',
        () async {
      expect(await userRepo.hasAnyUser(), isFalse);

      final id = await userRepo.createFirstOwner(
        displayName: 'المالك الأول',
        username: 'owner1',
        password: 'password123',
      );

      expect(id, greaterThan(0));
      final user = await userRepo.getUserById(id);
      expect(user, isNotNull);
      expect(user!.role, UserRole.owner);
      expect(user.isActive, isTrue);
      expect(await userRepo.hasAnyUser(), isTrue);
    });

    test('B. Second bootstrap denied after a user exists', () async {
      await userRepo.createFirstOwner(
        displayName: 'المالك الأول',
        username: 'owner1',
        password: 'password123',
      );

      await expectLater(
        () => userRepo.createFirstOwner(
          displayName: 'مالك ثانٍ',
          username: 'owner2',
          password: 'password123',
        ),
        throwsA(isA<PermissionDeniedException>()),
      );

      final users = await userRepo.getAllUsers();
      expect(users.length, 1);
      expect(users.single.role, UserRole.owner);
    });

    test('B2. Bootstrap also denied after a non-owner user exists', () async {
      await userRepo.createUser(
        displayName: 'موظف',
        username: 'employee1',
        password: 'password123',
        role: UserRole.employee,
        currentRole: UserRole.owner,
      );

      await expectLater(
        () => userRepo.createFirstOwner(
          displayName: 'مالك',
          username: 'late-owner',
          password: 'password123',
        ),
        throwsA(isA<PermissionDeniedException>()),
      );
    });

    test('B3. Failed bootstrap leaves no partial user row', () async {
      await userRepo.createFirstOwner(
        displayName: 'المالك الأول',
        username: 'owner1',
        password: 'password123',
      );

      await expectLater(
        () => userRepo.createFirstOwner(
          displayName: 'مالك ثانٍ',
          username: 'owner2',
          password: 'password123',
        ),
        throwsA(isA<PermissionDeniedException>()),
      );

      final users = await userRepo.getAllUsers();
      expect(users.length, 1);
    });

    test('B4. Bootstrap preserves validation on an empty table', () async {
      await expectLater(
        () => userRepo.createFirstOwner(
          displayName: 'مالك',
          username: 'owner1',
          password: '123',
        ),
        throwsA(isA<WeakPasswordException>()),
      );
      expect(await userRepo.hasAnyUser(), isFalse);

      await expectLater(
        () => userRepo.createFirstOwner(
          displayName: 'مالك',
          username: '  ',
          password: 'password123',
        ),
        throwsArgumentError,
      );
      expect(await userRepo.hasAnyUser(), isFalse);

      await expectLater(
        () => userRepo.createFirstOwner(
          displayName: '  ',
          username: 'owner1',
          password: 'password123',
        ),
        throwsArgumentError,
      );
      expect(await userRepo.hasAnyUser(), isFalse);
    });
  });

  group('Normal user management remains admin-guarded', () {
    test('C. createUser without currentRole is denied', () async {
      await expectLater(
        () => userRepo.createUser(
          displayName: 'مستخدم',
          username: 'user1',
          password: 'password123',
          role: UserRole.employee,
        ),
        throwsA(isA<PermissionDeniedException>()),
      );
      expect(await userRepo.hasAnyUser(), isFalse);
    });

    test('C2. createUser with a non-owner currentRole is denied', () async {
      await expectLater(
        () => userRepo.createUser(
          displayName: 'مستخدم',
          username: 'user1',
          password: 'password123',
          role: UserRole.employee,
          currentRole: UserRole.employee,
        ),
        throwsA(isA<PermissionDeniedException>()),
      );
    });

    test('C3. createUser with owner authorization still succeeds', () async {
      final id = await userRepo.createUser(
        displayName: 'موظف',
        username: 'employee1',
        password: 'password123',
        role: UserRole.employee,
        currentRole: UserRole.owner,
      );
      expect(id, greaterThan(0));
    });
  });

  group('No permission regression for non-owner roles', () {
    test('D. salesOnly cannot create users', () async {
      expect(
        PermissionResolver.instance
            .can(UserRole.salesOnly, AppPermission.canManageUsers),
        isFalse,
      );
      await expectLater(
        () => userRepo.createUser(
          displayName: 'كاشير',
          username: 'cashier1',
          password: 'password123',
          role: UserRole.salesOnly,
          currentRole: UserRole.salesOnly,
        ),
        throwsA(isA<PermissionDeniedException>()),
      );
    });

    test('D2. employee cannot create users', () async {
      expect(
        PermissionResolver.instance
            .can(UserRole.employee, AppPermission.canManageUsers),
        isFalse,
      );
      await expectLater(
        () => userRepo.createUser(
          displayName: 'موظف',
          username: 'employee1',
          password: 'password123',
          role: UserRole.employee,
          currentRole: UserRole.employee,
        ),
        throwsA(isA<PermissionDeniedException>()),
      );
    });
  });
}
