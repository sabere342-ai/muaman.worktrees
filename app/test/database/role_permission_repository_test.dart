import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:muaman_store/database/database_helper.dart';
import 'package:muaman_store/models/user_role.dart';
import 'package:muaman_store/services/permissions.dart';
import 'package:muaman_store/services/role_permission_repository.dart';

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

  group('RolePermissionRepository', () {
    test('No stored rows returns built-in defaults for every role', () async {
      final loaded = await RolePermissionRepository().loadAllOrDefaults();
      expect(loaded.keys.toSet(), UserRole.values.toSet());
      for (final role in UserRole.values) {
        expect(loaded[role], PermissionCatalog.defaultPermissionsForRole(role));
      }
    });

    test('Owner can save and reload a role configuration', () async {
      final repo = RolePermissionRepository();
      final employeeSet = {
        AppPermission.canAccessSales,
        AppPermission.canCreateSales,
        AppPermission.canViewSalesHistory,
      };

      await repo.saveRolePermissions(
        role: UserRole.employee,
        permissions: employeeSet,
        actorRole: UserRole.owner,
      );

      final rows = await testDb.query('role_permissions');
      expect(rows, hasLength(1));
      expect(rows.first['role'], 'employee');
      expect(rows.first['updatedAt'], isNotNull);

      final loaded = await RolePermissionRepository().loadAllOrDefaults();
      expect(loaded[UserRole.employee], employeeSet);
      expect(loaded[UserRole.salesOnly],
          PermissionCatalog.defaultPermissionsForRole(UserRole.salesOnly));
    });

    test('Non-owner actor is denied and nothing is written', () async {
      final repo = RolePermissionRepository();
      await expectLater(
        () => repo.saveRolePermissions(
          role: UserRole.employee,
          permissions: {AppPermission.canAccessSales},
          actorRole: UserRole.employee,
        ),
        throwsA(isA<PermissionDeniedException>()),
      );
      final rows = await testDb.query('role_permissions');
      expect(rows, isEmpty);
    });

    test('Cannot modify the owner role', () async {
      final repo = RolePermissionRepository();
      await expectLater(
        () => repo.saveRolePermissions(
          role: UserRole.owner,
          permissions: {AppPermission.canAccessSales},
          actorRole: UserRole.owner,
        ),
        throwsA(isA<PermissionDeniedException>()),
      );
      await expectLater(
        () => repo.resetRoleToDefaults(
          role: UserRole.owner,
          actorRole: UserRole.owner,
        ),
        throwsA(isA<PermissionDeniedException>()),
      );
      final rows = await testDb.query('role_permissions');
      expect(rows, isEmpty);
    });

    test('Cannot grant an owner-exclusive permission to a non-owner role',
        () async {
      final repo = RolePermissionRepository();
      await expectLater(
        () => repo.saveRolePermissions(
          role: UserRole.employee,
          permissions: {
            AppPermission.canAccessSales,
            AppPermission.canManageUsers,
          },
          actorRole: UserRole.owner,
        ),
        throwsA(isA<PermissionDeniedException>()),
      );
      final rows = await testDb.query('role_permissions');
      expect(rows, isEmpty);
    });

    test('Reset removes the stored row and falls back to defaults', () async {
      final repo = RolePermissionRepository();
      await repo.saveRolePermissions(
        role: UserRole.employee,
        permissions: {AppPermission.canAccessSales},
        actorRole: UserRole.owner,
      );
      await repo.resetRoleToDefaults(
        role: UserRole.employee,
        actorRole: UserRole.owner,
      );
      final rows = await testDb.query('role_permissions');
      expect(rows, isEmpty);
      final loaded = await RolePermissionRepository().loadAllOrDefaults();
      expect(loaded[UserRole.employee],
          PermissionCatalog.defaultPermissionsForRole(UserRole.employee));
    });

    test('A fresh repository sees persisted changes (new-session semantics)',
        () async {
      final repoA = RolePermissionRepository();
      await repoA.saveRolePermissions(
        role: UserRole.salesOnly,
        permissions: {
          AppPermission.canAccessSales,
          AppPermission.canCreateSales,
          AppPermission.canViewSalesHistory,
        },
        actorRole: UserRole.owner,
      );

      final repoB = RolePermissionRepository();
      final loaded = await repoB.loadAllOrDefaults();
      expect(loaded[UserRole.salesOnly],
          contains(AppPermission.canViewSalesHistory));
    });

    test('Unknown role ids in stored rows are ignored', () async {
      await testDb.insert('role_permissions', {
        'role': 'mysteryRole',
        'permissions': 'sales.view',
        'updatedAt': DateTime.now().toIso8601String(),
      });
      final loaded = await RolePermissionRepository().loadAllOrDefaults();
      expect(loaded.keys.toSet(), UserRole.values.toSet());
      for (final role in UserRole.values) {
        expect(loaded[role], PermissionCatalog.defaultPermissionsForRole(role));
      }
    });

    test('Missing role_permissions table falls back to defaults', () async {
      await testDb.execute('DROP TABLE role_permissions');

      final loaded = await RolePermissionRepository().loadAllOrDefaults();
      for (final role in UserRole.values) {
        expect(loaded[role], PermissionCatalog.defaultPermissionsForRole(role));
      }
    });
  });
}
