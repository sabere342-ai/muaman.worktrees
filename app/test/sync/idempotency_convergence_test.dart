import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:muaman_store/config/app_config.dart';
import 'package:muaman_store/errors/cloud_data_exception.dart';
import 'package:muaman_store/sync/conflict_audit_repository.dart';
import 'package:muaman_store/sync/conflict_resolver.dart';
import 'package:muaman_store/sync/sync_cloud_operations_transport.dart';
import 'package:muaman_store/sync/sync_engine.dart';
import 'package:muaman_store/sync/sync_queue_repository.dart';
import 'package:muaman_store/sync/adapters/entity_sync_adapter.dart';
import 'package:muaman_store/sync/adapters/product_sync_adapter.dart';
import 'package:muaman_store/sync/adapters/sale_sync_adapter.dart';
import 'package:muaman_store/sync/sync_status.dart';

/// Phase P Group A A5 — idempotency + convergence acceptance (plan §F A5).
///
/// Drives the REAL Phase M migration-28 style stock RPC surface through the
/// REAL A1 [SyncCloudOperationsTransport] and the real engine connected to a
/// full local schema (sync_queue + sales + products + conflict_audit), proving
/// the end-to-end idempotency chain:
///   - the persisted occurrence token lives INSIDE the canonical
///     p_idempotency_key the server receives (6.1 / INV-M19),
///   - duplicate same-key delivery applies the logical effect at most once,
///   - IDEMPOTENT replays CLOSE SUCCESS TOO: the original authoritative
///     server identity + version converge into the local row (6.3/6.4,
///     INV-M17 read-back verified inside the same transaction),
///   - retries across a network-error break resend the SAME persisted key,
///   - tenant authority is the persisted queue shop id (never the row's or
///     any ambient shop); mismatches fail closed (10/11),
///   - OVERSOLD and structural non-success are NEVER closed SYNCED (12),
///   - event drained metadata adopts, but current_quantity is never written
///     into local rows (6.5 / ES-1) and nothing is fabricated,
///   - conflicts land in durable REVIEW_REQUIRED with OF-4 audit-before-queue
///     (13/14) and drain stays dormant (15/16).
void main() {
  sqfliteFfiInit();

  late Database db;
  late SyncQueueRepository queueRepo;
  late ConflictAuditRepository auditRepo;
  late KeyedStockFixture fixture;
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
    fixture = KeyedStockFixture();
    logs.clear();
  });

  tearDown(() async {
    await db.close();
  });

  Map<SyncEntityType, EntitySyncAdapter> standardAdapters() => {
        SyncEntityType.product: ProductSyncAdapter(),
        SyncEntityType.sale: SaleSyncAdapter(),
      };

  /// Engine wired to the REAL transport backed by the keyed fixture.
  SyncEngine transportEngine({String cycleShop = 'shop-1'}) {
    final adapters = standardAdapters();
    return SyncEngine(
      queueRepository: queueRepo,
      conflictResolver: ConflictResolver(adapters),
      adapters: adapters,
      connectivityCheck: () async => true,
      licenseCheck: () async => true,
      shopIdProvider: () async => cycleShop,
      logger: (type, op, {details}) async =>
          logs.add('$type:$op${details != null ? ' ($details)' : ''}'),
      cloudOps: SyncCloudOperationsTransport(rpc: fixture.call).toOperations(),
      localDb: db,
      conflictAuditRepository: auditRepo,
    );
  }

  Future<int> seedSaleRow({
    int id = 1,
    String shopId = 'shop-1',
    String cloudUuid = 'client-uuid-1',
    int quantity = 2,
    int serverVersion = 0,
  }) async {
    await db.insert('sales', {
      'date': '2026-08-20T10:00:00Z',
      'productName': 'Widget',
      'barcode': 'B-1',
      'quantity': quantity,
      'salePrice': 50.0,
      'totalSaleValue': 100.0,
      'costPrice': 30.0,
      'cogs': 60.0,
      'shop_id': shopId,
      'cloud_uuid': cloudUuid,
      'server_version': serverVersion,
    });
    return id;
  }

  void enqueueSale({
    required int rowId,
    required String occurrenceToken,
    required String shopId,
    String? entityUuid,
    int quantity = 2,
    String? key,
  }) {
    final cloudUuid = entityUuid ?? 'client-uuid-$rowId';
    final idempotencyKey = key ?? 'sale:$cloudUuid:CREATE:$occurrenceToken';
    queueRepo.enqueue(
      entityType: SyncEntityType.sale.label,
      entityId: rowId,
      operation: SyncQueueOperation.CREATE,
      payload: {
        'id': rowId,
        'cloud_uuid': cloudUuid,
        'server_version': 0,
        'date': '2026-08-20T10:00:00Z',
        'product_name': 'Widget',
        'barcode': 'B-1',
        'quantity': quantity,
        'sale_price': 50.0,
        'total_sale_value': 100.0,
        'cost_price': 30.0,
        'cogs': 60.0,
      },
      idempotencyKey: idempotencyKey,
      shopId: shopId,
      occurrenceToken: occurrenceToken,
    );
  }

  Future<Map<String, dynamic>> queueRowByKey(String key) async => (await db
          .query('sync_queue', where: 'idempotency_key = ?', whereArgs: [key]))
      .first;

  Future<Map<String, dynamic>> saleRow(int id) async =>
      (await db.query('sales', where: 'id = ?', whereArgs: [id])).first;

  group('A5 6.1 — canonical key threading (INV-M19)', () {
    test(
        'the persisted occurrence token is embedded in the p_idempotency_key '
        'the server receives', () async {
      await seedSaleRow(id: 1, cloudUuid: 'client-uuid-1');
      enqueueSale(
        rowId: 1,
        occurrenceToken: 'TOK-ALPHA',
        shopId: 'shop-1',
        entityUuid: 'client-uuid-1',
      );

      final result = await transportEngine().processQueue();

      expect(result.synced, 1);
      final saleCalls = fixture.calls
          .where((c) => c.function == 'create_cloud_sale_with_stock_v2')
          .toList();
      expect(saleCalls, hasLength(1));
      expect(saleCalls.first.params['p_idempotency_key'],
          'sale:client-uuid-1:CREATE:TOK-ALPHA');
      expect(
          (saleCalls.first.params['p_idempotency_key'] as String)
              .contains('TOK-ALPHA'),
          isTrue,
          reason: 'the persisted token must participate in the sent identity');

      // Convergence ran end-to-end through the REAL transport: the fully
      // authoritative server identity + version were adopted locally.
      final row = await saleRow(1);
      expect(row['cloud_uuid'], 'sale-1');
      expect(row['server_version'], 1);
      expect(row['sync_status'], 'SYNCED');
      expect(logs.any((l) => l.contains('CONVERGED')), isTrue,
          reason: 'adoption must be observably logged');
    });
  });

  group('A5 6.2/6.3 — exactly-once and replay convergence', () {
    test(
        'crash window D: the server committed but the response was lost; the '
        'duplicate same-key delivery is replayed IDEMPOTENT, applied exactly '
        'once, and ALSO closes SYNCED by adopting the original authoritative '
        'response', () async {
      await seedSaleRow(id: 1, cloudUuid: 'client-uuid-1');
      enqueueSale(
        rowId: 1,
        occurrenceToken: 'TOK-A',
        shopId: 'shop-1',
        entityUuid: 'client-uuid-1',
        quantity: 2,
      );
      // The server applies the effect AND commits its idempotency log, but
      // the response never reaches the client (crash/network window D).
      fixture.commitThenDropResponseOnce = true;

      var result = await transportEngine().processQueue();
      expect(result.synced, 0, reason: 'the client never saw the response');
      expect(fixture.saleCount, 1, reason: 'the server DID apply the effect');
      expect(fixture.soldQuantity, 2);

      final entryAfterLoss =
          await queueRowByKey('sale:client-uuid-1:CREATE:TOK-A');
      expect(entryAfterLoss['status'], 'PENDING',
          reason: 'the entry genuinely remained pending across the crash');

      // Retry: SAME entry, SAME persisted canonical key. The server answers
      // from its idempotency log (IDEMPOTENT) — no re-execution.
      result = await transportEngine().processQueue();
      expect(result.synced, 1, reason: 'a replay is success, not a failure');
      expect(fixture.saleCount, 1, reason: 'no duplicate financial event');
      expect(fixture.soldQuantity, 2, reason: 'stock decremented exactly once');

      final replay = await queueRowByKey('sale:client-uuid-1:CREATE:TOK-A');
      expect(replay['status'], 'SYNCED');

      final row = await saleRow(1);
      expect(row['cloud_uuid'], 'sale-1',
          reason: 'replay converged the ORIGINAL server identity');
      expect(row['server_version'], 1);
      expect(row['sync_status'], 'SYNCED');
    });

    test(
        'a network-error break retries with the SAME persisted key — no '
        're-mint, no double effect (DR-M04)', () async {
      await seedSaleRow(id: 2, cloudUuid: 'client-uuid-2');
      enqueueSale(
        rowId: 2,
        occurrenceToken: 'TOK-B',
        shopId: 'shop-1',
        entityUuid: 'client-uuid-2',
      );
      fixture.failNextCallWithNetworkError = true;

      var result = await transportEngine().processQueue();
      expect(result.synced, 0, reason: 'network error breaks the cycle');
      final entryAfterFirst =
          await queueRowByKey('sale:client-uuid-2:CREATE:TOK-B');
      expect(entryAfterFirst['status'], 'PENDING',
          reason: 'network failure never fakes SYNCED');

      result = await transportEngine().processQueue();
      expect(result.synced, 1);
      expect(fixture.saleCount, 1);

      final saleCalls = fixture.calls
          .where((c) => c.function == 'create_cloud_sale_with_stock_v2')
          .toList();
      expect(saleCalls, hasLength(2));
      expect(saleCalls[0].params['p_idempotency_key'],
          saleCalls[1].params['p_idempotency_key'],
          reason: 'retry must resend the SAME persisted logical key');
    });
  });

  group('A5 6.7/10/11 — persisted shop tenant authority', () {
    test('the persisted queue shop_id is the RPC scope (never an ambient shop)',
        () async {
      await seedSaleRow(id: 1, cloudUuid: 'client-uuid-1');
      enqueueSale(
        rowId: 1,
        occurrenceToken: 'TOK-T1',
        shopId: 'shop-1',
      );

      await transportEngine().processQueue();

      final saleCalls = fixture.calls
          .where((c) => c.function == 'create_cloud_sale_with_stock_v2')
          .toList();
      expect(saleCalls, isNotEmpty);
      for (final c in saleCalls) {
        expect(c.params['p_shop_id'], 'shop-1');
      }
    });

    test(
        'an entry from another shop is never pulled or executed under the '
        'active shop', () async {
      await seedSaleRow(id: 1, cloudUuid: 'client-uuid-1', shopId: 'shop-2');
      enqueueSale(
        rowId: 1,
        occurrenceToken: 'TOK-T2',
        shopId: 'shop-2',
        entityUuid: 'client-uuid-1',
      );

      final result = await transportEngine().processQueue();

      expect(result.processed, 0);
      expect(fixture.calls, isEmpty,
          reason: 'cross-shop work must never reach ANY RPC');
      final entry = await queueRowByKey('sale:client-uuid-1:CREATE:TOK-T2');
      expect(entry['status'], 'PENDING');
    });

    test(
        'row-level tenant mismatch fails convergence closed: never a silent '
        'SYNCED and the authoritative identity never commits', () async {
      // The queue entry is shop-1 (rule-abiding) but the local row it is
      // supposed to converge belongs to shop-9 — corrupted/normalizing
      // projection. The engine must fail closed, not stamp the row.
      await seedSaleRow(id: 1, cloudUuid: 'client-uuid-9', shopId: 'shop-9');
      enqueueSale(
        rowId: 1,
        occurrenceToken: 'TOK-T9',
        shopId: 'shop-1',
        entityUuid: 'client-uuid-9',
      );

      final result = await transportEngine().processQueue();

      expect(result.synced, 0, reason: 'convergence must fail closed');
      expect(result.failed, 1);
      expect(logs.any((l) => l.contains('tenant guard')), isTrue,
          reason: 'the tenant guard must be the observable cause');

      final entry = await queueRowByKey('sale:client-uuid-9:CREATE:TOK-T9');
      expect(entry['status'], 'PENDING',
          reason: 'never SYNCED — retried, not faked');

      final row = await saleRow(1);
      expect(row['cloud_uuid'], 'client-uuid-9',
          reason: 'server identity must not leak into the mismatched row');
      expect(row['server_version'], 0);
    });
  });

  group('A5 6.6/12 — never a fake success', () {
    test('OVERSOLD/insufficient stock stays fail-closed (A3 owns the audit)',
        () async {
      await db.insert('products', {
        'name': 'Widget',
        'barcode': 'B-1',
        'openingQuantity': 10,
        'soldQuantity': 0,
        'returnedQuantity': 0,
        'currentQuantity': 10,
        'costPrice': 30.0,
        'totalInventoryCost': 300.0,
        'inventoryAdjustment': 0,
        'shop_id': 'shop-1',
        'cloud_uuid': 'prod-1',
      });
      await seedSaleRow(id: 1, cloudUuid: 'client-uuid-over', quantity: 999);
      enqueueSale(
        rowId: 1,
        occurrenceToken: 'TOK-OVER',
        shopId: 'shop-1',
        entityUuid: 'client-uuid-over',
        quantity: 999,
      );

      final result = await transportEngine().processQueue();

      expect(result.synced, 0, reason: 'oversold is never counted synced');
      expect(result.failed, 1);
      expect(fixture.saleCount, 0, reason: 'no partial server state');
      expect(logs.any((l) => l.contains('SERVER_ERROR')), isTrue);

      final entry =
          await queueRowByKey('sale:client-uuid-over:CREATE:TOK-OVER');
      expect(entry['status'], 'PENDING',
          reason: 'fail-closed: left for retry, never SYNCED');
      expect(entry['retry_count'], 1);

      final product =
          (await db.query('products', where: 'id = ?', whereArgs: [1])).first;
      expect(product['currentQuantity'], 10,
          reason: 'the stock equation is untouched on the failed path');
      expect(product['server_version'], 0);
    });

    test(
        'a transport structurally reporting success:false (non-conflict, '
        'non-idempotent) is marked FAILED, never falls through to SYNCED',
        () async {
      await seedSaleRow(id: 1, cloudUuid: 'client-uuid-false');
      enqueueSale(
        rowId: 1,
        occurrenceToken: 'TOK-FALSE',
        shopId: 'shop-1',
        entityUuid: 'client-uuid-false',
      );

      final engine = SyncEngine(
        queueRepository: queueRepo,
        conflictResolver: ConflictResolver(standardAdapters()),
        adapters: standardAdapters(),
        connectivityCheck: () async => true,
        licenseCheck: () async => true,
        shopIdProvider: () async => 'shop-1',
        logger: (type, op, {details}) async =>
            logs.add('$type:$op${details != null ? ' ($details)' : ''}'),
        cloudOps: SyncCloudOperations(
          upsertEntity: (
                  {required adapter,
                  required shopId,
                  required localId,
                  required payload,
                  required idempotencyKey}) async =>
              CloudUpsertResult(success: false),
          deleteEntity: (
              {required adapter,
              required shopId,
              required cloudUuid,
              required entityId,
              String? idempotencyKey}) async {},
        ),
        localDb: db,
      );

      final result = await engine.processQueue();

      expect(result.synced, 0);
      expect(result.failed, 1);
      expect(logs.any((l) => l.contains('SERVER_ERROR')), isTrue);
      final entry =
          await queueRowByKey('sale:client-uuid-false:CREATE:TOK-FALSE');
      expect(entry['status'], isNot('SYNCED'),
          reason: 'the pre-A5 fall-through to SYNCED is the regression');
    });
  });

  group('A5 6.5 / ES-1 — authoritative carrier, never fabricated', () {
    test(
        'draining an event adopts its metadata but never writes '
        'current_quantity or product components (ES-1)', () async {
      await db.insert('products', {
        'name': 'Widget',
        'barcode': 'B-1',
        'openingQuantity': 10,
        'soldQuantity': 2,
        'returnedQuantity': 0,
        'currentQuantity': 8,
        'costPrice': 30.0,
        'totalInventoryCost': 300.0,
        'inventoryAdjustment': 0,
        'shop_id': 'shop-1',
        'cloud_uuid': 'prod-1',
      });
      await seedSaleRow(id: 1, cloudUuid: 'client-uuid-es1', quantity: 2);
      enqueueSale(
        rowId: 1,
        occurrenceToken: 'TOK-ES1',
        shopId: 'shop-1',
        entityUuid: 'client-uuid-es1',
        quantity: 2,
      );

      final result = await transportEngine().processQueue();
      expect(result.synced, 1);

      final row = await saleRow(1);
      expect(row['cloud_uuid'], 'sale-1');
      expect(row['server_version'], 1);
      expect(row['sync_status'], 'SYNCED');
      expect(row.containsKey('currentQuantity'), isFalse,
          reason: 'event rows have no stock component column at all');

      // The authoritative quantity lives in the response carrier and the
      // existing reconciliation/conflict contract — never a local recompute.
      final product =
          (await db.query('products', where: 'id = ?', whereArgs: [1])).first;
      expect(product['currentQuantity'], 8, reason: 'unchanged by the drain');
      expect(product['soldQuantity'], 2);
      expect(product['server_version'], 0);
      expect(fixture.currentQuantity, 8,
          reason: 'the server current_quantity was the authoritative value');
    });

    test(
        'a server response WITHOUT metadata fabricates nothing: identity and '
        'components stay exactly as they were', () async {
      await db.insert('products', {
        'name': 'Kept Name',
        'barcode': 'B-KEEP',
        'openingQuantity': 4,
        'soldQuantity': 1,
        'returnedQuantity': 0,
        'currentQuantity': 3,
        'costPrice': 10.0,
        'totalInventoryCost': 30.0,
        'inventoryAdjustment': 0,
        'shop_id': 'shop-1',
        'cloud_uuid': 'prod-keep',
        'server_version': 4,
      });
      await queueRepo.enqueue(
        entityType: SyncEntityType.product.label,
        entityId: 1,
        operation: SyncQueueOperation.UPDATE,
        payload: {
          'id': 1,
          'cloud_uuid': 'prod-keep',
          'server_version': 4,
          'name': 'Kept Name',
          'barcode': 'B-KEEP',
          'opening_quantity': 4,
        },
        idempotencyKey: 'product:prod-keep:UPDATE:TOK-KEEP',
        shopId: 'shop-1',
        occurrenceToken: 'TOK-KEEP',
      );

      final engine = SyncEngine(
        queueRepository: queueRepo,
        conflictResolver: ConflictResolver(standardAdapters()),
        adapters: standardAdapters(),
        connectivityCheck: () async => true,
        licenseCheck: () async => true,
        shopIdProvider: () async => 'shop-1',
        logger: (type, op, {details}) async {},
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
        localDb: db,
      );

      final result = await engine.processQueue();
      expect(result.synced, 1);

      final row =
          (await db.query('products', where: 'id = ?', whereArgs: [1])).first;
      expect(row['cloud_uuid'], 'prod-keep');
      expect(row['server_version'], 4);
      expect(row['currentQuantity'], 3);
    });

    test(
        'generic CREATE adoption: the system-minted authoritative uuid '
        'converges into the local row only when the server sends it', () async {
      await db.insert('products', {
        'name': 'Created',
        'barcode': 'B-CREATE',
        'openingQuantity': 1,
        'soldQuantity': 0,
        'returnedQuantity': 0,
        'currentQuantity': 1,
        'costPrice': 1.0,
        'totalInventoryCost': 1.0,
        'inventoryAdjustment': 0,
        'shop_id': 'shop-1',
        'cloud_uuid': 'local-mint',
        'server_version': 0,
      });
      await queueRepo.enqueue(
        entityType: SyncEntityType.product.label,
        entityId: 1,
        operation: SyncQueueOperation.CREATE,
        payload: {
          'id': 1,
          'cloud_uuid': 'local-mint',
          'server_version': 0,
          'name': 'Created',
          'barcode': 'B-CREATE',
          'opening_quantity': 1,
        },
        idempotencyKey: 'product:local-mint:CREATE:TOK-MINT',
        shopId: 'shop-1',
        occurrenceToken: 'TOK-MINT',
      );

      final engine = SyncEngine(
        queueRepository: queueRepo,
        conflictResolver: ConflictResolver(standardAdapters()),
        adapters: standardAdapters(),
        connectivityCheck: () async => true,
        licenseCheck: () async => true,
        shopIdProvider: () async => 'shop-1',
        logger: (type, op, {details}) async {},
        cloudOps: SyncCloudOperations(
          upsertEntity: (
                  {required adapter,
                  required shopId,
                  required localId,
                  required payload,
                  required idempotencyKey}) async =>
              CloudUpsertResult(success: true, cloudUuid: 'prod-server-1'),
          deleteEntity: (
              {required adapter,
              required shopId,
              required cloudUuid,
              required entityId,
              String? idempotencyKey}) async {},
        ),
        localDb: db,
      );

      final result = await engine.processQueue();
      expect(result.synced, 1);

      final row =
          (await db.query('products', where: 'id = ?', whereArgs: [1])).first;
      expect(row['cloud_uuid'], 'prod-server-1',
          reason: 'the authoritative response replaces the placeholder uuid');
      expect(row['sync_status'], 'SYNCED');
    });
  });

  group('A5 13/14 — conflict durability + OF-4 audit-before-queue', () {
    test(
        'event-like quantity divergence lands in durable REVIEW_REQUIRED — '
        'never SYNCED', () async {
      await seedSaleRow(
          id: 1, cloudUuid: 'client-uuid-div', quantity: 3, serverVersion: 2);
      await queueRepo.enqueue(
        entityType: SyncEntityType.sale.label,
        entityId: 1,
        operation: SyncQueueOperation.UPDATE,
        payload: {
          'id': 1,
          'cloud_uuid': 'client-uuid-div',
          'server_version': 2,
          'date': '2026-08-20T10:00:00Z',
          'product_name': 'Widget',
          'barcode': 'B-1',
          'quantity': 3,
          'sale_price': 50.0,
          'total_sale_value': 150.0,
          'cost_price': 30.0,
          'cogs': 90.0,
        },
        idempotencyKey: 'sale:client-uuid-div:UPDATE:TOK-DIV',
        shopId: 'shop-1',
        occurrenceToken: 'TOK-DIV',
      );

      final engine = SyncEngine(
        queueRepository: queueRepo,
        conflictResolver: ConflictResolver(standardAdapters()),
        adapters: standardAdapters(),
        connectivityCheck: () async => true,
        licenseCheck: () async => true,
        shopIdProvider: () async => 'shop-1',
        logger: (type, op, {details}) async =>
            logs.add('$type:$op${details != null ? ' ($details)' : ''}'),
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
              'date': '2026-08-20T10:00:00Z',
              'product_name': 'Widget',
              'barcode': 'B-1',
              'quantity': 4,
              'sale_price': 50.0,
              'total_sale_value': 200.0,
              'cost_price': 30.0,
              'cogs': 120.0,
            },
            localVersion: 2,
            currentServerVersion: 6,
            cloudUuid: 'client-uuid-div',
          ),
          deleteEntity: (
              {required adapter,
              required shopId,
              required cloudUuid,
              required entityId,
              String? idempotencyKey}) async {},
        ),
        localDb: db,
        conflictAuditRepository: auditRepo,
      );

      final result = await engine.processQueue();

      expect(result.synced, 0, reason: 'review items are never counted synced');
      expect(result.conflicts, 1);
      final entry = await queueRowByKey('sale:client-uuid-div:UPDATE:TOK-DIV');
      expect(entry['status'], 'CONFLICT');
      expect(entry['resolution_status'], 'REVIEW_REQUIRED');

      final audits = await auditRepo
          .getByIdempotencyKey('sale:client-uuid-div:UPDATE:TOK-DIV');
      expect(audits, hasLength(1));
      expect(audits.first.status, ConflictLifecycleStatus.REVIEW_REQUIRED);
    });

    test(
        'OF-4: when the audit INSERT aborts, the queue transition cannot '
        'commit — audit-before-queue is atomic (INV-M17)', () async {
      await db.insert('products', {
        'name': 'Before Inject',
        'barcode': 'B-OF4',
        'openingQuantity': 1,
        'soldQuantity': 0,
        'returnedQuantity': 0,
        'currentQuantity': 1,
        'costPrice': 5.0,
        'totalInventoryCost': 5.0,
        'inventoryAdjustment': 0,
        'shop_id': 'shop-1',
        'cloud_uuid': 'prod-of4',
        'server_version': 2,
      });
      await db.execute('''
        CREATE TRIGGER trg_inject_of4_audit_failure
        BEFORE INSERT ON conflict_audit
        BEGIN
          SELECT RAISE(ABORT, 'OF-4 audit inject');
        END
      ''');
      await queueRepo.enqueue(
        entityType: SyncEntityType.product.label,
        entityId: 1,
        operation: SyncQueueOperation.UPDATE,
        payload: {
          'id': 1,
          'cloud_uuid': 'prod-of4',
          'server_version': 2,
          'name': 'Before Inject',
          'barcode': 'B-OF4',
          'updated_at': '2026-01-01T00:00:00Z',
        },
        idempotencyKey: 'product:prod-of4:UPDATE:TOK-OF4',
        shopId: 'shop-1',
        occurrenceToken: 'TOK-OF4',
      );

      final engine = SyncEngine(
        queueRepository: queueRepo,
        conflictResolver: ConflictResolver(standardAdapters()),
        adapters: standardAdapters(),
        connectivityCheck: () async => true,
        licenseCheck: () async => true,
        shopIdProvider: () async => 'shop-1',
        logger: (type, op, {details}) async =>
            logs.add('$type:$op${details != null ? ' ($details)' : ''}'),
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
              'barcode': 'B-OF4',
              'opening_quantity': 2,
              'updated_at': '2026-02-01T00:00:00Z',
            },
            localVersion: 2,
            currentServerVersion: 4,
            cloudUuid: 'prod-of4',
          ),
          deleteEntity: (
              {required adapter,
              required shopId,
              required cloudUuid,
              required entityId,
              String? idempotencyKey}) async {},
        ),
        localDb: db,
        conflictAuditRepository: auditRepo,
      );

      final result = await engine.processQueue();

      expect(result.synced, 0);
      expect(logs.any((l) => l.contains('CONFLICT_APPLY_FAILED')), isTrue);
      expect(logs.any((l) => l.contains('OF-4 audit inject')), isTrue);

      // Atomic OF-4: NO queue lifecycle transition committed ahead of the
      // audit evidence.
      final entry = (await db.query('sync_queue',
              where: 'idempotency_key = ?',
              whereArgs: ['product:prod-of4:UPDATE:TOK-OF4']))
          .first;
      expect(entry['status'], isNot('SYNCED'),
          reason: 'silent close without audit evidence is forbidden');
      expect((await db.query('conflict_audit')), isEmpty,
          reason: 'no evidence exists, therefore no transition may exist');

      final row =
          (await db.query('products', where: 'id = ?', whereArgs: [1])).first;
      expect(row['name'], 'Before Inject');
      expect(row['server_version'], 2);
    });
  });

  group('A5 15/16 — dormant drain, no accidental activation', () {
    test(
        'AppConfig.syncDrainEnabled stays false and the production transport '
        'construction performs zero RPC', () async {
      expect(AppConfig.syncDrainEnabled, isFalse,
          reason: 'drain must never be on by default in this slice');

      KeyedStockFixture builder = KeyedStockFixture();
      SyncCloudOperationsTransport(
        rpc: builder.call,
        allowOversell: false,
      ).toOperations();
      expect(builder.calls, isEmpty,
          reason: 'constructing + exposing the transport is side-effect free');
    });
  });
}

