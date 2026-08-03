import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:muaman_store/database/database_helper.dart';
import 'package:muaman_store/models/product.dart';
import 'package:muaman_store/models/sale.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  late Database testDb;

  setUp(() async {
    testDb = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await createTestTables(testDb);
    await DatabaseHelper.setTestDatabase(testDb);
  });

  tearDown(() async {
    await testDb.close();
  });

  Product insertTestProduct({
    int id = 1,
    String name = 'Test Product',
    String barcode = 'TEST001',
    int openingQuantity = 10,
    int soldQuantity = 0,
    int returnedQuantity = 0,
    int currentQuantity = 10,
    double costPrice = 50.0,
    int inventoryAdjustment = 0,
  }) {
    final product = Product(
      id: id,
      name: name,
      barcode: barcode,
      openingQuantity: openingQuantity,
      soldQuantity: soldQuantity,
      returnedQuantity: returnedQuantity,
      currentQuantity: currentQuantity,
      costPrice: costPrice,
      totalInventoryCost: currentQuantity * costPrice,
      inventoryAdjustment: inventoryAdjustment,
    );
    return product;
  }

  Sale makeSale({
    String productName = 'Test Product',
    String barcode = 'TEST001',
    int quantity = 3,
    double salePrice = 100.0,
    double costPrice = 50.0,
  }) {
    return Sale(
      date: DateTime(2026, 7, 28),
      productName: productName,
      barcode: barcode,
      quantity: quantity,
      salePrice: salePrice,
      costPrice: costPrice,
    );
  }

  void verifyEquation(Map<String, dynamic> productMap) {
    final p = Product.fromMap(productMap);
    final computed = p.openingQuantity -
        p.soldQuantity +
        p.returnedQuantity +
        p.inventoryAdjustment;
    expect(p.currentQuantity, computed,
        reason:
            'Inventory equation failed: opening=${p.openingQuantity} - sold=${p.soldQuantity} + returned=${p.returnedQuantity} + adjustment=${p.inventoryAdjustment} should equal current=${p.currentQuantity} but computed=$computed');
  }

  group('insertInventoryCountAndReconcileStock', () {
    test('Test 1: Downward reconciliation', () async {
      await testDb.insert(
          'products',
          insertTestProduct(
            currentQuantity: 10,
            openingQuantity: 10,
          ).toMap()
            ..remove('id'));

      await DatabaseHelper.instance.saveInventoryCount(1, 7, '');

      final counts = await testDb.query('inventory_count');
      expect(counts.length, 1);

      final products = await testDb.query('products');
      final product = Product.fromMap(products.first);
      expect(product.currentQuantity, 7);
      expect(product.inventoryAdjustment, -3);
      verifyEquation(products.first);
    });

    test('Test 2: Upward reconciliation', () async {
      await testDb.insert(
          'products',
          insertTestProduct(
            currentQuantity: 6,
            openingQuantity: 6,
          ).toMap()
            ..remove('id'));

      await DatabaseHelper.instance.saveInventoryCount(1, 9, '');

      final counts = await testDb.query('inventory_count');
      expect(counts.length, 1);

      final products = await testDb.query('products');
      final product = Product.fromMap(products.first);
      expect(product.currentQuantity, 9);
      expect(product.inventoryAdjustment, 3);
      verifyEquation(products.first);
    });

    test('Test 3: Exact count', () async {
      await testDb.insert(
          'products',
          insertTestProduct(
            currentQuantity: 8,
            openingQuantity: 8,
          ).toMap()
            ..remove('id'));

      await DatabaseHelper.instance.saveInventoryCount(1, 8, '');

      final counts = await testDb.query('inventory_count');
      expect(counts.length, 1);

      final products = await testDb.query('products');
      final product = Product.fromMap(products.first);
      expect(product.currentQuantity, 8);
      expect(product.inventoryAdjustment, 0);
      verifyEquation(products.first);
    });

    test('Test 4: Repeated identical count', () async {
      await testDb.insert(
          'products',
          insertTestProduct(
            currentQuantity: 10,
            openingQuantity: 10,
          ).toMap()
            ..remove('id'));

      await DatabaseHelper.instance.saveInventoryCount(1, 8, '');
      await DatabaseHelper.instance.saveInventoryCount(1, 8, '');

      final counts = await testDb.query('inventory_count');
      expect(counts.length, 2);

      final products = await testDb.query('products');
      final product = Product.fromMap(products.first);
      expect(product.currentQuantity, 8);
      expect(product.inventoryAdjustment, -2);
      verifyEquation(products.first);
    });

    test('Test 5: Zero physical count', () async {
      await testDb.insert(
          'products',
          insertTestProduct(
            currentQuantity: 5,
            openingQuantity: 5,
          ).toMap()
            ..remove('id'));

      await DatabaseHelper.instance.saveInventoryCount(1, 0, '');

      final counts = await testDb.query('inventory_count');
      expect(counts.length, 1);

      final products = await testDb.query('products');
      final product = Product.fromMap(products.first);
      expect(product.currentQuantity, 0);
      expect(product.inventoryAdjustment, -5);
      verifyEquation(products.first);
    });

    test('Test 6: Negative count rejected', () async {
      await testDb.insert(
          'products',
          insertTestProduct(
            currentQuantity: 5,
            openingQuantity: 5,
          ).toMap()
            ..remove('id'));

      expect(
        () => DatabaseHelper.instance.saveInventoryCount(1, -1, ''),
        throwsA(isA<ArgumentError>()),
      );

      final counts = await testDb.query('inventory_count');
      expect(counts, isEmpty);

      final products = await testDb.query('products');
      final product = Product.fromMap(products.first);
      expect(product.currentQuantity, 5);
      expect(product.inventoryAdjustment, 0);
    });

    test('Test 7: Rollback on product-update failure', () async {
      await testDb.insert(
          'products',
          insertTestProduct(
            currentQuantity: 10,
            openingQuantity: 10,
          ).toMap()
            ..remove('id'));

      try {
        await testDb.transaction((txn) async {
          final maps =
              await txn.query('products', where: 'id = ?', whereArgs: [1]);
          final product = Product.fromMap(maps.first);

          await txn.insert('inventory_count', {
            'productId': 1,
            'actualQuantity': 7,
            'notes': '',
            'countDate': DateTime.now().toIso8601String(),
          });

          final diff = 7 - product.currentQuantity;
          final newAdjustment = product.inventoryAdjustment + diff;
          final newCurrent = product.openingQuantity -
              product.soldQuantity +
              product.returnedQuantity +
              newAdjustment;

          final affected = await txn.update(
            'products',
            {
              'inventoryAdjustment': newAdjustment,
              'currentQuantity': newCurrent,
              'totalInventoryCost': newCurrent * product.costPrice,
            },
            where: 'id = ? AND currentQuantity = ?',
            whereArgs: [1, 999],
          );

          if (affected == 0) {
            throw StateError('Simulated update failure');
          }
        });
        fail('Expected StateError was not thrown');
      } catch (_) {}

      final counts = await testDb.query('inventory_count');
      expect(counts, isEmpty,
          reason: 'No inventory-count row should remain after rollback');

      final products = await testDb.query('products');
      final product = Product.fromMap(products.first);
      expect(product.currentQuantity, 10);
      expect(product.inventoryAdjustment, 0);
    });

    test('Test 8: Stale UI quantity', () async {
      await testDb.insert(
          'products',
          insertTestProduct(
            currentQuantity: 10,
            openingQuantity: 10,
          ).toMap()
            ..remove('id'));

      await testDb.update('products', {'currentQuantity': 7},
          where: 'id = ?', whereArgs: [1]);

      final diff = await DatabaseHelper.instance.saveInventoryCount(1, 6, '');
      expect(diff, -1,
          reason:
              'Diff should be computed from DB quantity (7), not UI quantity (10)');

      final products = await testDb.query('products');
      final product = Product.fromMap(products.first);
      expect(product.currentQuantity, 6);
      verifyEquation(products.first);
    });

    test('Test 9: Sale after count', () async {
      await testDb.insert(
          'products',
          insertTestProduct(
            currentQuantity: 10,
            openingQuantity: 10,
          ).toMap()
            ..remove('id'));

      await DatabaseHelper.instance.saveInventoryCount(1, 8, '');

      await DatabaseHelper.instance
          .insertSaleAndDecrementStock(makeSale(quantity: 3));

      final counts = await testDb.query('inventory_count');
      expect(counts.length, 1);

      final sales = await testDb.query('sales');
      expect(sales.length, 1);

      final products = await testDb.query('products');
      final product = Product.fromMap(products.first);
      expect(product.currentQuantity, 5);
      verifyEquation(products.first);
    });

    test('Test 10: Consecutive counts around a sale', () async {
      await testDb.insert(
          'products',
          insertTestProduct(
            currentQuantity: 10,
            openingQuantity: 10,
          ).toMap()
            ..remove('id'));

      await DatabaseHelper.instance.saveInventoryCount(1, 9, '');

      await DatabaseHelper.instance
          .insertSaleAndDecrementStock(makeSale(quantity: 4));

      await DatabaseHelper.instance.saveInventoryCount(1, 6, '');

      final counts = await testDb.query('inventory_count');
      expect(counts.length, 2);

      final sales = await testDb.query('sales');
      expect(sales.length, 1);

      final products = await testDb.query('products');
      final product = Product.fromMap(products.first);
      expect(product.currentQuantity, 6);
      expect(product.soldQuantity, 4);
      expect(product.inventoryAdjustment, 0);
      verifyEquation(products.first);
    });
  });
}

Future<void> createTestTables(Database db) async {
  await db.execute('''
    CREATE TABLE products (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      barcode TEXT UNIQUE NOT NULL,
      openingQuantity INTEGER DEFAULT 0,
      soldQuantity INTEGER DEFAULT 0,
      returnedQuantity INTEGER DEFAULT 0,
      currentQuantity INTEGER DEFAULT 0,
      costPrice REAL DEFAULT 0,
      totalInventoryCost REAL DEFAULT 0,
      inventoryAdjustment INTEGER DEFAULT 0
    )
  ''');

  await db.execute('''
    CREATE TABLE sales (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      invoiceId INTEGER,
      date TEXT NOT NULL,
      productName TEXT NOT NULL,
      barcode TEXT NOT NULL,
      quantity INTEGER DEFAULT 0,
      salePrice REAL DEFAULT 0,
      totalSaleValue REAL DEFAULT 0,
      costPrice REAL DEFAULT 0,
      cogs REAL DEFAULT 0
    )
  ''');

  await db.execute('''
    CREATE TABLE inventory_count (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      productId INTEGER NOT NULL,
      actualQuantity INTEGER DEFAULT 0,
      notes TEXT DEFAULT '',
      countDate TEXT NOT NULL
    )
  ''');
}
