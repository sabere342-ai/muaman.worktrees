import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:muaman_store/database/database_helper.dart';
import 'package:muaman_store/screens/sales/invoice_screen.dart';

import '../helpers/test_schema.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfiNoIsolate;

  late Database testDb;

  setUp(() async {
    testDb =
        await databaseFactoryFfiNoIsolate.openDatabase(inMemoryDatabasePath);
    await createTestSchema(testDb);
    DatabaseHelper.setTestDatabase(testDb);

    await testDb.insert('products', {
      'name': 'منتج اختبار',
      'barcode': 'TEST-BAR-001',
      'openingQuantity': 10,
      'currentQuantity': 10,
      'costPrice': 50,
      'totalInventoryCost': 500,
      'inventoryAdjustment': 0,
    });
  });

  tearDown(() async {
    await testDb.close();
  });

  Future<void> openInvoice(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const InvoiceScreen()),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Finder priceField() => find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == 'سعر البيع',
      );

  Future<void> addProductToCart(WidgetTester tester) async {
    await tester.tap(find.text('منتج اختبار'));
    await tester.pump();
  }

  testWidgets('sell price starts empty when product is added to invoice',
      (WidgetTester tester) async {
    await openInvoice(tester);
    await addProductToCart(tester);

    expect(priceField(), findsOneWidget);
    final field = tester.widget<TextField>(priceField());
    expect(field.controller?.text, isEmpty);
  });

  testWidgets('item total is not shown before a valid price is entered',
      (WidgetTester tester) async {
    await openInvoice(tester);
    await addProductToCart(tester);

    expect(find.textContaining('إجمالي العنصر'), findsNothing);
  });

  testWidgets('item total appears correctly after valid price and quantity',
      (WidgetTester tester) async {
    await openInvoice(tester);
    await addProductToCart(tester);

    await tester.enterText(priceField(), '120');
    await tester.pump();

    expect(find.text('إجمالي العنصر: 120 ج.م'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add_circle_outline));
    await tester.pump();

    expect(find.text('إجمالي العنصر: 240 ج.م'), findsOneWidget);
  });

  testWidgets('sale is rejected when sell price is empty',
      (WidgetTester tester) async {
    await openInvoice(tester);
    await addProductToCart(tester);

    await tester.tap(find.text('حفظ الفاتورة'));
    await tester.pump();

    expect(find.textContaining('سعر البيع غير صالح'), findsOneWidget);

    final invoices = await testDb.query('invoices');
    final sales = await testDb.query('sales');
    expect(invoices, isEmpty);
    expect(sales, isEmpty);
  });

  testWidgets('sale is rejected when sell price is zero',
      (WidgetTester tester) async {
    await openInvoice(tester);
    await addProductToCart(tester);

    await tester.enterText(priceField(), '0');
    await tester.pump();

    await tester.tap(find.text('حفظ الفاتورة'));
    await tester.pump();

    expect(find.textContaining('سعر البيع غير صالح'), findsOneWidget);

    final invoices = await testDb.query('invoices');
    final sales = await testDb.query('sales');
    expect(invoices, isEmpty);
    expect(sales, isEmpty);
  });

  testWidgets('sale is rejected when sell price is not a valid number',
      (WidgetTester tester) async {
    await openInvoice(tester);
    await addProductToCart(tester);

    await tester.enterText(priceField(), 'abc');
    await tester.pump();

    await tester.tap(find.text('حفظ الفاتورة'));
    await tester.pump();

    expect(find.textContaining('سعر البيع غير صالح'), findsOneWidget);

    final sales = await testDb.query('sales');
    expect(sales, isEmpty);
  });

  testWidgets('sale is saved with correct values when price is valid',
      (WidgetTester tester) async {
    await openInvoice(tester);
    await addProductToCart(tester);

    await tester.enterText(priceField(), '150');
    await tester.pump();

    await tester.tap(find.text('حفظ الفاتورة'));
    await tester.pumpAndSettle();

    final sales = await testDb.query('sales');
    expect(sales.length, 1);
    expect(sales.first['salePrice'], 150.0);
    expect(sales.first['quantity'], 1);

    final invoices = await testDb.query('invoices');
    expect(invoices.length, 1);
    expect(invoices.first['totalAmount'], 150.0);
  });
}
