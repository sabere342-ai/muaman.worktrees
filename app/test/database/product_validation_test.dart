import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:muaman_store/database/database_helper.dart';
import 'package:muaman_store/models/user_role.dart';
import 'package:muaman_store/models/product.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  late Database testDb;

  setUp(() async {
    testDb = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await createProductTestTables(testDb);
    await DatabaseHelper.setTestDatabase(testDb);
  });

  tearDown(() async {
    await testDb.close();
  });

  Product makeProduct({
    String name = 'Test Product',
    String barcode = 'TEST001',
    int openingQuantity = 10,
    int currentQuantity = 10,
    double costPrice = 100.0,
  }) {
    return Product(
      name: name,
      barcode: barcode,
      openingQuantity: openingQuantity,
      currentQuantity: currentQuantity,
      costPrice: costPrice,
      totalInventoryCost: currentQuantity * costPrice,
    );
  }

  group('insertProduct — cost price validation', () {
    test('Zero cost price is rejected', () async {
      expect(
        () => DatabaseHelper.instance.insertProduct(makeProduct(costPrice: 0),
            currentRole: UserRole.owner),
        throwsA(isA<ArgumentError>()),
      );

      final products = await testDb.query('products');
      expect(products, isEmpty);
    });

    test('Negative cost price is rejected', () async {
      expect(
        () => DatabaseHelper.instance.insertProduct(makeProduct(costPrice: -50),
            currentRole: UserRole.owner),
        throwsA(isA<ArgumentError>()),
      );

      final products = await testDb.query('products');
      expect(products, isEmpty);
    });

    test('Positive cost price is accepted', () async {
      await DatabaseHelper.instance.insertProduct(makeProduct(costPrice: 150),
          currentRole: UserRole.owner);

      final products = await testDb.query('products');
      expect(products.length, 1);
      final product = Product.fromMap(products.first);
      expect(product.costPrice, 150);
    });
  });

  group('updateProduct — cost price validation', () {
    test('Update with zero cost price is rejected', () async {
      final id =
          await testDb.insert('products', makeProduct().toMap()..remove('id'));

      expect(
        () => DatabaseHelper.instance.updateProduct(
          makeProduct(costPrice: 0).copyWith(id: id),
          currentRole: UserRole.owner,
        ),
        throwsA(isA<ArgumentError>()),
      );

      final products = await testDb.query('products');
      expect(products.length, 1);
      final product = Product.fromMap(products.first);
      expect(product.costPrice, 100);
    });

    test('Update with negative cost price is rejected', () async {
      final id =
          await testDb.insert('products', makeProduct().toMap()..remove('id'));

      expect(
        () => DatabaseHelper.instance.updateProduct(
          makeProduct(costPrice: -20).copyWith(id: id),
          currentRole: UserRole.owner,
        ),
        throwsA(isA<ArgumentError>()),
      );

      final products = await testDb.query('products');
      expect(products.length, 1);
      final product = Product.fromMap(products.first);
      expect(product.costPrice, 100);
    });

    test('Update with positive cost price is accepted', () async {
      final id =
          await testDb.insert('products', makeProduct().toMap()..remove('id'));

      await DatabaseHelper.instance.updateProduct(
        makeProduct(costPrice: 200).copyWith(id: id),
        currentRole: UserRole.owner,
      );

      final products = await testDb.query('products');
      expect(products.length, 1);
      final product = Product.fromMap(products.first);
      expect(product.costPrice, 200);
    });
  });
}

Future<void> createProductTestTables(Database db) async {
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
      inventoryAdjustment INTEGER DEFAULT 0,
      shop_id TEXT,
      cloud_uuid TEXT,
      server_version INTEGER DEFAULT 0,
      sync_status TEXT DEFAULT 'SYNCED',
      last_synced_at TEXT
    )
  ''');
}
