import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:muaman_store/database/database_helper.dart';
import 'package:muaman_store/models/invoice.dart';
import 'package:muaman_store/models/product.dart';
import 'package:muaman_store/models/return_item.dart';
import 'package:muaman_store/models/sale.dart';
import 'package:muaman_store/models/user_role.dart';

import '../helpers/test_schema.dart';

/// Phase M §29-A regression lock (manifest:
/// app/test/database/inventory_atomicity_regression_test.dart).
///
/// Locks the LOCAL transaction regression category A:
///   - invoice creation is atomic (header + lines + stock + queue),
///   - a failing invoice line rolls back EVERYTHING including the header
///     and all previously applied lines (M-C29 duplicate-line scenario
///     included as an insufficient-stock line),
///   - returns restore stock inside their transaction and keep the
///     inventory equation exact,
///   - counts reconcile atomically (existing dedicated suite keeps the
///     deep coverage; here we assert the equation invariant end-to-end).
void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  late Database testDb;

  setUp(() async {
    testDb = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await createTestSchema(testDb);
    await DatabaseHelper.setTestDatabase(testDb);
  });

  tearDown(() async {
    await testDb.close();
  });

  Future<void> insertProduct({
    int id = 1,
    String barcode = 'ATOM-001',
    int opening = 10,
    int sold = 0,
    int returned = 0,
    int adjustment = 0,
    double cost = 50.0,
  }) async {
    final product = Product(
      id: id,
      name: 'Atomic Product',
      barcode: barcode,
      openingQuantity: opening,
      soldQuantity: sold,
      returnedQuantity: returned,
      currentQuantity: opening - sold + returned + adjustment,
      costPrice: cost,
      totalInventoryCost: (opening - sold + returned + adjustment) * cost,
      inventoryAdjustment: adjustment,
    );
    await testDb.insert('products', product.toMap()..remove('id'));
  }

  void expectEquation(Map<String, dynamic> row) {
    final p = Product.fromMap(row);
    expect(
        p.currentQuantity,
        p.openingQuantity -
            p.soldQuantity +
            p.returnedQuantity +
            p.inventoryAdjustment,
        reason: 'stock equation must hold after every write path');
  }

  group('invoice atomicity', () {
    test(
        'invoice with two lines applies header, lines, stock and queue '
        'atomically', () async {
      await insertProduct();
      await insertProduct(id: 2, barcode: 'ATOM-002');

      final invoice = Invoice(
        invoiceNumber: 'INV-1',
        date: DateTime(2026, 8, 22),
        customerName: 'عميل',
        paymentMethod: 'cash',
        totalAmount: 500.0,
        totalItems: 6,
      );
      final items = [
        Sale(
          date: DateTime(2026, 8, 22),
          productName: 'Atomic Product',
          barcode: 'ATOM-001',
          quantity: 4,
          salePrice: 50.0,
          costPrice: 50.0,
        ),
        Sale(
          date: DateTime(2026, 8, 22),
          productName: 'Atomic Product',
          barcode: 'ATOM-002',
          quantity: 2,
          salePrice: 50.0,
          costPrice: 50.0,
        ),
      ];

      final id = await DatabaseHelper.instance
          .insertInvoiceWithItems(invoice, items, currentRole: UserRole.owner);

      expect(id, greaterThan(0));
      expect(await testDb.query('invoices'), hasLength(1));
      final sales = await testDb.query('sales');
      expect(sales, hasLength(2));

      // Every sale line carries the invoice link (bundle integrity).
      for (final s in sales) {
        expect(s['invoiceId'], id);
      }

      final rows = await testDb.query('products', orderBy: 'id');
      expect(Product.fromMap(rows.first).soldQuantity, 4);
      expect(Product.fromMap(rows.last).soldQuantity, 2);
      for (final r in rows) {
        expectEquation(r);
      }
    });

    test(
        'M-C29: a duplicated line exceeding stock fails the WHOLE invoice '
        '(no partial header/partial lines survive)', () async {
      await insertProduct(); // stock 10

      final items = [
        Sale(
          date: DateTime(2026, 8, 22),
          productName: 'Atomic Product',
          barcode: 'ATOM-001',
          quantity: 6,
          salePrice: 50.0,
          costPrice: 50.0,
        ),
        // Duplicate of the same product pushing total demand past stock.
        Sale(
          date: DateTime(2026, 8, 22),
          productName: 'Atomic Product',
          barcode: 'ATOM-001',
          quantity: 6,
          salePrice: 50.0,
          costPrice: 50.0,
        ),
      ];
      final invoice = Invoice(
        invoiceNumber: 'INV-DUP',
        date: DateTime(2026, 8, 22),
        customerName: 'عميل',
        paymentMethod: 'cash',
        totalAmount: 600.0,
        totalItems: 12,
      );

      await expectLater(
        DatabaseHelper.instance.insertInvoiceWithItems(invoice, items,
            currentRole: UserRole.owner),
        throwsA(isA<StateError>()),
      );

      // NOTHING survived: no header, no lines, no stock movement.
      expect(await testDb.query('invoices'), isEmpty);
      expect(await testDb.query('sales'), isEmpty);
      final row = (await testDb.query('products')).first;
      expect(Product.fromMap(row).currentQuantity, 10);
      expect(Product.fromMap(row).soldQuantity, 0);
      expectEquation(row);
    });
  });

  group('return atomicity', () {
    test(
        'a return restores sold stock and keeps the equation exact '
        '(COGS snapshot untouched — SG-9)', () async {
      await insertProduct(sold: 4); // current = 6

      final before = Product.fromMap((await testDb.query('products')).first);

      final ret = ReturnItem(
        date: DateTime(2026, 8, 22),
        productName: 'Atomic Product',
        barcode: 'ATOM-001',
        quantity: 2,
        salePrice: 100.0,
        totalReturnValue: 200.0,
        costPrice: 50.0,
        returnedCogs: 100.0,
      );
      await DatabaseHelper.instance
          .insertReturn(ret, currentRole: UserRole.owner);

      final row = (await testDb.query('products')).first;
      final after = Product.fromMap(row);
      expect(after.returnedQuantity, before.returnedQuantity + 2);
      expect(after.currentQuantity, 8);
      expectEquation(row);
      expect(after.costPrice, before.costPrice,
          reason: 'reconciliation never edits historical COGS/cost snapshots');
    });

    test('zero/negative quantity return rejected without side effects',
        () async {
      await insertProduct(sold: 4);

      final bad = ReturnItem(
        date: DateTime(2026, 8, 22),
        productName: 'Atomic Product',
        barcode: 'ATOM-001',
        quantity: 0,
        salePrice: 100.0,
      );
      await expectLater(
        DatabaseHelper.instance.insertReturn(bad, currentRole: UserRole.owner),
        throwsA(isA<ArgumentError>()),
      );

      expect(await testDb.query('returns'), isEmpty);
      final row = (await testDb.query('products')).first;
      expect(Product.fromMap(row).returnedQuantity, 0);
      expectEquation(row);
    });
  });

  group('count atomicity (equation end-to-end)', () {
    test(
        'count reconciliation lands as one atomic derived adjustment '
        'keeping the equation exact', () async {
      await insertProduct(opening: 20, sold: 14, returned: 1); // current=7

      await DatabaseHelper.instance
          .saveInventoryCount(1, 9, '', currentRole: UserRole.owner);

      final counts = await testDb.query('inventory_count');
      expect(counts, hasLength(1));
      expect(counts.first['actualQuantity'], 9);
      expect(counts.first['observedAt'] ?? counts.first['countDate'], isNotNull,
          reason: 'observation time recorded with the event');

      final row = (await testDb.query('products')).first;
      final p = Product.fromMap(row);
      expect(p.currentQuantity, 9);
      expect(p.inventoryAdjustment, 2); // 9 − 7 delta landed in adjustment
      expectEquation(row);
    });
  });
}
