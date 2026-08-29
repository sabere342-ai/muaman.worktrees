import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:muaman_store/database/database_helper.dart';
import 'package:muaman_store/migration/migration_progress_repository.dart';

void main() {
  sqfliteFfiInit();

  Directory? tempDir;

  Future<Database> openUniqueDb() async {
    final path = p.join(tempDir!.path,
        'db_${DateTime.now().microsecondsSinceEpoch}_${tempDir!.listSync().length}.db');
    return databaseFactoryFfiNoIsolate.openDatabase(path);
  }

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('muaman_v14_test');
  });

  tearDownAll(() async {
    try {
      await tempDir?.delete(recursive: true);
    } catch (_) {}
  });

  const allBusinessTables = [
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

  group('Schema v14 fresh database (D8)', () {
    late Database testDb;

    setUp(() async {
      testDb = await openUniqueDb();
    });

    tearDown(() async {
      await testDb.close();
    });

    test('fresh create lands at the current schema version', () async {
      // Phase M bumped the schema 14 -> 15 (additive conflict lifecycle +
      // audit artifacts); Phase P bumped it 15 -> 16 (cloud_uuid backfill).
      // The v14 expectations remain covered by the dedicated v13→v14 upgrade
      // group below.
      await DatabaseHelper.runCreateDbForTest(testDb);
      final version =
          (await testDb.rawQuery('PRAGMA user_version')).single['user_version'];
      expect(version, DatabaseHelper.schemaVersion);
    });

    test('legacy_migration_progress exists with exact D8 column set', () async {
      await DatabaseHelper.runCreateDbForTest(testDb);

      final info =
          await testDb.rawQuery('PRAGMA table_info(legacy_migration_progress)');
      final columns = info.map((r) => r['name'] as String).toSet();
      expect(columns, {
        'id',
        'batch_id',
        'shop_id',
        'phase',
        'status',
        'snapshot_path',
        'snapshot_sha256',
        'last_table',
        'last_local_id',
        'stats_json',
        'started_at',
        'updated_at',
        'completed_at',
      });
    });

    test('batch_id is unique (UNIQUE constraint enforced)', () async {
      await DatabaseHelper.runCreateDbForTest(testDb);

      Future<void> insert(String id) =>
          testDb.insert('legacy_migration_progress', {
            'batch_id': id,
            'shop_id': 'shop-1',
            'phase': 'P0',
            'status': 'NOT_STARTED',
            'started_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });

      await insert('b-1');
      expect(() => insert('b-1'), throwsA(anything));
    });

    test('onCreate parity: every business table plus bookkeeping table exists',
        () async {
      // Plan §1.3 lesson: anything created by a migration step MUST also be
      // created by _createDB. V14 adds legacy_migration_progress in BOTH
      // paths; this retro-guards the checklist.
      await DatabaseHelper.runCreateDbForTest(testDb);

      for (final table in [...allBusinessTables, 'sync_queue']) {
        final found = await testDb.rawQuery(
            "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
            [table]);
        expect(found, isNotEmpty, reason: 'missing table $table');
      }
    });

    test('MigrationProgressRepository round-trips batches durably', () async {
      await DatabaseHelper.runCreateDbForTest(testDb);
      final repo = MigrationProgressRepository(testDb);

      await repo.insertBatch(
        batchId: 'batch-A',
        shopId: 'shop-1',
        phase: 'P0',
        status: 'NOT_STARTED',
        snapshotPath: '/tmp/snap.db',
        snapshotSha256: 'deadbeef',
        stats: {'resumeAttempts': 0},
      );

      final row = await repo.getBatch('batch-A');
      expect(row, isNotNull);
      expect(row!['status'], 'NOT_STARTED');

      await repo.updateBatch(
        'batch-A',
        phase: 'P2',
        status: 'RUNNING',
        lastTable: 'products',
        lastLocalId: 42,
        stats: {
          'resumeAttempts': 1,
          'phases': {'P1': 'DONE'}
        },
      );

      final updated = (await repo.getBatch('batch-A'))!;
      expect(updated['status'], 'RUNNING');
      expect(updated['last_table'], 'products');
      expect(updated['last_local_id'], 42);
      final stats = MigrationProgressRepository.decodeStats(updated);
      expect(stats!['phases']['P1'], 'DONE');

      final latest = await repo.latestNonTerminalBatch('shop-1');
      expect(latest!['batch_id'], 'batch-A');

      await repo.updateBatch('batch-A',
          status: 'ABORTED', completedAt: DateTime.now().toIso8601String());
      expect(await repo.latestNonTerminalBatch('shop-1'), isNull);
    });
  });

  group('Schema v13 → v14 upgrade path (additive only)', () {
    late Database testDb;

    setUp(() async {
      testDb = await openUniqueDb();
    });

    tearDown(() async {
      await testDb.close();
    });

    test('upgrade creates bookkeeping table without touching business data',
        () async {
      // Build a representative v13-shaped store: business tables with data,
      // sync_queue present, NO legacy_migration_progress, user_version = 13.
      await _createV13ShapeWithLegacyData(testDb);
      await testDb.rawUpdate('PRAGMA user_version = 13');

      // Apply the production V14 step semantics (purely additive CREATE IF
      // NOT EXISTS, exactly what _migrateToV14 performs on openDatabase
      // upgrade): recreate through the same guarded statement family.
      await _applyV14Upgrade(testDb);
      await testDb.rawUpdate('PRAGMA user_version = 14');

      final version =
          (await testDb.rawQuery('PRAGMA user_version')).single['user_version'];
      expect(version, 14);

      // Bookkeeping table now exists.
      final progressInfo =
          await testDb.rawQuery('PRAGMA table_info(legacy_migration_progress)');
      expect(progressInfo.map((r) => r['name'] as String),
          containsAll(['batch_id', 'stats_json', 'last_local_id']));

      // Business data untouched by the additive migration.
      final products =
          await testDb.rawQuery('SELECT COUNT(*) AS c FROM products');
      expect(products.single['c'], 2);
      final sales = await testDb.rawQuery('SELECT COUNT(*) AS c FROM sales');
      expect(sales.single['c'], 1);
      final settings =
          await testDb.rawQuery('SELECT COUNT(*) AS c FROM app_settings');
      expect(settings.single['c'], 3);
    });

    test('upgraded table columns identical to fresh-create table', () async {
      // Fresh-create reference shape.
      final freshDb = await openUniqueDb();
      addTearDown(freshDb.close);
      await DatabaseHelper.runCreateDbForTest(freshDb);
      final freshColumns = (await freshDb
              .rawQuery('PRAGMA table_info(legacy_migration_progress)'))
          .map((r) => '${r["name"]}:${r["type"]}')
          .toList()
        ..sort();

      // Upgraded shape.
      await _createV13ShapeWithLegacyData(testDb);
      await _applyV14Upgrade(testDb);
      final upgradedColumns = (await testDb
              .rawQuery('PRAGMA table_info(legacy_migration_progress)'))
          .map((r) => '${r["name"]}:${r["type"]}')
          .toList()
        ..sort();

      expect(upgradedColumns, freshColumns,
          reason: 'V14 upgrade and fresh-create must produce byte-identical '
              'bookkeeping table shapes (plan §1.3 parity rule)');
    });
  });
}

/// Representative v13-era store WITHOUT the v14 bookkeeping table.
Future<void> _createV13ShapeWithLegacyData(Database db) async {
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
  await db.execute('''
    CREATE TABLE app_settings (
      key TEXT PRIMARY KEY,
      value TEXT NOT NULL,
      shop_id TEXT,
      cloud_uuid TEXT,
      server_version INTEGER DEFAULT 0,
      sync_status TEXT DEFAULT 'SYNCED',
      last_synced_at TEXT
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
      cloud_uuid TEXT,
      server_version INTEGER DEFAULT 0,
      sync_status TEXT DEFAULT 'SYNCED',
      last_synced_at TEXT
    )
  ''');

  await db.insert('products', {
    'name': 'منتج أ',
    'barcode': 'BAR-V14-1',
    'openingQuantity': 10,
    'currentQuantity': 10,
    'costPrice': 5.0,
    'totalInventoryCost': 50.0,
  });
  await db.insert('products', {
    'name': 'منتج ب',
    'barcode': 'BAR-V14-2',
    'openingQuantity': 4,
    'currentQuantity': 4,
    'costPrice': 2.5,
    'totalInventoryCost': 10.0,
  });
  await db.insert('sales', {
    'date': '2026-01-01T00:00:00.000',
    'productName': 'منتج أ',
    'barcode': 'BAR-V14-1',
    'quantity': 1,
    'salePrice': 9.99,
    'totalSaleValue': 9.99,
    'costPrice': 5.0,
    'cogs': 5.0,
  });
  for (final key in ['brandColor', 'shopName', 'receiptFooter']) {
    await db.insert('app_settings', {'key': key, 'value': '$key-value'});
  }
}

/// Mirrors `_migrateToV14`: purely additive, guarded, index included.
Future<void> _applyV14Upgrade(Database db) async {
  await db.execute('''
    CREATE TABLE IF NOT EXISTS legacy_migration_progress (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      batch_id TEXT NOT NULL UNIQUE,
      shop_id TEXT NOT NULL,
      phase TEXT NOT NULL,
      status TEXT NOT NULL,
      snapshot_path TEXT,
      snapshot_sha256 TEXT,
      last_table TEXT,
      last_local_id INTEGER,
      stats_json TEXT,
      started_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      completed_at TEXT
    )
  ''');
  await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_legacy_migration_progress_shop ON legacy_migration_progress(shop_id)');
}
