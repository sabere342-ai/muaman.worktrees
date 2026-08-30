import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:muaman_store/database/database_helper.dart';
import 'package:muaman_store/sync/stock_adjustment.dart';

/// Phase P Group A A3 (P-OD1 local half): schema v18 — additive durable
/// `stock_adjustments` table (the Option C adjustment artifact).
///
/// Proves:
///   - a fresh v18 install creates the `stock_adjustments` table with the
///     full durable row shape (shop scope, originating sale/return, product
///     identity, projected current, shortfall, related events, deterministic
///     idempotency key, lifecycle status, cloud uuid, timestamps),
///   - the v17 → v18 upgrade adds the table additively WITHOUT disturbing the
///     pre-existing v17 shape (legacy tables survive),
///   - the repository round-trips a durable artifact (insert → read back)
///     against the REAL migration seam.
void main() {
  sqfliteFfiInit();

  late Database testDb;
  late DatabaseHelper helper;

  setUp(() async {
    testDb =
        await databaseFactoryFfiNoIsolate.openDatabase(inMemoryDatabasePath);
    await DatabaseHelper.runCreateDbForTest(testDb);
    await DatabaseHelper.setTestDatabase(testDb);
    helper = DatabaseHelper.instance;
  });

  tearDown(() async {
    DatabaseHelper.resetForTest();
    await testDb.close();
  });

  Future<Set<String>> tables(Database db) async {
    final rows = await db
        .rawQuery("SELECT name FROM sqlite_master WHERE type = 'table'");
    return rows.map((r) => r['name'] as String).toSet();
  }

  Future<List<Map<String, String>>> tableColumns(
      Database db, String table) async {
    final info = await db.rawQuery('PRAGMA table_info($table)');
    return info
        .map((r) => {
              'name': r['name'] as String,
              'type': r['type'] as String,
            })
        .toList();
  }

  group('A3 v18 — stock_adjustments schema', () {
    test('fresh v18 install carries the durable table with the full shape',
        () async {
      expect(await tables(testDb), contains('stock_adjustments'));

      final columns = await tableColumns(testDb, 'stock_adjustments');
      final names = columns.map((c) => c['name']).toSet();
      expect(
          names,
          containsAll(<String>[
            'id',
            'shop_id',
            'sale_id',
            'return_id',
            'product_barcode',
            'product_id',
            'projected_current',
            'shortfall',
            'related_event_ids',
            'idempotency_key',
            'status',
            'cloud_uuid',
            'created_at',
            'resolved_at',
          ]));
      expect(names, isNot(contains('server_version')),
          reason: 'the evidence table must never fake a server_version');
      expect(names, isNot(contains('sync_status')),
          reason: 'the evidence table must never fake a sync_status');
    });

    test('the repository round-trips a durable Option C artifact (v18)',
        () async {
      final repo = StockAdjustmentRepository(testDb);
      final id = await repo.insertAdjustment(
        shopId: 'shop-1',
        saleId: 7,
        productBarcode: 'B-1',
        productId: 'prod-1',
        projectedCurrent: -3,
        shortfall: 3,
        relatedEventIds: const ['sale:1:CREATE:TOK-1'],
        idempotencyKey: 'sale:7:ADJUST:TOK-1',
      );

      final adj = await repo.getById(id);
      expect(adj, isNotNull);
      expect(adj!.shopId, 'shop-1');
      expect(adj.saleId, 7);
      expect(adj.productBarcode, 'B-1');
      expect(adj.productId, 'prod-1');
      expect(adj.projectedCurrent, -3);
      expect(adj.shortfall, 3);
      expect(adj.relatedEventIds, ['sale:1:CREATE:TOK-1']);
      expect(adj.idempotencyKey, 'sale:7:ADJUST:TOK-1');
      expect(adj.status, AdjustmentLifecycleStatus.OPEN);
      expect(adj.cloudUuid, isNull);

      await repo.markSynced(id, 'cloud-adj-1');
      final synced = await repo.getById(id);
      expect(synced!.status, AdjustmentLifecycleStatus.SYNCED);
      expect(synced.cloudUuid, 'cloud-adj-1');
    });

    test('v17 -> v18 upgrade is additive and idempotent', () async {
      final tempDir = await Directory.systemTemp.createTemp('muaman_v18_test');
      final v17Path = p.join(
          tempDir.path, 'db_${DateTime.now().microsecondsSinceEpoch}.db');
      final v17Db = await databaseFactoryFfiNoIsolate.openDatabase(v17Path);
      await DatabaseHelper.runFreshOnCreateForTest(v17Db, version: 17);
      await DatabaseHelper.setTestDatabase(v17Db);

      // v17 shape: no stock_adjustments table; the core tables survive.
      final v17Tables = await tables(v17Db);
      expect(v17Tables, isNot(contains('stock_adjustments')));
      expect(v17Tables, contains('sync_queue'));
      expect(v17Tables, contains('products'));

      // Upgrade to v18: table lands additively; legacy tables untouched.
      await DatabaseHelper.runUpgradeToV18ForTest(v17Db);
      final v18Tables = await tables(v17Db);
      expect(v18Tables, contains('stock_adjustments'));
      expect(v18Tables, contains('sync_queue'));
      expect(v18Tables, contains('products'));

      // Idempotent: a re-run of the seam does not drop or duplicate.
      await DatabaseHelper.runUpgradeToV18ForTest(v17Db);
      final afterRerun = await tables(v17Db);
      expect(afterRerun.where((t) => t == 'stock_adjustments').length, 1);

      // The real repository can write against the upgraded database.
      final repo = StockAdjustmentRepository(v17Db);
      final id = await repo.insertAdjustment(
        shopId: 'shop-1',
        saleId: 1,
        productBarcode: 'B-1',
        projectedCurrent: -2,
        shortfall: 2,
        idempotencyKey: 'sale:1:ADJUST:TOK-UP',
      );
      expect((await repo.getById(id)), isNotNull);

      await v17Db.close();
      try {
        await tempDir.delete(recursive: true);
      } catch (_) {}
    });
  });
}
