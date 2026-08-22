import 'package:flutter_test/flutter_test.dart';
import 'package:muaman_store/database/database_helper.dart';
import 'package:muaman_store/models/customer.dart';
import 'package:muaman_store/models/expense.dart';
import 'package:muaman_store/models/expense_category.dart';
import 'package:muaman_store/models/product.dart';
import 'package:muaman_store/models/sale.dart';
import 'package:muaman_store/models/user_role.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'fixture.dart';

/// J-WS3 mutation matrix (plan §H/§K): cross-shop mutations by local id or
/// barcode must be no-ops that surface an explicit ownership error, inserts
/// must stamp the active shop, and armed writes without a tenant context must
/// fail closed.
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
    await _seedTwoShops(testDb);
    DatabaseHelper.setTenantIsolationArmed(true);
  });

  tearDown(() async {
    resetTestContext();
    DatabaseHelper.setTenantIsolationArmed(false);
    DatabaseHelper.resetForTest();
    await testDb.close();
  });

  Future<int> bProductId() async => (await testDb
          .query('products', where: 'barcode = ?', whereArgs: ['BC-B']))
      .first['id'] as int;

  group('armed isolation: Shop A cannot mutate Shop B data', () {
    test('J-W01: updating a Shop B product by id is an ownership error',
        () async {
      final bId = await bProductId();
      await expectLater(
        helper.updateProduct(
          Product(id: bId, name: 'اختراق', barcode: 'BC-B', costPrice: 1.0),
          currentRole: UserRole.owner,
        ),
        throwsA(isA<TenantOwnershipException>()),
      );
    });

    test('J-W02: deleting a Shop B product by id is an ownership error',
        () async {
      final bId = await bProductId();
      await expectLater(
        helper.deleteProduct(bId, currentRole: UserRole.owner),
        throwsA(isA<TenantOwnershipException>()),
      );
      // Row survives.
      expect(
        await testDb.query('products', where: 'id = ?', whereArgs: [bId]),
        hasLength(1),
      );
    });

    test('J-W03: deleting a Shop B sale by id is an ownership error', () async {
      final bSale = await testDb.query('sales',
          where: 'shop_id = ?', whereArgs: ['shop-b'], limit: 1);
      await expectLater(
        helper.deleteSale(bSale.first['id'] as int,
            currentRole: UserRole.owner),
        throwsA(isA<TenantOwnershipException>()),
      );
      expect(
        await testDb
            .query('sales', where: 'id = ?', whereArgs: [bSale.first['id']]),
        hasLength(1),
      );
    });

    test(
        'J-W04: archiving/reactivating a Shop B customer is an ownership error',
        () async {
      final bCustomer = await testDb.query('customers',
          where: 'shop_id = ?', whereArgs: ['shop-b'], limit: 1);
      final bId = bCustomer.first['id'] as int;

      await expectLater(
        helper.archiveCustomer(bId, currentRole: UserRole.owner),
        throwsA(isA<TenantOwnershipException>()),
      );
      await expectLater(
        helper.reactivateCustomer(bId, currentRole: UserRole.owner),
        throwsA(isA<TenantOwnershipException>()),
      );

      final stillActive =
          await testDb.query('customers', where: 'id = ?', whereArgs: [bId]);
      expect(stillActive.first['isActive'], 1);
    });
  });

  group('inserts stamp the active shop (plan §K)', () {
    test('J-W05: product insert carries shop_id of the bound context',
        () async {
      final id = await helper.insertProduct(
        Product(name: 'منتج جديد', barcode: 'BC-NEW', costPrice: 5.0),
        currentRole: UserRole.owner,
      );
      final row =
          (await testDb.query('products', where: 'id = ?', whereArgs: [id]))
              .single;
      expect(row['shop_id'], 'shop-a');
    });

    test('J-W06: expense and category inserts carry shop_id; dup check scoped',
        () async {
      final catId = await helper.insertExpenseCategory(
          const ExpenseCategory(name: 'تصنيف جديد'),
          currentRole: UserRole.owner);
      expect(
          ((await testDb.query('expense_categories',
                  where: 'id = ?', whereArgs: [catId]))
              .single)['shop_id'],
          'shop-a');

      // The scoped duplicate check only sees THIS shop's rows: a name used
      // exclusively by shop B does not block shop A's entry. (Cross-shop
      // duplicate names themselves are still blocked by the global UNIQUE
      // backstop — documented asymmetry, same class as Z-1 barcodes.)
      final uniqueName = 'فريد-${DateTime.now().microsecondsSinceEpoch}-أ';
      final catId2 = await helper.insertExpenseCategory(
          ExpenseCategory(name: uniqueName),
          currentRole: UserRole.owner);
      expect(catId2, greaterThan(0));

      // Same-name within shop A IS rejected by the scoped check.
      await expectLater(
        helper.insertExpenseCategory(const ExpenseCategory(name: 'تصنيف جديد'),
            currentRole: UserRole.owner),
        throwsArgumentError,
      );

      final expId = await helper.insertExpense(
        Expense(
            date: DateTime.now(),
            description: 'مصروف جديد',
            amount: 10,
            category: 'تصنيف جديد'),
        currentRole: UserRole.owner,
      );
      expect(
          ((await testDb.query('expenses', where: 'id = ?', whereArgs: [expId]))
              .single)['shop_id'],
          'shop-a');
    });

    test('J-W07: sale insert stamps shop_id and stock update stays scoped',
        () async {
      final id = await helper.insertSale(
        Sale(
            date: DateTime.now(),
            productName: 'منتج أ',
            barcode: 'BC-A',
            quantity: 1,
            salePrice: 15,
            costPrice: 10),
        currentRole: UserRole.owner,
      );
      final row =
          (await testDb.query('sales', where: 'id = ?', whereArgs: [id]))
              .single;
      expect(row['shop_id'], 'shop-a');
    });

    test('J-W08: selling a foreign-shop barcode fails (scoped lookup)',
        () async {
      // BC-B belongs to shop B only. Under armed isolation A cannot resolve
      // it, so the sale is rejected instead of touching B's inventory.
      await expectLater(
        helper.insertSaleAndDecrementStock(
          Sale(
              date: DateTime.now(),
              productName: 'منتج ب',
              barcode: 'BC-B',
              quantity: 1,
              salePrice: 60,
              costPrice: 20),
          currentRole: UserRole.owner,
        ),
        throwsStateError,
      );
    });
  });

  group('fail-closed without an authorized tenant context', () {
    setUp(() async {
      resetTestContext();
    });

    test('J-W09: business writes throw TenantIsolationException when unbound',
        () async {
      await expectLater(
        helper.insertProduct(
          Product(name: 'بلا متجر', barcode: 'BC-NOSHOP', costPrice: 5.0),
          currentRole: UserRole.owner,
        ),
        throwsA(isA<TenantIsolationException>()),
      );
      expect(
        await testDb
            .query('products', where: 'barcode = ?', whereArgs: ['BC-NOSHOP']),
        isEmpty,
        reason: 'no silent unattributed local-only write under armed isolation',
      );
    });

    test('J-W10: reads return empty (never unscoped) when unbound', () async {
      expect(await helper.getAllProducts(), isEmpty);
      expect(await helper.getProductByBarcode('BC-A'), isNull);
      expect(await helper.getTotalSales(), 0);
    });

    test('J-W11: customer insert stamps context shop', () async {
      await bindTestShop('shop-a');
      final id = await helper.insertCustomer(Customer(name: 'عميل جديد'),
          currentRole: UserRole.owner);
      expect(
          ((await testDb.query('customers', where: 'id = ?', whereArgs: [id]))
              .single)['shop_id'],
          'shop-a');
    });
  });
}

