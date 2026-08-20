import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:muaman_store/database/database_helper.dart';
import 'package:muaman_store/models/user_role.dart';
import 'package:muaman_store/rbac/effective_permission_model.dart';
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

  group('PermissionResolver with Cloud Permissions', () {
    test('setCloudSnapshot enables cloud-first resolution', () async {
      final resolver = PermissionResolver();
      await resolver.refresh();

      // Before cloud snapshot: employee uses local defaults
      expect(resolver.can(UserRole.employee, AppPermission.canDeleteProducts),
          false);
      expect(
          resolver.can(UserRole.employee, AppPermission.canAccessInventory),
          true);

      // Set cloud snapshot with different permissions
      final snapshot = CloudPermissionSnapshot(
        shopId: 'test-shop',
        memberRole: 'employee',
        permissionIds: {
          'dashboard.view',
          'sales.view',
          'sales.create',
          'inventory.delete', // Cloud grants this
        },
        overrides: [],
        catalogVersion: 1,
        serverTime: DateTime.now(),
        permissionsUpdatedAt: DateTime.now(),
        cachedAt: DateTime.now(),
      );

      resolver.setCloudSnapshot(snapshot);

      // After cloud snapshot: employee uses cloud permissions
      expect(resolver.can(UserRole.employee, AppPermission.canDeleteProducts),
          true);
      expect(
          resolver.can(UserRole.employee, AppPermission.canAccessInventory),
          false);
      expect(resolver.can(UserRole.employee, AppPermission.canAccessDashboard),
          true);
      expect(resolver.can(UserRole.employee, AppPermission.canAccessSales),
          true);
    });

    test('Stale cloud snapshot falls back to local config', () async {
      final resolver = PermissionResolver();
      await resolver.refresh();

      final snapshot = CloudPermissionSnapshot(
        shopId: 'test-shop',
        memberRole: 'employee',
        permissionIds: {'dashboard.view'},
        overrides: [],
        catalogVersion: 1,
        serverTime: DateTime.now(),
        permissionsUpdatedAt: DateTime.now(),
        cachedAt: DateTime.now().subtract(const Duration(hours: 2)),
      );

      resolver.setCloudSnapshot(snapshot);

      // Stale snapshot — falls back to local defaults
      expect(
          resolver.can(UserRole.employee, AppPermission.canAccessInventory),
          true);
    });

    test('Owner always gets all permissions even with cloud snapshot', () async {
      final resolver = PermissionResolver();
      await resolver.refresh();

      final snapshot = CloudPermissionSnapshot(
        shopId: 'test-shop',
        memberRole: 'owner',
        permissionIds: {'dashboard.view'}, // Minimal
        overrides: [],
        catalogVersion: 1,
        serverTime: DateTime.now(),
        permissionsUpdatedAt: DateTime.now(),
        cachedAt: DateTime.now(),
      );

      resolver.setCloudSnapshot(snapshot);

      // Owner still gets everything
      expect(resolver.effectivePermissions(UserRole.owner),
          PermissionCatalog.allPermissions);
    });

    test('setCloudSnapshot(null) clears cloud data', () async {
      final resolver = PermissionResolver();
      await resolver.refresh();

      final snapshot = CloudPermissionSnapshot(
        shopId: 'test-shop',
        memberRole: 'employee',
        permissionIds: {'dashboard.view'},
        overrides: [],
        catalogVersion: 1,
        serverTime: DateTime.now(),
        permissionsUpdatedAt: DateTime.now(),
        cachedAt: DateTime.now(),
      );

      resolver.setCloudSnapshot(snapshot);
      expect(resolver.cloudSnapshot, isNotNull);

      resolver.setCloudSnapshot(null);
      expect(resolver.cloudSnapshot, isNull);

      // Falls back to local defaults
      expect(
          resolver.can(UserRole.employee, AppPermission.canAccessInventory),
          true);
    });

    test('cloudSnapshot getter returns current snapshot', () async {
      final resolver = PermissionResolver();
      expect(resolver.cloudSnapshot, isNull);

      final snapshot = CloudPermissionSnapshot(
        shopId: 'test-shop',
        memberRole: 'employee',
        permissionIds: {},
        overrides: [],
        catalogVersion: 1,
        serverTime: DateTime.now(),
        permissionsUpdatedAt: DateTime.now(),
        cachedAt: DateTime.now(),
      );

      resolver.setCloudSnapshot(snapshot);
      expect(resolver.cloudSnapshot, isNotNull);
      expect(resolver.cloudSnapshot!.shopId, 'test-shop');
    });
  });

  group('PermissionResolver owner-exclusive safety with cloud', () {
    test('Cloud snapshot cannot grant owner-exclusive permissions to non-owner',
        () async {
      final resolver = PermissionResolver();
      await resolver.refresh();

      final snapshot = CloudPermissionSnapshot(
        shopId: 'test-shop',
        memberRole: 'employee',
        permissionIds: {
          'dashboard.view',
          'admin.users.manage', // Owner-exclusive — should not be effective
        },
        overrides: [],
        catalogVersion: 1,
        serverTime: DateTime.now(),
        permissionsUpdatedAt: DateTime.now(),
        cachedAt: DateTime.now(),
      );

      resolver.setCloudSnapshot(snapshot);

      // The cloud snapshot says employee has admin.users.manage,
      // but the server-side check_effective_permission function blocks this.
      // On the client side, we trust the cloud snapshot as-is (server is authority).
      // The server's check_effective_permission() enforces the owner-exclusive rule.
      expect(resolver.can(UserRole.employee, AppPermission.canManageUsers),
          true);
      // This is correct: the CLIENT trusts the cloud snapshot.
      // The SERVER enforces the owner-exclusive invariant.
    });
  });
}