/// Migration-28 style emulation of the keyed, log-aware stock RPC surface:
///   - unknown key → execute; known key → return the ORIGINAL result wrapped
///     as an IDEMPOTENT envelope (same id/current_quantity/server_version),
///   - oversell guard without allow-oversell raises a server-side rejection,
///   - records every invocation for scope/key assertions.
class KeyedStockFixture {
  static const int openingQuantity = 10;
  int soldQuantity = 0;
  int serverVersion = 0;
  int saleCount = 0;
  bool failNextCallWithNetworkError = false;

  final Map<String, Map<String, dynamic>> _idempotencyLog = {};

  final List<RecordedCall> calls = [];

  /// Crash/network window D: the server applied the effect and committed its
  /// idempotency log, but the response is dropped before reaching the client.
  bool commitThenDropResponseOnce = false;

  int get currentQuantity => openingQuantity - soldQuantity;

  dynamic _lookup(String? key) {
    if (key == null || key.isEmpty) return null;
    final original = _idempotencyLog[key];
    if (original == null) return null;
    return {
      'status': 'IDEMPOTENT',
      'id': original['id'],
      'current_quantity': original['current_quantity'],
      'server_version': original['server_version'],
    };
  }

  Future<dynamic> call(String function, Map<String, dynamic> params) async {
    calls.add(RecordedCall(function, Map<String, dynamic>.of(params)));
    if (failNextCallWithNetworkError) {
      failNextCallWithNetworkError = false;
      throw CloudDataException(
        type: CloudDataErrorType.networkError,
        message: 'injected network failure before the response arrived',
      );
    }

    switch (function) {
      case 'create_cloud_sale_with_stock_v2':
        return _sale(params);
      default:
        throw UnimplementedError(function);
    }
  }

