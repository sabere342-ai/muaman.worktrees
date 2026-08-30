import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:muaman_store/config/app_config.dart';
import 'package:muaman_store/errors/cloud_data_exception.dart';
import 'package:muaman_store/services/session_state.dart';
import 'package:muaman_store/sync/sync_engine.dart';
import 'package:muaman_store/sync/sync_queue_repository.dart';
import 'package:muaman_store/sync/sync_runtime.dart';
import 'package:muaman_store/sync/sync_status.dart';

/// Phase P Group A — A6 observability (truthful status + retry/reconnect).
///
/// Proves the truthfulness guarantees:
///   T1  pending is never reported as fully synced
///   T2  failed is never reported as synced
///   T3  conflict is never reported as synced
///   T4  true convergence may be reported as success
///   T5  lastSyncedAt is truthful (only advances on real convergence)
///   T6  offline/cloud-valid-but-not-reconciling is never "fully synced"
///   T7  retry/reconnect preserves every gate
///   T8  drain OFF stays dormant (retry cannot hide a cloud mutation)
///   T9  retry can re-evaluate without duplicate workers/processing
///   T10 session/tenant lifecycle resets stale status
void main() {
  sqfliteFfiInit();

  late Database db;
  late SyncQueueRepository queueRepo;
  late SessionState session;
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
    queueRepo = SyncQueueRepository(db);
    session = SessionState();
    logs.clear();
  });

  tearDown(() async {
    await db.close();
  });

  SyncRuntime buildRuntime({
    bool drainEnabled = false,
    SyncCloudOperations? cloudOps,
    Future<bool> Function()? licenseCheck,
    Future<bool> Function()? connectivityCheck,
    Future<String?> Function()? shopIdProvider,
  }) {
    final runtime = SyncRuntime();
    runtime.configure(
      database: db,
      queueRepository: queueRepo,
      adapters: buildStandardAdapters(),
      cloudOperations: cloudOps,
      sessionState: session,
      shopIdProvider: shopIdProvider ?? (() async => 'shop-1'),
      licenseCheck: licenseCheck ?? (() async => true),
      connectivityCheck: connectivityCheck ?? (() async => true),
      logger: (msg) async => logs.add(msg),
      drainEnabled: drainEnabled,
      interval: const Duration(hours: 1),
    );
    return runtime;
  }

  SyncCloudOperations successOps({void Function()? onUpsert}) {
    return SyncCloudOperations(
      upsertEntity: ({
        required adapter,
        required shopId,
        required localId,
        required payload,
        required idempotencyKey,
      }) async {
        onUpsert?.call();
        return CloudUpsertResult(success: true, currentServerVersion: 1);
      },
      deleteEntity: ({
        required adapter,
        required shopId,
        required cloudUuid,
        required entityId,
        String? idempotencyKey,
      }) async {},
    );
  }

  Future<void> enqueue({
    required String key,
    String shop = 'shop-1',
    String status = 'PENDING',
    int retryCount = 0,
  }) =>
      queueRepo.enqueue(
        entityType: 'product',
        entityId: 1,
        operation: SyncQueueOperation.CREATE,
        payload: {'name': 'Widget', 'barcode': 'B-$key'},
        idempotencyKey: key,
        shopId: shop,
      ).then((_) async {
        if (status != 'PENDING' || retryCount != 0) {
          await db.update(
            'sync_queue',
            {
              'status': status,
              'retry_count': retryCount,
            },
            where: 'idempotency_key = ?',
            whereArgs: [key],
          );
        }
      });

  // -----------------------------------------------------------------------
  // T1/T2/T3 — failed/conflict/pending must never be presented as success.
  // The runtime publishes the raw authoritative counts; the "fully synced"
  // rendering is gated on the genuine converged condition (see also the
  // indicator widget tests).
  // -----------------------------------------------------------------------
  group('A6 truthful status — T1/T2/T3/T4/T6', () {
    test(
        'T1 — pending > 0 with zero failed/conflict must not be a converged '
        'state', () async {
      // Drain ON, armed, one pending entry that stays pending (offline cycle
      // defers it). pendingSyncCount must remain > 0, and drainActive true
      // alone must not be treated as convergence.
      final runtime = buildRuntime(
        drainEnabled: true,
        cloudOps: successOps(),
        connectivityCheck: () async => false,
      );
      await enqueue(key: 't1-pending');

      await runtime.ensureStarted();
      expect(runtime.isRunning, isTrue,
          reason: 'worker armed with the drain seam on');
      expect(session.drainActive, isTrue,
          reason: 'reconciliation engine is armed');

      await runtime.syncNow();
      expect(session.pendingSyncCount, 1,
          reason: 'offline deferred work stays pending — never success');
      expect(session.hasPendingSync, isTrue);

      // Truthfulness gate: pending implies NOT converged. drainActive alone is
      // insufficient to claim success (SessionState exposes the queue truth).
      expect(session.hasPendingSync && session.drainActive, isTrue);
      runtime.reset();
    });

    test('T2 — failed > 0 must indicate failure regardless of cloud link',
        () async {
      final runtime = buildRuntime(
        drainEnabled: true,
        cloudOps: successOps(),
      );
      await enqueue(key: 't2-failed', status: 'FAILED');

      await runtime.ensureStarted();
      expect(session.failedSyncCount, 1);
      expect(session.hasFailedSync, isTrue,
          reason: 'failed evidence must not be suppressed');
      runtime.reset();
    });

    test('T3 — conflict > 0 must indicate conflict, never success', () async {
      final runtime = buildRuntime(
        drainEnabled: true,
        cloudOps: successOps(),
      );
      await enqueue(key: 't3-conflict', status: 'CONFLICT');

      await runtime.ensureStarted();
      expect(session.conflictSyncCount, 1);
      expect(session.hasConflictSync, isTrue);
      runtime.reset();
    });

    test('T4 — true convergence is reported when evidence supports it',
        () async {
      final runtime = buildRuntime(drainEnabled: true, cloudOps: successOps());
      await enqueue(key: 't4-ok');

      await runtime.ensureStarted();
      final result = await runtime.syncNow();
      expect(result!.synced, 1);
      expect(session.pendingSyncCount, 0);
      expect(session.failedSyncCount, 0);
      expect(session.conflictSyncCount, 0);
      expect(session.lastSyncedAt, isNotNull,
          reason: 'a genuinely converged entry records a success timestamp');
      runtime.reset();
    });

    test('T6 — cloud-valid but drain inactive is NOT fully synced', () async {
      // Production posture: drain seam OFF. The session may be cloud-linked
      // with an empty queue, but reconciliation never ran, so "synced" must
      // not be claimed.
      expect(AppConfig.syncDrainEnabled, isFalse,
          reason: 'the governed production default stays FALSE');

      final runtime = buildRuntime(
        drainEnabled: false,
        cloudOps: successOps(),
      );

      await runtime.ensureStarted();
      expect(session.drainActive, isFalse,
          reason: 'drain seam OFF ⇒ no reconciliation capacity');
      expect(session.pendingSyncCount, 0);
      // The indicator derives "fully synced" ONLY when drainActive is true;
      // here it is false, so the converged-success gate is false (asserted by
      // the widget-level tests and the boolean below).
      expect(session.isReconciling, isFalse);
      // The truthful converged precondition is not met even though counts are
      // zero and the session is cloud-linked.
      expect(session.isReconciling && session.pendingSyncCount == 0, isFalse);
      runtime.reset();
    });

    test('T6b — drain off leaves queued work durable and unpromised', () async {
      final runtime = buildRuntime(
        drainEnabled: false,
        cloudOps: successOps(),
      );
      await enqueue(key: 't6b-queued');

      await runtime.ensureStarted();
      expect(runtime.isRunning, isFalse);
      expect(session.drainActive, isFalse);
      expect(session.pendingSyncCount, 1,
          reason: 'queued work is durable and surfaced, not hidden or claimed');
      runtime.reset();
    });
  });

  // -----------------------------------------------------------------------
  // T5 — lastSyncedAt truthfulness
  // -----------------------------------------------------------------------
  group('A6 lastSyncedAt truthfulness — T5', () {
    test('lastSyncedAt does NOT advance when everything fails', () async {
      final runtime = buildRuntime(
        drainEnabled: true,
        cloudOps: SyncCloudOperations(
          upsertEntity: ({
            required adapter,
            required shopId,
            required localId,
            required payload,
            required idempotencyKey,
          }) async {
            throw CloudDataException(
                type: CloudDataErrorType.serverError, message: 'boom');
          },
          deleteEntity: ({
            required adapter,
            required shopId,
            required cloudUuid,
            required entityId,
            String? idempotencyKey,
          }) async {},
        ),
      );
      await enqueue(key: 't5-fail');

      await runtime.ensureStarted();
      final result = await runtime.syncNow();
      expect(result!.processed, 1);
      expect(result.synced, 0);
      expect(result.failed, 1);
      expect(session.lastSyncedAt, isNull,
          reason: 'a cycle where only failures occurred must not fabricate a '
              'successful-sync timestamp (processed>0 is not success)');
      runtime.reset();
    });

    test('lastSyncedAt does NOT advance when cycle is skipped offline',
        () async {
      // Pre-seed a prior success timestamp to prove it is not overwritten by a
      // skipped/offline cycle.
      await enqueue(key: 't5b-prev');
      // Temporarily online to converge once.
      final onlineRuntime = buildRuntime(
        drainEnabled: true,
        cloudOps: successOps(),
      );
      await onlineRuntime.ensureStarted();
      await onlineRuntime.syncNow();
      expect(session.lastSyncedAt, isNotNull);

      // Now switch to an offline runnin runtime through a fresh harvest: use a
      // dedicated offline runtime with the same SessionState (runtime-level).
      final offlineRuntime = SyncRuntime();
      offlineRuntime.configure(
        database: db,
        queueRepository: queueRepo,
        adapters: buildStandardAdapters(),
        cloudOperations: successOps(),
        sessionState: session,
        shopIdProvider: () async => 'shop-1',
        licenseCheck: () async => true,
        connectivityCheck: () async => false,
        logger: (msg) async => logs.add(msg),
        drainEnabled: true,
        interval: const Duration(hours: 1),
      );
      await offlineRuntime.ensureStarted();
      final before = session.lastSyncedAt;
      final result = await offlineRuntime.syncNow();
      expect(result, isNull, reason: 'offline cycle skipped');
      expect(session.lastSyncedAt, before,
          reason: 'an offline no-op cycle must not refresh the sync timestamp');
      onlineRuntime.stop();
      onlineRuntime.reset();
      offlineRuntime.stop();
      offlineRuntime.reset();
    });

    test('lastSyncedAt ADVANCES on genuine convergence', () async {
      final runtime = buildRuntime(drainEnabled: true, cloudOps: successOps());
      await enqueue(key: 't5c-ok');
      await runtime.ensureStarted();
      expect(session.lastSyncedAt, isNull);
      final result = await runtime.syncNow();
      expect(result!.synced, 1);
      expect(session.lastSyncedAt, isNotNull,
          reason: 'a real success advances the truthful timestamp');
      runtime.reset();
    });
  });

  // -----------------------------------------------------------------------
  // T7/T8/T9 — retry/reconnect affordance
  // -----------------------------------------------------------------------
  group('A6 retry/reconnect affordance — T7/T8/T9', () {
    test('T8 — retry with drain OFF causes zero cloud calls, queue durable',
        () async {
      var networkCalls = 0;
      expect(AppConfig.syncDrainEnabled, isFalse);
      final runtime = buildRuntime(
        drainEnabled: false,
        cloudOps: successOps(onUpsert: () => networkCalls++),
      );
      await enqueue(key: 't8-queued');

      await runtime.ensureStarted();
      expect(runtime.drainEnabled, isFalse);
      expect(runtime.isRunning, isFalse);

      await runtime.retryNow();

      expect(networkCalls, 0,
          reason: 'retry with the production seam OFF must never cause a '
              'hidden cloud mutation');
      expect(session.drainActive, isFalse);
      expect(await queueRepo.getPendingCount(shopId: 'shop-1'), 1,
          reason: 'queued evidence remains durable after a gate-preserving '
              'retry');
      runtime.reset();
    });

    test('T7 — retry respects the license gate (no cloud calls)', () async {
      var networkCalls = 0;
      final runtime = buildRuntime(
        drainEnabled: true,
        cloudOps: successOps(onUpsert: () => networkCalls++),
        licenseCheck: () async => false,
      );
      await enqueue(key: 't7-unlicensed');

      await runtime.ensureStarted();
      expect(runtime.isRunning, isFalse);

      await runtime.retryNow();

      expect(networkCalls, 0,
          reason: 'license gate preserved — retry cannot bypass it');
      expect(runtime.isRunning, isFalse);
      runtime.reset();
    });

    test('T7b — retry respects the connectivity gate (no cloud calls)',
        () async {
      var networkCalls = 0;
      final runtime = buildRuntime(
        drainEnabled: true,
        cloudOps: successOps(onUpsert: () => networkCalls++),
        connectivityCheck: () async => false,
      );
      await enqueue(key: 't7b-offline');

      await runtime.ensureStarted();
      await runtime.retryNow();

      expect(networkCalls, 0,
          reason: 'connectivity gate preserved — offline retry cannot mutate');
      expect(await queueRepo.getPendingCount(shopId: 'shop-1'), 1);
      runtime.stop();
      runtime.reset();
    });

    test('T7c — retry respects the shop-binding gate (no cloud calls)',
        () async {
      var networkCalls = 0;
      final runtime = buildRuntime(
        drainEnabled: true,
        cloudOps: successOps(onUpsert: () => networkCalls++),
        shopIdProvider: () async => null,
      );
      await enqueue(key: 't7c-unbound', shop: 'shop-9');

      await runtime.ensureStarted();
      expect(runtime.boundShopId, isNull);

      await runtime.retryNow();

      expect(networkCalls, 0,
          reason: 'unbound retry must never drain any tenant');
      expect(session.drainActive, isFalse);
      runtime.reset();
    });

    test('T9 — retry after recovery re-evaluates without duplicate workers '
        'or duplicate processing', () async {
      var networkCalls = 0;
      var online = false;
      final runtime = buildRuntime(
        drainEnabled: true,
        cloudOps: successOps(onUpsert: () => networkCalls++),
        connectivityCheck: () async => online,
      );
      await enqueue(key: 't9-recover');

      // Start offline: worker armed, cycle deferred.
      await runtime.ensureStarted();
      expect(runtime.isRunning, isTrue);
      expect(session.pendingSyncCount, 1);

      // Connectivity recovers; retryNow must re-evaluate and drive exactly one
      // cycle on the SAME single worker.
      online = true;
      await runtime.retryNow();

      expect(runtime.isRunning, isTrue);
      expect(networkCalls, 1,
          reason: 'exactly one cycle on one worker — no duplicates');
      expect(session.pendingSyncCount, 0);
      expect(session.lastSyncedAt, isNotNull);

      runtime.stop();
      runtime.reset();
    });
  });

  // -----------------------------------------------------------------------
  // T10 — session/tenant lifecycle reset
  // -----------------------------------------------------------------------
  group('A6 session/tenant lifecycle — T10', () {
    test('logout resets sync status so one tenant never leaks to another',
        () async {
      final runtime = buildRuntime(drainEnabled: true, cloudOps: successOps());
      await enqueue(key: 't10-ok', shop: 'shop-1');
      await enqueue(key: 't10-fail', shop: 'shop-1', status: 'FAILED');

      await runtime.ensureStarted();
      await runtime.syncNow();
      expect(session.pendingSyncCount, 0);
      expect(session.failedSyncCount, 1);
      expect(session.lastSyncedAt, isNotNull);

      // Simulate the user logging out and switching tenants.
      runtime.stop();
      session.logout();

      expect(session.pendingSyncCount, 0);
      expect(session.failedSyncCount, 0);
      expect(session.conflictSyncCount, 0);
      expect(session.lastSyncedAt, isNull,
          reason: 'stale tenant sync status must never survive a session '
              'boundary');
      expect(session.drainActive, isFalse);
      runtime.reset();
    });

    test('tenant switch clears prior tenant evidence and resets status',
        () async {
      final runtime = buildRuntime(drainEnabled: true, cloudOps: successOps());
      await enqueue(key: 't10-a', shop: 'shop-1');
      await runtime.ensureStarted(shopId: 'shop-1');
      await runtime.syncNow();
      expect(session.lastSyncedAt, isNotNull);
      expect(runtime.boundShopId, 'shop-1');

      // Switch to shop-2: the runtime must tear down shop-1's worker and clear
      // its success evidence before provisioning shop-2.
      await enqueue(key: 't10-b', shop: 'shop-2');
      await runtime.ensureStarted(shopId: 'shop-2');

      expect(runtime.boundShopId, 'shop-2');
      expect(session.lastSyncedAt, isNull,
          reason: 'shop-1 last-synced evidence must not leak to shop-2');
      // shop-2 has its own pending work surfaced truthfully.
      expect(session.pendingSyncCount, 1,
          reason: 'shop-2 queue status is scoped to shop-2, not shop-1');
      expect(await queueRepo.getPendingCount(shopId: 'shop-1'), 0);
      expect(await queueRepo.getPendingCount(shopId: 'shop-2'), 1);
      runtime.reset();
    });
  });
}
