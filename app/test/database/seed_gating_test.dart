import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:muaman_store/database/database_helper.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfiNoIsolate;
  });

  late Database testDb;

  setUp(() async {
    testDb =
        await databaseFactoryFfiNoIsolate.openDatabase(inMemoryDatabasePath);
  });

  tearDown(() async {
    await testDb.close();
    DatabaseHelper.seedDemoEnabled = false;
  });

  group('MUAMAN-19 seed gating', () {
    test('production default: demo seeding is disabled', () {
      // The test environment passes no --dart-define, so the compiled default
      // must be false. Production/release builds start empty.
      expect(DatabaseHelper.seedDemoEnabled, isFalse);
    });

    test('seed disabled: _createDB leaves the store empty', () async {
      DatabaseHelper.seedDemoEnabled = false;

      await DatabaseHelper.runCreateDbForTest(testDb);

      expect(await testDb.query('products'), isEmpty);
      expect(await testDb.query('sales'), isEmpty);
      expect(await testDb.query('returns'), isEmpty);
      expect(await testDb.query('expenses'), isEmpty);
      expect(await testDb.query('invoices'), isEmpty);
      expect(await testDb.query('import_batches'), isEmpty);
    });

    test('seed enabled: _createDB populates demo data', () async {
      DatabaseHelper.seedDemoEnabled = true;

      await DatabaseHelper.runCreateDbForTest(testDb);

      final products = await testDb.query('products');
      expect(products, isNotEmpty);
      expect(products.length, greaterThan(10));
      expect(await testDb.query('sales'), isNotEmpty);
      expect(await testDb.query('returns'), isNotEmpty);
      expect(await testDb.query('expenses'), isNotEmpty);

      // The seeded catalog is the known demo set (first seeded barcode).
      final demo = await testDb.query('products',
          where: 'barcode = ?', whereArgs: ['2000000000001']);
      expect(demo, hasLength(1));
      expect(demo.first['name'], 'تي شيرت 2سوستة تركي');
    });

    test('toggle back to disabled still yields an empty schema', () async {
      // Recreate the schema twice to prove gating is per-run, not
      // latched from an earlier seed.
      final seeded =
          await databaseFactoryFfiNoIsolate.openDatabase(inMemoryDatabasePath);
      DatabaseHelper.seedDemoEnabled = true;
      await DatabaseHelper.runCreateDbForTest(seeded);
      expect(await seeded.query('products'), isNotEmpty);
      await seeded.close();

      final fresh =
          await databaseFactoryFfiNoIsolate.openDatabase(inMemoryDatabasePath);
      DatabaseHelper.seedDemoEnabled = false;
      await DatabaseHelper.runCreateDbForTest(fresh);
      expect(await fresh.query('products'), isEmpty);
      await fresh.close();
    });
  });
}
