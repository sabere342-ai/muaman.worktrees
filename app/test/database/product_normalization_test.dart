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
    await createNormalizationTestTables(testDb);
    await DatabaseHelper.setTestDatabase(testDb);
  });

  tearDown(() async {
    await testDb.close();
  });

  Product makeProduct({
    int? id,
    String name = 'Test Product',
    String barcode = 'TEST001',
    int openingQuantity = 10,
    int currentQuantity = 10,
    double costPrice = 100.0,
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

  group('Name normalization — insertProduct', () {
    test('Name with leading/trailing spaces is trimmed on insert', () async {
      final id = await DatabaseHelper.instance.insertProduct(
          makeProduct(name: '  سكر  '),
          currentRole: UserRole.owner);

      final products =
          await testDb.query('products', where: 'id = ?', whereArgs: [id]);
      expect(products.first['name'], 'سكر');
    });

    test('Whitespace-only name is rejected on insert', () async {
      expect(
        () => DatabaseHelper.instance.insertProduct(makeProduct(name: '   '),
            currentRole: UserRole.owner),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('Empty name is rejected on insert', () async {
      expect(
        () => DatabaseHelper.instance
            .insertProduct(makeProduct(name: ''), currentRole: UserRole.owner),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('Name normalization — updateProduct', () {
    test('Name with leading/trailing spaces is trimmed on update', () async {
      final id =
          await testDb.insert('products', makeProduct().toMap()..remove('id'));

      await DatabaseHelper.instance.updateProduct(
          makeProduct(id: id, name: '  سكر أبيض  '),
          currentRole: UserRole.owner);

      final products =
          await testDb.query('products', where: 'id = ?', whereArgs: [id]);
      expect(products.first['name'], 'سكر أبيض');
    });

    test('Whitespace-only name is rejected on update', () async {
      final id =
          await testDb.insert('products', makeProduct().toMap()..remove('id'));

      expect(
        () => DatabaseHelper.instance.updateProduct(
            makeProduct(id: id, name: '   '),
            currentRole: UserRole.owner),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('Barcode normalization — insertProduct', () {
    test('Barcode with leading/trailing spaces is trimmed on insert', () async {
      final id = await DatabaseHelper.instance.insertProduct(
          makeProduct(barcode: '  12345  '),
          currentRole: UserRole.owner);

      final products =
          await testDb.query('products', where: 'id = ?', whereArgs: [id]);
      expect(products.first['barcode'], '12345');
    });
  });

  group('Barcode duplicate prevention with whitespace', () {
    test('Insert with barcode that matches existing after trim is rejected',
        () async {
      await DatabaseHelper.instance.insertProduct(makeProduct(barcode: '12345'),
          currentRole: UserRole.owner);

      expect(
        () => DatabaseHelper.instance.insertProduct(
            makeProduct(barcode: '  12345  '),
            currentRole: UserRole.owner),
        throwsA(isA<ArgumentError>()),
      );
    });

    test(
        'Update with barcode that matches another product after trim is rejected',
        () async {
      await testDb.insert('products',
          makeProduct(id: 1, barcode: '12345').toMap()..remove('id'));
      await testDb.insert('products',
          makeProduct(id: 2, barcode: '67890').toMap()..remove('id'));

      expect(
        () => DatabaseHelper.instance.updateProduct(
            makeProduct(id: 2, barcode: '  12345  '),
            currentRole: UserRole.owner),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('Update with same barcode (whitespace variation) allowed for self',
        () async {
      final id = await DatabaseHelper.instance.insertProduct(
          makeProduct(barcode: '12345'),
          currentRole: UserRole.owner);

      await DatabaseHelper.instance.updateProduct(
          makeProduct(id: id, barcode: '  12345  '),
          currentRole: UserRole.owner);

      final products =
          await testDb.query('products', where: 'id = ?', whereArgs: [id]);
      expect(products.first['barcode'], '12345');
    });
  });

  group('No partial write on rejection', () {
    test('Product count unchanged after rejected insert', () async {
      await DatabaseHelper.instance.insertProduct(makeProduct(barcode: 'ORIG'),
          currentRole: UserRole.owner);

      expect(
        () => DatabaseHelper.instance.insertProduct(
            makeProduct(barcode: '  ORIG  '),
            currentRole: UserRole.owner),
        throwsA(isA<ArgumentError>()),
      );

      final count = await testDb.query('products');
      expect(count.length, 1);
    });

    test('Product unchanged after rejected update', () async {
      await DatabaseHelper.instance.insertProduct(
          makeProduct(id: 1, barcode: 'ORIG', name: 'Original'),
          currentRole: UserRole.owner);

      expect(
        () => DatabaseHelper.instance.updateProduct(
            makeProduct(id: 1, barcode: 'DIFF', name: '   '),
            currentRole: UserRole.owner),
        throwsA(isA<ArgumentError>()),
      );

      final products =
          await testDb.query('products', where: 'id = ?', whereArgs: [1]);
      expect(products.first['name'], 'Original');
      expect(products.first['barcode'], 'ORIG');
    });
  });

  group('Normalized values stored in DB', () {
    test('Inserted name and barcode are stored trimmed', () async {
      await DatabaseHelper.instance.insertProduct(
          makeProduct(name: '  منتج جديد  ', barcode: '  NEW001  '),
          currentRole: UserRole.owner);

      final products = await testDb.query('products');
      expect(products.length, 1);
      expect(Product.fromMap(products.first).name, 'منتج جديد');
      expect(Product.fromMap(products.first).barcode, 'NEW001');
    });

    test('Updated name and barcode are stored trimmed', () async {
      final id = await DatabaseHelper.instance.insertProduct(
          makeProduct(name: 'Old', barcode: 'OLD001'),
          currentRole: UserRole.owner);

      await DatabaseHelper.instance.updateProduct(
          makeProduct(id: id, name: '  Updated  ', barcode: '  NEW001  '),
          currentRole: UserRole.owner);

      final products =
          await testDb.query('products', where: 'id = ?', whereArgs: [id]);
      final p = Product.fromMap(products.first);
      expect(p.name, 'Updated');
      expect(p.barcode, 'NEW001');
    });
  });

  group('Empty barcode validation', () {
    test('Empty barcode after trim is rejected', () async {
      expect(
        () => DatabaseHelper.instance.insertProduct(makeProduct(barcode: '   '),
            currentRole: UserRole.owner),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}

Future<void> createNormalizationTestTables(Database db) async {
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
