import 'package:flutter_test/flutter_test.dart';

import 'package:muaman_store/models/user_role.dart';
import 'package:muaman_store/services/permissions.dart';

void main() {
  group('PermissionCatalog', () {
    test('Every permission has a stable, unique, non-empty id', () {
      final ids = AppPermission.values.map((p) => p.id).toList();
      expect(ids.toSet().length, ids.length,
          reason: 'Permission ids must be unique');
      for (final permission in AppPermission.values) {
        expect(permission.id, isNotEmpty);
        expect(permission.displayName, isNotEmpty);
        expect(permission.description, isNotEmpty);
      }
    });

    test('fromId resolves known ids and throws on unknown', () {
      for (final permission in AppPermission.values) {
        expect(AppPermission.fromId(permission.id), permission);
      }
      expect(() => AppPermission.fromId('nope.unknown'), throwsArgumentError);
    });

    test('encodeSet is order-independent and round-trips', () {
      final sample = {
        AppPermission.canAccessSales,
        AppPermission.canCreateSales,
        AppPermission.canAccessInventory,
      };
      final reordered = {
        AppPermission.canCreateSales,
        AppPermission.canAccessInventory,
        AppPermission.canAccessSales,
      };
      expect(
        PermissionCatalog.encodeSet(sample),
        PermissionCatalog.encodeSet(reordered),
      );
      expect(
        PermissionCatalog.decodeSet(PermissionCatalog.encodeSet(sample)),
        sample,
      );
    });

    test(
        'decodeSet ignores unknown/foreign ids (corrupt-safe, never allow-all)',
        () {
      final decoded = PermissionCatalog.decodeSet(
          'sales.view,not.a.real.permission,  ,admin.ghost');
      expect(decoded, {AppPermission.canAccessSales});
      expect(PermissionCatalog.decodeSet(''), isEmpty);
      expect(PermissionCatalog.decodeSet('   , ,'), isEmpty);
    });

    test('Owner defaults = all permissions (MUAMAN-14)', () {
      expect(
        PermissionCatalog.defaultPermissions[UserRole.owner],
        PermissionCatalog.allPermissions,
      );
      for (final permission in AppPermission.values) {
        expect(
            PermissionCatalog.hasDefaultPermission(UserRole.owner, permission),
            true,
            reason: 'Owner should hold ${permission.id}');
      }
    });

    test(
        'Employee defaults = operational access without deletes/admin/settings '
        '(MUAMAN-14)', () {
      final employee = PermissionCatalog.defaultPermissions[UserRole.employee]!;
      for (final permission in {
        AppPermission.canAccessDashboard,
        AppPermission.canAccessInventory,
        AppPermission.canEditProducts,
        AppPermission.canAccessSales,
        AppPermission.canCreateSales,
        AppPermission.canViewSalesHistory,
        AppPermission.canAccessReturns,
        AppPermission.canCreateReturns,
        AppPermission.canAccessExpenses,
        AppPermission.canCreateExpenses,
        AppPermission.canAccessStocktake,
      }) {
        expect(employee.contains(permission), true,
            reason: 'Employee should hold ${permission.id}');
      }
      for (final permission in {
        AppPermission.canDeleteProducts,
        AppPermission.canDeleteSales,
        AppPermission.canDeleteReturns,
        AppPermission.canDeleteExpenses,
        AppPermission.canManageUsers,
        AppPermission.canManagePermissions,
        AppPermission.canManageDevices,
        AppPermission.canAccessSettings,
      }) {
        expect(employee.contains(permission), false,
            reason: 'Employee should NOT hold ${permission.id}');
      }
    });

    test('SalesOnly defaults = sales access + create only (no history)', () {
      expect(
        PermissionCatalog.defaultPermissions[UserRole.salesOnly],
        {AppPermission.canAccessSales, AppPermission.canCreateSales},
      );
    });

    test('ownerExclusive holds only the owner-level admin powers', () {
      expect(PermissionCatalog.ownerExclusive, {
        AppPermission.canManageUsers,
        AppPermission.canManagePermissions,
        AppPermission.canManageDevices,
      });
      expect(PermissionCatalog.ownerExclusive.length, 3);
    });

    test('grouped covers every permission exactly once with its category', () {
      final grouped = PermissionCatalog.grouped();
      final total =
          grouped.values.fold<int>(0, (sum, list) => sum + list.length);
      expect(total, AppPermission.values.length);
      for (final entry in grouped.entries) {
        for (final permission in entry.value) {
          expect(permission.category, entry.key);
        }
      }
      for (final permission in AppPermission.values) {
        expect(grouped[permission.category], contains(permission));
      }
    });
  });
}
