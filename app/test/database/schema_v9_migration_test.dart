import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:muaman_store/database/database_helper.dart';

void main() {
  sqfliteFfiInit();

  const expectedTables = [
    'products',
    'sales',
    'returns',
    'expenses',
    'expense_categories',
    'inventory_count',
    'invoices',
    'import_batches',
    'customers',
    'users',
    'role_permissions',
    'app_settings',
  ];

  group('Schema v9 fresh database', () {
    late Database testDb;

    setUp(() async {
      testDb =
          await databaseFactoryFfiNoIsolate.openDatabase(inMemoryDatabasePath);
    });

    tearDown(() async {
      await testDb.close();
    });

    test('fresh v9 database has shop_id and cloud_uuid on all 12 tables',
        () async {
      await DatabaseHelper.runCreateDbForTest(testDb);

      for (final table in expectedTables) {
        final info = await testDb.rawQuery('PRAGMA table_info($table)');
        final columns = info.map((r) => r['name'] as String).toSet();
        expect(columns, contains('shop_id'), reason: '$table missing shop_id');
        expect(columns, contains('cloud_uuid'),
            reason: '$table missing cloud_uuid');
      }
    });

    test('fresh v9 database schema version is 9', () async {
      await DatabaseHelper.runCreateDbForTest(testDb);
      final version =
          (await testDb.rawQuery('PRAGMA user_version')).single['user_version'];
      expect(version, 9);
    });

    test('fresh v9 database has all 12 tables', () async {
      await DatabaseHelper.runCreateDbForTest(testDb);

      for (final table in expectedTables) {
        final result = await testDb.rawQuery(
            "SELECT name FROM sqlite_master WHERE type='table' AND name='$table'");
        expect(result, isNotEmpty, reason: 'Table $table not found');
      }
    });

    test('fresh v9 database products row has NULL shop_id and cloud_uuid',
        () async {
      await DatabaseHelper.runCreateDbForTest(testDb);

      await testDb.insert('products', {
        'name': 'منتج',
        'barcode': 'BAR-FRESH-001',
        'openingQuantity': 10,
        'soldQuantity': 0,
        'currentQuantity': 10,
        'costPrice': 50.0,
        'totalInventoryCost': 500.0,
        'inventoryAdjustment': 0,
      });

      final row = (await testDb.query('products',
              where: 'barcode = ?', whereArgs: ['BAR-FRESH-001']))
          .first;
      expect(row['shop_id'], isNull);
      expect(row['cloud_uuid'], isNull);
    });
  });

  group('Schema v9 migration (v8 -> v9)', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = Directory.systemTemp.createTempSync('schema_v9_migration_');
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('migration from v8 to v9 adds 24 columns without data loss', () async {
      final dbPath = '${tempDir.path}\\migration.db';

      var db = await databaseFactoryFfiNoIsolate.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(
          version: 8,
          onCreate: (db, version) async {
            await _createV8Schema(db);
          },
        ),
      );

      await db.insert('products', {
        'name': 'منتج تجريبي',
        'barcode': 'BAR-MIG-001',
        'openingQuantity': 10,
        'soldQuantity': 2,
        'returnedQuantity': 0,
        'currentQuantity': 8,
        'costPrice': 50.0,
        'totalInventoryCost': 400.0,
        'inventoryAdjustment': 0,
      });
      await db.insert('sales', {
        'date': '2026-08-20',
        'productName': 'منتج تجريبي',
        'barcode': 'BAR-MIG-001',
        'quantity': 2,
        'salePrice': 100.0,
        'totalSaleValue': 200.0,
        'costPrice': 50.0,
        'cogs': 100.0,
      });
      await db.insert('expenses', {
        'date': '2026-08-20',
        'description': 'إيجار',
        'amount': 500.0,
      });
      await db.insert('returns', {
        'date': '2026-08-20',
        'productName': 'منتج تجريبي',
        'barcode': 'BAR-MIG-001',
        'quantity': 1,
        'salePrice': 100.0,
        'totalReturnValue': 100.0,
        'costPrice': 50.0,
        'returnedCogs': 50.0,
      });

      final productCount =
          (await db.rawQuery('SELECT COUNT(*) as c FROM products')).single['c']
              as int;
      final salesCount = (await db.rawQuery('SELECT COUNT(*) as c FROM sales'))
          .single['c'] as int;
      final expenseCount =
          (await db.rawQuery('SELECT COUNT(*) as c FROM expenses')).single['c']
              as int;
      final returnCount =
          (await db.rawQuery('SELECT COUNT(*) as c FROM returns')).single['c']
              as int;

      // Close and reopen at version 9 to trigger onUpgrade.
      await db.close();
      db = await databaseFactoryFfiNoIsolate.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(
          version: 9,
          onUpgrade: (db, oldVersion, newVersion) async {
            if (oldVersion < 9) {
              await _migrateV8toV9(db);
            }
          },
        ),
      );

      // Verify data survived migration.
      expect(
          (await db.rawQuery('SELECT COUNT(*) as c FROM products')).single['c'],
          productCount);
      expect((await db.rawQuery('SELECT COUNT(*) as c FROM sales')).single['c'],
          salesCount);
      expect(
          (await db.rawQuery('SELECT COUNT(*) as c FROM expenses')).single['c'],
          expenseCount);
      expect(
          (await db.rawQuery('SELECT COUNT(*) as c FROM returns')).single['c'],
          returnCount);

      // Verify new columns exist on all 12 tables.
      for (final table in expectedTables) {
        final info = await db.rawQuery('PRAGMA table_info($table)');
        final columns = info.map((r) => r['name'] as String).toSet();
        expect(columns, contains('shop_id'),
            reason: '$table missing shop_id after migration');
        expect(columns, contains('cloud_uuid'),
            reason: '$table missing cloud_uuid after migration');
      }

      // Verify schema version is now 9.
      final version =
          (await db.rawQuery('PRAGMA user_version')).single['user_version'];
      expect(version, 9);

      await db.close();
    });

    test('existing rows have NULL for new columns after migration', () async {
      final dbPath = '${tempDir.path}\\null_values.db';

      var db = await databaseFactoryFfiNoIsolate.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(
          version: 8,
          onCreate: (db, version) async {
            await _createV8Schema(db);
          },
        ),
      );

      await db.insert('products', {
        'name': 'منتج',
        'barcode': 'BAR-NULL-001',
        'openingQuantity': 5,
        'soldQuantity': 0,
        'currentQuantity': 5,
        'costPrice': 25.0,
        'totalInventoryCost': 125.0,
        'inventoryAdjustment': 0,
      });
      await db.insert('sales', {
        'date': '2026-08-20',
        'productName': 'منتج',
        'barcode': 'BAR-NULL-001',
        'quantity': 1,
        'salePrice': 50.0,
        'totalSaleValue': 50.0,
        'costPrice': 25.0,
        'cogs': 25.0,
      });

      await db.close();
      db = await databaseFactoryFfiNoIsolate.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(
          version: 9,
          onUpgrade: (db, oldVersion, newVersion) async {
            if (oldVersion < 9) {
              await _migrateV8toV9(db);
            }
          },
        ),
      );

      final productRow = (await db.query('products',
              where: 'barcode = ?', whereArgs: ['BAR-NULL-001']))
          .first;
      expect(productRow['shop_id'], isNull);
      expect(productRow['cloud_uuid'], isNull);

      final saleRow = (await db.query('sales',
              where: 'barcode = ?', whereArgs: ['BAR-NULL-001']))
          .first;
      expect(saleRow['shop_id'], isNull);
      expect(saleRow['cloud_uuid'], isNull);

      await db.close();
    });

    test('v8->v9 migration executes exactly once (idempotency)', () async {
      final dbPath = '${tempDir.path}\\idempotent.db';

      var db = await databaseFactoryFfiNoIsolate.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(
          version: 8,
          onCreate: (db, version) async {
            await _createV8Schema(db);
          },
        ),
      );

      // Close and upgrade to v9.
      await db.close();
      db = await databaseFactoryFfiNoIsolate.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(
          version: 9,
          onUpgrade: (db, oldVersion, newVersion) async {
            if (oldVersion < 9) {
              await _migrateV8toV9(db);
            }
          },
        ),
      );

      // Reopen at version 9 again — should NOT trigger onUpgrade.
      await db.close();
      var upgradeCalled = false;
      db = await databaseFactoryFfiNoIsolate.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(
          version: 9,
          onUpgrade: (db, oldVersion, newVersion) async {
            upgradeCalled = true;
          },
        ),
      );

      expect(upgradeCalled, isFalse);

      final version =
          (await db.rawQuery('PRAGMA user_version')).single['user_version'];
      expect(version, 9);

      // Verify columns still exist and are usable.
      final info = await db.rawQuery('PRAGMA table_info(products)');
      final columns = info.map((r) => r['name'] as String).toSet();
      expect(columns, contains('shop_id'));
      expect(columns, contains('cloud_uuid'));

      await db.close();
    });
  });
}