Future<void> _seedTwoShops(Database db) async {
  await db.insert('products', {
    'name': 'منتج أ',
    'barcode': 'BC-A',
    'openingQuantity': 10,
    'currentQuantity': 10,
    'costPrice': 10.0,
    'totalInventoryCost': 100.0,
    'shop_id': 'shop-a',
  });
  await db.insert('products', {
    'name': 'منتج ب',
    'barcode': 'BC-B',
    'openingQuantity': 20,
    'currentQuantity': 20,
    'costPrice': 20.0,
    'totalInventoryCost': 400.0,
    'shop_id': 'shop-b',
  });

  final date = DateTime.now().toIso8601String();
  for (final (barcode, name, price, cost, shop) in [
    ('BC-A', 'منتج أ', 30.0, 10.0, 'shop-a'),
    ('BC-B', 'منتج ب', 60.0, 20.0, 'shop-b'),
  ]) {
    await db.insert('sales', {
      'date': date,
      'productName': name,
      'barcode': barcode,
      'quantity': 1,
      'salePrice': price,
      'totalSaleValue': price,
      'costPrice': cost,
      'cogs': cost,
      'shop_id': shop,
    });
  }

  await db.insert('expense_categories', {'name': 'مشترك', 'shop_id': 'shop-b'});

  final now = DateTime.now().toIso8601String();
  await db.insert(
      'customers',
      Customer(name: 'عميل أ').toMap()
        ..['shop_id'] = 'shop-a'
        ..['createdAt'] = now
        ..['updatedAt'] = now);
  await db.insert(
      'customers',
      Customer(name: 'عميل ب').toMap()
        ..['shop_id'] = 'shop-b'
        ..['createdAt'] = now
        ..['updatedAt'] = now);
}
