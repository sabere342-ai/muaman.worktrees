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
    await createConsistencyTestTables(testDb);
    await DatabaseHelper.setTestDatabase(testDb);
  });

  tearDown(() async {
    await testDb.close();
  });

  /// Creates a Product whose [toMap] will produce consistent fields.
  /// [stock] sets both openingQuantity and currentQuantity (with all other
  /// counters at zero) so the equation holds.
  Product makeProduct({
    int id = 1,
    String name = 'Test Product',
    String barcode = 'TEST001',
    int stock = 10,
    int sold = 0,
    int returned = 0,
    int adjustment = 0,
    double costPrice = 50.0,
  }) {
    return Product(
      id: id,
      name: name,
      barcode: barcode,
      openingQuantity: stock,
      soldQuantity: sold,
      returnedQuantity: returned,
      currentQuantity: stock - sold + returned + adjustment,
      costPrice: costPrice,
      totalInventoryCost: (stock - sold + returned + adjustment) * costPrice,
      inventoryAdjustment: adjustment,
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

  // =================== UPDATE SALE — SAME PRODUCT ===================

  group('updateSale — same product', () {
    test('1: Increasing quantity updates stock correctly', () async {
      await testDb.insert(
          'products', makeProduct(stock: 10).toMap()..remove('id'));
      final saleId = await DatabaseHelper.instance
          .insertSaleAndDecrementStock(makeSale(quantity: 3));

      await DatabaseHelper.instance
          .updateSale(makeSale(id: saleId, quantity: 5));

      final products = await testDb.query('products');
      expect(products.length, 1);
      final p = Product.fromMap(products.first);
      expect(p.soldQuantity, 5);
      expect(p.currentQuantity, 5);
      verifyEquation(products.first);
    });

    test('2: Increasing quantity above available stock is rejected', () async {
      await testDb.insert(
          'products', makeProduct(stock: 5).toMap()..remove('id'));
      final saleId = await DatabaseHelper.instance
          .insertSaleAndDecrementStock(makeSale(quantity: 3));

      expect(
        () => DatabaseHelper.instance
            .updateSale(makeSale(id: saleId, quantity: 6)),
        throwsA(isA<InsufficientStockException>()),
      );

      final products = await testDb.query('products');
      final p = Product.fromMap(products.first);
      expect(p.soldQuantity, 3);
      expect(p.currentQuantity, 2);
      verifyEquation(products.first);

      final sales = await testDb.query('sales');
      expect(sales.first['quantity'], 3);
    });

    test('3: Decreasing quantity restores difference to stock', () async {
      await testDb.insert(
          'products', makeProduct(stock: 10).toMap()..remove('id'));
      final saleId = await DatabaseHelper.instance
          .insertSaleAndDecrementStock(makeSale(quantity: 5));

      await DatabaseHelper.instance
          .updateSale(makeSale(id: saleId, quantity: 2));

      final products = await testDb.query('products');
      final p = Product.fromMap(products.first);
      expect(p.soldQuantity, 2);
      expect(p.currentQuantity, 8);
      verifyEquation(products.first);
    });

    test('4: Keeping same quantity does not change stock', () async {
      await testDb.insert(
          'products', makeProduct(stock: 10).toMap()..remove('id'));
      final saleId = await DatabaseHelper.instance
          .insertSaleAndDecrementStock(makeSale(quantity: 3));

      await DatabaseHelper.instance
          .updateSale(makeSale(id: saleId, quantity: 3));

      final products = await testDb.query('products');
      final p = Product.fromMap(products.first);
      expect(p.soldQuantity, 3);
      expect(p.currentQuantity, 7);
      verifyEquation(products.first);
    });

    test('5: Changing price only does not affect stock', () async {
      await testDb.insert(
          'products', makeProduct(stock: 10).toMap()..remove('id'));
      final saleId = await DatabaseHelper.instance
          .insertSaleAndDecrementStock(makeSale(quantity: 3, salePrice: 100));

      await DatabaseHelper.instance
          .updateSale(makeSale(id: saleId, quantity: 3, salePrice: 150));

      final products = await testDb.query('products');
      final p = Product.fromMap(products.first);
      expect(p.soldQuantity, 3);
      expect(p.currentQuantity, 7);
      verifyEquation(products.first);

      final sales = await testDb.query('sales');
      expect((sales.first['salePrice'] as num).toDouble(), 150);
    });

    test('6: Saving same values twice does not cause stock drift', () async {
      await testDb.insert(
          'products', makeProduct(stock: 10).toMap()..remove('id'));
      final saleId = await DatabaseHelper.instance
          .insertSaleAndDecrementStock(makeSale(quantity: 3));

      await DatabaseHelper.instance
          .updateSale(makeSale(id: saleId, quantity: 5));
      final stockAfterFirstSave =
          Product.fromMap((await testDb.query('products')).first)
              .currentQuantity;

      await DatabaseHelper.instance
          .updateSale(makeSale(id: saleId, quantity: 5));
      final stockAfterSecondSave =
          Product.fromMap((await testDb.query('products')).first)
              .currentQuantity;

      expect(stockAfterSecondSave, stockAfterFirstSave);
      expect(stockAfterSecondSave, 5);
    });

    test('7: Zero quantity is rejected', () async {
      await testDb.insert('products', makeProduct().toMap()..remove('id'));
      final saleId = await DatabaseHelper.instance
          .insertSaleAndDecrementStock(makeSale(quantity: 3));

      expect(
        () => DatabaseHelper.instance
            .updateSale(makeSale(id: saleId, quantity: 0)),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('8: Negative quantity is rejected', () async {
      await testDb.insert('products', makeProduct().toMap()..remove('id'));
      final saleId = await DatabaseHelper.instance
          .insertSaleAndDecrementStock(makeSale(quantity: 3));

      expect(
        () => DatabaseHelper.instance
            .updateSale(makeSale(id: saleId, quantity: -1)),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('9: NaN price is rejected', () async {
      await testDb.insert('products', makeProduct().toMap()..remove('id'));
      final saleId = await DatabaseHelper.instance
          .insertSaleAndDecrementStock(makeSale(quantity: 3));

      expect(
        () => DatabaseHelper.instance.updateSale(Sale(
          id: saleId,
          date: DateTime(2026, 7, 28),
          productName: 'Test',
          barcode: 'TEST001',
          quantity: 3,
          salePrice: double.nan,
        )),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('10: Infinity price is rejected', () async {
      await testDb.insert('products', makeProduct().toMap()..remove('id'));
      final saleId = await DatabaseHelper.instance
          .insertSaleAndDecrementStock(makeSale(quantity: 3));

      expect(
        () => DatabaseHelper.instance.updateSale(Sale(
          id: saleId,
          date: DateTime(2026, 7, 28),
          productName: 'Test',
          barcode: 'TEST001',
          quantity: 3,
          salePrice: double.infinity,
        )),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('11: Zero price is rejected', () async {
      await testDb.insert('products', makeProduct().toMap()..remove('id'));
      final saleId = await DatabaseHelper.instance
          .insertSaleAndDecrementStock(makeSale(quantity: 3));

      expect(
        () => DatabaseHelper.instance
            .updateSale(makeSale(id: saleId, quantity: 3, salePrice: 0)),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('12: Negative price is rejected', () async {
      await testDb.insert('products', makeProduct().toMap()..remove('id'));
      final saleId = await DatabaseHelper.instance
          .insertSaleAndDecrementStock(makeSale(quantity: 3));

      expect(
        () => DatabaseHelper.instance
            .updateSale(makeSale(id: saleId, quantity: 3, salePrice: -10)),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('13: Failure does not change sale record', () async {
      await testDb.insert(
          'products', makeProduct(stock: 5).toMap()..remove('id'));
      final saleId = await DatabaseHelper.instance
          .insertSaleAndDecrementStock(makeSale(quantity: 3));

      expect(
        () => DatabaseHelper.instance
            .updateSale(makeSale(id: saleId, quantity: 6)),
        throwsA(isA<InsufficientStockException>()),
      );

      final sales = await testDb.query('sales');
      expect(sales.length, 1);
      expect(sales.first['quantity'], 3);
      expect(sales.first['barcode'], 'TEST001');
    });

    test('14: Failure does not change product stock', () async {
      await testDb.insert(
          'products', makeProduct(stock: 5).toMap()..remove('id'));
      final saleId = await DatabaseHelper.instance
          .insertSaleAndDecrementStock(makeSale(quantity: 3));

      expect(
        () => DatabaseHelper.instance
            .updateSale(makeSale(id: saleId, quantity: 6)),
        throwsA(isA<InsufficientStockException>()),
      );

      final products = await testDb.query('products');
      final p = Product.fromMap(products.first);
      expect(p.currentQuantity, 2);
      expect(p.soldQuantity, 3);
    });
  });

  // =================== UPDATE SALE — CHANGE PRODUCT ===================

  group('updateSale — change product', () {
    test('15: Changing from A to B restores old quantity to A', () async {
      await testDb.insert('products',
          makeProduct(id: 1, barcode: 'A001', stock: 10).toMap()..remove('id'));
      await testDb.insert('products',
          makeProduct(id: 2, barcode: 'B001', stock: 10).toMap()..remove('id'));
      final saleId = await DatabaseHelper.instance
          .insertSaleAndDecrementStock(makeSale(barcode: 'A001', quantity: 3));

      await DatabaseHelper.instance
          .updateSale(makeSale(id: saleId, barcode: 'B001', quantity: 2));

      final products = await testDb.query('products', orderBy: 'id ASC');
      expect(products.length, 2);
      final pA = Product.fromMap(products[0]);
      final pB = Product.fromMap(products[1]);
      expect(pA.currentQuantity, 10);
      expect(pA.soldQuantity, 0);
      expect(pB.currentQuantity, 8);
      expect(pB.soldQuantity, 2);
    });

    test('16: Insufficient stock in B causes full rollback', () async {
      await testDb.insert('products',
          makeProduct(id: 1, barcode: 'A001', stock: 10).toMap()..remove('id'));
      await testDb.insert('products',
          makeProduct(id: 2, barcode: 'B001', stock: 2).toMap()..remove('id'));
      final saleId = await DatabaseHelper.instance
          .insertSaleAndDecrementStock(makeSale(barcode: 'A001', quantity: 3));

      expect(
        () => DatabaseHelper.instance
            .updateSale(makeSale(id: saleId, barcode: 'B001', quantity: 5)),
        throwsA(isA<InsufficientStockException>()),
      );
    });

    test('17: After rollback stock of A is unchanged', () async {
      await testDb.insert('products',
          makeProduct(id: 1, barcode: 'A001', stock: 10).toMap()..remove('id'));
      await testDb.insert('products',
          makeProduct(id: 2, barcode: 'B001', stock: 2).toMap()..remove('id'));
      final saleId = await DatabaseHelper.instance
          .insertSaleAndDecrementStock(makeSale(barcode: 'A001', quantity: 3));

      expect(
        () => DatabaseHelper.instance
            .updateSale(makeSale(id: saleId, barcode: 'B001', quantity: 5)),
        throwsA(isA<InsufficientStockException>()),
      );

      final pA = Product.fromMap((await testDb
              .query('products', where: 'barcode = ?', whereArgs: ['A001']))
          .first);
      expect(pA.currentQuantity, 7);
    });

    test('18: After rollback stock of B is unchanged', () async {
      await testDb.insert('products',
          makeProduct(id: 1, barcode: 'A001', stock: 10).toMap()..remove('id'));
      await testDb.insert('products',
          makeProduct(id: 2, barcode: 'B001', stock: 2).toMap()..remove('id'));
      final saleId = await DatabaseHelper.instance
          .insertSaleAndDecrementStock(makeSale(barcode: 'A001', quantity: 3));

      expect(
        () => DatabaseHelper.instance
            .updateSale(makeSale(id: saleId, barcode: 'B001', quantity: 5)),
        throwsA(isA<InsufficientStockException>()),
      );

      final pB = Product.fromMap((await testDb
              .query('products', where: 'barcode = ?', whereArgs: ['B001']))
          .first);
      expect(pB.currentQuantity, 2);
    });

    test('19: After rollback sale still points to A', () async {
      await testDb.insert('products',
          makeProduct(id: 1, barcode: 'A001', stock: 10).toMap()..remove('id'));
      await testDb.insert('products',
          makeProduct(id: 2, barcode: 'B001', stock: 2).toMap()..remove('id'));
      final saleId = await DatabaseHelper.instance
          .insertSaleAndDecrementStock(makeSale(barcode: 'A001', quantity: 3));

      expect(
        () => DatabaseHelper.instance
            .updateSale(makeSale(id: saleId, barcode: 'B001', quantity: 5)),
        throwsA(isA<InsufficientStockException>()),
      );

      final sales = await testDb.query('sales');
      expect(sales.first['barcode'], 'A001');
    });

    test('20: Barcode with spaces is normalized per MUAMAN-07', () async {
      await testDb.insert('products',
          makeProduct(id: 1, barcode: 'A001', stock: 10).toMap()..remove('id'));
      final saleId = await DatabaseHelper.instance
          .insertSaleAndDecrementStock(makeSale(barcode: 'A001', quantity: 3));

      await DatabaseHelper.instance
          .updateSale(makeSale(id: saleId, barcode: '  A001  ', quantity: 5));

      final sales = await testDb.query('sales');
      expect(sales.first['barcode'], 'A001');

      final products = await testDb.query('products');
      final p = Product.fromMap(products.first);
      expect(p.currentQuantity, 5);
    });

    test(
        '21: Non-existent new product throws ProductReferenceIntegrityException',
        () async {
      await testDb.insert('products',
          makeProduct(id: 1, barcode: 'A001').toMap()..remove('id'));
      final saleId = await DatabaseHelper.instance
          .insertSaleAndDecrementStock(makeSale(barcode: 'A001', quantity: 3));

      expect(
        () => DatabaseHelper.instance
            .updateSale(makeSale(id: saleId, barcode: 'GHOST001', quantity: 3)),
        throwsA(isA<ProductReferenceIntegrityException>()),
      );
    });

    test('22: Non-existent old product rejection (no data repair)', () async {
      final saleId = await testDb.insert('sales', {
        'date': '2026-07-28T00:00:00.000',
        'productName': 'Ghost',
        'barcode': 'GHOST001',
        'quantity': 3,
        'salePrice': 100.0,
        'totalSaleValue': 300.0,
        'costPrice': 50.0,
        'cogs': 150.0,
      });

      await testDb.insert('products',
          makeProduct(id: 1, barcode: 'B001').toMap()..remove('id'));

      expect(
        () => DatabaseHelper.instance
            .updateSale(makeSale(id: saleId, barcode: 'B001', quantity: 3)),
        throwsA(isA<ProductReferenceIntegrityException>()),
      );

      final sales = await testDb.query('sales');
      expect(sales.first['barcode'], 'GHOST001');
    });
  });

  // =================== UPDATE SALE — RECORD ===================

  group('updateSale — record and transaction', () {
    test('23: Non-existent sale id is rejected', () async {
      expect(
        () => DatabaseHelper.instance
            .updateSale(makeSale(id: 999, barcode: 'TEST001', quantity: 3)),
        throwsA(isA<StateError>()),
      );
    });

    test('24: UPDATE affects exactly one row', () async {
      await testDb.insert(
          'products', makeProduct(stock: 10).toMap()..remove('id'));
      final saleId = await DatabaseHelper.instance
          .insertSaleAndDecrementStock(makeSale(quantity: 3));

      await DatabaseHelper.instance
          .updateSale(makeSale(id: saleId, quantity: 5));

      final sales = await testDb.query('sales');
      expect(sales.length, 1);
      expect(sales.first['quantity'], 5);
    });

    test('25: Stored financial values are consistent with qty and price',
        () async {
      await testDb.insert(
          'products', makeProduct(costPrice: 50).toMap()..remove('id'));
      final saleId = await DatabaseHelper.instance.insertSaleAndDecrementStock(
          makeSale(quantity: 3, salePrice: 100, costPrice: 50));

      await DatabaseHelper.instance.updateSale(
          makeSale(id: saleId, quantity: 5, salePrice: 120, costPrice: 50));

      final sales = await testDb.query('sales');
      final s = sales.first;
      expect((s['totalSaleValue'] as num).toDouble(), 5 * 120);
      expect((s['cogs'] as num).toDouble(), 5 * 50);
    });

    test('26: No partial write if stock check fails after reversal', () async {
      await testDb.insert('products',
          makeProduct(id: 1, barcode: 'A001', stock: 5).toMap()..remove('id'));
      final saleId = await DatabaseHelper.instance
          .insertSaleAndDecrementStock(makeSale(barcode: 'A001', quantity: 3));

      expect(
        () => DatabaseHelper.instance
            .updateSale(makeSale(id: saleId, barcode: 'A001', quantity: 6)),
        throwsA(isA<InsufficientStockException>()),
      );

      final sales = await testDb.query('sales');
      expect(sales.first['quantity'], 3);
    });

    test('27: Transaction atomicity — stock update commits only on success',
        () async {
      await testDb.insert(
          'products', makeProduct(stock: 10).toMap()..remove('id'));
      final saleId = await DatabaseHelper.instance
          .insertSaleAndDecrementStock(makeSale(quantity: 3));

      await DatabaseHelper.instance
          .updateSale(makeSale(id: saleId, quantity: 5));

      final products = await testDb.query('products');
      final p = Product.fromMap(products.first);
      expect(p.currentQuantity, 5);
    });

    test('28: InsufficientStockException has correct fields', () async {
      await testDb.insert(
          'products', makeProduct(stock: 5).toMap()..remove('id'));
      final saleId = await DatabaseHelper.instance
          .insertSaleAndDecrementStock(makeSale(quantity: 3));

      try {
        await DatabaseHelper.instance
            .updateSale(makeSale(id: saleId, quantity: 6));
        fail('Expected InsufficientStockException');
      } on InsufficientStockException catch (e) {
        expect(e.message, 'الكمية المطلوبة غير متوفرة في المخزون');
        expect(e.availableQuantity, 2);
        expect(e.requestedQuantity, 3);
      }
    });
  });

  // =================== UPDATE RETURN — SAME PRODUCT ===================

  group('updateReturn — same product', () {
    test('29: Increasing return quantity increases stock correctly', () async {
      await testDb.insert(
          'products', makeProduct(stock: 10).toMap()..remove('id'));
      final returnId =
          await DatabaseHelper.instance.insertReturn(makeReturn(quantity: 2));

      await DatabaseHelper.instance
          .updateReturn(makeReturn(id: returnId, quantity: 5));

      final products = await testDb.query('products');
      final p = Product.fromMap(products.first);
      expect(p.returnedQuantity, 5);
      expect(p.currentQuantity, 15);
      verifyEquation(products.first);
    });

    test('30: Decreasing return quantity deducts correctly if possible',
        () async {
      await testDb.insert(
          'products', makeProduct(stock: 10).toMap()..remove('id'));
      final returnId =
          await DatabaseHelper.instance.insertReturn(makeReturn(quantity: 5));

      await DatabaseHelper.instance
          .updateReturn(makeReturn(id: returnId, quantity: 2));

      final products = await testDb.query('products');
      final p = Product.fromMap(products.first);
      expect(p.returnedQuantity, 2);
      expect(p.currentQuantity, 12);
      verifyEquation(products.first);
    });

    test('31: Keeping same quantity does not change stock', () async {
      await testDb.insert(
          'products', makeProduct(stock: 10).toMap()..remove('id'));
      final returnId =
          await DatabaseHelper.instance.insertReturn(makeReturn(quantity: 2));

      await DatabaseHelper.instance
          .updateReturn(makeReturn(id: returnId, quantity: 2));

      final products = await testDb.query('products');
      final p = Product.fromMap(products.first);
      expect(p.returnedQuantity, 2);
      expect(p.currentQuantity, 12);
      verifyEquation(products.first);
    });

    test('32: Changing price only does not affect stock', () async {
      await testDb.insert(
          'products', makeProduct(stock: 10).toMap()..remove('id'));
      final returnId = await DatabaseHelper.instance
          .insertReturn(makeReturn(quantity: 2, salePrice: 100));

      await DatabaseHelper.instance
          .updateReturn(makeReturn(id: returnId, quantity: 2, salePrice: 150));

      final products = await testDb.query('products');
      final p = Product.fromMap(products.first);
      expect(p.currentQuantity, 12);
      verifyEquation(products.first);

      final returns = await testDb.query('returns');
      expect((returns.first['salePrice'] as num).toDouble(), 150);
    });

    test('33: Saving same values twice does not cause stock drift', () async {
      await testDb.insert(
          'products', makeProduct(stock: 10).toMap()..remove('id'));
      final returnId =
          await DatabaseHelper.instance.insertReturn(makeReturn(quantity: 2));

      await DatabaseHelper.instance
          .updateReturn(makeReturn(id: returnId, quantity: 5));
      final stockAfterFirst =
          Product.fromMap((await testDb.query('products')).first)
              .currentQuantity;

      await DatabaseHelper.instance
          .updateReturn(makeReturn(id: returnId, quantity: 5));
      final stockAfterSecond =
          Product.fromMap((await testDb.query('products')).first)
              .currentQuantity;

      expect(stockAfterSecond, stockAfterFirst);
      expect(stockAfterSecond, 15);
    });

    test('34: Zero quantity is rejected', () async {
      await testDb.insert('products', makeProduct().toMap()..remove('id'));
      final returnId =
          await DatabaseHelper.instance.insertReturn(makeReturn(quantity: 2));

      expect(
        () => DatabaseHelper.instance
            .updateReturn(makeReturn(id: returnId, quantity: 0)),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('35: Negative quantity is rejected', () async {
      await testDb.insert('products', makeProduct().toMap()..remove('id'));
      final returnId =
          await DatabaseHelper.instance.insertReturn(makeReturn(quantity: 2));

      expect(
        () => DatabaseHelper.instance
            .updateReturn(makeReturn(id: returnId, quantity: -1)),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('36: Zero price is rejected', () async {
      await testDb.insert('products', makeProduct().toMap()..remove('id'));
      final returnId =
          await DatabaseHelper.instance.insertReturn(makeReturn(quantity: 2));

      expect(
        () => DatabaseHelper.instance
            .updateReturn(makeReturn(id: returnId, quantity: 2, salePrice: 0)),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  // =================== UPDATE RETURN — REVERSAL CONFLICT ===================

  group('updateReturn — reversal conflict', () {
    test('37: Return update succeeds when stock allows reversal', () async {
      await testDb.insert(
          'products', makeProduct(stock: 5).toMap()..remove('id'));
      final returnId =
          await DatabaseHelper.instance.insertReturn(makeReturn(quantity: 3));

      await DatabaseHelper.instance
          .updateReturn(makeReturn(id: returnId, quantity: 1));

      final products = await testDb.query('products');
      final p = Product.fromMap(products.first);
      expect(p.currentQuantity, 6);
    });

    test('38: Return update is rejected if reversal would make stock negative',
        () async {
      await testDb.insert(
          'products', makeProduct(stock: 0).toMap()..remove('id'));
      final returnId =
          await DatabaseHelper.instance.insertReturn(makeReturn(quantity: 5));

      await DatabaseHelper.instance.insertSaleAndDecrementStock(
          makeSale(barcode: 'TEST001', quantity: 3));

      expect(
        () => DatabaseHelper.instance
            .updateReturn(makeReturn(id: returnId, quantity: 2)),
        throwsA(isA<ReturnStockReversalException>()),
      );
    });

    test('39: Rejected reversal does not change product stock', () async {
      await testDb.insert(
          'products', makeProduct(stock: 0).toMap()..remove('id'));
      final returnId =
          await DatabaseHelper.instance.insertReturn(makeReturn(quantity: 5));

      await DatabaseHelper.instance.insertSaleAndDecrementStock(
          makeSale(barcode: 'TEST001', quantity: 3));

      expect(
        () => DatabaseHelper.instance
            .updateReturn(makeReturn(id: returnId, quantity: 2)),
        throwsA(isA<ReturnStockReversalException>()),
      );

      final products = await testDb.query('products');
      final p = Product.fromMap(products.first);
      expect(p.currentQuantity, 2);
    });

    test('40: Rejected reversal does not change return record', () async {
      await testDb.insert(
          'products', makeProduct(stock: 0).toMap()..remove('id'));
      final returnId =
          await DatabaseHelper.instance.insertReturn(makeReturn(quantity: 5));

      await DatabaseHelper.instance.insertSaleAndDecrementStock(
          makeSale(barcode: 'TEST001', quantity: 3));

      expect(
        () => DatabaseHelper.instance
            .updateReturn(makeReturn(id: returnId, quantity: 2)),
        throwsA(isA<ReturnStockReversalException>()),
      );

      final returns = await testDb.query('returns');
      expect(returns.first['quantity'], 5);
    });

    test('41: Rejected reversal does not change financial value', () async {
      await testDb.insert(
          'products', makeProduct(stock: 0).toMap()..remove('id'));
      final returnId = await DatabaseHelper.instance
          .insertReturn(makeReturn(quantity: 5, salePrice: 100));

      await DatabaseHelper.instance.insertSaleAndDecrementStock(
          makeSale(barcode: 'TEST001', quantity: 3));

      expect(
        () => DatabaseHelper.instance.updateReturn(
            makeReturn(id: returnId, quantity: 2, salePrice: 200)),
        throwsA(isA<ReturnStockReversalException>()),
      );

      final returns = await testDb.query('returns');
      expect((returns.first['totalReturnValue'] as num).toDouble(), 500);
    });

    test('42: Correct exception is thrown for reversal conflict', () async {
      await testDb.insert(
          'products', makeProduct(stock: 0).toMap()..remove('id'));
      final returnId =
          await DatabaseHelper.instance.insertReturn(makeReturn(quantity: 5));

      await DatabaseHelper.instance.insertSaleAndDecrementStock(
          makeSale(barcode: 'TEST001', quantity: 3));

      try {
        await DatabaseHelper.instance
            .updateReturn(makeReturn(id: returnId, quantity: 2));
        fail('Expected ReturnStockReversalException');
      } on ReturnStockReversalException catch (e) {
        expect(e.returnId, returnId);
        expect(e.currentStock, 2);
        expect(e.requiredReversalQuantity, 5);
      }
    });
  });

  // =================== UPDATE RETURN — CHANGE PRODUCT ===================

  group('updateReturn — change product', () {
    test('43: Changing from A to B removes old return effect from A', () async {
      await testDb.insert('products',
          makeProduct(id: 1, barcode: 'A001', stock: 10).toMap()..remove('id'));
      await testDb.insert('products',
          makeProduct(id: 2, barcode: 'B001', stock: 10).toMap()..remove('id'));
      final returnId = await DatabaseHelper.instance
          .insertReturn(makeReturn(barcode: 'A001', quantity: 3));

      await DatabaseHelper.instance
          .updateReturn(makeReturn(id: returnId, barcode: 'B001', quantity: 2));

      final pA = Product.fromMap((await testDb
              .query('products', where: 'barcode = ?', whereArgs: ['A001']))
          .first);
      expect(pA.currentQuantity, 10);
      expect(pA.returnedQuantity, 0);
    });

    test('44: Changing from A to B adds new return effect to B', () async {
      await testDb.insert('products',
          makeProduct(id: 1, barcode: 'A001', stock: 10).toMap()..remove('id'));
      await testDb.insert('products',
          makeProduct(id: 2, barcode: 'B001', stock: 5).toMap()..remove('id'));
      final returnId = await DatabaseHelper.instance
          .insertReturn(makeReturn(barcode: 'A001', quantity: 3));

      await DatabaseHelper.instance
          .updateReturn(makeReturn(id: returnId, barcode: 'B001', quantity: 2));

      final pB = Product.fromMap((await testDb
              .query('products', where: 'barcode = ?', whereArgs: ['B001']))
          .first);
      expect(pB.currentQuantity, 7);
      expect(pB.returnedQuantity, 2);
    });

    test('45: If old return cannot be reversed, full rollback occurs',
        () async {
      await testDb.insert('products',
          makeProduct(id: 1, barcode: 'A001', stock: 0).toMap()..remove('id'));
      await testDb.insert('products',
          makeProduct(id: 2, barcode: 'B001', stock: 10).toMap()..remove('id'));
      final returnId = await DatabaseHelper.instance
          .insertReturn(makeReturn(barcode: 'A001', quantity: 5));

      await DatabaseHelper.instance
          .insertSaleAndDecrementStock(makeSale(barcode: 'A001', quantity: 3));

      expect(
        () => DatabaseHelper.instance.updateReturn(
            makeReturn(id: returnId, barcode: 'B001', quantity: 2)),
        throwsA(isA<ReturnStockReversalException>()),
      );
    });

    test('46: After rollback return stock of A is unchanged', () async {
      await testDb.insert('products',
          makeProduct(id: 1, barcode: 'A001', stock: 0).toMap()..remove('id'));
      await testDb.insert('products',
          makeProduct(id: 2, barcode: 'B001', stock: 10).toMap()..remove('id'));
      final returnId = await DatabaseHelper.instance
          .insertReturn(makeReturn(barcode: 'A001', quantity: 5));

      await DatabaseHelper.instance
          .insertSaleAndDecrementStock(makeSale(barcode: 'A001', quantity: 3));

      expect(
        () => DatabaseHelper.instance.updateReturn(
            makeReturn(id: returnId, barcode: 'B001', quantity: 2)),
        throwsA(isA<ReturnStockReversalException>()),
      );

      final pA = Product.fromMap((await testDb
              .query('products', where: 'barcode = ?', whereArgs: ['A001']))
          .first);
      expect(pA.currentQuantity, 2);
    });

    test('47: After rollback stock of B is unchanged', () async {
      await testDb.insert('products',
          makeProduct(id: 1, barcode: 'A001', stock: 0).toMap()..remove('id'));
      await testDb.insert('products',
          makeProduct(id: 2, barcode: 'B001', stock: 10).toMap()..remove('id'));
      final returnId = await DatabaseHelper.instance
          .insertReturn(makeReturn(barcode: 'A001', quantity: 5));

      await DatabaseHelper.instance
          .insertSaleAndDecrementStock(makeSale(barcode: 'A001', quantity: 3));

      expect(
        () => DatabaseHelper.instance.updateReturn(
            makeReturn(id: returnId, barcode: 'B001', quantity: 2)),
        throwsA(isA<ReturnStockReversalException>()),
      );

      final pB = Product.fromMap((await testDb
              .query('products', where: 'barcode = ?', whereArgs: ['B001']))
          .first);
      expect(pB.currentQuantity, 10);
    });

    test('48: After rollback return still points to A', () async {
      await testDb.insert('products',
          makeProduct(id: 1, barcode: 'A001', stock: 0).toMap()..remove('id'));
      await testDb.insert('products',
          makeProduct(id: 2, barcode: 'B001', stock: 10).toMap()..remove('id'));
      final returnId = await DatabaseHelper.instance
          .insertReturn(makeReturn(barcode: 'A001', quantity: 5));

      await DatabaseHelper.instance
          .insertSaleAndDecrementStock(makeSale(barcode: 'A001', quantity: 3));

      expect(
        () => DatabaseHelper.instance.updateReturn(
            makeReturn(id: returnId, barcode: 'B001', quantity: 2)),
        throwsA(isA<ReturnStockReversalException>()),
      );

      final returns = await testDb.query('returns');
      expect(returns.first['barcode'], 'A001');
    });

    test(
        '49: Non-existent new product throws ProductReferenceIntegrityException',
        () async {
      await testDb.insert('products',
          makeProduct(id: 1, barcode: 'A001').toMap()..remove('id'));
      final returnId = await DatabaseHelper.instance
          .insertReturn(makeReturn(barcode: 'A001', quantity: 2));

      expect(
        () => DatabaseHelper.instance.updateReturn(
            makeReturn(id: returnId, barcode: 'GHOST001', quantity: 2)),
        throwsA(isA<ProductReferenceIntegrityException>()),
      );
    });

    test('50: Non-existent old product rejection (no data repair)', () async {
      final returnId = await testDb.insert('returns', {
        'date': '2026-07-28T00:00:00.000',
        'productName': 'Ghost',
        'barcode': 'GHOST001',
        'quantity': 2,
        'salePrice': 100.0,
        'totalReturnValue': 200.0,
        'costPrice': 50.0,
        'returnedCogs': 100.0,
      });

      await testDb.insert('products',
          makeProduct(id: 1, barcode: 'B001').toMap()..remove('id'));

      expect(
        () => DatabaseHelper.instance.updateReturn(
            makeReturn(id: returnId, barcode: 'B001', quantity: 2)),
        throwsA(isA<ProductReferenceIntegrityException>()),
      );

      final returns = await testDb.query('returns');
      expect(returns.first['barcode'], 'GHOST001');
    });
  });

  // =================== UPDATE RETURN — RECORD ===================

  group('updateReturn — record', () {
    test('51: Non-existent return id is rejected', () async {
      expect(
        () => DatabaseHelper.instance
            .updateReturn(makeReturn(id: 999, barcode: 'TEST001', quantity: 2)),
        throwsA(isA<StateError>()),
      );
    });

    test('52: UPDATE affects exactly one row', () async {
      await testDb.insert('products', makeProduct().toMap()..remove('id'));
      final returnId =
          await DatabaseHelper.instance.insertReturn(makeReturn(quantity: 2));

      await DatabaseHelper.instance
          .updateReturn(makeReturn(id: returnId, quantity: 3));

      final returns = await testDb.query('returns');
      expect(returns.length, 1);
      expect(returns.first['quantity'], 3);
    });

    test('53: Stored financial values remain consistent', () async {
      await testDb.insert(
          'products', makeProduct(costPrice: 50).toMap()..remove('id'));
      final returnId = await DatabaseHelper.instance
          .insertReturn(makeReturn(quantity: 2, salePrice: 100, costPrice: 50));

      await DatabaseHelper.instance.updateReturn(
          makeReturn(id: returnId, quantity: 3, salePrice: 120, costPrice: 50));

      final returns = await testDb.query('returns');
      final r = returns.first;
      expect((r['totalReturnValue'] as num).toDouble(), 3 * 120);
      expect((r['returnedCogs'] as num).toDouble(), 3 * 50);
    });

    test('54: All steps inside single transaction', () async {
      await testDb.insert(
          'products', makeProduct(stock: 10).toMap()..remove('id'));
      final returnId =
          await DatabaseHelper.instance.insertReturn(makeReturn(quantity: 2));
      final stockBefore =
          Product.fromMap((await testDb.query('products')).first)
              .currentQuantity;

      await DatabaseHelper.instance
          .updateReturn(makeReturn(id: returnId, quantity: 5));
      final stockAfter = Product.fromMap((await testDb.query('products')).first)
          .currentQuantity;
      expect(stockAfter, stockBefore - 2 + 5);
      expect(stockAfter, 15);
    });
  });
}

Future<void> createConsistencyTestTables(Database db) async {
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
    CREATE TABLE IF NOT EXISTS inventory_count (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      productId INTEGER NOT NULL,
      actualQuantity INTEGER DEFAULT 0,
      notes TEXT DEFAULT '',
      countDate TEXT NOT NULL
    )
  ''');
}
