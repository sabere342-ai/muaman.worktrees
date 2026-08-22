import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:muaman_store/database/database_helper.dart';
import 'package:muaman_store/database/workbook_importer.dart';
import 'package:muaman_store/services/active_shop_context.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../database/workbook_import_test.dart' show createAllTablesForTest;

/// J-WS7 import tenant safety (plan §P): imported rows are stamped with the
/// authorized shop context; importing with NO context fails closed.
void main() {
  sqfliteFfiInit();

  late Database testDb;
  late String workbookPath;

  String repoWorkbook() {
    final repoRoot = Directory.current.parent.path;
    return path.join(repoRoot, 'app', 'شهر 8', 'شيت_ادارة_محل_مؤمن_شهر8.xlsx');
  }

  setUp(() async {
    workbookPath = repoWorkbook();
    testDb =
        await databaseFactoryFfiNoIsolate.openDatabase(inMemoryDatabasePath);
    await createAllTablesForTest(testDb);
    await DatabaseHelper.setTestDatabase(testDb);
  });

  tearDown(() async {
    ActiveShopContext.instance.resetForTest();
    DatabaseHelper.resetForTest();
    await testDb.close();
  });

  test('J-I01: explicit shopId argument stamps every imported row', () async {
    final report = await WorkbookImporter.import(
      workbookPath: workbookPath,
      db: testDb,
      allowZeroCost: true,
      skipShaCheck: true,
      shopId: 'shop-import',
    );
    expect(report.productsImported, greaterThan(0));

    final productShops =
        await testDb.query('products', columns: ['DISTINCT shop_id']);
    expect(productShops.map((r) => r['shop_id']), ['shop-import']);

    final batches = await testDb.query('import_batches');
    expect(batches.single['shop_id'], 'shop-import');
  });

  test('J-I02: bound ActiveShopContext is used when no argument is given',
      () async {
    ActiveShopContext.instance
        .configure(membershipValidator: (_) async => true);
    await ActiveShopContext.instance.bind('shop-context');

    await WorkbookImporter.import(
      workbookPath: workbookPath,
      db: testDb,
      allowZeroCost: true,
      skipShaCheck: true,
    );

    final productShops =
        await testDb.query('products', columns: ['DISTINCT shop_id']);
    expect(productShops.map((r) => r['shop_id']), ['shop-context']);
  });

  test('J-I03: import without any authorized context fails CLOSED', () async {
    // No context bound, no explicit shopId → hard failure, no partial data.
    await expectLater(
      WorkbookImporter.import(
        workbookPath: workbookPath,
        db: testDb,
        allowZeroCost: true,
        skipShaCheck: true,
      ),
      throwsA(isA<WorkbookImportException>()),
    );

    // Nothing was imported before the failure.
    final products = await testDb.query('products');
    expect(products, isEmpty,
        reason:
            'unattributed import must never land as NULL-shop rows (plan §P)');
  });
}
