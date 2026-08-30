import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:muaman_store/sync/conflict_audit_repository.dart';
import 'package:muaman_store/sync/conflict_resolver.dart';
import 'package:muaman_store/sync/sync_engine.dart';
import 'package:muaman_store/sync/sync_queue_repository.dart';
import 'package:muaman_store/sync/hydration_service.dart';
import 'package:muaman_store/sync/incremental_sync_service.dart';
import 'package:muaman_store/sync/adapters/entity_sync_adapter.dart';
import 'package:muaman_store/sync/adapters/product_sync_adapter.dart';
import 'package:muaman_store/sync/adapters/sale_sync_adapter.dart';
import 'package:muaman_store/sync/sync_status.dart';
import 'package:muaman_store/sync/sync_worker.dart';

/// Phase M M-I05 acceptance suite (plan §28 M-I05, §29-N/O, §30).
///
/// Closes the §8-major gap: a server conflict used to end in LOG-ONLY
/// handling followed by markSynced (silent divergence). After M-I05 every
/// conflict REALLY applies (both directions) or lands in durable
/// REVIEW_REQUIRED — never log-and-forget — and hydration/pull protect
/// pending local intent from destructive authoritative overwrite (SG-1).
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
        last_synced_at TEXT,
        updatedAt TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
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
    Map<SyncEntityType, EntitySyncAdapter>? adapters,
  }) {
    final effectiveAdapters = adapters ??
        {
          SyncEntityType.product: ProductSyncAdapter(),
          SyncEntityType.sale: SaleSyncAdapter(),
        };
    return SyncEngine(
      queueRepository: queueRepo,
      conflictResolver: ConflictResolver(effectiveAdapters),
      adapters: effectiveAdapters,
      connectivityCheck: () async => true,
      licenseCheck: () async => true,
      shopIdProvider: () async => 'shop-1',
      logger: (type, op, {details}) async =>
          logs.add('$type:$op${details != null ? ' ($details)' : ''}'),
      cloudOps: cloudOps,
      localDb: db,
      conflictAuditRepository: auditRepo,
    );
  }

  Future<Map<String, dynamic>> queueRowByIdempotencyKey(String key) async {
    final rows = await db
        .query('sync_queue', where: 'idempotency_key = ?', whereArgs: [key]);
    return rows.first;
  }

  group('M-I05 convergence apply — server winner', () {
    test(
        'server-authoritative conflict REALLY applies locally: '
        'authoritative state + server_version adopted (never log-only)',
        () async {
      await db.insert('sales', {
        'date': '2026-08-20T10:00:00Z',
        'productName': 'Widget',
        'barcode': 'B-1',
        'quantity': 3,
        'salePrice': 50.0,
        'totalSaleValue': 150.0,
        'costPrice': 30.0,
        'cogs': 90.0,
        'shop_id': 'shop-1',
        'cloud_uuid': 'sale-uuid-1',
        'server_version': 2,
      });
      await queueRepo.enqueue(
        entityType: 'sale',
        entityId: 1,
        operation: SyncQueueOperation.UPDATE,
        payload: {
          'date': '2026-08-20T10:00:00Z',
          'product_name': 'Widget',
          'barcode': 'B-1',
          'quantity': 5,
          'sale_price': 50.0,
          'total_sale_value': 250.0,
          'cost_price': 30.0,
          'cogs': 150.0,
        },
        idempotencyKey: 'conv-sale-1',
        shopId: 'shop-1',
      );

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
            // Server-side correction of the money fields; quantity kept
            // identical so the event does not diverge (no review needed).
            serverData: {
              'date': '2026-08-20T10:00:00Z',
              'product_name': 'Widget (corrected)',
              'barcode': 'B-1',
              'quantity': 5,
              'sale_price': 45.0,
              'total_sale_value': 225.0,
              'cost_price': 30.0,
              'cogs': 135.0,
            },
            localVersion: 2,
            currentServerVersion: 7,
            cloudUuid: 'sale-uuid-1',
          ),
          deleteEntity: (
              {required adapter,
              required shopId,
              required cloudUuid,
              required entityId,
              String? idempotencyKey}) async {},
        ),
      );

      final result = await engine.processQueue();

      expect(result.synced, 1, reason: 'resolved conflict counts as synced');
      expect(result.conflicts, 0);

      // Local projection ACTUALLY adopted the authoritative server state.
      final row =
          (await db.query('sales', where: 'id = ?', whereArgs: [1])).first;
      expect(row['productName'], 'Widget (corrected)');
      expect((row['salePrice'] as num).toDouble(), 45.0);
      expect(row['quantity'], 5);
      expect(row['server_version'], 7,
          reason: 'server_version must be adopted locally');
      expect(row['sync_status'], 'SYNCED');

      // Queue lifecycle closed only AFTER convergence (RESOLVED, not silent).
      final q = await queueRowByIdempotencyKey('conv-sale-1');
      expect(q['status'], 'SYNCED');
      expect(q['resolution_status'], 'RESOLVED');

      // Durable audit evidence exists and is terminal-resolved.
      final audits = await auditRepo.getByIdempotencyKey('conv-sale-1');
      expect(audits, hasLength(1));
      expect(audits.first.status, ConflictLifecycleStatus.RESOLVED);
      expect(audits.first.resolutionMethod, ConflictResolutionMethod.AUTO);
      expect(audits.first.serverVersion, 7);
    });

    test(
        'true-LWW server winner applies locally with stock components '
        'protected (ES-1) — metadata converges, event-owned columns stay',
        () async {
      await db.insert('products', {
        'name': 'Local Name',
        'barcode': 'B-2',
        'openingQuantity': 5,
        'soldQuantity': 2,
        'returnedQuantity': 0,
        'currentQuantity': 9,
        'costPrice': 10.0,
        'totalInventoryCost': 90.0,
        'inventoryAdjustment': 6,
        'shop_id': 'shop-1',
        'cloud_uuid': 'prod-uuid-2',
        'server_version': 2,
      });
      await queueRepo.enqueue(
        entityType: 'product',
        entityId: 1,
        operation: SyncQueueOperation.UPDATE,
        payload: {
          'name': 'Local Name',
          'barcode': 'B-2',
          'opening_quantity': 5,
          'updated_at': '2026-01-01T00:00:00Z',
        },
        idempotencyKey: 'conv-prod-lww-server',
        shopId: 'shop-1',
      );

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
              'name': 'Server Name',
              'barcode': 'B-2',
              'opening_quantity': 10,
              'sold_quantity': 99,
              'returned_quantity': 88,
              'current_quantity': 77,
              'inventory_adjustment': 66,
              'updated_at': '2026-06-01T00:00:00Z',
            },
            localVersion: 2,
            currentServerVersion: 8,
            cloudUuid: 'prod-uuid-2',
          ),
          deleteEntity: (
              {required adapter,
              required shopId,
              required cloudUuid,
              required entityId,
              String? idempotencyKey}) async {},
        ),
      );

      final result = await engine.processQueue();
      expect(result.synced, 1);

      final row =
          (await db.query('products', where: 'id = ?', whereArgs: [1])).first;
      expect(row['name'], 'Server Name',
          reason: 'metadata LWW loser must adopt server state');
      expect(row['openingQuantity'], 10);
      // ES-1: component columns are owned by events, NEVER by metadata LWW.
      expect(row['soldQuantity'], 2);
      expect(row['returnedQuantity'], 0);
      expect(row['currentQuantity'], 9);
      expect(row['inventoryAdjustment'], 6);
      expect(row['server_version'], 8);

      final q = await queueRowByIdempotencyKey('conv-prod-lww-server');
      expect(q['status'], 'SYNCED');
      expect(q['resolution_status'], 'RESOLVED');
    });

    test(
        'true-LWW local winner reaches the server, then the authoritative '
        'response/version converges back into the local projection', () async {
      await db.insert('products', {
        'name': 'Newer Local Name',
        'barcode': 'B-3',
        'openingQuantity': 4,
        'soldQuantity': 1,
        'returnedQuantity': 0,
        'currentQuantity': 3,
        'costPrice': 10.0,
        'totalInventoryCost': 30.0,
        'inventoryAdjustment': 0,
        'shop_id': 'shop-1',
        'cloud_uuid': 'prod-uuid-3',
        'server_version': 2,
      });

      final pushedPayloads = <Map<String, dynamic>>[];
      var callCount = 0;
      final engine = buildEngine(
        cloudOps: SyncCloudOperations(
          upsertEntity: (
              {required adapter,
              required shopId,
              required localId,
              required payload,
              required idempotencyKey}) async {
            callCount++;
            pushedPayloads.add(payload);
            if (callCount == 1) {
              // Conditional update rejected: server moved ahead.
              return CloudUpsertResult(
                conflict: true,
                serverData: {
                  'name': 'Older Server Name',
                  'barcode': 'B-3',
                  'opening_quantity': 4,
                  'updated_at': '2026-01-01T00:00:00Z',
                },
                localVersion: 2,
                currentServerVersion: 5,
                cloudUuid: 'prod-uuid-3',
              );
            }
            // Re-push of the LOCAL winner succeeds conditionally.
            return CloudUpsertResult(
              success: true,
              currentServerVersion: 9,
              cloudUuid: 'prod-uuid-3',
            );
          },
          deleteEntity: (
              {required adapter,
              required shopId,
              required cloudUuid,
              required entityId,
              String? idempotencyKey}) async {},
        ),
      );

      await queueRepo.enqueue(
        entityType: 'product',
        entityId: 1,
        operation: SyncQueueOperation.UPDATE,
        payload: {
          'name': 'Newer Local Name',
          'barcode': 'B-3',
          'opening_quantity': 4,
          'updated_at': '2026-07-01T00:00:00Z',
        },
        idempotencyKey: 'conv-prod-lww-local',
        shopId: 'shop-1',
      );

      final result = await engine.processQueue();

      expect(result.synced, 1);
      expect(callCount, 2,
          reason: 'local winner must actually reach the server');
      expect(pushedPayloads.last['name'], 'Newer Local Name');

      // Authoritative response flowed back: version converged locally.
      final row =
          (await db.query('products', where: 'id = ?', whereArgs: [1])).first;
      expect(row['server_version'], 9);
      expect(row['sync_status'], 'SYNCED');

      final q = await queueRowByIdempotencyKey('conv-prod-lww-local');
      expect(q['status'], 'SYNCED');
      expect(q['resolution_status'], 'RESOLVED');

      final audits = await auditRepo.getByIdempotencyKey('conv-prod-lww-local');
      expect(audits.first.status, ConflictLifecycleStatus.RESOLVED);
      expect(audits.first.resolutionMethod, ConflictResolutionMethod.POLICY);
    });
  });

  group('M-I05 — never silent: durable review landings', () {
    test(
        'review-required event divergence stays durable: CONFLICT + '
        'REVIEW_REQUIRED, audit survives cleanupSynced (INV-M18)', () async {
      await db.insert('sales', {
        'date': '2026-08-20T10:00:00Z',
        'productName': 'Widget',
        'barcode': 'B-4',
        'quantity': 3,
        'salePrice': 50.0,
        'totalSaleValue': 150.0,
        'costPrice': 30.0,
        'cogs': 90.0,
        'shop_id': 'shop-1',
        'cloud_uuid': 'sale-uuid-4',
        'server_version': 2,
      });
      await queueRepo.enqueue(
        entityType: 'sale',
        entityId: 1,
        operation: SyncQueueOperation.UPDATE,
        payload: {
          'date': '2026-08-20T10:00:00Z',
          'product_name': 'Widget',
          'barcode': 'B-4',
          'quantity': 3,
          'sale_price': 50.0,
          'total_sale_value': 150.0,
          'cost_price': 30.0,
          'cogs': 90.0,
        },
        idempotencyKey: 'conv-sale-review',
        shopId: 'shop-1',
      );

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
            // Event-like QUANTITY divergence (3 local vs 4 server):
            // must NEVER be auto-discarded.
            serverData: {
              'date': '2026-08-20T10:00:00Z',
              'product_name': 'Widget',
              'barcode': 'B-4',
              'quantity': 4,
              'sale_price': 50.0,
              'total_sale_value': 200.0,
              'cost_price': 30.0,
              'cogs': 120.0,
            },
            localVersion: 2,
            currentServerVersion: 6,
            cloudUuid: 'sale-uuid-4',
          ),
          deleteEntity: (
              {required adapter,
              required shopId,
              required cloudUuid,
              required entityId,
              String? idempotencyKey}) async {},
        ),
      );

      final result = await engine.processQueue();

      expect(result.synced, 0, reason: 'review items are never counted synced');
      expect(result.conflicts, 1);

      final q = await queueRowByIdempotencyKey('conv-sale-review');
      expect(q['status'], 'CONFLICT');
      expect(q['resolution_status'], 'REVIEW_REQUIRED');

      // cleanup cannot remove unresolved evidence (AU-1 / INV-M18).
      await queueRepo.cleanupSynced(olderThanDays: 0);
      final stillThere = await queueRowByIdempotencyKey('conv-sale-review');
      expect(stillThere['status'], 'CONFLICT');
      final audits = await auditRepo.getByIdempotencyKey('conv-sale-review');
      expect(audits, hasLength(1));
      expect(audits.first.status, ConflictLifecycleStatus.REVIEW_REQUIRED);
      expect(audits.first.localBefore, isNotEmpty);
      expect(audits.first.serverBefore, isNotEmpty);
    });

    test(
        'local-winner re-push rejected by server → durable review, '
        'NOT marked synced (queue never closes before convergence)', () async {
      await db.insert('products', {
        'name': 'Local Winner',
        'barcode': 'B-5',
        'openingQuantity': 1,
        'soldQuantity': 0,
        'returnedQuantity': 0,
        'currentQuantity': 1,
        'costPrice': 5.0,
        'totalInventoryCost': 5.0,
        'inventoryAdjustment': 0,
        'shop_id': 'shop-1',
        'cloud_uuid': 'prod-uuid-5',
        'server_version': 2,
      });
      await queueRepo.enqueue(
        entityType: 'product',
        entityId: 1,
        operation: SyncQueueOperation.UPDATE,
        payload: {
          'name': 'Local Winner',
          'barcode': 'B-5',
          'updated_at': '2026-07-01T00:00:00Z',
        },
        idempotencyKey: 'conv-prod-reject',
        shopId: 'shop-1',
      );

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
              'name': 'Server Newer',
              'barcode': 'B-5',
              'opening_quantity': 1,
              'updated_at': '2026-01-01T00:00:00Z',
            },
            localVersion: 2,
            currentServerVersion: 5,
            cloudUuid: 'prod-uuid-5',
          ),
          deleteEntity: (
              {required adapter,
              required shopId,
              required cloudUuid,
              required entityId,
              String? idempotencyKey}) async {},
        ),
      );

      final result = await engine.processQueue();

      expect(result.synced, 0);
      expect(result.conflicts, 1);

      final row =
          (await db.query('products', where: 'id = ?', whereArgs: [1])).first;
      expect(row['name'], 'Local Winner',
          reason: 'failed convergence must leave the projection untouched');
      expect(row['server_version'], 2);

      final q = await queueRowByIdempotencyKey('conv-prod-reject');
      expect(q['status'], 'CONFLICT');
      expect(q['resolution_status'], 'REVIEW_REQUIRED');

      final audits = await auditRepo.getByIdempotencyKey('conv-prod-reject');
      expect(audits.first.status, ConflictLifecycleStatus.REVIEW_REQUIRED);
    });

    test(
        'mid-transaction failure injection rolls back atomically: no partial '
        'apply, no premature queue close, evidence still durable (§24-G)',
        () async {
      await db.insert('products', {
        'name': 'Before Inject',
        'barcode': 'B-6',
        'openingQuantity': 1,
        'soldQuantity': 0,
        'returnedQuantity': 0,
        'currentQuantity': 1,
        'costPrice': 5.0,
        'totalInventoryCost': 5.0,
        'inventoryAdjustment': 0,
        'shop_id': 'shop-1',
        'cloud_uuid': 'prod-uuid-6',
        'server_version': 2,
      });
      // Failure injector: any UPDATE on products aborts the statement,
      // killing the apply transaction midway.
      await db.execute('''
        CREATE TRIGGER trg_inject_mid_apply_failure
        BEFORE UPDATE ON products
        BEGIN
          SELECT RAISE(ABORT, 'injected mid-apply failure');
        END
      ''');
      await queueRepo.enqueue(
        entityType: 'product',
        entityId: 1,
        operation: SyncQueueOperation.UPDATE,
        payload: {
          'name': 'Before Inject',
          'barcode': 'B-6',
          'updated_at': '2026-01-01T00:00:00Z',
        },
        idempotencyKey: 'conv-prod-inject',
        shopId: 'shop-1',
      );

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
              'name': 'Server Truth',
              'barcode': 'B-6',
              'opening_quantity': 2,
              'updated_at': '2026-02-01T00:00:00Z',
            },
            localVersion: 2,
            currentServerVersion: 4,
            cloudUuid: 'prod-uuid-6',
          ),
          deleteEntity: (
              {required adapter,
              required shopId,
              required cloudUuid,
              required entityId,
              String? idempotencyKey}) async {},
        ),
      );

      final result = await engine.processQueue();

      expect(result.synced, 0);
      expect(logs.any((l) => l.contains('CONFLICT_APPLY_FAILED')), isTrue);

      // Atomicity: the aborted transaction left NO partial projection write.
      final row =
          (await db.query('products', where: 'id = ?', whereArgs: [1])).first;
      expect(row['name'], 'Before Inject');
      expect(row['server_version'], 2);
      expect(row['sync_status'], 'SYNCED');

      // The durable review landing happened OUTSIDE the aborted txn.
      final q = await queueRowByIdempotencyKey('conv-prod-inject');
      expect(q['status'], 'CONFLICT');
      expect(q['resolution_status'], 'REVIEW_REQUIRED');
      final audits = await auditRepo.getByIdempotencyKey('conv-prod-inject');
      expect(audits, hasLength(1));
      expect(audits.first.status, ConflictLifecycleStatus.REVIEW_REQUIRED);
    });
  });

  group('M-I05 — hydration / incremental SG-1 pending-op protection', () {
    Future<Database> seedProtectedProduct() async {
      await db.insert('products', {
        'name': 'Local Intent',
        'barcode': 'SG1-1',
        'openingQuantity': 5,
        'soldQuantity': 0,
        'returnedQuantity': 0,
        'currentQuantity': 5,
        'costPrice': 10.0,
        'totalInventoryCost': 50.0,
        'inventoryAdjustment': 0,
        'shop_id': 'shop-1',
        'cloud_uuid': 'sg1-uuid-1',
        'server_version': 2,
      });
      // Unsynced local work for this exact entity.
      await queueRepo.enqueue(
        entityType: 'product',
        entityId: 1,
        operation: SyncQueueOperation.UPDATE,
        payload: {'name': 'Local Intent'},
        idempotencyKey: 'sg1-pending-op',
        shopId: 'shop-1',
      );
      return db;
    }

    HydrationCloudSource newerCloudSource() => HydrationCloudSource(
          fetchAll: ({required shopId, required adapter}) async => [
            {
              'id': 'sg1-uuid-1',
              'name': 'Cloud Newer',
              'barcode': 'SG1-1',
              'opening_quantity': 9,
              'sold_quantity': 3,
              'returned_quantity': 0,
              'current_quantity': 6,
              'cost_price': 15.0,
              'total_inventory_cost': 90.0,
              'inventory_adjustment': 0,
              'server_version': 9,
            },
          ],
        );

    test(
        'hydration defers destructive overwrite while a pending local '
        'operation exists (SG-1)', () async {
      await seedProtectedProduct();

      final service = HydrationService(
        db: db,
        cloudSource: newerCloudSource(),
        logger: (msg) async => logs.add(msg),
        queueRepository: queueRepo,
      );

      final pendingBefore = await queueRepo.getPendingCount();

      final result = await service.hydrate(
        shopId: 'shop-1',
        adapters: [ProductSyncAdapter()],
      );

      expect(result.deferred, 1);
      expect(result.updated, 0);

      final row = (await db.query('products',
              where: 'cloud_uuid = ?', whereArgs: ['sg1-uuid-1']))
          .first;
      expect(row['name'], 'Local Intent',
          reason: 'unsynced local intent must survive hydration');
      expect(row['server_version'], 2);

      final pendingAfter = await queueRepo.getPendingCount();
      expect(pendingAfter, pendingBefore);
    });

    test('incremental sync has equivalent SG-1 protection', () async {
      await seedProtectedProduct();

      final service = IncrementalSyncService(
        db: db,
        cloudSource: newerCloudSource(),
        logger: (msg) async => logs.add(msg),
        queueRepository: queueRepo,
      );

      final result = await service.pullChanges(
        shopId: 'shop-1',
        adapters: [ProductSyncAdapter()],
        since: DateTime.utc(2026, 1, 1),
      );

      expect(result.deferred, 1);
      expect(result.updated, 0);
      final row = (await db.query('products')).first;
      expect(row['name'], 'Local Intent');
      expect(row['server_version'], 2);
    });

    test(
        'pure authoritative hydration produces ZERO outbound queue entries '
        '(INV-M10 no-sync-echo)', () async {
      await db.insert('products', {
        'name': 'Existing Product',
        'barcode': 'ECHO-1',
        'openingQuantity': 1,
        'soldQuantity': 0,
        'returnedQuantity': 0,
        'currentQuantity': 1,
        'costPrice': 1.0,
        'totalInventoryCost': 1.0,
        'inventoryAdjustment': 0,
        'shop_id': 'shop-1',
        'cloud_uuid': 'echo-uuid-existing',
        'server_version': 1,
      });

      final service = HydrationService(
        db: db,
        cloudSource: HydrationCloudSource(
          fetchAll: ({required shopId, required adapter}) async => [
            {
              'id': 'echo-uuid-existing',
              'name': 'Existing Product (v2)',
              'barcode': 'ECHO-1',
              'opening_quantity': 2,
              'sold_quantity': 0,
              'returned_quantity': 0,
              'current_quantity': 2,
              'cost_price': 1.0,
              'total_inventory_cost': 2.0,
              'inventory_adjustment': 0,
              'server_version': 4,
            },
            {
              'id': 'echo-uuid-new',
              'name': 'Brand New From Cloud',
              'barcode': 'ECHO-2',
              'opening_quantity': 7,
              'sold_quantity': 0,
              'returned_quantity': 0,
              'current_quantity': 7,
              'cost_price': 2.0,
              'total_inventory_cost': 14.0,
              'inventory_adjustment': 0,
              'server_version': 1,
            },
          ],
        ),
        logger: (msg) async {},
        queueRepository: queueRepo,
      );

      final pendingBefore = await queueRepo.getPendingCount();
      final totalBefore =
          (await db.rawQuery('SELECT COUNT(*) c FROM sync_queue')).first['c'];

      final result = await service.hydrate(
        shopId: 'shop-1',
        adapters: [ProductSyncAdapter()],
      );

      expect(result.updated, 1);
      expect(result.inserted, 1);

      final pendingAfter = await queueRepo.getPendingCount();
      final totalAfter =
          (await db.rawQuery('SELECT COUNT(*) c FROM sync_queue')).first['c'];
      expect(pendingAfter, pendingBefore,
          reason: 'hydration must not enqueue outbound work');
      expect(totalAfter, totalBefore,
          reason: 'no sync echo: zero new queue entries of ANY kind');
    });

    test(
        'overlap harness (Completer-gated): a pending op enqueued WHILE '
        'hydration is in flight is still protected (interleaving, not '
        'sequential)', () async {
      await db.insert('products', {
        'name': 'Racy Local',
        'barcode': 'RACE-1',
        'openingQuantity': 3,
        'soldQuantity': 0,
        'returnedQuantity': 0,
        'currentQuantity': 3,
        'costPrice': 1.0,
        'totalInventoryCost': 3.0,
        'inventoryAdjustment': 0,
        'shop_id': 'shop-1',
        'cloud_uuid': 'race-uuid-1',
        'server_version': 1,
      });

      final fetchReleased = Completer<void>();
      final fetchStarted = Completer<void>();

      final service = HydrationService(
        db: db,
        cloudSource: HydrationCloudSource(
          fetchAll: ({required shopId, required adapter}) async {
            fetchStarted.complete();
            // Barrier: hold the fetched rows hostage until the test has
            // interleaved a pending local enqueue.
            await fetchReleased.future;
            return [
              {
                'id': 'race-uuid-1',
                'name': 'Racy Cloud Overwrite Attempt',
                'barcode': 'RACE-1',
                'opening_quantity': 3,
                'sold_quantity': 1,
                'returned_quantity': 0,
                'current_quantity': 2,
                'cost_price': 1.0,
                'total_inventory_cost': 2.0,
                'inventory_adjustment': 0,
                'server_version': 12,
              },
            ];
          },
        ),
        logger: (msg) async => logs.add(msg),
        queueRepository: queueRepo,
      );

      final hydration = service.hydrate(
        shopId: 'shop-1',
        adapters: [ProductSyncAdapter()],
      );

      await fetchStarted.future;
      // Interleave: the local user queues work DURING the hydration pull.
      await queueRepo.enqueue(
        entityType: 'product',
        entityId: 1,
        operation: SyncQueueOperation.UPDATE,
        payload: {'name': 'Racy Local'},
        idempotencyKey: 'race-pending-op',
        shopId: 'shop-1',
      );
      fetchReleased.complete();

      final result = await hydration;

      expect(result.deferred, 1,
          reason: 'protection must hold under real interleaving');
      final row =
          (await db.query('products', where: 'id = ?', whereArgs: [1])).first;
      expect(row['name'], 'Racy Local');
      expect(row['server_version'], 1);
    });
  });

  group('M-I05 — worker reconciliation hook', () {
    test(
        'worker runs the startup recovery sweep exactly once without '
        'activating periodic scheduling changes (DR-M09)', () async {
      var sweeps = 0;
      final worker = SyncWorker(
        engine: buildEngine(
          cloudOps: SyncCloudOperations(
            upsertEntity: (
                    {required adapter,
                    required shopId,
                    required localId,
                    required payload,
                    required idempotencyKey}) async =>
                CloudUpsertResult(success: true),
            deleteEntity: (
                {required adapter,
                required shopId,
                required cloudUuid,
                required entityId,
                String? idempotencyKey}) async {},
          ),
        ),
        connectivityCheck: () async => false,
        sessionCheck: () async => true,
        logger: (msg) async => logs.add(msg),
        interval: const Duration(hours: 1),
        recoverySweep: () async => sweeps++,
      );

      worker.start();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      worker.stop();

      expect(sweeps, 1);
      expect(logs.any((l) => l.contains('recovery sweep complete')), isTrue);
    });

    test('recovery-sweep errors are logged and non-fatal', () async {
      final worker = SyncWorker(
        engine: buildEngine(
          cloudOps: SyncCloudOperations(
            upsertEntity: (
                    {required adapter,
                    required shopId,
                    required localId,
                    required payload,
                    required idempotencyKey}) async =>
                CloudUpsertResult(success: true),
            deleteEntity: (
                {required adapter,
                required shopId,
                required cloudUuid,
                required entityId,
                String? idempotencyKey}) async {},
          ),
        ),
        connectivityCheck: () async => false,
        sessionCheck: () async => true,
        logger: (msg) async => logs.add(msg),
        interval: const Duration(hours: 1),
        recoverySweep: () async => throw StateError('sweep boom'),
      );

      worker.start();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      worker.stop();

      expect(logs.any((l) => l.contains('recovery sweep error')), isTrue);
    });
  });
}
