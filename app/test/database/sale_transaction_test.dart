import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:muaman_store/database/database_helper.dart';
import 'package:muaman_store/models/user_role.dart';
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

  group('insertSaleAndDecrementStock', () {
    test('Test 1: Successful sale decrements stock', () async {
      await testDb.insert(
          'products', insertTestProduct().toMap()..remove('id'));

      await DatabaseHelper.instance
          .insertSaleAndDecrementStock(makeSale(), currentRole: UserRole.owner);

      final sales = await testDb.query('sales');
      expect(sales.length, 1);

      final products = await testDb.query('products');
      expect(products.length, 1);
      final updatedProduct = Product.fromMap(products.first);
      expect(updatedProduct.currentQuantity, 7);
      expect(updatedProduct.soldQuantity, 3);

      final expectedCurrent = updatedProduct.openingQuantity -
          updatedProduct.soldQuantity +
          updatedProduct.returnedQuantity +
          updatedProduct.inventoryAdjustment;
      expect(updatedProduct.currentQuantity, expectedCurrent);
    });

    test('Test 2: Exact stock sale succeeds and results in zero stock',
        () async {
      await testDb.insert(
          'products',
          insertTestProduct(
            currentQuantity: 5,
            openingQuantity: 5,
          ).toMap()
            ..remove('id'));

      await DatabaseHelper.instance.insertSaleAndDecrementStock(
          makeSale(quantity: 5),
          currentRole: UserRole.owner);

      final products = await testDb.query('products');
      final updatedProduct = Product.fromMap(products.first);
      expect(updatedProduct.currentQuantity, 0);
      expect(updatedProduct.soldQuantity, 5);
    });

    test('Test 3: Insufficient stock rejects sale', () async {
      await testDb.insert(
          'products',
          insertTestProduct(
            currentQuantity: 4,
            openingQuantity: 4,
          ).toMap()
            ..remove('id'));

      expect(
        () => DatabaseHelper.instance.insertSaleAndDecrementStock(
            makeSale(quantity: 5),
            currentRole: UserRole.owner),
        throwsA(isA<StateError>()),
      );

      final sales = await testDb.query('sales');
      expect(sales, isEmpty);

      final products = await testDb.query('products');
      expect(products.length, 1);
      final product = Product.fromMap(products.first);
      expect(product.currentQuantity, 4);
    });

    test('Test 4: Zero quantity rejects sale', () async {
      await testDb.insert(
          'products', insertTestProduct().toMap()..remove('id'));

      expect(
        () => DatabaseHelper.instance.insertSaleAndDecrementStock(
            makeSale(quantity: 0),
            currentRole: UserRole.owner),
        throwsA(isA<ArgumentError>()),
      );

      final sales = await testDb.query('sales');
      expect(sales, isEmpty);

      final products = await testDb.query('products');
      expect(products.length, 1);
      final product = Product.fromMap(products.first);
      expect(product.currentQuantity, 10);
    });

    test('Test 5: Negative quantity rejects sale', () async {
      await testDb.insert(
          'products', insertTestProduct().toMap()..remove('id'));

      expect(
        () => DatabaseHelper.instance.insertSaleAndDecrementStock(
            makeSale(quantity: -1),
            currentRole: UserRole.owner),
        throwsA(isA<ArgumentError>()),
      );

      final sales = await testDb.query('sales');
      expect(sales, isEmpty);

      final products = await testDb.query('products');
      expect(products.length, 1);
      final product = Product.fromMap(products.first);
      expect(product.currentQuantity, 10);
    });

    test('Test 6: Rollback when stock check fails after sale insert', () async {
      await testDb.insert(
          'products',
          insertTestProduct(
            currentQuantity: 5,
            openingQuantity: 5,
          ).toMap()
            ..remove('id'));

      expect(
        () => DatabaseHelper.instance.insertSaleAndDecrementStock(
            makeSale(quantity: 6),
            currentRole: UserRole.owner),
        throwsA(isA<StateError>()),
      );

      final sales = await testDb.query('sales');
      expect(sales, isEmpty,
          reason: 'Sale must be rolled back on stock check failure');

      final products = await testDb.query('products');
      final product = Product.fromMap(products.first);
      expect(product.currentQuantity, 5);
    });

    test('Test 7: Stale UI quantity — method reads fresh stock from DB',
        () async {
      await testDb.insert(
          'products',
          insertTestProduct(
            currentQuantity: 2,
            openingQuantity: 2,
          ).toMap()
            ..remove('id'));

      expect(
        () => DatabaseHelper.instance.insertSaleAndDecrementStock(
            makeSale(quantity: 3),
            currentRole: UserRole.owner),
        throwsA(isA<StateError>()),
      );

      final sales = await testDb.query('sales');
      expect(sales, isEmpty);

      final products = await testDb.query('products');
      final product = Product.fromMap(products.first);
      expect(product.currentQuantity, 2);
    });

    test('Test 9: Zero sale price is rejected', () async {
      await testDb.insert(
          'products', insertTestProduct().toMap()..remove('id'));

      expect(
        () => DatabaseHelper.instance.insertSaleAndDecrementStock(
            makeSale(salePrice: 0),
            currentRole: UserRole.owner),
        throwsA(isA<ArgumentError>()),
      );

      final sales = await testDb.query('sales');
      expect(sales, isEmpty);

      final products = await testDb.query('products');
      final product = Product.fromMap(products.first);
      expect(product.currentQuantity, 10);
    });

    test('Test 10: Negative sale price is rejected', () async {
      await testDb.insert(
          'products', insertTestProduct().toMap()..remove('id'));

      expect(
        () => DatabaseHelper.instance.insertSaleAndDecrementStock(
            makeSale(salePrice: -50),
            currentRole: UserRole.owner),
        throwsA(isA<ArgumentError>()),
      );

      final sales = await testDb.query('sales');
      expect(sales, isEmpty);

      final products = await testDb.query('products');
      final product = Product.fromMap(products.first);
      expect(product.currentQuantity, 10);
    });

    test('Test 11: Positive sale price still accepted', () async {
      await testDb.insert(
          'products', insertTestProduct().toMap()..remove('id'));

      await DatabaseHelper.instance.insertSaleAndDecrementStock(
          makeSale(salePrice: 100),
          currentRole: UserRole.owner);

      final sales = await testDb.query('sales');
      expect(sales.length, 1);
      expect((sales.first['salePrice'] as num).toDouble(), 100);

      final products = await testDb.query('products');
      final product = Product.fromMap(products.first);
      expect(product.currentQuantity, 7);
    });

    test('Test 8: Consecutive sales maintain correct stock', () async {
      await testDb.insert(
          'products',
          insertTestProduct(
            currentQuantity: 10,
            openingQuantity: 10,
          ).toMap()
            ..remove('id'));

      await DatabaseHelper.instance.insertSaleAndDecrementStock(
          makeSale(quantity: 4),
          currentRole: UserRole.owner);
      await DatabaseHelper.instance.insertSaleAndDecrementStock(
          makeSale(quantity: 3),
          currentRole: UserRole.owner);

      final sales = await testDb.query('sales');
      expect(sales.length, 2);

      final products = await testDb.query('products');
      final product = Product.fromMap(products.first);
      expect(product.currentQuantity, 3);
      expect(product.soldQuantity, 7);

      final expectedCurrent = product.openingQuantity -
          product.soldQuantity +
          product.returnedQuantity +
          product.inventoryAdjustment;
      expect(product.currentQuantity, expectedCurrent);
    });
  });

  group('insertSale', () {
    test('rejects zero sale price', () async {
      await testDb.insert(
          'products', insertTestProduct().toMap()..remove('id'));

      expect(
        () => DatabaseHelper.instance
            .insertSale(makeSale(salePrice: 0), currentRole: UserRole.owner),
        throwsA(isA<ArgumentError>()),
      );

      final sales = await testDb.query('sales');
      expect(sales, isEmpty);
    });

    test('rejects negative sale price', () async {
      await testDb.insert(
          'products', insertTestProduct().toMap()..remove('id'));

      expect(
        () => DatabaseHelper.instance
            .insertSale(makeSale(salePrice: -50), currentRole: UserRole.owner),
        throwsA(isA<ArgumentError>()),
      );

      final sales = await testDb.query('sales');
      expect(sales, isEmpty);
    });

    test('rejects zero quantity', () async {
      await testDb.insert(
          'products', insertTestProduct().toMap()..remove('id'));

      expect(
        () => DatabaseHelper.instance
            .insertSale(makeSale(quantity: 0), currentRole: UserRole.owner),
        throwsA(isA<ArgumentError>()),
      );

      final sales = await testDb.query('sales');
      expect(sales, isEmpty);
    });

    test('accepts positive sale price', () async {
      await testDb.insert(
          'products', insertTestProduct().toMap()..remove('id'));

      await DatabaseHelper.instance
          .insertSale(makeSale(salePrice: 100), currentRole: UserRole.owner);

      final sales = await testDb.query('sales');
      expect(sales.length, 1);
      expect((sales.first['salePrice'] as num).toDouble(), 100);
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
}
