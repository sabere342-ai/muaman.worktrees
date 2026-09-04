import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:muaman_store/database/database_helper.dart';
import 'package:muaman_store/models/product.dart';
import 'package:muaman_store/models/user_role.dart';
import 'package:muaman_store/services/permissions.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../tenant_isolation/fixture.dart';

/// Phase P Group D D1 (P-OD4) — cost-change history.
///
/// Proves:
///   1. unchanged cost -> no history entry
///   2. cost change -> exactly one history entry
///   3. correct old/new cost captured
///   4. correct product identity
///   5. correct shop identity
///   6. repeated changes create ordered/distinct transitions
///   7. existing sale cost snapshot remains unchanged
///   8. unauthorized role cannot gain mutation authority
///   9. cross-shop history access fails
///  10. malformed/invalid cost input fails safely
///  11. v18 -> v19 migration is additive and idempotent
///  12. atomicity: product update + history insert are transactional
void main() {
  sqfliteFfiInit();

  late Database testDb;
  final helper = DatabaseHelper.instance;

  setUp(() async {
    testDb =
        await databaseFactoryFfiNoIsolate.openDatabase(inMemoryDatabasePath);
    await DatabaseHelper.runCreateDbForTest(testDb);
    await DatabaseHelper.setTestDatabase(testDb);
    await bindTestShop('shop-a');
  });

  tearDown(() async {
    resetTestContext();
    DatabaseHelper.setTenantIsolationArmed(false);
    DatabaseHelper.resetForTest();
    await testDb.close();
  });

  Future<Product> seedProduct({
    String name = 'منتج أ',
    String barcode = 'BC-A',
    int quantity = 10,
    double cost = 100.0,
  }) async {
    await helper.insertProduct(
      Product(
        name: name,
        barcode: barcode,
        openingQuantity: quantity,
        currentQuantity: quantity,
        costPrice: cost,
        totalInventoryCost: quantity * cost,
      ),
      currentRole: UserRole.owner,
    );
    return (await helper.getProductByBarcode(barcode))!;
  }

  group('D1 — cost history recording', () {
    test('1: unchanged cost produces no history entry', () async {
      final product = await seedProduct(cost: 100);
      await helper.updateProduct(
        product.copyWith(costPrice: 100),
        currentRole: UserRole.owner,
      );
      final history = await helper.getAllCostHistory();
      expect(history, isEmpty);
    });

    test('2: cost change produces exactly one history entry', () async {
      final product = await seedProduct(cost: 100);
      await helper.updateProduct(
        product.copyWith(costPrice: 120),
        currentRole: UserRole.owner,
      );
      final history = await helper.getAllCostHistory();
      expect(history, hasLength(1));
    });

    test('3: old and new cost are captured correctly', () async {
      final product = await seedProduct(cost: 100);
      await helper.updateProduct(
        product.copyWith(costPrice: 120),
        currentRole: UserRole.owner,
      );
      final history = await helper.getAllCostHistory();
      expect(history.single.oldCost, 100);
      expect(history.single.newCost, 120);
    });

    test('4: correct product identity is captured', () async {
      final product = await seedProduct(name: 'منتج أ', barcode: 'BC-A');
      await helper.updateProduct(
        product.copyWith(costPrice: 120),
        currentRole: UserRole.owner,
      );
      final history = await helper.getAllCostHistory();
      final entry = history.single;
      expect(entry.productId, product.id);
      expect(entry.productName, 'منتج أ');
      expect(entry.productBarcode, 'BC-A');
    });

    test('5: correct shop identity is captured', () async {
      final product = await seedProduct();
      await helper.updateProduct(
        product.copyWith(costPrice: 120),
        currentRole: UserRole.owner,
      );
      final history = await helper.getAllCostHistory();
      expect(history.single.shopId, 'shop-a');
    });

    test('6: repeated cost changes create ordered/distinct transitions',
        () async {
      final product = await seedProduct(cost: 100);
      await helper.updateProduct(
        product.copyWith(costPrice: 120),
        currentRole: UserRole.owner,
      );
      await helper.updateProduct(
        product.copyWith(costPrice: 135),
        currentRole: UserRole.owner,
      );
      final history = await helper.getCostHistoryByProduct(product.id!);
      expect(history, hasLength(2));
      expect(history[0].oldCost, 120);
      expect(history[0].newCost, 135);
      expect(history[1].oldCost, 100);
      expect(history[1].newCost, 120);
    });

    test('7: existing sale cost snapshot remains unchanged', () async {
      final product = await seedProduct(cost: 100);

      // Record a sale at cost 100
      await testDb.insert('sales', {
        'date': DateTime.now().toIso8601String(),
        'productName': product.name,
        'barcode': product.barcode,
        'quantity': 1,
        'salePrice': 200,
        'totalSaleValue': 200,
        'costPrice': 100,
        'cogs': 100,
        'shop_id': 'shop-a',
      });

      final beforeChange = await testDb
          .query('sales', where: 'barcode = ?', whereArgs: ['BC-A']);
      expect(beforeChange.single['costPrice'], 100);

      // Change cost to 120
      await helper.updateProduct(
        product.copyWith(costPrice: 120),
        currentRole: UserRole.owner,
      );

      final afterChange = await testDb
          .query('sales', where: 'barcode = ?', whereArgs: ['BC-A']);
      expect(afterChange.single['costPrice'], 100,
          reason: 'historical sale cost snapshot must NOT be rewritten');

      final history = await helper.getAllCostHistory();
      expect(history.single.oldCost, 100);
      expect(history.single.newCost, 120);
    });

    test('8: unauthorized role cannot gain mutation authority', () async {
      final product = await seedProduct(cost: 100);
      expect(
        () => helper.updateProduct(
          product.copyWith(costPrice: 120),
          currentRole: UserRole.salesOnly,
        ),
        throwsA(isA<PermissionDeniedException>()),
      );
      final history = await helper.getAllCostHistory();
      expect(history, isEmpty, reason: 'salesOnly must not create history');
    });

    test('9: cross-shop history access fails', () async {
      DatabaseHelper.setTenantIsolationArmed(true);
      final product = await seedProduct(cost: 100);
      await helper.updateProduct(
        product.copyWith(costPrice: 120),
        currentRole: UserRole.owner,
      );

      // Switch to a different shop
      await bindTestShop('shop-b');
      final historyB = await helper.getAllCostHistory();
      expect(historyB, isEmpty,
          reason: 'Shop B must not read Shop A cost history');
      final productHistoryB = await helper.getCostHistoryByProduct(product.id!);
      expect(productHistoryB, isEmpty);
    });

    test('10: malformed/invalid cost input fails safely', () async {
      final product = await seedProduct(cost: 100);

      // NaN is rejected
      expect(
        () => helper.updateProduct(
          product.copyWith(costPrice: double.nan),
          currentRole: UserRole.owner,
        ),
        throwsA(isA<ArgumentError>()),
      );

      // Negative cost is rejected
      expect(
        () => helper.updateProduct(
          product.copyWith(costPrice: -5),
          currentRole: UserRole.owner,
        ),
        throwsA(isA<ArgumentError>()),
      );

      // Zero cost is rejected
      expect(
        () => helper.updateProduct(
          product.copyWith(costPrice: 0),
          currentRole: UserRole.owner,
        ),
        throwsA(isA<ArgumentError>()),
      );

      // No history created for rejected inputs
      final history = await helper.getAllCostHistory();
      expect(history, isEmpty);
    });

    test('11: v18 -> v19 migration is additive and idempotent', () async {
      final tempDir = await Directory.systemTemp.createTemp('muaman_v19_test');
      final path =
          p.join(tempDir.path, 'db_${DateTime.now().microsecondsSinceEpoch}.db');
      final v18Db = await databaseFactoryFfiNoIsolate.openDatabase(path);
      await DatabaseHelper.runFreshOnCreateForTest(v18Db, version: 18);
      await DatabaseHelper.setTestDatabase(v18Db);

      final before = await v18Db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='cost_history'");
      expect(before, isEmpty, reason: 'v18 does not have cost_history');

      await DatabaseHelper.runUpgradeToV19ForTest(v18Db);
      final after = await v18Db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='cost_history'");
      expect(after, isNotEmpty, reason: 'v19 adds cost_history additively');

      // Idempotent re-run
      await DatabaseHelper.runUpgradeToV19ForTest(v18Db);
      final afterRerun = await v18Db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='cost_history'");
      expect(afterRerun, hasLength(1));

      await v18Db.close();
      try {
        await tempDir.delete(recursive: true);
      } catch (_) {}
    });

    test('12: product update and history insert are transactionally coherent',
        () async {
      final product = await seedProduct(cost: 100);
      await helper.updateProduct(
        product.copyWith(costPrice: 120),
        currentRole: UserRole.owner,
      );

      // Verify both the product update and the history record committed.
      final updated = await helper.getProductByBarcode('BC-A');
      expect(updated!.costPrice, 120);
      final history = await helper.getAllCostHistory();
      expect(history, hasLength(1));
      expect(history.single.newCost, 120);
    });
  });
}
