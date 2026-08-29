import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:muaman_store/errors/cloud_data_exception.dart';
import 'package:muaman_store/services/session_state.dart';
import 'package:muaman_store/sync/conflict_audit_repository.dart';
import 'package:muaman_store/sync/sync_engine.dart';
import 'package:muaman_store/sync/sync_queue_repository.dart';
import 'package:muaman_store/sync/sync_runtime.dart';
import 'package:muaman_store/sync/sync_status.dart';

/// Phase P WS-1 acceptance harness (plan F.2.9 / §M.1).
///
/// Exercises the application-owned sync runtime as production wiring would:
/// session-establishment gating, the drain seam (shipping posture OFF by
/// default), bounded-retries queue drain, status publication and the
/// startup crash-recovery sweep.
void main() {
  sqfliteFfiInit();

  late Database db;
  late SyncQueueRepository queueRepo;
  late ConflictAuditRepository auditRepo;
  final logs = <String>[];

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

  SyncRuntime buildRuntime({
    required SessionState sessionState,
    required SyncCloudOperations cloudOps,
    bool drainEnabled = false,
    Future<bool> Function()? licenseCheck,
    Future<String?> Function()? shopIdProvider,
    Future<bool> Function()? connectivityCheck,
  }) {
    final runtime = SyncRuntime();
    runtime.configure(
      database: db,
      queueRepository: queueRepo,
      conflictAuditRepository: auditRepo,
      adapters: buildStandardAdapters(),
      cloudOperations: cloudOps,
      sessionState: sessionState,
      shopIdProvider: shopIdProvider ?? (() async => 'shop-1'),
      licenseCheck: licenseCheck ?? (() async => true),
      connectivityCheck: connectivityCheck ?? (() async => true),
      logger: (msg) async => logs.add(msg),
      drainEnabled: drainEnabled,
      interval: const Duration(hours: 1),
    );
    return runtime;
  }

  SyncCloudOperations countingOps({required int Function() upserts}) {
    return SyncCloudOperations(
      upsertEntity: ({
        required adapter,
        required shopId,
        required localId,
        required payload,
        required idempotencyKey,
      }) async {
        upserts();
        return CloudUpsertResult(success: true, currentServerVersion: 1);
      },
      deleteEntity: ({
        required adapter,
        required shopId,
        required cloudUuid,
        required entityId,
      }) async {},
    );
  }

  Future<void> enqueue({required String key, String shop = 'shop-1'}) =>
      queueRepo.enqueue(
        entityType: 'product',
        entityId: 1,
        operation: SyncQueueOperation.CREATE,
        payload: {'name': 'Widget', 'barcode': 'B-$key'},
        idempotencyKey: key,
        shopId: shop,
      );

  group('WS-1 gating — the runtime must never run for a tenant it must not',
      () {
    test('offline-only tenant (no bound shop) fails closed: zero network',
        () async {
      var networkCalls = 0;
      final session = SessionState();
      final runtime = buildRuntime(
        sessionState: session,
        cloudOps: countingOps(upserts: () => networkCalls++),
        drainEnabled: true,
        shopIdProvider: () async => null,
      );

      await runtime.ensureStarted();

      expect(runtime.isRunning, isFalse);
      expect(runtime.boundShopId, isNull);
      expect(networkCalls, 0,
          reason: 'no bound shop ⇒ no drain, even when the seam is ON');
      expect(session.pendingSyncCount, 0);
    });

    test('unlicensed tenant never starts the drain', () async {
      var networkCalls = 0;
      final session = SessionState();
      final runtime = buildRuntime(
        sessionState: session,
        cloudOps: countingOps(upserts: () => networkCalls++),
        drainEnabled: true,
        licenseCheck: () async => false,
      );

      await runtime.ensureStarted();

      expect(runtime.isRunning, isFalse);
      expect(networkCalls, 0);
      expect(logs.any((l) => l.contains('unlicensed')), isTrue);
    });

    test('no cloud operations wired ⇒ fail-safe, nothing starts', () async {
      final session = SessionState();
      final runtime = buildRuntime(
        sessionState: session,
        cloudOps: countingOps(upserts: () => fail('must not be invoked')),
      );
      // Override the configured ops to null to prove the fail-safe path.
      runtime.reset();
      runtime.configure(
        database: db,
        queueRepository: queueRepo,
        adapters: buildStandardAdapters(),
        sessionState: session,
        shopIdProvider: () async => 'shop-1',
        licenseCheck: () async => true,
        logger: (msg) async => logs.add(msg),
        drainEnabled: true,
        interval: const Duration(hours: 1),
      );

      await runtime.ensureStarted();

      expect(runtime.isRunning, isFalse);
      expect(logs.any((l) => l.contains('no SyncCloudOperations')), isTrue);
    });
  });

  group('WS-1 shipping posture — drain seam OFF', () {
    test('runtime manages and publishes status, performs zero network calls',
        () async {
      var networkCalls = 0;
      final session = SessionState();
      final runtime = buildRuntime(
        sessionState: session,
        cloudOps: countingOps(upserts: () => networkCalls++),
        drainEnabled: false,
      );

      await enqueue(key: 'off-1');
      await enqueue(key: 'off-2');
      await db.update(
          'sync_queue',
          {
            'status': 'FAILED',
            'retry_count': 6,
          },
          where: 'idempotency_key = ?',
          whereArgs: ['off-1']);
      await db.update(
          'sync_queue',
          {
            'status': 'CONFLICT',
          },
          where: 'idempotency_key = ?',
          whereArgs: ['off-2']);

      await runtime.ensureStarted();

      expect(runtime.isRunning, isFalse, reason: 'seam OFF ⇒ no worker');
      expect(runtime.drainEnabled, isFalse);
      expect(networkCalls, 0,
          reason: 'seam OFF ⇒ zero cloud calls even with a bound shop');
      expect(session.pendingSyncCount, 0);
      expect(session.failedSyncCount, 1);
      expect(session.conflictSyncCount, 1);
    });
  });

  group('WS-1 enabled drain', () {
    test('queue drains with bounded retries and counters publish', () async {
      var networkCalls = 0;
      final session = SessionState();
      final runtime = buildRuntime(
        sessionState: session,
        cloudOps: SyncCloudOperations(
          upsertEntity: ({
            required adapter,
            required shopId,
            required localId,
            required payload,
            required idempotencyKey,
          }) async {
            networkCalls++;
            if (idempotencyKey == 'doomed') {
              throw CloudDataException(
                  type: CloudDataErrorType.serverError, message: 'boom');
            }
            return CloudUpsertResult(success: true, currentServerVersion: 1);
          },
          deleteEntity: ({
            required adapter,
            required shopId,
            required cloudUuid,
            required entityId,
          }) async {},
        ),
        drainEnabled: true,
      );

      await enqueue(key: 'ok-1');
      await enqueue(key: 'ok-2');
      // A retry-exhausted entry (retry_count already at the bound) must be
      // terminal FAILED after one cycle — bounded retries contract.
      await db.insert('sync_queue', {
        'id': 'sq-doomed',
        'entity_type': 'product',
        'entity_id': 1,
        'operation': 'CREATE',
        'payload': '{"name":"Doomed","barcode":"B-doomed"}',
        'created_at': DateTime.now()
            .subtract(const Duration(minutes: 20))
            .toIso8601String(),
        'retry_count': 5,
        'status': 'PENDING',
        'idempotency_key': 'doomed',
        'shop_id': 'shop-1',
      });

      expect(await queueRepo.getPendingCount(shopId: 'shop-1'), 3);

      await runtime.ensureStarted();
      expect(runtime.isRunning, isTrue);

      final result = await runtime.syncNow();

      expect(result, isNotNull);
      expect(result!.processed, 3);
      expect(result.synced, 2);
      expect(result.failed, 1);
      expect(await queueRepo.getPendingCount(shopId: 'shop-1'), 0);
      expect(await queueRepo.getFailedCount(shopId: 'shop-1'), 1);
      expect(networkCalls, 3);

      expect(session.pendingSyncCount, 0);
      expect(session.failedSyncCount, 1);
      expect(session.lastSyncedAt, isNotNull,
          reason: 'lastSyncedAt set after a cycle with synced>0');

      await runtime.stop();
      expect(runtime.isRunning, isFalse);

      runtime.reset();
    });

    test('offline worker defers the drain but keeps status live', () async {
      var networkCalls = 0;
      final session = SessionState();
      final runtime = buildRuntime(
        sessionState: session,
        cloudOps: countingOps(upserts: () => networkCalls++),
        drainEnabled: true,
        connectivityCheck: () async => false,
      );

      await enqueue(key: 'stays-pending');
      await runtime.ensureStarted();

      final result = await runtime.syncNow();
      expect(result, isNull, reason: 'offline cycle skipped');
      expect(networkCalls, 0);
      expect(await queueRepo.getPendingCount(shopId: 'shop-1'), 1);
      expect(session.pendingSyncCount, 1,
          reason: 'status reflects the deferred queue state');

      await runtime.stop();
      runtime.reset();
    });

    test('recovery sweep re-drives RESOLUTION_PENDING audits on start',
        () async {
      var networkCalls = 0;
      final session = SessionState();
      // Two non-terminal audits: one stuck RESOLUTION_PENDING (crashed
      // apply), one REVIEW_REQUIRED (correctly awaited).
      await auditRepo.recordConflict(
        shopId: 'shop-1',
        entityType: 'product',
        entityId: 1,
        operation: 'UPDATE',
        idempotencyKey: 'stuck',
      );
      final stuckId = (await auditRepo.getByIdempotencyKey('stuck')).first.id;
      await auditRepo.recordConflict(
        shopId: 'shop-1',
        entityType: 'product',
        entityId: 2,
        operation: 'UPDATE',
        idempotencyKey: 'open',
      );
      await auditRepo.markResolutionPending(stuckId);

      final runtime = buildRuntime(
        sessionState: session,
        cloudOps: countingOps(upserts: () => networkCalls++),
        drainEnabled: true,
      );

      await runtime.ensureStarted();
      // The startup sweep is fired fire-and-forget from worker.start().
      await Future<void>.delayed(const Duration(milliseconds: 80));
      await runtime.stop();

      final stuck = (await auditRepo.getByIdempotencyKey('stuck')).first;
      final open = (await auditRepo.getByIdempotencyKey('open')).first;
      expect(stuck.status, ConflictLifecycleStatus.REVIEW_REQUIRED,
          reason: 'crashed RESOLUTION_PENDING re-driven to review');
      expect(open.status, ConflictLifecycleStatus.REVIEW_REQUIRED,
          reason: 'REVIEW_REQUIRED stays untouched');

      runtime.reset();
    });
  });
}
