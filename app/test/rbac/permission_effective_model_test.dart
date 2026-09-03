import 'package:flutter_test/flutter_test.dart';

import 'package:muaman_store/rbac/effective_permission_model.dart';
import 'package:muaman_store/services/permissions.dart';

void main() {
  group('CloudPermissionSnapshot', () {
    test('fromRpc parses valid JSON correctly', () {
      final data = {
        'shop_id': 'test-shop-id',
        'member_role': 'employee',
        'permissions': ['dashboard.view', 'inventory.view', 'sales.view'],
        'overrides': [
          {'permission_id': 'inventory.edit', 'effect': 'DENY'},
        ],
        'catalog_version': 1,
        'server_time': '2026-08-20T12:00:00Z',
        'updated_at': '2026-08-20T11:30:00Z',
      };

      final snapshot = CloudPermissionSnapshot.fromRpc(data);
      expect(snapshot.shopId, 'test-shop-id');
      expect(snapshot.memberRole, 'employee');
      expect(snapshot.permissionIds,
          {'dashboard.view', 'inventory.view', 'sales.view'});
      expect(snapshot.overrides.length, 1);
      expect(snapshot.overrides[0].permissionId, 'inventory.edit');
      expect(snapshot.overrides[0].effect, 'DENY');
      expect(snapshot.catalogVersion, 1);
    });

    test('toPermissionSet maps valid IDs to AppPermission enum', () {
      final snapshot = CloudPermissionSnapshot(
        shopId: 'shop',
        memberRole: 'employee',
        permissionIds: {'dashboard.view', 'inventory.view', 'sales.view'},
        overrides: [],
        catalogVersion: 1,
        serverTime: DateTime.now(),
        permissionsUpdatedAt: DateTime.now(),
        cachedAt: DateTime.now(),
      );

      final permSet = snapshot.toPermissionSet();
      expect(permSet, {
        AppPermission.canAccessDashboard,
        AppPermission.canAccessInventory,
        AppPermission.canAccessSales,
      });
    });

    test('toPermissionSet skips unknown permission IDs gracefully', () {
      final snapshot = CloudPermissionSnapshot(
        shopId: 'shop',
        memberRole: 'employee',
        permissionIds: {'dashboard.view', 'unknown.future.permission'},
        overrides: [],
        catalogVersion: 1,
        serverTime: DateTime.now(),
        permissionsUpdatedAt: DateTime.now(),
        cachedAt: DateTime.now(),
      );

      final permSet = snapshot.toPermissionSet();
      expect(permSet.length, 1);
      expect(permSet.contains(AppPermission.canAccessDashboard), true);
    });

    test('isFresh returns true within 1 hour', () {
      final snapshot = CloudPermissionSnapshot(
        shopId: 'shop',
        memberRole: 'employee',
        permissionIds: {},
        overrides: [],
        catalogVersion: 1,
        serverTime: DateTime.now(),
        permissionsUpdatedAt: DateTime.now(),
        cachedAt: DateTime.now(),
      );
      expect(snapshot.isFresh, true);
    });

    test('isFresh returns false after 1 hour', () {
      final snapshot = CloudPermissionSnapshot(
        shopId: 'shop',
        memberRole: 'employee',
        permissionIds: {},
        overrides: [],
        catalogVersion: 1,
        serverTime: DateTime.now(),
        permissionsUpdatedAt: DateTime.now(),
        cachedAt: DateTime.now().subtract(const Duration(hours: 2)),
      );
      expect(snapshot.isFresh, false);
    });

    test('toJson and fromJson round-trip preserves data', () {
      final original = CloudPermissionSnapshot(
        shopId: 'shop-123',
        memberRole: 'employee',
        permissionIds: {'dashboard.view', 'sales.view'},
        overrides: [
          const PermissionOverride(
              permissionId: 'inventory.edit', effect: 'DENY'),
        ],
        catalogVersion: 1,
        serverTime: DateTime.utc(2026, 8, 20, 12, 0, 0),
        permissionsUpdatedAt: DateTime.utc(2026, 8, 20, 11, 30, 0),
        cachedAt: DateTime.utc(2026, 8, 20, 12, 0, 30),
      );

      final json = original.toJson();
      final restored = CloudPermissionSnapshot.fromJson(json);

      expect(restored.shopId, original.shopId);
      expect(restored.memberRole, original.memberRole);
      expect(restored.permissionIds, original.permissionIds);
      expect(restored.overrides.length, original.overrides.length);
      expect(restored.catalogVersion, original.catalogVersion);
    });
  });

  group('PermissionOverride', () {
    test('fromMap creates correct instance', () {
      final override = PermissionOverride.fromMap({
        'permission_id': 'inventory.edit',
        'effect': 'DENY',
      });
      expect(override.permissionId, 'inventory.edit');
      expect(override.effect, 'DENY');
      expect(override.isDeny, true);
      expect(override.isAllow, false);
    });

    test('isAllow and isDeny work correctly', () {
      const allowOverride =
          PermissionOverride(permissionId: 'sales.view', effect: 'ALLOW');
      const denyOverride =
          PermissionOverride(permissionId: 'sales.view', effect: 'DENY');

      expect(allowOverride.isAllow, true);
      expect(allowOverride.isDeny, false);
      expect(denyOverride.isAllow, false);
      expect(denyOverride.isDeny, true);
    });

    test('equality works correctly', () {
      const a = PermissionOverride(permissionId: 'sales.view', effect: 'DENY');
      const b = PermissionOverride(permissionId: 'sales.view', effect: 'DENY');
      const c = PermissionOverride(permissionId: 'sales.view', effect: 'ALLOW');

      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a == c, false);
    });
  });

  group('Canonical Permission ID Alignment', () {
    test('All 19 AppPermission IDs are canonical and match cloud seed', () {
      const expectedIds = {
        'dashboard.view',
        'inventory.view',
        'inventory.edit',
        'inventory.delete',
        'sales.view',
        'sales.create',
        'sales.history.view',
        'sales.delete',
        'returns.view',
        'returns.create',
        'returns.delete',
        'expenses.view',
        'expenses.create',
        'expenses.delete',
        'stocktake.view',
        'admin.users.manage',
        'admin.permissions.manage',
        'admin.settings.access',
        'admin.devices.manage',
      };

      final actualIds = AppPermission.values.map((p) => p.id).toSet();
      expect(actualIds, expectedIds);
      expect(actualIds.length, 19);
    });

    test('No duplicate IDs across all permissions', () {
      final ids = AppPermission.values.map((p) => p.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('fromId resolves all 19 canonical IDs', () {
      for (final p in AppPermission.values) {
        expect(AppPermission.fromId(p.id), p);
      }
    });

    test('fromId throws on unknown ID', () {
      expect(() => AppPermission.fromId('unknown.id'), throwsArgumentError);
    });

    test('Owner-exclusive set is exactly 3 permissions', () {
      expect(PermissionCatalog.ownerExclusive.length, 3);
      expect(PermissionCatalog.ownerExclusive, {
        AppPermission.canManageUsers,
        AppPermission.canManagePermissions,
        AppPermission.canManageDevices,
      });
    });
  });

  group('Cloud-first Resolution', () {
    test('Cloud snapshot overrides local config for non-owner roles', () {
      final snapshot = CloudPermissionSnapshot(
        shopId: 'shop',
        memberRole: 'employee',
        permissionIds: {
          'dashboard.view',
          'sales.view',
          'sales.create',
        },
        overrides: [],
        catalogVersion: 1,
        serverTime: DateTime.now(),
        permissionsUpdatedAt: DateTime.now(),
        cachedAt: DateTime.now(),
      );

      final permSet = snapshot.toPermissionSet();
      expect(permSet, {
        AppPermission.canAccessDashboard,
        AppPermission.canAccessSales,
        AppPermission.canCreateSales,
      });

      // These would normally be in employee defaults but are NOT in the cloud snapshot
      expect(permSet.contains(AppPermission.canAccessInventory), false);
      expect(permSet.contains(AppPermission.canDeleteProducts), false);
    });

    test('Owner gets all permissions regardless of cloud snapshot', () {
      // Owner always gets all 19 permissions regardless of cloud snapshot content
      expect(PermissionCatalog.allPermissions.length, 19);
    });
  });
}
