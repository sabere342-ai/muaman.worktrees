import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:muaman_store/database/database_helper.dart';
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

    await testDb.insert('products', {
      'name': 'منتج اختبار',
      'barcode': 'BAR-DATA-001',
      'openingQuantity': 10,
      'soldQuantity': 2,
      'returnedQuantity': 1,
      'currentQuantity': 9,
      'costPrice': 50,
      'totalInventoryCost': 450,
      'inventoryAdjustment': 0,
    });
    await testDb.insert('sales', {
      'date': DateTime.now().toIso8601String(),
      'productName': 'منتج اختبار',
      'barcode': 'BAR-DATA-001',
      'quantity': 2,
      'salePrice': 100,
      'totalSaleValue': 200,
      'costPrice': 50,
      'cogs': 100,
    });
    await testDb.insert('returns', {
      'date': DateTime.now().toIso8601String(),
      'productName': 'منتج اختبار',
      'barcode': 'BAR-DATA-001',
      'quantity': 1,
      'salePrice': 100,
      'totalReturnValue': 100,
      'costPrice': 50,
      'returnedCogs': 50,
    });
    await testDb.insert('expenses', {
      'date': DateTime.now().toIso8601String(),
      'description': 'مصروف اختبار',
      'amount': 25,
    });

    // Each test starts from a clean cache so defaults (MUAMAN-14) apply unless
    // the test explicitly persists a new configuration.
    PermissionResolver.instance.invalidate();
  });

  tearDown(() async {
    await testDb.close();
  });

  group('Data-layer permission guards', () {
    test('Owner can delete product, sale, return and expense', () async {
      expect(
          await DatabaseHelper.instance
              .deleteSale(1, currentRole: UserRole.owner),
          greaterThan(0));
      expect(
          await DatabaseHelper.instance
              .deleteReturn(1, currentRole: UserRole.owner),
          greaterThan(0));
      expect(
          await DatabaseHelper.instance
              .deleteProduct(1, currentRole: UserRole.owner),
          greaterThan(0));
      expect(
          await DatabaseHelper.instance
              .deleteExpense(1, currentRole: UserRole.owner),
          greaterThan(0));
    });

    test('Employee is denied deletes by default (fail-closed)', () async {
      expect(
        () => DatabaseHelper.instance
            .deleteProduct(1, currentRole: UserRole.employee),
        throwsA(isA<PermissionDeniedException>()),
      );
      expect(
        () => DatabaseHelper.instance
            .deleteSale(1, currentRole: UserRole.employee),
        throwsA(isA<PermissionDeniedException>()),
      );
      expect(
        () => DatabaseHelper.instance
            .deleteReturn(1, currentRole: UserRole.employee),
        throwsA(isA<PermissionDeniedException>()),
      );
      expect(
        () => DatabaseHelper.instance
            .deleteExpense(1, currentRole: UserRole.employee),
        throwsA(isA<PermissionDeniedException>()),
      );
    });

    test('SalesOnly is denied deletes', () async {
      expect(
        () => DatabaseHelper.instance
            .deleteProduct(1, currentRole: UserRole.salesOnly),
        throwsA(isA<PermissionDeniedException>()),
      );
      expect(
        () => DatabaseHelper.instance
            .deleteSale(1, currentRole: UserRole.salesOnly),
        throwsA(isA<PermissionDeniedException>()),
      );
    });

    test('Deletes are denied when no role is supplied (never allow-all)',
        () async {
      expect(
        () => DatabaseHelper.instance.deleteProduct(1),
        throwsA(isA<PermissionDeniedException>()),
      );
      expect(
        () => DatabaseHelper.instance.deleteSale(1),
        throwsA(isA<PermissionDeniedException>()),
      );
    });

    test('A persisted grant enables the data-layer delete for the role',
        () async {
      await PermissionResolver.instance.saveRolePermissions(
        role: UserRole.employee,
        permissions: {
          ...PermissionCatalog.defaultPermissionsForRole(UserRole.employee),
          AppPermission.canDeleteSales,
          AppPermission.canDeleteReturns,
          AppPermission.canDeleteProducts,
        },
        actorRole: UserRole.owner,
      );
      expect(
        await DatabaseHelper.instance
            .deleteSale(1, currentRole: UserRole.employee),
        greaterThan(0),
      );
      expect(
        await DatabaseHelper.instance
            .deleteReturn(1, currentRole: UserRole.employee),
        greaterThan(0),
      );
      expect(
        await DatabaseHelper.instance
            .deleteProduct(1, currentRole: UserRole.employee),
        greaterThan(0),
      );
    });

    test('A revoked permission blocks a new session at the data layer',
        () async {
      await PermissionResolver.instance.saveRolePermissions(
        role: UserRole.employee,
        permissions: {
          ...PermissionCatalog.defaultPermissionsForRole(UserRole.employee),
          AppPermission.canDeleteSales,
        },
        actorRole: UserRole.owner,
      );
      expect(
        await DatabaseHelper.instance
            .deleteSale(1, currentRole: UserRole.employee),
        greaterThan(0),
      );

      // Revoke the delete permission and refresh the resolver (as a fresh
      // session would). The employee must no longer be able to delete.
      await PermissionResolver.instance.saveRolePermissions(
        role: UserRole.employee,
        permissions: {
          ...PermissionCatalog.defaultPermissionsForRole(UserRole.employee),
        },
        actorRole: UserRole.owner,
      );
      expect(
        () => DatabaseHelper.instance
            .deleteSale(1, currentRole: UserRole.employee),
        throwsA(isA<PermissionDeniedException>()),
      );
    });
  });
}
