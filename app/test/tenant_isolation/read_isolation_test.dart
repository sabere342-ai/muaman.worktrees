import 'package:flutter_test/flutter_test.dart';
import 'package:muaman_store/database/database_helper.dart';
import 'package:muaman_store/models/customer.dart';
import 'package:muaman_store/models/user_role.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'fixture.dart';

/// J-WS2/WS4 negative read matrix (plan §H/§J): while strict tenant isolation
/// is armed, Shop A must never READ any Shop B row — by list, id, search,
/// barcode, invoice or date-range. Disarmed runtime keeps legacy behavior.
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
  });

  tearDown(() async {
    resetTestContext();
    DatabaseHelper.setTenantIsolationArmed(false);
    DatabaseHelper.resetForTest();
    await testDb.close();
  });

  group('legacy behavior preserved while isolation is DISARMED', () {
    test('J-R00: all shops\' rows are visible (compatibility mode)', () async {
      expect(await helper.getAllProducts(), hasLength(2));
      expect(
          await helper.getAllSales(currentRole: UserRole.owner), hasLength(2));
      expect(await helper.getAllCustomers(), hasLength(2));
      expect(await helper.getAllExpenseCategories(), hasLength(2));

      // Barcode of shop B resolves in legacy mode.
      expect(await helper.getProductByBarcode('BC-B'), isNotNull);
      // Invoice of shop B loads in legacy mode.
      final bInvoice = await testDb.query('invoices',
          where: 'shop_id = ?', whereArgs: ['shop-b'], limit: 1);
      expect(
          await helper.getInvoiceById(bInvoice.first['id'] as int,
              currentRole: UserRole.owner),
          isNotNull);
    });
  });

  group('armed isolation: Shop A cannot read Shop B data', () {
    setUp(() async {
      DatabaseHelper.setTenantIsolationArmed(true);
    });

    test('J-R01: product list excludes Shop B rows', () async {
      final products = await helper.getAllProducts();
      expect(products, hasLength(1));
      final row = await testDb
          .query('products', where: 'barcode = ?', whereArgs: ['BC-A']);
      expect(products.single.id, row.first['id']);
    });

    test('J-R02: barcode lookup cannot leak Shop B', () async {
      expect(await helper.getProductByBarcode('BC-A'), isNotNull);
      expect(await helper.getProductByBarcode('BC-B'), isNull,
          reason: "B's barcode scanned in A must resolve to not-found");
    });

    test('J-R03: name lookup cannot leak Shop B', () async {
      expect(await helper.getProductByName('منتج أ'), isNotNull);
      expect(await helper.getProductByName('منتج ب'), isNull);
    });

    test('J-R04: customer fetch by id cannot leak Shop B', () async {
      final bCustomer = await testDb.query('customers',
          where: 'shop_id = ?', whereArgs: ['shop-b'], limit: 1);
      expect(
          await helper.getCustomerById(bCustomer.first['id'] as int), isNull);

      final aCustomer = await testDb.query('customers',
          where: 'shop_id = ?', whereArgs: ['shop-a'], limit: 1);
      expect(await helper.getCustomerById(aCustomer.first['id'] as int),
          isNotNull);
    });

    test('J-R05: customer search cannot enumerate Shop B', () async {
      expect((await helper.searchCustomers('عميل')).map((c) => c.name),
          contains('عميل أ'));
      expect((await helper.searchCustomers('عميل')).map((c) => c.name),
          isNot(contains('عميل ب')));
    });

    test('J-R06: sales list and date-range exclude Shop B', () async {
      expect(
          await helper.getAllSales(currentRole: UserRole.owner), hasLength(1));

      final now = DateTime.now();
      final range = await helper.getSalesByDateRange(
          now.subtract(const Duration(days: 1)),
          now.add(const Duration(days: 1)),
          currentRole: UserRole.owner);
      expect(range.map((s) => s.barcode), contains('BC-A'));
      expect(range.map((s) => s.barcode), isNot(contains('BC-B')));
    });

    test('J-R07: invoice lookup by id cannot open a Shop B invoice', () async {
      final bInvoice = await testDb.query('invoices',
          where: 'shop_id = ?', whereArgs: ['shop-b'], limit: 1);
      final aInvoice = await testDb.query('invoices',
          where: 'shop_id = ?', whereArgs: ['shop-a'], limit: 1);

      expect(
          await helper.getInvoiceById(bInvoice.first['id'] as int,
              currentRole: UserRole.owner),
          isNull,
          reason: "B's invoice number must open nothing in A");
      expect(
          await helper.getInvoiceById(aInvoice.first['id'] as int,
              currentRole: UserRole.owner),
          isNotNull);
    });

    test('J-R08: sale lines of an invoice are scoped', () async {
      final bInvoice = await testDb.query('invoices',
          where: 'shop_id = ?', whereArgs: ['shop-b'], limit: 1);
      expect(
        await helper.getSalesByInvoiceId(bInvoice.first['id'] as int,
            currentRole: UserRole.owner),
        isEmpty,
      );
    });

    test('J-R09: returns, expenses and categories lists are scoped', () async {
      expect(await helper.getAllReturns(), hasLength(1));
      final returns = await testDb.query('returns');
      expect(returns.map((r) => r['shop_id']).toSet(),
          containsAll(['shop-a', 'shop-b']));
      expect((await helper.getAllReturns()).first.totalReturnValue, 100);

      final expenses = await helper.getAllExpenses();
      expect(expenses, hasLength(1));
      expect(expenses.single.amount, 50);

      final categories = await helper.getAllExpenseCategories();
      expect(categories.map((c) => c.name), contains('تصنيف أ'));
      expect(categories.map((c) => c.name), isNot(contains('تصنيف ب')));

      final distinct = await helper.getDistinctExpenseCategories();
      expect(distinct, contains('تصنيف أ'));
      expect(distinct, isNot(contains('تصنيف ب')));
    });

    test('J-R10: NULL-shop rows are invisible under strict mode', () async {
      await testDb.insert('products', {
        'name': 'يتيم',
        'barcode': 'BC-ORPHAN',
        'costPrice': 5.0,
      });
      expect(
        (await helper.getAllProducts()).map((p) => p.barcode),
        isNot(contains('BC-ORPHAN')),
        reason: 'unattributed rows belong to no authorized shop (plan §J)',
      );
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
  await db.insert('sales', {
    'date': date,
    'productName': 'منتج أ',
    'barcode': 'BC-A',
    'quantity': 1,
    'salePrice': 30,
    'totalSaleValue': 30,
    'costPrice': 10,
    'cogs': 10,
    'shop_id': 'shop-a',
  });
  await db.insert('sales', {
    'date': date,
    'productName': 'منتج ب',
    'barcode': 'BC-B',
    'quantity': 1,
    'salePrice': 60,
    'totalSaleValue': 60,
    'costPrice': 20,
    'cogs': 20,
    'shop_id': 'shop-b',
  });

  await db.insert('returns', {
    'date': date,
    'productName': 'منتج أ',
    'barcode': 'BC-A',
    'quantity': 1,
    'salePrice': 100,
    'totalReturnValue': 100,
    'costPrice': 10,
    'returnedCogs': 10,
    'shop_id': 'shop-a',
  });
  await db.insert('returns', {
    'date': date,
    'productName': 'منتج ب',
    'barcode': 'BC-B',
    'quantity': 1,
    'salePrice': 200,
    'totalReturnValue': 200,
    'costPrice': 20,
    'returnedCogs': 20,
    'shop_id': 'shop-b',
  });

  for (final entry in {
    'a': ('تصنيف أ', 50.0, 'shop-a'),
    'b': ('تصنيف ب', 75.0, 'shop-b'),
  }.entries) {
    final catId = await db.insert('expense_categories', {
      'name': entry.value.$1,
      'shop_id': entry.value.$3,
    });
    if (entry.key == 'a') {
      await db.insert('expenses', {
        'date': date,
        'description': 'مصروف أ',
        'amount': entry.value.$2,
        'category': entry.value.$1,
        'shop_id': entry.value.$3,
      });
    } else {
      await db.insert('expenses', {
        'date': date,
        'description': 'مصروف ب',
        'amount': entry.value.$2,
        'category': entry.value.$1,
        'shop_id': entry.value.$3,
      });
    }
    // Silence unused local warnings for catId bookkeeping.
    assert(catId > 0);
  }

  final now = DateTime.now().toIso8601String();
  for (final (name, shop, number) in [
    ('عميل أ', 'shop-a', 'INV-A'),
    ('عميل ب', 'shop-b', 'INV-B'),
  ]) {
    await db.insert(
        'customers',
        Customer(name: name).toMap()
          ..['shop_id'] = shop
          ..['createdAt'] = now
          ..['updatedAt'] = now);
    await db.insert('invoices', {
      'invoiceNumber': number,
      'date': date,
      'customerName': name,
      'paymentMethod': 'cash',
      'totalAmount': 10,
      'totalItems': 1,
      'createdAt': now,
      'shop_id': shop,
    });
  }
}
