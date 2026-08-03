import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:muaman_store/database/database_helper.dart';
import 'package:muaman_store/database/user_repository.dart';
import 'package:muaman_store/models/user_role.dart';
import 'package:muaman_store/main.dart' as app;

/// Pumps frames until [condition] becomes true (or a real-time timeout).
Future<void> pumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 90),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (condition()) return;
  }
  fail('Timed out waiting for condition');
}

Finder fieldWithLabel(String label) => find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.labelText == label,
    );

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'live smoke: login, empty-price invoice rejected, valid invoice saved',
      (tester) async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    // Reset the runtime DB to a known state (schema recreated on open).
    final dbPath = p.join(await getDatabasesPath(), 'muaman_store.db');
    for (final suffix in ['', '-journal', '-wal', '-shm']) {
      final f = File('$dbPath$suffix');
      if (f.existsSync()) f.deleteSync();
    }

    await DatabaseHelper.instance.database;
    await UserRepository().createUser(
      displayName: 'المالك',
      username: 'owner',
      password: 'secret123',
      role: UserRole.owner,
    );

    app.main();
    await pumpUntil(
        tester, () => find.text('تسجيل الدخول').evaluate().isNotEmpty);

    await tester.enterText(find.byType(TextField).at(0), 'owner');
    await tester.pump();
    await tester.enterText(find.byType(TextField).at(1), 'secret123');
    await tester.pump();
    await tester.tap(find.widgetWithText(ElevatedButton, 'تسجيل الدخول'));

    // Wait for the dashboard to finish loading (app shell is then ready).
    await pumpUntil(
        tester, () => find.text('الملخص المالي').evaluate().isNotEmpty);

    // Open the sales screen and create a new invoice.
    await tester.tap(find.text('المبيعات'));
    await pumpUntil(
        tester, () => find.text('فاتورة جديدة').evaluate().isNotEmpty);
    await tester.tap(find.text('فاتورة جديدة'));

    // Wait for the invoice screen to finish loading its products.
    final search = find.byWidgetPredicate((w) =>
        w is TextField &&
        w.decoration?.hintText == 'ابحث عن صنف بالاسم أو الباركود');
    await pumpUntil(tester, () => search.evaluate().isNotEmpty);

    // Filter to a single product that still has stock, then add it to cart.
    await tester.enterText(search, '2سوستة');
    await tester.pump();
    await pumpUntil(
        tester, () => find.text('تي شيرت 2سوستة تركي').evaluate().isNotEmpty);
    await tester.tap(find.text('تي شيرت 2سوستة تركي'));
    await tester.pump();

    // The sell price must start empty and no item total may be shown.
    expect(fieldWithLabel('سعر البيع'), findsOneWidget);
    final priceField = tester.widget<TextField>(fieldWithLabel('سعر البيع'));
    expect(priceField.controller?.text, isEmpty);
    expect(find.textContaining('إجمالي العنصر'), findsNothing);

    final db = await DatabaseHelper.instance.database;
    final invoicesBefore = (await db.query('invoices')).length;
    final salesBefore = (await db.query('sales')).length;
    final prodBefore = (await db.query('products',
            where: 'barcode = ?', whereArgs: ['2000000000001']))
        .first;

    // Saving with an empty price must be rejected with no DB writes.
    await tester.tap(find.text('حفظ الفاتورة'));
    await pumpUntil(tester,
        () => find.textContaining('سعر البيع غير صالح').evaluate().isNotEmpty);
    expect((await db.query('invoices')).length, invoicesBefore);
    expect((await db.query('sales')).length, salesBefore);

    // Wait for the rejection SnackBar to dismiss; it covers the save button.
    await pumpUntil(tester,
        () => find.textContaining('سعر البيع غير صالح').evaluate().isEmpty);

    // Entering a valid price must let the invoice save and pop back.
    await tester.enterText(fieldWithLabel('سعر البيع'), '150');
    await tester.pump();
    await tester.tap(find.text('حفظ الفاتورة'));
    await pumpUntil(
        tester, () => find.text('فاتورة جديدة').evaluate().isNotEmpty);

    final invoicesAfter = await db.query('invoices');
    expect(invoicesAfter.length, invoicesBefore + 1);
    expect(invoicesAfter.first['totalAmount'], 150.0);
    expect((await db.query('sales')).length, salesBefore + 1);

    final prodAfter = (await db.query('products',
            where: 'barcode = ?', whereArgs: ['2000000000001']))
        .first;
    expect(prodAfter['currentQuantity'],
        (prodBefore['currentQuantity'] as int) - 1);

    // Login side effect: the owner's lastLoginAt must be recorded.
    final owner =
        await db.query('users', where: 'username = ?', whereArgs: ['owner']);
    expect(owner.single['lastLoginAt'], isNotNull);
  });
}