/// Creates a minimal v8 schema (without shop_id/cloud_uuid) for migration testing.
Future<void> _createV8Schema(Database db) async {
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
    CREATE TABLE expenses (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      date TEXT NOT NULL,
      description TEXT NOT NULL,
      amount REAL DEFAULT 0,
      category TEXT
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
  await db.execute('''
    CREATE TABLE invoices (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      invoiceNumber TEXT NOT NULL UNIQUE,
      date TEXT NOT NULL,
      customerName TEXT NOT NULL,
      paymentMethod TEXT NOT NULL,
      totalAmount REAL DEFAULT 0,
      totalItems INTEGER DEFAULT 0,
      createdAt TEXT NOT NULL
    )
  ''');
  await db.execute('''
    CREATE TABLE import_batches (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      file_sha256 TEXT NOT NULL UNIQUE,
      file_name TEXT NOT NULL,
      imported_at TEXT NOT NULL,
      products_count INTEGER DEFAULT 0,
      sales_count INTEGER DEFAULT 0,
      returns_count INTEGER DEFAULT 0,
      expenses_count INTEGER DEFAULT 0,
      adjustments_count INTEGER DEFAULT 0,
      total_quantity INTEGER DEFAULT 0,
      total_inventory_value REAL DEFAULT 0,
      total_sales REAL DEFAULT 0,
      total_returns REAL DEFAULT 0,
      net_sales REAL DEFAULT 0,
      total_cogs REAL DEFAULT 0,
      returned_cogs REAL DEFAULT 0,
      net_cogs REAL DEFAULT 0,
      gross_profit REAL DEFAULT 0,
      total_expenses REAL DEFAULT 0,
      net_profit REAL DEFAULT 0,
      reconciliation_json TEXT
    )
  ''');
  await db.execute('''
    CREATE TABLE users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      displayName TEXT NOT NULL,
      username TEXT NOT NULL UNIQUE,
      passwordHash TEXT NOT NULL,
      role TEXT NOT NULL,
      isActive INTEGER NOT NULL DEFAULT 1,
      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL,
      lastLoginAt TEXT
    )
  ''');
  await db.execute('''
    CREATE TABLE role_permissions (
      role TEXT PRIMARY KEY,
      permissions TEXT NOT NULL,
      updatedAt TEXT NOT NULL
    )
  ''');
  await db.execute('''
    CREATE TABLE app_settings (
      key TEXT PRIMARY KEY,
      value TEXT NOT NULL
    )
  ''');
  await db.execute('''
    CREATE TABLE expense_categories (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL UNIQUE
    )
  ''');
  await db.execute('''
    CREATE TABLE customers (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      phone TEXT,
      address TEXT,
      notes TEXT,
      isActive INTEGER NOT NULL DEFAULT 1,
      isSystem INTEGER NOT NULL DEFAULT 0,
      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL
    )
  ''');
}

/// Mirrors the v8->v9 migration in database_helper.dart for test isolation.
Future<void> _migrateV8toV9(Database db) async {
  const tables = [
    'products',
    'sales',
    'returns',
    'expenses',
    'expense_categories',
    'inventory_count',
    'invoices',
    'import_batches',
    'customers',
    'users',
    'role_permissions',
    'app_settings',
  ];
  for (final table in tables) {
    await db.execute('ALTER TABLE $table ADD COLUMN shop_id TEXT');
    await db.execute('ALTER TABLE $table ADD COLUMN cloud_uuid TEXT');
  }
}
