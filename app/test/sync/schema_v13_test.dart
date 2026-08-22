import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:muaman_store/database/database_helper.dart';

void main() {
  sqfliteFfiInit();

  const expectedBusinessTables = [
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

  group('Schema v13 fresh database', () {
    late Database testDb;

    setUp(() async {
      testDb =
          await databaseFactoryFfiNoIsolate.openDatabase(inMemoryDatabasePath);
    });

    tearDown(() async {
      await testDb.close();
    });

    test('fresh v13 database has sync_queue table', () async {
      await DatabaseHelper.runCreateDbForTest(testDb);

      final result = await testDb.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='sync_queue'");
      expect(result, isNotEmpty, reason: 'sync_queue table not found');
    });

    test('fresh v13-lineage database schema version is current (14)', () async {
      // Phase I bumped the schema 13 -> 14 (additive legacy_migration_progress
      // table); the historical v13 expectations remain covered by the other
      // tests in this group.
      await DatabaseHelper.runCreateDbForTest(testDb);
      final version =
          (await testDb.rawQuery('PRAGMA user_version')).single['user_version'];
      expect(version, 14);
    });

    test('fresh v13 database has all 12 business tables', () async {
      await DatabaseHelper.runCreateDbForTest(testDb);

      for (final table in expectedBusinessTables) {
        final result = await testDb.rawQuery(
            "SELECT name FROM sqlite_master WHERE type='table' AND name='$table'");
        expect(result, isNotEmpty, reason: 'Table $table not found');
      }
    });

    test('sync_queue has correct columns', () async {
      await DatabaseHelper.runCreateDbForTest(testDb);

      final info = await testDb.rawQuery('PRAGMA table_info(sync_queue)');
      final columns = info.map((r) => r['name'] as String).toSet();
      expect(columns, contains('id'));
      expect(columns, contains('entity_type'));
      expect(columns, contains('entity_id'));
      expect(columns, contains('operation'));
      expect(columns, contains('payload'));
      expect(columns, contains('created_at'));
      expect(columns, contains('synced_at'));
      expect(columns, contains('retry_count'));
      expect(columns, contains('status'));
      expect(columns, contains('conflict_data'));
      expect(columns, contains('idempotency_key'));
      expect(columns, contains('shop_id'));
    });

    test('sync_queue indexes exist', () async {
      await DatabaseHelper.runCreateDbForTest(testDb);

      final indexes = await testDb.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='index' AND tbl_name='sync_queue'");
      final indexNames = indexes.map((r) => r['name'] as String).toSet();
      expect(indexNames, contains('idx_sync_queue_status'));
      expect(indexNames, contains('idx_sync_queue_created_at'));
      expect(indexNames, contains('idx_sync_queue_shop_id'));
      expect(indexNames, contains('idx_sync_queue_entity'));
    });

    test('all 12 business tables have server_version column', () async {
      await DatabaseHelper.runCreateDbForTest(testDb);

      for (final table in expectedBusinessTables) {
        final info = await testDb.rawQuery('PRAGMA table_info($table)');
        final columns = info.map((r) => r['name'] as String).toSet();
        expect(columns, contains('server_version'),
            reason: '$table missing server_version');
      }
    });

    test('all 12 business tables have sync_status column', () async {
      await DatabaseHelper.runCreateDbForTest(testDb);

      for (final table in expectedBusinessTables) {
        final info = await testDb.rawQuery('PRAGMA table_info($table)');
        final columns = info.map((r) => r['name'] as String).toSet();
        expect(columns, contains('sync_status'),
            reason: '$table missing sync_status');
      }
    });

    test('all 12 business tables have last_synced_at column', () async {
      await DatabaseHelper.runCreateDbForTest(testDb);

      for (final table in expectedBusinessTables) {
        final info = await testDb.rawQuery('PRAGMA table_info($table)');
        final columns = info.map((r) => r['name'] as String).toSet();
        expect(columns, contains('last_synced_at'),
            reason: '$table missing last_synced_at');
      }
    });

    test('server_version defaults to 0 on new product insert', () async {
      await DatabaseHelper.runCreateDbForTest(testDb);

      await testDb.insert('products', {
        'name': 'منتج',
        'barcode': 'BAR-SYNC-001',
        'openingQuantity': 10,
        'soldQuantity': 0,
        'currentQuantity': 10,
        'costPrice': 50.0,
        'totalInventoryCost': 500.0,
        'inventoryAdjustment': 0,
      });

      final row = (await testDb.query('products',
              where: 'barcode = ?', whereArgs: ['BAR-SYNC-001']))
          .first;
      expect(row['server_version'], 0);
      expect(row['sync_status'], 'SYNCED');
      expect(row['last_synced_at'], isNull);
    });

    test('sync_queue can store and retrieve entries', () async {
      await DatabaseHelper.runCreateDbForTest(testDb);

      await testDb.insert('sync_queue', {
        'id': 'test-entry-1',
        'entity_type': 'product',
        'entity_id': 1,
        'operation': 'CREATE',
        'created_at': DateTime.now().toIso8601String(),
        'retry_count': 0,
        'status': 'PENDING',
        'idempotency_key': 'idem-key-001',
      });

      final result = await testDb
          .query('sync_queue', where: 'id = ?', whereArgs: ['test-entry-1']);
      expect(result, isNotEmpty);
      expect(result.first['entity_type'], 'product');
      expect(result.first['status'], 'PENDING');
    });

    test('sync_queue enforces unique idempotency_key', () async {
      await DatabaseHelper.runCreateDbForTest(testDb);

      await testDb.insert('sync_queue', {
        'id': 'test-entry-a',
        'entity_type': 'product',
        'entity_id': 1,
        'operation': 'CREATE',
        'created_at': DateTime.now().toIso8601String(),
        'retry_count': 0,
        'status': 'PENDING',
        'idempotency_key': 'unique-key-001',
      });

      expect(
        () => testDb.insert('sync_queue', {
          'id': 'test-entry-b',
          'entity_type': 'product',
          'entity_id': 2,
          'operation': 'UPDATE',
          'created_at': DateTime.now().toIso8601String(),
          'retry_count': 0,
          'status': 'PENDING',
          'idempotency_key': 'unique-key-001',
        }),
        throwsA(anything),
      );
    });
  });

  group('Schema v13 migration (v9 -> v13)', () {
    late Database testDb;

    setUp(() async {
      testDb =
          await databaseFactoryFfiNoIsolate.openDatabase(inMemoryDatabasePath);
    });

    tearDown(() async {
      await testDb.close();
    });

    test('migration from v9 adds sync columns without data loss', () async {
      await _createV9Schema(testDb);

      await testDb.insert('products', {
        'name': 'منتج تجريبي',
        'barcode': 'BAR-MIG-V13-001',
        'openingQuantity': 10,
        'soldQuantity': 2,
        'returnedQuantity': 0,
        'currentQuantity': 8,
        'costPrice': 50.0,
        'totalInventoryCost': 400.0,
        'inventoryAdjustment': 0,
        'shop_id': 'shop-001',
        'cloud_uuid': 'uuid-001',
      });

      await _migrateV9toV13(testDb);

      final migratedCount =
          (await testDb.rawQuery('SELECT COUNT(*) as c FROM products'))
              .single['c'] as int;
      expect(migratedCount, 1);

      final productRow = (await testDb.query('products',
              where: 'barcode = ?', whereArgs: ['BAR-MIG-V13-001']))
          .first;
      expect(productRow['shop_id'], 'shop-001');
      expect(productRow['cloud_uuid'], 'uuid-001');
      expect(productRow['server_version'], 0);
      expect(productRow['sync_status'], 'SYNCED');
      expect(productRow['last_synced_at'], isNull);

      final syncQueueResult = await testDb.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='sync_queue'");
      expect(syncQueueResult, isNotEmpty);
    });
  });
}

Future<void> _createV9Schema(Database db) async {
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
      cloud_uuid TEXT
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
      cogs REAL DEFAULT 0,
      shop_id TEXT,
      cloud_uuid TEXT
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
      returnedCogs REAL DEFAULT 0,
      shop_id TEXT,
      cloud_uuid TEXT
    )
  ''');
  await db.execute('''
    CREATE TABLE expenses (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      date TEXT NOT NULL,
      description TEXT NOT NULL,
      amount REAL DEFAULT 0,
      category TEXT,
      shop_id TEXT,
      cloud_uuid TEXT
    )
  ''');
  await db.execute('''
    CREATE TABLE inventory_count (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      productId INTEGER NOT NULL,
      actualQuantity INTEGER DEFAULT 0,
      notes TEXT DEFAULT '',
      countDate TEXT NOT NULL,
      shop_id TEXT,
      cloud_uuid TEXT,
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
      createdAt TEXT NOT NULL,
      customerId INTEGER,
      shop_id TEXT,
      cloud_uuid TEXT
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
      reconciliation_json TEXT,
      shop_id TEXT,
      cloud_uuid TEXT
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
      lastLoginAt TEXT,
      shop_id TEXT,
      cloud_uuid TEXT
    )
  ''');
  await db.execute('''
    CREATE TABLE role_permissions (
      role TEXT PRIMARY KEY,
      permissions TEXT NOT NULL,
      updatedAt TEXT NOT NULL,
      shop_id TEXT,
      cloud_uuid TEXT
    )
  ''');
  await db.execute('''
    CREATE TABLE app_settings (
      key TEXT PRIMARY KEY,
      value TEXT NOT NULL,
      shop_id TEXT,
      cloud_uuid TEXT
    )
  ''');
  await db.execute('''
    CREATE TABLE expense_categories (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL UNIQUE,
      shop_id TEXT,
      cloud_uuid TEXT
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
      updatedAt TEXT NOT NULL,
      shop_id TEXT,
      cloud_uuid TEXT
    )
  ''');
}

Future<void> _migrateV9toV13(Database db) async {
  await db.execute('''
    CREATE TABLE IF NOT EXISTS sync_queue (
      id TEXT PRIMARY KEY,
      entity_type TEXT NOT NULL,
      entity_id INTEGER NOT NULL,
      operation TEXT NOT NULL,
      payload TEXT,
      created_at TEXT NOT NULL,
      synced_at TEXT,
      retry_count INTEGER DEFAULT 0,
      status TEXT DEFAULT 'PENDING',
      conflict_data TEXT,
      idempotency_key TEXT NOT NULL UNIQUE,
      shop_id TEXT
    )
  ''');

  await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_sync_queue_status ON sync_queue(status)');
  await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_sync_queue_created_at ON sync_queue(created_at ASC)');
  await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_sync_queue_shop_id ON sync_queue(shop_id)');
  await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_sync_queue_entity ON sync_queue(entity_type, entity_id)');

  const syncTables = [
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

  for (final table in syncTables) {
    final info = await db.rawQuery('PRAGMA table_info($table)');
    final columns = info.map((r) => r['name'] as String).toSet();

    if (!columns.contains('server_version')) {
      await db.execute(
          'ALTER TABLE $table ADD COLUMN server_version INTEGER DEFAULT 0');
    }
    if (!columns.contains('sync_status')) {
      await db.execute(
          "ALTER TABLE $table ADD COLUMN sync_status TEXT DEFAULT 'SYNCED'");
    }
    if (!columns.contains('last_synced_at')) {
      await db.execute('ALTER TABLE $table ADD COLUMN last_synced_at TEXT');
    }
  }
}
