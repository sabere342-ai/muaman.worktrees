import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:muaman_store/database/database_helper.dart';
import 'package:muaman_store/models/user_role.dart';
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
    await createIntegrityTestTables(testDb);
    await DatabaseHelper.setTestDatabase(testDb);
  });

  tearDown(() async {
    await testDb.close();
  });

  Product makeProduct({
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

  Sale makeSale({
    int? id,
    String productName = 'Test Product',
    String barcode = 'TEST001',
    int quantity = 3,
    double salePrice = 100.0,
    double costPrice = 50.0,
  }) {
    return Sale(
      id: id,
      date: DateTime(2026, 7, 28),
      productName: productName,
      barcode: barcode,
      quantity: quantity,
      salePrice: salePrice,
      costPrice: costPrice,
    );
  }

  ReturnItem makeReturn({
    int? id,
    String productName = 'Test Product',
    String barcode = 'TEST001',
    int quantity = 2,
    double salePrice = 100.0,
    double costPrice = 50.0,
  }) {
    return ReturnItem(
      id: id,
      date: DateTime(2026, 7, 28),
      productName: productName,
      barcode: barcode,
      quantity: quantity,
      salePrice: salePrice,
      costPrice: costPrice,
    );
  }

  group('ProductReferenceIntegrityException', () {
    test('Exception carries Arabic message', () {
      final e = ProductReferenceIntegrityException('المنتج غير موجود');
      expect(e.message, contains('المنتج غير موجود'));
    });

    test('toString includes message', () {
      final e = ProductReferenceIntegrityException('test error');
      expect(e.toString(), contains('test error'));
    });
  });

  group('IntegrityIssueReport', () {
    test('hasIssues false when all lists empty', () {
      final report = IntegrityIssueReport(
        orphanSales: [],
        orphanReturns: [],
        orphanInventoryCounts: [],
      );
      expect(report.hasIssues, false);
      expect(report.totalOrphans, 0);
    });

    test('hasIssues true when any list non-empty', () {
      final report = IntegrityIssueReport(
        orphanSales: [
          {'id': 1}
        ],
        orphanReturns: [],
        orphanInventoryCounts: [],
      );
      expect(report.hasIssues, true);
      expect(report.totalOrphans, 1);
    });

    test('totalOrphans sums all lists', () {
      final report = IntegrityIssueReport(
        orphanSales: [
          {'id': 1}
        ],
        orphanReturns: [
          {'id': 2},
          {'id': 3}
        ],
        orphanInventoryCounts: [
          {'id': 4}
        ],
      );
      expect(report.totalOrphans, 4);
    });
  });

  group('findProductReferenceIntegrityIssues', () {
    test('Empty database produces no orphans', () async {
      final report =
          await DatabaseHelper.instance.findProductReferenceIntegrityIssues();
      expect(report.hasIssues, false);
    });

    test('Detects orphan inventory_count row', () async {
      await testDb.insert('products', makeProduct().toMap()..remove('id'));
      await testDb.insert('inventory_count', {
        'productId': 999,
        'actualQuantity': 10,
        'notes': '',
        'countDate': '2026-07-28T00:00:00.000',
      });

      final report =
          await DatabaseHelper.instance.findProductReferenceIntegrityIssues();
      expect(report.hasIssues, true);
      expect(report.orphanInventoryCounts.length, 1);
      expect(report.orphanSales, isEmpty);
      expect(report.orphanReturns, isEmpty);
    });

    test('Detects orphan sales row', () async {
      await testDb.insert('sales', {
        'date': '2026-07-28T00:00:00.000',
        'productName': 'Ghost Product',
        'barcode': 'NONEXISTENT',
        'quantity': 3,
        'salePrice': 100.0,
        'totalSaleValue': 300.0,
        'costPrice': 50.0,
        'cogs': 150.0,
      });

      final report =
          await DatabaseHelper.instance.findProductReferenceIntegrityIssues();
      expect(report.hasIssues, true);
      expect(report.orphanSales.length, 1);
      expect(report.orphanInventoryCounts, isEmpty);
      expect(report.orphanReturns, isEmpty);
    });

    test('Detects orphan returns row', () async {
      await testDb.insert('returns', {
        'date': '2026-07-28T00:00:00.000',
        'productName': 'Ghost Return',
        'barcode': 'NONEXISTENT',
        'quantity': 2,
        'salePrice': 100.0,
        'totalReturnValue': 200.0,
        'costPrice': 50.0,
        'returnedCogs': 100.0,
      });

      final report =
          await DatabaseHelper.instance.findProductReferenceIntegrityIssues();
      expect(report.hasIssues, true);
      expect(report.orphanReturns.length, 1);
      expect(report.orphanSales, isEmpty);
      expect(report.orphanInventoryCounts, isEmpty);
    });

    test('Rows with valid product references are not reported', () async {
      await testDb.insert('products', makeProduct().toMap()..remove('id'));

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

      await testDb.insert('inventory_count', {
        'productId': 1,
        'actualQuantity': 10,
        'notes': '',
        'countDate': '2026-07-28T00:00:00.000',
      });

      final report =
          await DatabaseHelper.instance.findProductReferenceIntegrityIssues();
      expect(report.hasIssues, false);
    });
  });

  group('insertSale guard', () {
    test('Rejects sale with non-existent product barcode', () async {
      expect(
        () => DatabaseHelper.instance.insertSale(makeSale(barcode: 'GHOST001'),
            currentRole: UserRole.owner),
        throwsA(isA<ProductReferenceIntegrityException>()),
      );
    });

    test('No sale row written after rejection', () async {
      expect(
        () => DatabaseHelper.instance.insertSale(makeSale(barcode: 'GHOST001'),
            currentRole: UserRole.owner),
        throwsA(isA<ProductReferenceIntegrityException>()),
      );

      final sales = await testDb.query('sales');
      expect(sales, isEmpty);
    });

    test('Accepts sale with valid product barcode', () async {
      await testDb.insert('products', makeProduct().toMap()..remove('id'));

      await DatabaseHelper.instance
          .insertSale(makeSale(), currentRole: UserRole.owner);

      final sales = await testDb.query('sales');
      expect(sales.length, 1);
    });

    test('Updates stock after valid sale', () async {
      await testDb.insert('products', makeProduct().toMap()..remove('id'));

      await DatabaseHelper.instance
          .insertSale(makeSale(quantity: 3), currentRole: UserRole.owner);

      final products = await testDb.query('products');
      final product = Product.fromMap(products.first);
      expect(product.soldQuantity, 3);
      expect(product.currentQuantity, 7);
    });
  });

  group('insertReturn guard', () {
    test('Rejects return with non-existent product barcode', () async {
      expect(
        () => DatabaseHelper.instance.insertReturn(
            makeReturn(barcode: 'GHOST001'),
            currentRole: UserRole.owner),
        throwsA(isA<ProductReferenceIntegrityException>()),
      );
    });

    test('No return row written after rejection', () async {
      expect(
        () => DatabaseHelper.instance.insertReturn(
            makeReturn(barcode: 'GHOST001'),
            currentRole: UserRole.owner),
        throwsA(isA<ProductReferenceIntegrityException>()),
      );

      final returns = await testDb.query('returns');
      expect(returns, isEmpty);
    });

    test('Accepts return with valid product barcode', () async {
      await testDb.insert('products', makeProduct().toMap()..remove('id'));

      await DatabaseHelper.instance
          .insertReturn(makeReturn(), currentRole: UserRole.owner);

      final returns = await testDb.query('returns');
      expect(returns.length, 1);
    });

    test('Updates stock after valid return', () async {
      await testDb.insert('products', makeProduct().toMap()..remove('id'));

      await DatabaseHelper.instance
          .insertReturn(makeReturn(quantity: 2), currentRole: UserRole.owner);

      final products = await testDb.query('products');
      final product = Product.fromMap(products.first);
      expect(product.returnedQuantity, 2);
      expect(product.currentQuantity, 12);
    });
  });

  group('updateSale guard', () {
    test('Rejects update when new barcode has no matching product', () async {
      await testDb.insert('products',
          makeProduct(id: 1, barcode: 'OLD001').toMap()..remove('id'));
      await testDb.insert('products',
          makeProduct(id: 2, barcode: 'VALID002').toMap()..remove('id'));

      final saleId = await testDb.insert('sales', {
        'date': '2026-07-28T00:00:00.000',
        'productName': 'Old Product',
        'barcode': 'OLD001',
        'quantity': 3,
        'salePrice': 100.0,
        'totalSaleValue': 300.0,
        'costPrice': 50.0,
        'cogs': 150.0,
      });

      expect(
        () => DatabaseHelper.instance
            .updateSale(makeSale(id: saleId, barcode: 'GHOST001')),
        throwsA(isA<ProductReferenceIntegrityException>()),
      );
    });

    test('Old stock is preserved and no partial write after rejection',
        () async {
      await testDb.insert('products',
          makeProduct(id: 1, barcode: 'OLD001').toMap()..remove('id'));

      final saleId = await DatabaseHelper.instance.insertSale(
          makeSale(barcode: 'OLD001', quantity: 3),
          currentRole: UserRole.owner);

      await DatabaseHelper.instance
          .updateSale(makeSale(id: saleId, barcode: 'OLD001', quantity: 5));

      expect(
        () => DatabaseHelper.instance
            .updateSale(makeSale(id: saleId, barcode: 'GHOST001')),
        throwsA(isA<ProductReferenceIntegrityException>()),
      );

      final products = await testDb.query('products');
      final product = Product.fromMap(products.first);
      expect(product.soldQuantity, 5);

      final sales = await testDb.query('sales');
      expect(sales.first['barcode'], 'OLD001');
    });

    test('Accepts update when new barcode matches existing product', () async {
      await testDb.insert('products',
          makeProduct(id: 1, barcode: 'OLD001').toMap()..remove('id'));
      await testDb.insert('products',
          makeProduct(id: 2, barcode: 'NEW001').toMap()..remove('id'));

      final saleId = await testDb.insert('sales', {
        'date': '2026-07-28T00:00:00.000',
        'productName': 'Old Product',
        'barcode': 'OLD001',
        'quantity': 3,
        'salePrice': 100.0,
        'totalSaleValue': 300.0,
        'costPrice': 50.0,
        'cogs': 150.0,
      });

      await DatabaseHelper.instance.updateSale(
        makeSale(id: saleId, barcode: 'NEW001', quantity: 2),
      );

      final sales = await testDb.query('sales');
      expect(sales.length, 1);
      expect(sales.first['barcode'], 'NEW001');
    });
  });

  group('updateReturn guard', () {
    test('Rejects update when new barcode has no matching product', () async {
      await testDb.insert('products',
          makeProduct(id: 1, barcode: 'OLD001').toMap()..remove('id'));
      await testDb.insert('products',
          makeProduct(id: 2, barcode: 'VALID002').toMap()..remove('id'));

      final returnId = await testDb.insert('returns', {
        'date': '2026-07-28T00:00:00.000',
        'productName': 'Old Return',
        'barcode': 'OLD001',
        'quantity': 2,
        'salePrice': 100.0,
        'totalReturnValue': 200.0,
        'costPrice': 50.0,
        'returnedCogs': 100.0,
      });

      expect(
        () => DatabaseHelper.instance
            .updateReturn(makeReturn(id: returnId, barcode: 'GHOST001')),
        throwsA(isA<ProductReferenceIntegrityException>()),
      );
    });

    test('Accepts update when new barcode matches existing product', () async {
      await testDb.insert('products',
          makeProduct(id: 1, barcode: 'OLD001').toMap()..remove('id'));
      await testDb.insert('products',
          makeProduct(id: 2, barcode: 'NEW001').toMap()..remove('id'));

      final returnId = await testDb.insert('returns', {
        'date': '2026-07-28T00:00:00.000',
        'productName': 'Old Return',
        'barcode': 'OLD001',
        'quantity': 2,
        'salePrice': 100.0,
        'totalReturnValue': 200.0,
        'costPrice': 50.0,
        'returnedCogs': 100.0,
      });

      await DatabaseHelper.instance.updateReturn(
        makeReturn(id: returnId, barcode: 'NEW001', quantity: 1),
      );

      final returns = await testDb.query('returns');
      expect(returns.length, 1);
      expect(returns.first['barcode'], 'NEW001');
    });
  });

  group('Existing guarded paths still work', () {
    test('insertSaleAndDecrementStock still rejects missing product', () async {
      expect(
        () => DatabaseHelper.instance.insertSaleAndDecrementStock(
            makeSale(barcode: 'GHOST001'),
            currentRole: UserRole.owner),
        throwsA(isA<StateError>()),
      );
    });

    test('saveInventoryCount still rejects missing product', () async {
      expect(
        () => DatabaseHelper.instance
            .saveInventoryCount(999, 10, '', currentRole: UserRole.owner),
        throwsA(isA<StateError>()),
      );
    });

    test('insertSaleAndDecrementStock succeeds with valid product', () async {
      await testDb.insert('products', makeProduct().toMap()..remove('id'));

      await DatabaseHelper.instance.insertSaleAndDecrementStock(
          makeSale(quantity: 3),
          currentRole: UserRole.owner);

      final sales = await testDb.query('sales');
      expect(sales.length, 1);

      final products = await testDb.query('products');
      final product = Product.fromMap(products.first);
      expect(product.currentQuantity, 7);
    });
  });

  group('Transaction atomicity on guard rejection', () {
    test(
        'No partial write when sale product missing and sale insert is guarded',
        () async {
      await testDb.insert('products', makeProduct().toMap()..remove('id'));

      expect(
        () => DatabaseHelper.instance.insertSale(makeSale(barcode: 'GHOST001'),
            currentRole: UserRole.owner),
        throwsA(isA<ProductReferenceIntegrityException>()),
      );

      final sales = await testDb.query('sales');
      expect(sales, isEmpty);

      final products = await testDb.query('products');
      expect(products.length, 1);
    });

    test('No partial write when return product missing', () async {
      await testDb.insert('products', makeProduct().toMap()..remove('id'));

      expect(
        () => DatabaseHelper.instance.insertReturn(
            makeReturn(barcode: 'GHOST001'),
            currentRole: UserRole.owner),
        throwsA(isA<ProductReferenceIntegrityException>()),
      );

      final returns = await testDb.query('returns');
      expect(returns, isEmpty);

      final products = await testDb.query('products');
      expect(products.length, 1);
    });
  });

  group('Defense in depth', () {
    test('Direct insertSaleAndDecrementStock already has product check',
        () async {
      expect(
        () => DatabaseHelper.instance.insertSaleAndDecrementStock(
            makeSale(barcode: 'MISSING'),
            currentRole: UserRole.owner),
        throwsA(isA<StateError>()),
      );

      final sales = await testDb.query('sales');
      expect(sales, isEmpty);
    });

    test('Direct saveInventoryCount already has product check', () async {
      expect(
        () => DatabaseHelper.instance
            .saveInventoryCount(9999, 5, '', currentRole: UserRole.owner),
        throwsA(isA<StateError>()),
      );

      final counts = await testDb.query('inventory_count');
      expect(counts, isEmpty);
    });
  });
}

Future<void> createIntegrityTestTables(Database db) async {
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
