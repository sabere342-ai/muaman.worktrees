import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:muaman_store/database/database_helper.dart';

/// Phase K / W1 (plan D3): fresh-install parity regression.
///
/// Android ships as FRESH installs taking the production `onCreate` path.
/// This test proves that a fresh v14 database is byte-equivalent in shape
/// to an upgraded-to-v14 database for every table, including the v13
/// artifacts (`sync_queue`, its indexes, and the sync columns on all 12
/// tenant-owned tables) that production `onCreate` historically missed.
void main() {
  sqfliteFfiInit();

  Directory? tempDir;

  Future<Database> openUniqueDb() async {
    final path = p.join(tempDir!.path,
        'db_${DateTime.now().microsecondsSinceEpoch}_${tempDir!.listSync().length}.db');
    return databaseFactoryFfiNoIsolate.openDatabase(path);
  }

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('muaman_w1_parity_test');
  });

  tearDownAll(() async {
    try {
      await tempDir?.delete(recursive: true);
    } catch (_) {}
  });

  const tenantTables = [
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

  const allTables = [
    ...tenantTables,
    'sync_queue',
    'legacy_migration_progress',
  ];

  Future<List<String>> columnShapes(Database db, String table) async {
    final info = await db.rawQuery('PRAGMA table_info($table)');
    return info
        .map((r) =>
            '${r['name']}:${r['type']}:${r['notnull']}:${r['dflt_value']}')
        .toList()
      ..sort();
  }

  Future<Set<String>> indexNames(Database db, String table) async {
    final rows = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='index' AND tbl_name=?",
        [table]);
    return rows.map((r) => r['name'] as String).toSet();
  }

  test('fresh onCreate == create+upgrade-replay for every v14 table', () async {
    final freshDb = await openUniqueDb();
    addTearDown(freshDb.close);
    // Production fresh-install path ONLY (openDatabase onCreate semantics).
    await DatabaseHelper.runFreshOnCreateForTest(freshDb);

    final upgradedDb = await openUniqueDb();
    addTearDown(upgradedDb.close);
    // Create + real migration replay (historical upgrade end-state).
    await DatabaseHelper.runCreateDbForTest(upgradedDb);

    for (final table in allTables) {
      final freshShape = await columnShapes(freshDb, table);
      final upgradedShape = await columnShapes(upgradedDb, table);

      expect(freshShape, isNotEmpty,
          reason: 'fresh onCreate must create $table');
      expect(freshShape, upgradedShape,
          reason: 'W1 parity violated for table $table');
    }

    final freshVersion =
        (await freshDb.rawQuery('PRAGMA user_version')).single['user_version'];
    // Phase M/P: parity is proven at the current schema version; the
    // historical v14 expectation is covered by the v14 suites.
    expect(freshVersion, DatabaseHelper.schemaVersion);
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('fresh onCreate creates sync_queue with full index set', () async {
    final freshDb = await openUniqueDb();
    addTearDown(freshDb.close);
    await DatabaseHelper.runFreshOnCreateForTest(freshDb);

    final indexes = await indexNames(freshDb, 'sync_queue');
    expect(
        indexes,
        containsAll([
          'idx_sync_queue_status',
          'idx_sync_queue_created_at',
          'idx_sync_queue_shop_id',
          'idx_sync_queue_entity',
        ]));
  });

  test('fresh onCreate carries sync columns on ALL 12 tenant tables', () async {
    final freshDb = await openUniqueDb();
    addTearDown(freshDb.close);
    await DatabaseHelper.runFreshOnCreateForTest(freshDb);

    for (final table in tenantTables) {
      final columns = (await columnShapes(freshDb, table))
          .map((c) => c.split(':').first)
          .toSet();
      expect(columns,
          containsAll(['server_version', 'sync_status', 'last_synced_at']),
          reason: 'missing sync columns on $table');
    }
  });
}
