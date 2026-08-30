import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:muaman_store/config/app_config.dart';
import 'package:muaman_store/errors/cloud_data_exception.dart';
import 'package:muaman_store/services/session_state.dart';
import 'package:muaman_store/sync/conflict_audit_repository.dart';
import 'package:muaman_store/sync/sync_cloud_operations_transport.dart';
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
        String? idempotencyKey,
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
            String? idempotencyKey,
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

  // -------------------------------------------------------------------------
  // Phase P Group A — A2 drain wiring (production transport attachment)
  //
  // Proves that attaching the production SyncCloudOperationsTransport to
  // SyncRuntime.configure(cloudOperations:) makes the A1 transport genuinely
  // reachable by the real runtime, while the drain seam (AppConfig
  // .syncDrainEnabled == FALSE) keeps every gate fail-closed and performs
  // zero cloud calls. Wiring is NOT activation.
  // -------------------------------------------------------------------------
  group('A2 — production transport wiring (drain wiring, still dormant)', () {
    late A2RecordingRpc a2Rpc;

    setUp(() {
      a2Rpc = A2RecordingRpc();
    });

    // Mirrors the production factory seam used in main.dart: the runtime is
    // configured with the REAL SyncCloudOperationsTransport (A1) exposed via
    // toOperations(), with allowOversell enabled so the A3 Option C
    // reconciliation route stays reachable.
    SyncCloudOperations productionCloudOperations() =>
        SyncCloudOperationsTransport(rpc: a2Rpc.call, allowOversell: true)
            .toOperations();

    Future<void> enqueueSale({
      required String key,
      String shop = 'shop-1',
      String barcode = 'B1',
      int quantity = 2,
      double salePrice = 5.0,
    }) =>
        queueRepo.enqueue(
          entityType: 'sale',
          entityId: 1,
          operation: SyncQueueOperation.CREATE,
          payload: {
            'barcode': barcode,
            'quantity': quantity,
            'sale_price': salePrice,
            'date': '2026-08-20T00:00:00.000Z',
          },
          idempotencyKey: key,
          shopId: shop,
        );

    test(
        'T1 — the production factory seam resolves to the A1 transport and '
        'the runtime genuinely reaches its RPC seam', () async {
      final license =
          productionCloudOperations(); // building invokes zero RPC calls
      expect(a2Rpc.calls, isEmpty,
          reason: 'constructing/toOperations must never hit the network');

      final session = SessionState();
      final runtime = buildRuntime(
        sessionState: session,
        cloudOps: license,
        drainEnabled: true,
      );
      await enqueueSale(key: 't1-sale');

      await runtime.ensureStarted();
      expect(runtime.isRunning, isTrue);

      final result = await runtime.syncNow();
      expect(result, isNotNull);
      expect(a2Rpc.calls, isNotEmpty,
          reason: 'the drained queue entry must reach the wired A1 transport');
      final call = a2Rpc.calls.single;
      expect(call.name, 'create_cloud_sale_with_stock_v2');
      expect(call.params['p_shop_id'], 'shop-1',
          reason: 'persisted queue shop id is the operation authority');

      await runtime.stop();
      runtime.reset();
    });

    test(
        'T2 — DRAIN REMAINS OFF with cloudOps configured, queue, online, '
        'licensed, bound: AppConfig.syncDrainEnabled == FALSE ⇒ zero calls',
        () async {
      // The governed production posture: drainEnabled mirrors
      // AppConfig.syncDrainEnabled which MUST be FALSE in production.
      expect(AppConfig.syncDrainEnabled, isFalse,
          reason: 'the governed default flag must stay FALSE');

      final session = SessionState();
      final runtime = buildRuntime(
        sessionState: session,
        cloudOps: productionCloudOperations(),
        drainEnabled: false,
      );
      await enqueueSale(key: 't2-sale');

      await runtime.ensureStarted();

      expect(runtime.drainEnabled, isFalse);
      expect(runtime.isRunning, isFalse,
          reason: 'seam OFF ⇒ no worker even with the production transport');
      expect(a2Rpc.calls, isEmpty,
          reason: 'transport attached but drain flag FALSE ⇒ ZERO cloud calls');
      expect(await queueRepo.getPendingCount(shopId: 'shop-1'), 1,
          reason: 'the queued write stays durable');

      runtime.reset();
      expect(a2Rpc.calls, isEmpty);
    });

    test(
        'T3 — offline fail-closed: transport wired, drain ON, but offline ⇒ '
        'no cloud mutation, queue preserved', () async {
      final session = SessionState();
      final runtime = buildRuntime(
        sessionState: session,
        cloudOps: productionCloudOperations(),
        drainEnabled: true,
        connectivityCheck: () async => false,
      );
      await enqueueSale(key: 't3-sale');

      await runtime.ensureStarted();
      expect(runtime.isRunning, isTrue);

      final result = await runtime.syncNow();
      expect(result, isNull, reason: 'offline cycle skipped by the worker');
      expect(a2Rpc.calls, isEmpty,
          reason: 'offline ⇒ no cloud mutation via the wired transport');
      expect(await queueRepo.getPendingCount(shopId: 'shop-1'), 1,
          reason: 'queue preserved offline');

      await runtime.stop();
      runtime.reset();
    });

    test(
        'T4 — license fail-closed: transport wired, drain ON, but unlicensed '
        '⇒ no drain', () async {
      final session = SessionState();
      final runtime = buildRuntime(
        sessionState: session,
        cloudOps: productionCloudOperations(),
        drainEnabled: true,
        licenseCheck: () async => false,
      );
      await enqueueSale(key: 't4-sale');

      await runtime.ensureStarted();

      expect(runtime.isRunning, isFalse, reason: 'license gate closed');
      expect(a2Rpc.calls, isEmpty,
          reason: 'unlicensed ⇒ no cloud mutation via the wired transport');
      expect(logs.any((l) => l.contains('unlicensed')), isTrue);

      runtime.reset();
    });

    test(
        'T5 — unbound fail-closed: transport wired, drain ON, but no bound '
        'shop ⇒ no drain', () async {
      final session = SessionState();
      final runtime = buildRuntime(
        sessionState: session,
        cloudOps: productionCloudOperations(),
        drainEnabled: true,
        shopIdProvider: () async => null,
      );
      await enqueueSale(key: 't5-sale');

      await runtime.ensureStarted();

      expect(runtime.isRunning, isFalse, reason: 'no bound shop');
      expect(runtime.boundShopId, isNull);
      expect(a2Rpc.calls, isEmpty,
          reason: 'unbound ⇒ no cloud mutation via the wired transport');

      runtime.reset();
    });

    test(
        'T6 — tenant mismatch fail-closed: a queued entry for another shop_id '
        'is never drained under the ambient/bound shop', () async {
      final session = SessionState();
      final runtime = buildRuntime(
        sessionState: session,
        cloudOps: productionCloudOperations(),
        drainEnabled: true,
      );
      // Bound runtime is shop-1; the queued write belongs to shop-2.
      await enqueueSale(key: 't6-other', shop: 'shop-2');
      await enqueueSale(key: 't6-bound', shop: 'shop-1');

      await runtime.ensureStarted();
      await runtime.syncNow();

      expect(a2Rpc.names.where((n) => n == 'create_cloud_sale_with_stock_v2'),
          hasLength(1),
          reason: 'only the bound shop-1 entry is drained');
      expect(a2Rpc.calls.single.params['p_shop_id'], 'shop-1',
          reason: 'the shop-2 entry is never executed under the bound shop');
      expect(await queueRepo.getPendingCount(shopId: 'shop-2'), 1,
          reason: 'the other-tenant entry stays durable, untouched');

      await runtime.stop();
      runtime.reset();
    });

    test('T7 — repeated configure/ensureStarted does not duplicate workers',
        () async {
      final session = SessionState();
      final runtime = buildRuntime(
        sessionState: session,
        cloudOps: productionCloudOperations(),
        drainEnabled: true,
      );
      await enqueueSale(key: 't7-sale');

      await runtime.ensureStarted();
      final firstWorker = runtime.isRunning;

      // Re-running configure (as the app does on every session re-establish)
      // must not spawn a second worker.
      runtime.configure(
        database: db,
        queueRepository: queueRepo,
        conflictAuditRepository: auditRepo,
        adapters: buildStandardAdapters(),
        cloudOperations: productionCloudOperations(),
        sessionState: session,
        shopIdProvider: () async => 'shop-1',
        licenseCheck: () async => true,
        logger: (msg) async => logs.add(msg),
        drainEnabled: true,
        interval: const Duration(hours: 1),
      );
      await runtime.ensureStarted();

      expect(firstWorker, isTrue);
      expect(runtime.isRunning, isTrue,
          reason: 'idempotent re-provision keeps the single drain worker');

      final result = await runtime.syncNow();
      expect(result!.processed, 1,
          reason: 'one worker processes the queue exactly once');

      await runtime.stop();
      runtime.reset();
    });

    test(
        'T8 — A3 stockAdjustment route remains dormant-but-reachable through '
        'the wired production transport', () async {
      // A registered stockAdjustment queue entry must route, via the wired
      // production transport, to the A4 owner-gated adjustment RPC with the
      // persisted shop id — without any transport regression and without
      // fabricating a product identity.
      final session = SessionState();
      final runtime = buildRuntime(
        sessionState: session,
        cloudOps: productionCloudOperations(),
        drainEnabled: true,
      );
      await queueRepo.enqueue(
        entityType: 'stockAdjustment',
        entityId: 1,
        operation: SyncQueueOperation.CREATE,
        payload: {
          'product_id': 'prod-1',
          'projected_current': 5,
          'shortfall': 2,
          'adjustment_type': 'OVERSOLD',
          'sale_id': 'sale-1',
          'notes': null,
        },
        idempotencyKey: 't8-adjust',
        shopId: 'shop-1',
      );

      await runtime.ensureStarted();
      final result = await runtime.syncNow();
      expect(result, isNotNull);

      final calls =
          a2Rpc.calls.where((c) => c.name == 'create_cloud_stock_adjustment');
      expect(calls, hasLength(1),
          reason:
              'A3 adjustment route is reachable through the wired transport');
      expect(calls.single.params['p_shop_id'], 'shop-1');
      expect(calls.single.params['p_product_id'], 'prod-1',
          reason: 'the governed product identity is used verbatim');

      await runtime.stop();
      runtime.reset();
    });
  });
}

/// Records real transport RPC invocations (A2 fixtures). Mirror of the A1
/// contract fixture so the A2 wiring tests assert against the actual A1
/// transport's routing — not a stub cloudOps.
class A2RecordingRpc {
  final List<({String name, Map<String, dynamic> params})> calls = [];

  List<String> get names => calls.map((c) => c.name).toList();

  Future<dynamic> call(String function, Map<String, dynamic> params) async {
    calls.add((name: function, params: Map<String, dynamic>.from(params)));
    if (function.contains('_v2') || function.startsWith('save_cloud')) {
      return <String, dynamic>{
        'status': 'SYNCED',
        'id': 'server-uuid',
        'current_quantity': 0,
        'server_version': 1,
      };
    }
    if (function.startsWith('create_cloud_')) return 'server-uuid';
    return true;
  }
}
