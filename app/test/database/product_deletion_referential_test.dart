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
    await createDeletionTestTables(testDb);
    await DatabaseHelper.setTestDatabase(testDb);
  });

  tearDown(() async {
    await testDb.close();
  });

  Product insertProduct({
    int id = 1,
    String name = 'Test Product',
    String barcode = 'TEST001',
    int openingQuantity = 10,
    int currentQuantity = 10,
    double costPrice = 50.0,
  }) {
    return Product(
      id: id,
      name: name,
      barcode: barcode,
      openingQuantity: openingQuantity,
      currentQuantity: currentQuantity,
      costPrice: costPrice,
      totalInventoryCost: currentQuantity * costPrice,
    );
  }

  group('Product without references', () {
    test('Unreferenced product can be deleted successfully', () async {
      await testDb.insert('products', insertProduct().toMap()..remove('id'));

      await DatabaseHelper.instance.deleteProduct(1);

      final products = await testDb.query('products');
      expect(products, isEmpty);
    });

    test('Other products remain after deleting one unreferenced product',
        () async {
      await testDb.insert(
          'products',
          insertProduct(id: 1, name: 'A', barcode: 'A001').toMap()
            ..remove('id'));
      await testDb.insert(
          'products',
          insertProduct(id: 2, name: 'B', barcode: 'A002').toMap()
            ..remove('id'));

      await DatabaseHelper.instance.deleteProduct(1);

      final products = await testDb.query('products');
      expect(products.length, 1);
      expect(Product.fromMap(products.first).name, 'B');
    });
  });

  group('Product with sales references', () {
    test('Deleting product with sales is rejected', () async {
      await testDb.insert('products', insertProduct().toMap()..remove('id'));

      await testDb.insert('sales', {
        'date': '2026-07-28T00:00:00.000',
        'productName': 'Test Product',
        'barcode': 'TEST001',
        'quantity': 3,
        'salePrice': 100.0,
        'totalSaleValue': 300.0,
        'costPrice': 50.0,
        'cogs': 150.0,
      });

      expect(
        () => DatabaseHelper.instance.deleteProduct(1),
        throwsA(isA<ProductDeletionException>()),
      );
    });

    test('Product and sales remain intact after rejection', () async {
      await testDb.insert('products', insertProduct().toMap()..remove('id'));

      await testDb.insert('sales', {
        'date': '2026-07-28T00:00:00.000',
        'productName': 'Test Product',
        'barcode': 'TEST001',
        'quantity': 3,
        'salePrice': 100.0,
        'totalSaleValue': 300.0,
        'costPrice': 50.0,
        'cogs': 150.0,
      });

      expect(
        () => DatabaseHelper.instance.deleteProduct(1),
        throwsA(isA<ProductDeletionException>()),
      );

      final products = await testDb.query('products');
      expect(products.length, 1);

      final sales = await testDb.query('sales');
      expect(sales.length, 1);

      final product = Product.fromMap(products.first);
      expect(product.currentQuantity, 10);
    });
  });

  group('Product with returns references', () {
    test('Deleting product with returns is rejected', () async {
      await testDb.insert('products', insertProduct().toMap()..remove('id'));

      await testDb.insert('returns', {
        'date': '2026-07-28T00:00:00.000',
        'productName': 'Test Product',
        'barcode': 'TEST001',
        'quantity': 2,
        'salePrice': 100.0,
        'totalReturnValue': 200.0,
        'costPrice': 50.0,
        'returnedCogs': 100.0,
      });

      expect(
        () => DatabaseHelper.instance.deleteProduct(1),
        throwsA(isA<ProductDeletionException>()),
      );
    });

    test('Product and returns remain intact after rejection', () async {
      await testDb.insert('products', insertProduct().toMap()..remove('id'));

      await testDb.insert('returns', {
        'date': '2026-07-28T00:00:00.000',
        'productName': 'Test Product',
        'barcode': 'TEST001',
        'quantity': 2,
        'salePrice': 100.0,
        'totalReturnValue': 200.0,
        'costPrice': 50.0,
        'returnedCogs': 100.0,
      });

      expect(
        () => DatabaseHelper.instance.deleteProduct(1),
        throwsA(isA<ProductDeletionException>()),
      );

      final products = await testDb.query('products');
      expect(products.length, 1);

      final returns = await testDb.query('returns');
      expect(returns.length, 1);
    });
  });

  group('Product with inventory_count references', () {
    test('Deleting product with inventory count is rejected', () async {
      await testDb.insert('products', insertProduct().toMap()..remove('id'));

      await testDb.insert('inventory_count', {
        'productId': 1,
        'actualQuantity': 10,
        'notes': '',
        'countDate': '2026-07-28T00:00:00.000',
      });

      expect(
        () => DatabaseHelper.instance.deleteProduct(1),
        throwsA(isA<ProductDeletionException>()),
      );
    });

    test('Product and count records remain intact after rejection', () async {
      await testDb.insert('products', insertProduct().toMap()..remove('id'));

      await testDb.insert('inventory_count', {
        'productId': 1,
        'actualQuantity': 10,
        'notes': '',
        'countDate': '2026-07-28T00:00:00.000',
      });

      expect(
        () => DatabaseHelper.instance.deleteProduct(1),
        throwsA(isA<ProductDeletionException>()),
      );

      final products = await testDb.query('products');
      expect(products.length, 1);

      final counts = await testDb.query('inventory_count');
      expect(counts.length, 1);
    });
  });

  group('Product with zero quantity but history', () {
    test(
        'Product with zero current quantity but sale history cannot be deleted',
        () async {
      await testDb.insert(
          'products', insertProduct(currentQuantity: 0).toMap()..remove('id'));

      await testDb.insert('sales', {
        'date': '2026-07-28T00:00:00.000',
        'productName': 'Test Product',
        'barcode': 'TEST001',
        'quantity': 10,
        'salePrice': 100.0,
        'totalSaleValue': 1000.0,
        'costPrice': 50.0,
        'cogs': 500.0,
      });

      expect(
        () => DatabaseHelper.instance.deleteProduct(1),
        throwsA(isA<ProductDeletionException>()),
      );

      final products = await testDb.query('products');
      expect(products.length, 1);
    });
  });

  group('Direct DB layer protection (defense in depth)', () {
    test('Direct call to deleteProduct with references is rejected', () async {
      await testDb.insert('products', insertProduct().toMap()..remove('id'));

      await testDb.insert('inventory_count', {
        'productId': 1,
        'actualQuantity': 10,
        'notes': '',
        'countDate': '2026-07-28T00:00:00.000',
      });

      expect(
        () => DatabaseHelper.instance.deleteProduct(1),
        throwsA(isA<ProductDeletionException>()),
      );
    });

    test('getProductReferences returns correct reasons', () async {
      await testDb.insert('products', insertProduct().toMap()..remove('id'));

      await testDb.insert('sales', {
        'date': '2026-07-28T00:00:00.000',
        'productName': 'Test Product',
        'barcode': 'TEST001',
        'quantity': 3,
        'salePrice': 100.0,
        'totalSaleValue': 300.0,
        'costPrice': 50.0,
        'cogs': 150.0,
      });

      final refs = await DatabaseHelper.instance.getProductReferences(1);
      expect(refs, contains('مبيعات'));
    });

    test('getProductReferences returns empty for unreferenced product',
        () async {
      await testDb.insert('products', insertProduct().toMap()..remove('id'));

      final refs = await DatabaseHelper.instance.getProductReferences(1);
      expect(refs, isEmpty);
    });
  });

  group('ProductDeletionException message', () {
    test('Exception message is in Arabic', () async {
      final e = ProductDeletionException(['مبيعات']);
      expect(e.message, contains('لا يمكن حذف المنتج'));
      expect(e.message, contains('مبيعات'));
    });

    test('Exception with empty reasons falls back to default message', () {
      final e = ProductDeletionException([]);
      expect(e.message, 'لا يمكن حذف المنتج لوجود معاملات أو سجلات مرتبطة به');
    });
  });
}

Future<void> createDeletionTestTables(Database db) async {
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

  await db.execute('''
    CREATE TABLE inventory_count (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      productId INTEGER NOT NULL,
      actualQuantity INTEGER DEFAULT 0,
      notes TEXT DEFAULT '',
      countDate TEXT NOT NULL,
      FOREIGN KEY (productId) REFERENCES products (id)
    )
  ''');
}