  Map<String, dynamic> _sale(Map<String, dynamic> p) {
    final prior = _lookup(p['p_idempotency_key'] as String?);
    if (prior != null) return prior;

    final quantity = p['p_quantity'] as int;
    if (quantity <= 0) {
      throw StateError('sale quantity must be positive');
    }
    final allow = p['p_allow_oversell'] == true;
    if (currentQuantity < quantity && !allow) {
      throw CloudDataException(
        type: CloudDataErrorType.insufficientStock,
        message: 'Insufficient stock: available $currentQuantity, '
            'requested $quantity',
      );
    }

    soldQuantity += quantity;
    serverVersion += 1;
    saleCount += 1;

    final result = <String, dynamic>{
      'status': 'SYNCED',
      'id': 'sale-$saleCount',
      'current_quantity': currentQuantity,
      'server_version': serverVersion,
    };
    _record(p['p_idempotency_key'] as String?, result);

    if (commitThenDropResponseOnce) {
      commitThenDropResponseOnce = false;
      throw CloudDataException(
        type: CloudDataErrorType.networkError,
        message: 'injected: response lost after server commit (window D)',
      );
    }
    return result;
  }

  void _record(String? key, Map<String, dynamic> result) {
    if (key == null || key.isEmpty) return;
    _idempotencyLog[key] = result;
  }
}

class RecordedCall {
  final String function;
  final Map<String, dynamic> params;

  RecordedCall(this.function, this.params);
}
