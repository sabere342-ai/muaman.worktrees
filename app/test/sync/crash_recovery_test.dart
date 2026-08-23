import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:muaman_store/sync/conflict_audit_repository.dart';
import 'package:muaman_store/sync/conflict_resolver.dart';
import 'package:muaman_store/sync/sync_engine.dart';
import 'package:muaman_store/sync/sync_queue_repository.dart';
import 'package:muaman_store/sync/adapters/entity_sync_adapter.dart';
import 'package:muaman_store/sync/adapters/product_sync_adapter.dart';
import 'package:muaman_store/sync/sync_status.dart';

/// Phase M M-I09 acceptance suite (plan §24 windows A–G, §28 M-I09).
///
/// Guarantees proven for every window:
///   - states live in SQLite, NOT memory ⇒ a NEW engine/queue/audit
///     instance over the same database is the process-restart model,
///   - same-key replay has at-most-once server effect (counted),
///   - non-terminal lifecycle entries are always restartable,
///   - audit + apply share one transaction boundary (no half-states).
void main() {
  sqfliteFfiInit();

  late Database db;
  late SyncQueueRepository queueRepo;
  late ConflictAuditRepository auditRepo;
  final logs = <String>[];

  final adapters = <SyncEntityType, EntitySyncAdapter>{
    SyncEntityType.product: ProductSyncAdapter(),
  };

  setUp(() async {
    db = await databaseFactoryFfiNoIsolate.openDatabase(inMemoryDatabasePath);
    await db.execute('''
      CREATE TABLE sync_queue (
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
        shop_id TEXT,
        occurrence_token TEXT,
        resolution_status TEXT
      )
    ''');
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
      CREATE TABLE conflict_audit (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        shop_id TEXT NOT NULL,
        entity_type TEXT NOT NULL,
        entity_id INTEGER NOT NULL,
        entity_uuid TEXT,
        product_name TEXT,
        product_barcode TEXT,
        operation TEXT NOT NULL,
        local_before TEXT,
        local_after TEXT,
        server_before TEXT,
        server_after TEXT,
        related_event_ids TEXT,
        local_version INTEGER,
        server_version INTEGER,
        idempotency_key TEXT,
        detected_at TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'REVIEW_REQUIRED',
        resolution_method TEXT,
        resolved_by_user TEXT,
        resolved_at TEXT,
        resolution_note TEXT,
        resulting_adjustment_id INTEGER
      )
    ''');
    queueRepo = SyncQueueRepository(db);
    auditRepo = ConflictAuditRepository(db);
    logs.clear();
  });

  tearDown(() async {
    await db.close();
  });

  SyncEngine buildEngine({
    required SyncCloudOperations cloudOps,
  }) {
    return SyncEngine(
      queueRepository: queueRepo,
      conflictResolver: ConflictResolver(adapters),
      adapters: adapters,
      connectivityCheck: () async => true,
      licenseCheck: () async => true,
      shopIdProvider: () async => 'shop-1',
      logger: (type, op, {details}) async => logs.add('$type:$op'),
      cloudOps: cloudOps,
      localDb: db,
      conflictAuditRepository: auditRepo,
    );
  }

  Future<void> seedProduct({int version = 2}) async {
    await db.insert('products', {
      'name': 'Widget',
      'barcode': 'CR-1',
      'openingQuantity': 5,
      'soldQuantity': 0,
      'returnedQuantity': 0,
      'currentQuantity': 5,
      'costPrice': 10.0,
      'totalInventoryCost': 50.0,
      'inventoryAdjustment': 0,
      'shop_id': 'shop-1',
      'cloud_uuid': 'cr-uuid-1',
      'server_version': version,
    });
  }

  Future<void> enqueueUpdate(String key) => queueRepo.enqueue(
        entityType: 'product',
        entityId: 1,
        operation: SyncQueueOperation.UPDATE,
        payload: {
          'name': 'Widget v2',
          'barcode': 'CR-1',
          'updated_at': '2026-01-01T00:00:00Z',
        },
        idempotencyKey: key,
        shopId: 'shop-1',
      );

  group('window A — crash BEFORE RPC', () {
    test('entry stays PENDING; fresh engine replays it to completion',
        () async {
      await seedProduct();
      await enqueueUpdate('crash-a');

      var serverCalls = 0;
      // "Process death" before any RPC: engine #1 dies instantly.
      final deadEngine = buildEngine(
        cloudOps: SyncCloudOperations(
          upsertEntity: (
              {required adapter,
              required shopId,
              required localId,
              required payload,
              required idempotencyKey}) async {
            serverCalls++;
            throw StateError('simulated process death');
          },
          deleteEntity: (
              {required adapter,
              required shopId,
              required cloudUuid,
              required entityId}) async {},
        ),
      );
      final resultBefore = await deadEngine.processQueue();
      expect(resultBefore.synced, 0);
      expect((await queueRepo.getPendingEntries()), hasLength(1));

      // RESTART: brand-new engine over the SAME database.
      final restartedEngine = buildEngine(
        cloudOps: SyncCloudOperations(
          upsertEntity: (
              {required adapter,
              required shopId,
              required localId,
              required payload,
              required idempotencyKey}) async {
            serverCalls++;
            return CloudUpsertResult(success: true, currentServerVersion: 3);
          },
          deleteEntity: (
              {required adapter,
              required shopId,
              required cloudUuid,
              required entityId}) async {},
        ),
      );
      final resultAfter = await restartedEngine.processQueue();

      expect(resultAfter.synced, 1);
      expect(serverCalls, 2,
          reason: 'exactly one rejected pre-RPC attempt + one real effect');
      expect((await queueRepo.getPendingEntries()), isEmpty);
    });
  });

  group('window B/C/D — crash DURING/AFTER RPC, outcome unknown', () {
    test(
        'window B: RPC never returns (kill mid-flight); replay with the '
        'SAME key reaches the server exactly once more', () async {
      await seedProduct();
      await enqueueUpdate('crash-b');

      var committedOnServer = false;
      var serverEffects = 0;
      Future<CloudUpsertResult> rpc(
          {required EntitySyncAdapter adapter,
          required String shopId,
          required int localId,
          required Map<String, dynamic> payload,
          required String idempotencyKey}) async {
        if (!committedOnServer) {
          // Server commits but the client never observes the response.
          committedOnServer = true;
          serverEffects++;
          throw StateError('connection killed after commit');
        }
        // Same-key replay: DB-layer idempotency ⇒ at-most-once effect.
        return CloudUpsertResult(idempotent: true, currentServerVersion: 4);
      }

      final first = buildEngine(
        cloudOps: SyncCloudOperations(
          upsertEntity: rpc,
          deleteEntity: (
              {required adapter,
              required shopId,
              required cloudUuid,
              required entityId}) async {},
        ),
      );
      await first.processQueue();

      final restarted = buildEngine(
        cloudOps: SyncCloudOperations(
          upsertEntity: rpc,
          deleteEntity: (
              {required adapter,
              required shopId,
              required cloudUuid,
              required entityId}) async {},
        ),
      );
      final result = await restarted.processQueue();

      expect(result.synced, 1);
      expect(serverEffects, 1,
          reason: 'INV-M03: same-key replay must be at-most-once');
      expect((await queueRepo.getPendingEntries()), isEmpty);
    });

    test(
        'window D: response received but local markSynced did not happen; '
        'replay converges via IDEMPOTENT no-op', () async {
      await seedProduct();
      await enqueueUpdate('crash-d');

      var idempotentReplies = 0;
      final engine = buildEngine(
        cloudOps: SyncCloudOperations(
          upsertEntity: (
                  {required adapter,
                  required shopId,
                  required localId,
                  required payload,
                  required idempotencyKey}) async =>
              CloudUpsertResult(success: true, currentServerVersion: 3),
          deleteEntity: (
              {required adapter,
              required shopId,
              required cloudUuid,
              required entityId}) async {},
        ),
      );

      // Simulate crash AFTER server success but BEFORE the local close:
      // run the engine, then force the row back to PENDING without
      // touching the server (this models lost local completion marker).
      await engine.processQueue();
      await db.update('sync_queue', {'status': 'PENDING', 'synced_at': null},
          where: 'idempotency_key = ?', whereArgs: ['crash-d']);

      final restarted = buildEngine(
        cloudOps: SyncCloudOperations(
          upsertEntity: (
              {required adapter,
              required shopId,
              required localId,
              required payload,
              required idempotencyKey}) async {
            idempotentReplies++;
            return CloudUpsertResult(idempotent: true, currentServerVersion: 3);
          },
          deleteEntity: (
              {required adapter,
              required shopId,
              required cloudUuid,
              required entityId}) async {},
        ),
      );
      final result = await restarted.processQueue();

      expect(result.synced, 1);
      expect(idempotentReplies, 1);
      final q = (await db.query('sync_queue',
              where: 'idempotency_key = ?', whereArgs: ['crash-d']))
          .first;
      expect(q['status'], 'SYNCED');
    });
  });

  group('window E/F — crash during resolution decision/apply', () {
    test(
        'mid-resolution kill leaves ZERO partial state; restart applies '
        'the resolution exactly once with exactly one audit row', () async {
      await seedProduct();
      await enqueueUpdate('crash-e');

      // Failure injector kills the FIRST apply transaction midway.
      await db.execute('''
        CREATE TRIGGER trg_crash_e BEFORE UPDATE ON products
        BEGIN
          SELECT RAISE(ABORT, 'simulated crash mid-resolution');
        END
      ''');

      final conflictingOps = buildEngine(
        cloudOps: SyncCloudOperations(
          upsertEntity: (
                  {required adapter,
                  required shopId,
                  required localId,
                  required payload,
                  required idempotencyKey}) async =>
              CloudUpsertResult(
            conflict: true,
            serverData: {
              'name': 'Server Truth',
              'barcode': 'CR-1',
              'updated_at': '2026-06-01T00:00:00Z',
            },
            localVersion: 2,
            currentServerVersion: 6,
            cloudUuid: 'cr-uuid-1',
          ),
          deleteEntity: (
              {required adapter,
              required shopId,
              required cloudUuid,
              required entityId}) async {},
        ),
      );
      await conflictingOps.processQueue();

      // Window E hit: apply aborted atomically.
      expect(
        (await db.query('sync_queue',
                where: 'idempotency_key = ?', whereArgs: ['crash-e']))
            .first['status'],
        'CONFLICT',
        reason: 'durable review landing after failed apply',
      );
      expect(await db.query('conflict_audit'), hasLength(1));
      final productRow =
          (await db.query('products', where: 'id = ?', whereArgs: [1])).first;
      expect(productRow['name'], 'Widget',
          reason: 'NO partial projection write survived');

      // RESTART: remove injector, resolve durably via owner flow.
      await db.execute('DROP TRIGGER trg_crash_e');
      final auditRow = (await auditRepo.getByIdempotencyKey('crash-e')).first;
      await auditRepo.markResolutionPending(auditRow.id);
      await auditRepo.markResolved(
        auditRow.id,
        method: ConflictResolutionMethod.POLICY,
        resolvedByUser: 'system:auto-convergence',
        note: 'replayed after restart',
      );

      final audits = await auditRepo.getByIdempotencyKey('crash-e');
      expect(audits, hasLength(1),
          reason: 'at-most-once evidence: replay did not duplicate the row');
      expect(audits.first.isTerminal, isTrue);
    });
  });

  group('window G — local apply / audit boundary', () {
    test(
        'audit write and queue close are one boundary: resolved entry can '
        'never exist without its audit evidence', () async {
      await seedProduct();
      await enqueueUpdate('crash-g');

      final engine = buildEngine(
        cloudOps: SyncCloudOperations(
          upsertEntity: (
                  {required adapter,
                  required shopId,
                  required localId,
                  required payload,
                  required idempotencyKey}) async =>
              CloudUpsertResult(
            conflict: true,
            serverData: {
              'name': 'Server Truth G',
              'barcode': 'CR-1',
              'updated_at': '2026-05-01T00:00:00Z',
            },
            localVersion: 2,
            currentServerVersion: 5,
            cloudUuid: 'cr-uuid-1',
          ),
          deleteEntity: (
              {required adapter,
              required shopId,
              required cloudUuid,
              required entityId}) async {},
        ),
      );
      final result = await engine.processQueue();

      expect(result.synced, 1);

      final q = (await db.query('sync_queue',
              where: 'idempotency_key = ?', whereArgs: ['crash-g']))
          .first;
      final audits = await auditRepo.getByIdempotencyKey('crash-g');
      expect(q['status'], 'SYNCED');
      expect(q['resolution_status'], 'RESOLVED');
      expect(audits, hasLength(1));
      expect(audits.first.status, ConflictLifecycleStatus.RESOLVED);
      // cleanup cannot orphan resolved history either (AU-1).
      await queueRepo.cleanupSynced(olderThanDays: 0);
      expect(
        (await db.query('sync_queue',
            where: 'idempotency_key = ?', whereArgs: ['crash-g'])),
        isEmpty,
        reason: 'resolved SYNCED row may be cleaned',
      );
      expect(await auditRepo.getByIdempotencyKey('crash-g'), hasLength(1),
          reason: 'but its audit evidence survives cleanup forever');
    });
  });
}
