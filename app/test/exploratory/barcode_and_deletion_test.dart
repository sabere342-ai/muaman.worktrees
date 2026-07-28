import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:muaman_store/database/database_helper.dart';
import 'package:muaman_store/models/product.dart';
import 'package:muaman_store/models/sale.dart';
import 'package:muaman_store/models/return_item.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  late Database testDb;

  setUp(() async {
    testDb = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await createExploratoryTables(testDb);
    await DatabaseHelper.setTestDatabase(testDb);
  });

  tearDown(() async {
    await testDb.close();
  });

  group('Barcode uniqueness', () {
    test('Duplicate barcode is rejected by UNIQUE constraint', () async {
      await testDb.insert('products', {
        'name': 'Product A',
        'barcode': 'SAME001',
        'openingQuantity': 10,
        'soldQuantity': 0,
        'returnedQuantity': 0,
        'currentQuantity': 10,
        'costPrice': 100.0,
        'totalInventoryCost': 1000.0,
        'inventoryAdjustment': 0,
      });

      expect(
        () => testDb.insert('products', {
          'name': 'Product B',
          'barcode': 'SAME001',
          'openingQuantity': 5,
          'soldQuantity': 0,
          'returnedQuantity': 0,
          'currentQuantity': 5,
          'costPrice': 50.0,
          'totalInventoryCost': 250.0,
          'inventoryAdjustment': 0,
        }),
        throwsA(isA<DatabaseException>()),
      );

      final products = await testDb.query('products');
      expect(products.length, 1);
    });

    test('Sale uses barcode for lookup — duplicate would confuse', () async {
      await testDb.insert('products', {
        'name': 'Product A',
        'barcode': 'TEST001',
        'openingQuantity': 10,
        'soldQuantity': 0,
        'returnedQuantity': 0,
        'currentQuantity': 10,
        'costPrice': 100.0,
        'totalInventoryCost': 1000.0,
        'inventoryAdjustment': 0,
      });

      await DatabaseHelper.instance.insertSaleAndDecrementStock(
        Sale(
          date: DateTime(2026, 7, 28),
          productName: 'Product A',
          barcode: 'TEST001',
          quantity: 3,
          salePrice: 200.0,
          costPrice: 100.0,
        ),
      );

      final products = await testDb.query('products');
      final product = Product.fromMap(products.first);
      expect(product.currentQuantity, 7);
      expect(product.soldQuantity, 3);
    });
  });

  group('Product deletion', () {
    test('Deleting product with sales is rejected', () async {
      await testDb.insert('products', {
        'name': 'Product X',
        'barcode': 'DEL001',
        'openingQuantity': 10,
        'soldQuantity': 3,
        'returnedQuantity': 0,
        'currentQuantity': 7,
        'costPrice': 100.0,
        'totalInventoryCost': 700.0,
        'inventoryAdjustment': 0,
      });

      await testDb.insert('sales', {
        'date': '2026-07-28T00:00:00.000',
        'productName': 'Product X',
        'barcode': 'DEL001',
        'quantity': 3,
        'salePrice': 200.0,
        'totalSaleValue': 600.0,
        'costPrice': 100.0,
        'cogs': 300.0,
      });

      await testDb.insert('inventory_count', {
        'productId': 1,
        'actualQuantity': 7,
        'notes': '',
        'countDate': '2026-07-28T00:00:00.000',
      });

      expect(
        () => DatabaseHelper.instance.deleteProduct(1),
        throwsA(isA<ProductDeletionException>()),
      );

      final products = await testDb.query('products');
      expect(products.length, 1,
          reason: 'Product must still exist after rejection');

      final sales = await testDb.query('sales');
      expect(sales.length, 1,
          reason: 'Sales should persist after rejection');
      expect(sales.first['productName'], 'Product X');

      final counts = await testDb.query('inventory_count');
      expect(counts.length, 1,
          reason: 'Count records should persist after rejection');
    });

    test('Unreferenced product can be deleted', () async {
      await testDb.insert('products', {
        'name': 'Standalone',
        'barcode': 'STAND001',
        'openingQuantity': 5,
        'soldQuantity': 0,
        'returnedQuantity': 0,
        'currentQuantity': 5,
        'costPrice': 50.0,
        'totalInventoryCost': 250.0,
        'inventoryAdjustment': 0,
      });

      await DatabaseHelper.instance.deleteProduct(1);

      final products = await testDb.query('products');
      expect(products, isEmpty,
          reason: 'Unreferenced product should be deleted');
    });

    test('Deleting product referenced only by return is rejected', () async {
      await testDb.insert('products', {
        'name': 'Returned Item',
        'barcode': 'RET001',
        'openingQuantity': 10,
        'soldQuantity': 0,
        'returnedQuantity': 2,
        'currentQuantity': 10,
        'costPrice': 100.0,
        'totalInventoryCost': 1000.0,
        'inventoryAdjustment': 0,
      });

      await testDb.insert('returns', {
        'date': '2026-07-28T00:00:00.000',
        'productName': 'Returned Item',
        'barcode': 'RET001',
        'quantity': 2,
        'salePrice': 200.0,
        'totalReturnValue': 400.0,
        'costPrice': 100.0,
        'returnedCogs': 200.0,
      });

      expect(
        () => DatabaseHelper.instance.deleteProduct(1),
        throwsA(isA<ProductDeletionException>()),
      );

      final products = await testDb.query('products');
      expect(products.length, 1);
    });
  });

  group('Zero price', () {
    test('Zero sale price is rejected', () async {
      await testDb.insert('products', {
        'name': 'Free Sample',
        'barcode': 'FREE001',
        'openingQuantity': 5,
        'soldQuantity': 0,
        'returnedQuantity': 0,
        'currentQuantity': 5,
        'costPrice': 50.0,
        'totalInventoryCost': 250.0,
        'inventoryAdjustment': 0,
      });

      expect(
        () => DatabaseHelper.instance.insertSaleAndDecrementStock(
          Sale(
            date: DateTime(2026, 7, 28),
            productName: 'Free Sample',
            barcode: 'FREE001',
            quantity: 1,
            salePrice: 0,
            costPrice: 50.0,
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );

      final sales = await testDb.query('sales');
      expect(sales, isEmpty);

      final products = await testDb.query('products');
      final product = Product.fromMap(products.first);
      expect(product.currentQuantity, 5);
    });
  });
}

Future<void> createExploratoryTables(Database db) async {
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

  await db.execute('''
    CREATE TABLE returns (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      date TEXT NOT NULL,
      productName TEXT NOT NULL,
      barcode TEXT NOT NULL,
      quantity INTEGER DEFAULT 0,
      salePrice REAL DEFAULT 0,
      totalReturnValue REAL DEFAULT 0,
      costPrice REAL DEFAULT 0,
      returnedCogs REAL DEFAULT 0
    )
  ''');
}
