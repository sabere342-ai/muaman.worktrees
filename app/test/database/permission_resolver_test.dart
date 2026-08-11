import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:muaman_store/database/database_helper.dart';
import 'package:muaman_store/models/user.dart';
import 'package:muaman_store/models/user_role.dart';
import 'package:muaman_store/services/permission_resolver.dart';
import 'package:muaman_store/services/permissions.dart';

import '../helpers/test_schema.dart';

void main() {
  sqfliteFfiInit();

  late Database testDb;

  setUp(() async {
    testDb =
        await databaseFactoryFfiNoIsolate.openDatabase(inMemoryDatabasePath);
    await createTestSchema(testDb);
    DatabaseHelper.setTestDatabase(testDb);
  });

  tearDown(() async {
    await testDb.close();
  });

  User ownerUser() => User(
        displayName: 'المالك',
        username: 'owner',
        passwordHash: 'dummy',
        role: UserRole.owner,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

  User employeeUser() => User(
        displayName: 'موظف',
        username: 'employee',
        passwordHash: 'dummy',
        role: UserRole.employee,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

  group('PermissionResolver', () {
    test('Defaults apply before any refresh (fail-safe, never allow-all)', () {
      final resolver = PermissionResolver();
      expect(resolver.isLoaded, false);
      expect(
          resolver.can(UserRole.owner, AppPermission.canAccessSettings), true);
      expect(
          resolver.can(UserRole.employee, AppPermission.canDeleteSales), false);
      expect(
          resolver.can(UserRole.salesOnly, AppPermission.canViewSalesHistory),
          false);
    });

    test('Refresh with an empty table keeps built-in defaults', () async {
      final resolver = PermissionResolver();
      await resolver.refresh();
      expect(resolver.isLoaded, true);
      expect(resolver.snapshot()[UserRole.employee],
          PermissionCatalog.defaultPermissionsForRole(UserRole.employee));
    });

    test('Save updates the resolver cache', () async {
      final resolver = PermissionResolver();
      await resolver.saveRolePermissions(
        role: UserRole.employee,
        permissions: {
          AppPermission.canAccessSales,
          AppPermission.canCreateSales,
          AppPermission.canDeleteSales,
        },
        actorRole: UserRole.owner,
      );
      expect(
          resolver.can(UserRole.employee, AppPermission.canDeleteSales), true);
      expect(resolver.can(UserRole.employee, AppPermission.canAccessExpenses),
          false);
    });

    test('Reset restores defaults in the cache', () async {
      final resolver = PermissionResolver();
      await resolver.saveRolePermissions(
        role: UserRole.employee,
        permissions: {AppPermission.canAccessSales},
        actorRole: UserRole.owner,
      );
      expect(
          resolver.can(UserRole.employee, AppPermission.canCreateSales), false);
      await resolver.resetRoleToDefaults(
        role: UserRole.employee,
        actorRole: UserRole.owner,
      );
      expect(
          resolver.can(UserRole.employee, AppPermission.canCreateSales), true);
      expect(
          resolver.can(UserRole.employee, AppPermission.canDeleteSales), false);
    });

    test('invalidate falls back to defaults until the next refresh', () async {
      final resolver = PermissionResolver();
      await resolver.saveRolePermissions(
        role: UserRole.employee,
        permissions: {
          AppPermission.canAccessSales,
          AppPermission.canCreateSales,
          AppPermission.canDeleteSales,
        },
        actorRole: UserRole.owner,
      );
      resolver.invalidate();
      expect(resolver.isLoaded, false);
      expect(
          resolver.can(UserRole.employee, AppPermission.canDeleteSales), false);
      await resolver.refresh();
      expect(
          resolver.can(UserRole.employee, AppPermission.canDeleteSales), true);
    });

    test('canForUser denies a null/unknown user and resolves by role', () {
      final resolver = PermissionResolver();
      expect(resolver.canForUser(null, AppPermission.canCreateSales), false);
      expect(
          resolver.canForUser(ownerUser(), AppPermission.canManagePermissions),
          true);
      expect(resolver.canForUser(employeeUser(), AppPermission.canCreateSales),
          true);
      expect(resolver.canForUser(employeeUser(), AppPermission.canDeleteSales),
          false);
    });

    test('Owner is always fully privileged even after refresh', () async {
      final resolver = PermissionResolver();
      await resolver.refresh();
      for (final permission in AppPermission.values) {
        expect(resolver.can(UserRole.owner, permission), true,
            reason: 'Owner should hold ${permission.id}');
      }
      expect(resolver.effectivePermissions(UserRole.owner),
          PermissionCatalog.allPermissions);
    });

    test('snapshot covers every role', () async {
      final resolver = PermissionResolver();
      await resolver.refresh();
      final snapshot = resolver.snapshot();
      expect(snapshot.keys.toSet(), UserRole.values.toSet());
    });
  });
}
