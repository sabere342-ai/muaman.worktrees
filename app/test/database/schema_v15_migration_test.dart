import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:muaman_store/database/database_helper.dart';
import 'package:muaman_store/sync/conflict_audit_repository.dart';
import 'package:muaman_store/sync/sync_queue_repository.dart';
import 'package:muaman_store/sync/sync_status.dart';

/// Phase M (plan §26 / DR-M11): schema v14 → v15 is ADDITIVE ONLY.
///
/// Proves:
///   - the upgrade adds `sync_queue.resolution_status`,
///     `sync_queue.occurrence_token` and the `conflict_audit` table
///     without touching business data,
///   - legacy terminal CONFLICT rows backfill to REVIEW_REQUIRED (CL-4),
///   - fresh-create parity: onCreate at v15 == upgraded-to-v15 shape,
///   - audit rows survive queue cleanupSynced (AU-1 / INV-M18).
void main() {
  sqfliteFfiInit();

  Directory? tempDir;

  Future<Database> openUniqueDb() async {
    final path = p.join(tempDir!.path,
        'db_${DateTime.now().microsecondsSinceEpoch}_${tempDir!.listSync().length}.db');
    return databaseFactoryFfiNoIsolate.openDatabase(path);
  }

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('muaman_v15_test');
  });

  tearDownAll(() async {
    try {
      await tempDir?.delete(recursive: true);
    } catch (_) {}
  });

  Future<void> seedV14QueueRow(
    Database db, {
    required String id,
    required String status,
  }) async {
    await db.insert('sync_queue', {
      'id': id,
      'entity_type': 'product',
      'entity_id': 1,
      'operation': 'CREATE',
      'payload': '{"name":"x"}',
      'created_at': DateTime.now().toIso8601String(),
      'retry_count': 0,
      'status': status,
      'idempotency_key': 'legacy-$id',
      'shop_id': 'shop-1',
    });
  }

  Future<Set<String>> columnsOf(Database db, String table) async {
    final info = await db.rawQuery('PRAGMA table_info($table)');
    return info.map((r) => r['name'] as String).toSet();
  }

  group('v14 → v15 upgrade path (additive only)', () {
    late Database db;

    setUp(() async {
      db = await openUniqueDb();
      // Real v14 fresh shape, then stamp it as a genuine v14 install.
      await DatabaseHelper.runFreshOnCreateForTest(db, version: 14);
      await db.rawUpdate('PRAGMA user_version = 14');
    });

    tearDown(() async {
      await db.close();
    });

    test('upgrade adds lifecycle/token columns and conflict_audit table',
        () async {
      await seedV14QueueRow(db, id: 'q-1', status: 'PENDING');

      await DatabaseHelper.runUpgradeToV15ForTest(db);

      final queueColumns = await columnsOf(db, 'sync_queue');
      expect(
          queueColumns, containsAll(['resolution_status', 'occurrence_token']));

      final tables =
          await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' "
              "AND name='conflict_audit'");
      expect(tables, isNotEmpty, reason: 'conflict_audit must be created');

      final indexes =
          await db.rawQuery("SELECT name FROM sqlite_master WHERE type='index' "
              "AND tbl_name='conflict_audit'");
      expect(
        indexes.map((r) => r['name'] as String),
        containsAll([
          'idx_conflict_audit_shop',
          'idx_conflict_audit_entity',
          'idx_conflict_audit_status',
        ]),
      );
    });

    test('legacy CONFLICT rows backfill to REVIEW_REQUIRED (CL-4)', () async {
      await seedV14QueueRow(db, id: 'q-conflict', status: 'CONFLICT');
      await seedV14QueueRow(db, id: 'q-pending', status: 'PENDING');
      await seedV14QueueRow(db, id: 'q-synced', status: 'SYNCED');
      await seedV14QueueRow(db, id: 'q-failed', status: 'FAILED');

      await DatabaseHelper.runUpgradeToV15ForTest(db);

      final rows = await db.query('sync_queue',
          orderBy: 'id', columns: ['id', 'status', 'resolution_status']);
      final byId = {for (final r in rows) r['id'] as String: r};

      expect(byId['q-conflict']!['resolution_status'], 'REVIEW_REQUIRED',
          reason: 'legacy terminal CONFLICT migrates to review semantics');
      expect(byId['q-pending']!['resolution_status'], isNull,
          reason: 'non-conflict rows keep implicit legacy semantics');
      expect(byId['q-synced']!['resolution_status'], isNull);
      expect(byId['q-failed']!['resolution_status'], isNull);

      // The legacy status column itself is never rewritten.
      expect(byId['q-conflict']!['status'], 'CONFLICT');
    });

    test('upgrade does not touch business data (additive only)', () async {
      await db.insert('products', {
        'name': 'منتج',
        'barcode': 'BAR-V15-1',
        'openingQuantity': 7,
        'soldQuantity': 0,
        'returnedQuantity': 0,
        'inventoryAdjustment': 0,
        'currentQuantity': 7,
        'costPrice': 3.0,
        'totalInventoryCost': 21.0,
        'shop_id': 'shop-1',
      });
      await seedV14QueueRow(db, id: 'q-2', status: 'PENDING');

      await DatabaseHelper.runUpgradeToV15ForTest(db);

      final products = await db.query('products');
      expect(products.length, 1);
      expect(products.single['currentQuantity'], 7);
      expect(products.single['barcode'], 'BAR-V15-1');

      final queue = await db.query('sync_queue');
      expect(queue.length, 1);
      expect(queue.single['payload'], '{"name":"x"}');
    });
  });

  group('v15 fresh-create parity', () {
    test('fresh onCreate at v15 == create + upgrade-replay for Phase M tables',
        () async {
      final freshDb = await openUniqueDb();
      addTearDown(freshDb.close);
      await DatabaseHelper.runFreshOnCreateForTest(freshDb);

      final upgradedDb = await openUniqueDb();
      addTearDown(upgradedDb.close);
      // Create + real migration replay (historical upgrade end-state).
      await DatabaseHelper.runCreateDbForTest(upgradedDb);

      for (final table in ['sync_queue', 'conflict_audit']) {
        Future<List<String>> shape(Database d) async {
          final info = await d.rawQuery('PRAGMA table_info($table)');
          return info
              .map((r) => '${r['name']}:${r['type']}:${r['notnull']}')
              .toList()
            ..sort();
        }

        expect(await shape(freshDb), await shape(upgradedDb),
            reason: 'fresh v15 $table must equal upgraded $table');
      }

      final version = (await freshDb.rawQuery('PRAGMA user_version'))
          .single['user_version'];
      expect(version, DatabaseHelper.schemaVersion);
    });
  });

  group('conflict_audit durability (AU-1 / INV-M18)', () {
    late Database db;
    late ConflictAuditRepository repo;
    late SyncQueueRepository queueRepo;

    setUp(() async {
      db = await openUniqueDb();
      await DatabaseHelper.runCreateDbForTest(db);
      repo = ConflictAuditRepository(db);
      queueRepo = SyncQueueRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('record → resolve round-trip carries full evidence trail', () async {
      final id = await repo.recordConflict(
        shopId: 'shop-1',
        entityType: 'sale',
        entityId: 42,
        entityUuid: 'sale-uuid-1',
        productName: 'منتج أ',
        productBarcode: 'BAR-1',
        operation: 'CREATE',
        localBefore: {'currentQuantity': 5},
        localAfter: {'currentQuantity': 3},
        serverBefore: {'current_quantity': 4},
        serverAfter: {'current_quantity': 4},
        relatedEventIds: ['evt-1', 'evt-2'],
        localVersion: 3,
        serverVersion: 7,
        idempotencyKey:
            'sale:sale-uuid-1:CREATE:aaaaaaaa-bbbb-cccc-dddd-eeeeffff0000',
      );

      final record = (await repo.getById(id))!;
      expect(record.status, ConflictLifecycleStatus.REVIEW_REQUIRED);
      expect(record.shopId, 'shop-1');
      expect(record.localBefore, {'currentQuantity': 5});
      expect(record.serverAfter, {'current_quantity': 4});
      expect(record.relatedEventIds, ['evt-1', 'evt-2']);
      expect(record.localVersion, 3);
      expect(record.serverVersion, 7);
      expect(record.isTerminal, isFalse);

      await repo.markResolutionPending(id);
      expect((await repo.getById(id))!.status,
          ConflictLifecycleStatus.RESOLUTION_PENDING);

      await repo.markResolved(
        id,
        method: ConflictResolutionMethod.OWNER,
        resolvedByUser: 'owner-uuid',
        note: 'قبول قيمة المخزون من الخادم',
        resultingAdjustmentId: 99,
      );

      final resolved = (await repo.getById(id))!;
      expect(resolved.isTerminal, isTrue);
      expect(resolved.resolutionMethod, ConflictResolutionMethod.OWNER);
      expect(resolved.resolvedByUser, 'owner-uuid');
      expect(resolved.resolvedAt, isNotNull);
      expect(resolved.resultingAdjustmentId, 99);
    });

    test('double-resolve is rejected (transition-only records)', () async {
      final id = await repo.recordConflict(
        shopId: 'shop-1',
        entityType: 'product',
        entityId: 1,
        operation: 'UPDATE',
      );
      await repo.markResolved(id,
          method: ConflictResolutionMethod.AUTO, resolvedByUser: 'system');

      expect(
        () => repo.markResolved(id,
            method: ConflictResolutionMethod.POLICY, resolvedByUser: 'system'),
        throwsA(isA<StateError>()),
      );
    });

    test('audit survives cleanupSynced of the queue (INV-M18)', () async {
      await db.insert('sync_queue', {
        'id': 'sq-clean-1',
        'entity_type': 'product',
        'entity_id': 1,
        'operation': 'CREATE',
        'payload': null,
        'created_at': DateTime.now().toIso8601String(),
        'retry_count': 0,
        'status': 'SYNCED',
        'synced_at':
            DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
        'idempotency_key': 'k-clean-1',
        'shop_id': 'shop-1',
      });
      final auditId = await repo.recordConflict(
        shopId: 'shop-1',
        entityType: 'sale',
        entityId: 9,
        operation: 'CREATE',
        idempotencyKey: 'k-clean-1',
      );

      await queueRepo.cleanupSynced(olderThanDays: 7);

      final pending = await db.query('sync_queue');
      expect(pending, isEmpty, reason: 'queue row cleaned up');
      expect(await repo.getById(auditId), isNotNull,
          reason: 'audit evidence must outlive queue cleanup');
    });

    test('open-conflict queries are tenant-scoped (TA-1)', () async {
      await repo.recordConflict(
        shopId: 'shop-A',
        entityType: 'sale',
        entityId: 1,
        operation: 'CREATE',
      );
      await repo.recordConflict(
        shopId: 'shop-B',
        entityType: 'sale',
        entityId: 2,
        operation: 'CREATE',
      );

      final openA = await repo.getOpenConflicts(shopId: 'shop-A');
      expect(openA.map((r) => r.shopId), everyElement('shop-A'));
      expect(await repo.getOpenConflictCount(shopId: 'shop-B'), 1);
      expect(await repo.getOpenConflictCount(), 2);
    });
  });
}
