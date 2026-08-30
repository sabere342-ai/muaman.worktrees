import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:muaman_store/config/app_config.dart';
import 'package:muaman_store/errors/cloud_data_exception.dart';
import 'package:muaman_store/sync/adapters/entity_sync_adapter.dart';
import 'package:muaman_store/sync/adapters/product_sync_adapter.dart';
import 'package:muaman_store/sync/adapters/sale_sync_adapter.dart';
import 'package:muaman_store/sync/adapters/stock_adjustment_sync_adapter.dart';
import 'package:muaman_store/sync/conflict_audit_repository.dart';
import 'package:muaman_store/sync/conflict_resolver.dart';
import 'package:muaman_store/sync/reconciliation_service.dart';
import 'package:muaman_store/sync/stock_adjustment.dart';
import 'package:muaman_store/sync/sync_cloud_operations_transport.dart';
import 'package:muaman_store/sync/sync_engine.dart';
import 'package:muaman_store/sync/sync_queue_repository.dart';
import 'package:muaman_store/sync/sync_status.dart';

/// Phase P Group A A3 — Option C reconciliation routing (P-OD1 local half).
///
/// Drives the REAL A1 transport (allowOversell=true seam) against a full
/// local schema (sync_queue + products + sales + conflict_audit +
/// stock_adjustments) to prove the A3 contract end-to-end:
///   T1  a preserved OVERSOLD sale lands durable Option C artifacts
///   T2  the local inventory equation is never rewritten by reconciliation
///   T3  replay/retry idempotency — one logical event ⇒ one adjustment +
///       one audit + one adjustment sync op (same occurrence token)
///   T4  cross-shop queue work fails closed before any RPC
///   T5  row-level tenant mismatch inside reconciliation fails the txn
///   T6  the enqueued adjustment drains to `create_cloud_stock_adjustment`
///       and adopts the governing server adjustment uuid (SYNCED)
///   T7  policy seams (`adjustmentSink` → `ownerNotifier`) run post-commit;
///       a notifier failure never erases durable evidence
///   T8  non-oversold A5 success is untouched (still SYNCED)
///   T9  normal conflicts/failures are untouched
///   T10 drain stays dormant and transport construction is side-effect free
void main() {
  sqfliteFfiInit();

  late Database db;
  late SyncQueueRepository queueRepo;
  late ConflictAuditRepository auditRepo;
  late StockAdjustmentRepository adjustmentRepo;
  late OversoldRpcFixture fixture;
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
    await db.execute('''
      CREATE TABLE stock_adjustments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        shop_id TEXT NOT NULL,
        sale_id INTEGER,
        return_id INTEGER,
        product_barcode TEXT NOT NULL,
        product_id TEXT,
        projected_current INTEGER NOT NULL,
        shortfall INTEGER NOT NULL,
        related_event_ids TEXT,
        idempotency_key TEXT,
        status TEXT NOT NULL DEFAULT 'OPEN',
        cloud_uuid TEXT,
        created_at TEXT NOT NULL,
        resolved_at TEXT
      )
    ''');

    queueRepo = SyncQueueRepository(db);
    auditRepo = ConflictAuditRepository(db);
    adjustmentRepo = StockAdjustmentRepository(db);
    fixture = OversoldRpcFixture();
    logs.clear();
  });

  tearDown(() async {
    await db.close();
  });

  Map<SyncEntityType, EntitySyncAdapter> standardAdapters() => {
        SyncEntityType.product: ProductSyncAdapter(),
        SyncEntityType.sale: SaleSyncAdapter(),
        SyncEntityType.stockAdjustment: StockAdjustmentSyncAdapter(),
      };

  Future<void> seedProduct({
    String barcode = 'B-1',
    String shopId = 'shop-1',
    int opening = 10,
    String cloudUuid = 'prod-1',
  }) async {
    await db.insert('products', {
      'name': 'Widget',
      'barcode': barcode,
      'openingQuantity': opening,
      'soldQuantity': 0,
      'returnedQuantity': 0,
      'currentQuantity': opening,
      'costPrice': 30.0,
      'totalInventoryCost': opening * 30.0,
      'inventoryAdjustment': 0,
      'shop_id': shopId,
      'cloud_uuid': cloudUuid,
    });
  }

  Future<void> seedSaleRow({
    int id = 1,
    String shopId = 'shop-1',
    String cloudUuid = 'client-uuid-1',
    int quantity = 999,
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
      'server_version': 0,
    });
  }

  Future<void> enqueueSale({
    required int rowId,
    required String occurrenceToken,
    required String shopId,
    String? key,
    String? entityUuid,
  }) async {
    final cloudUuid = entityUuid ?? 'client-uuid-$rowId';
    final idempotencyKey = key ?? 'sale:$cloudUuid:CREATE:$occurrenceToken';
    await queueRepo.enqueue(
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
        'quantity': 999,
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

  /// Engine wired to the REAL A1 transport (allowOversell=true seam) and the
  /// full A3 local harness (adjustment + audit + reconciliation seams).
  SyncEngine transportEngine({
    String cycleShop = 'shop-1',
    ReconciliationService? reconciliation,
    bool localHarness = true,
  }) {
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
      cloudOps:
          SyncCloudOperationsTransport(rpc: fixture.call, allowOversell: true)
              .toOperations(),
      localDb: db,
      conflictAuditRepository: auditRepo,
      adjustmentRepository: localHarness ? adjustmentRepo : null,
      reconciliation: reconciliation,
    );
  }

  Future<Map<String, dynamic>> queueRowByKey(String key) async => (await db
          .query('sync_queue', where: 'idempotency_key = ?', whereArgs: [key]))
      .first;

  Future<Map<String, dynamic>> saleRow(int id) async =>
      (await db.query('sales', where: 'id = ?', whereArgs: [id])).first;

  Future<List<Map<String, dynamic>>> adjustments({String? shopId}) async {
    final where = shopId == null ? null : 'shop_id = ?';
    final args = shopId == null ? null : <Object?>[shopId];
    return db.query('stock_adjustments', where: where, whereArgs: args);
  }

  group('A3 T1/T2 — preserved OVERSOLD -> durable Option C artifacts', () {
    test(
        'the preserved sale lands a durable adjustment + open conflict audit '
        '(with resulting_adjustment_id) + enqueued adjustment sync, and the '
        'entry surfaces CONFLICT/REVIEW_REQUIRED', () async {
      await seedProduct();
      await seedSaleRow();
await enqueueSale(
        rowId: 1,
        occurrenceToken: 'TOK-OVER',
        shopId: 'shop-1',
      );

      final result = await transportEngine().processQueue();

      // Not a fake success, not a destructive failure: surfaced as
      // requires-reconciliation.
      expect(result.synced, 0);
      expect(result.conflicts, 1);
      expect(result.failed, 0);

      // Durable adjustment artifact (projected current is negative, shortfall
      // strictly positive, keyed deterministically to the occurrence token).
      final adj = await adjustments(shopId: 'shop-1');
      expect(adj.first['projected_current'], -989);
      expect(adj.first['shortfall'], 989);
      expect(adj.first['product_barcode'], 'B-1');
      expect(adj.first['product_id'], 'prod-1');
      expect(adj.first['status'], 'OPEN');
      expect(adj.first['idempotency_key'], 'sale:1:ADJUST:TOK-OVER');
      final adjId = adj.first['id'] as int;

      // Open conflict audit durably linked to the artifact.
      final audits =
          await auditRepo.getByIdempotencyKey('sale:1:ADJUST:TOK-OVER');
      expect(audits, hasLength(1));
      expect(audits.first.status, ConflictLifecycleStatus.REVIEW_REQUIRED);
      expect(audits.first.resultingAdjustmentId, adjId);
      expect(audits.first.entityUuid, 'sale-1',
          reason: 'the preserved sale carries the authoritative cloud uuid');
      expect(audits.first.productBarcode, 'B-1');

      // Requires-reconciliation surfacing in the existing status model.
      final entry = await queueRowByKey('sale:client-uuid-1:CREATE:TOK-OVER');
      expect(entry['status'], 'CONFLICT');
      expect(entry['resolution_status'], 'REVIEW_REQUIRED');

      // Adjustment sync operation enqueued (idempotent on the SAME key).
      final adjOp = await queueRowByKey('sale:1:ADJUST:TOK-OVER');
      expect(adjOp['entity_type'], 'stockAdjustment');
      expect(adjOp['entity_id'], adjId);
      expect(adjOp['status'], 'PENDING');
      final payload = Map<String, dynamic>.from(
          (jsonDecode(adjOp['payload'] as String) as Map)
              .cast<String, dynamic>());
      expect(payload['product_id'], 'prod-1');
      expect(payload['projected_current'], -989);
      expect(payload['shortfall'], 989);
      expect(payload['adjustment_type'], 'OVERSOLD');
      expect(payload['sale_id'], 'sale-1',
          reason: 'the RPC sale reference is the cloud uuid, not a local int');

      // The sale itself is PRESERVED and adopts the authoritative server
      // metadata (INV-M01: no legitimate event is ever lost).
      final row = await saleRow(1);
      expect(row['cloud_uuid'], 'sale-1');
      expect(row['server_version'], 1);
    });

    test('T2: the local inventory equation is never rewritten', () async {
      await seedProduct();
      await seedSaleRow();
await enqueueSale(
        rowId: 1,
        occurrenceToken: 'TOK-EQ',
        shopId: 'shop-1',
      );

      await transportEngine().processQueue();

      final product =
          (await db.query('products', where: 'id = ?', whereArgs: [1])).first;
      expect(product['currentQuantity'], 10,
          reason: 'reconciliation never rewrites the local current quantity');
      expect(product['soldQuantity'], 0);
      expect(product['inventoryAdjustment'], 0);
    });
  });

  group('A3 T3 — replay/retry idempotency (one logical event, one chain)', () {
    test(
        'the SAME occurrence token re-delivered under a DIFFERENT delivery key '
        'reuses ONE adjustment, ONE audit and ONE adjustment sync op',
        () async {
      await seedProduct();
      await seedSaleRow();
      // Two deliveries of the same logical oversold event: same occurrence
      // token, different delivery idempotency keys (crash-window re-delivery).
await enqueueSale(
        rowId: 1,
        occurrenceToken: 'TOK-RE',
        shopId: 'shop-1',
        key: 'sale:client-uuid-1:CREATE:TOK-RE',
      );
await enqueueSale(
        rowId: 1,
        occurrenceToken: 'TOK-RE',
        shopId: 'shop-1',
        key: 'sale:REDELIVERED:CREATE:TOK-RE',
      );

      final result = await transportEngine().processQueue();

      expect(result.conflicts, 2, reason: 'both deliveries surface for review');
      expect(await adjustments(), hasLength(1));
      expect(await db.query('conflict_audit'), hasLength(1));
      final adjOps = await db.query('sync_queue',
          where: 'entity_type = ?', whereArgs: ['stockAdjustment']);
      expect(adjOps, hasLength(1));
    });

    test(
        'a retry of the same delivery key (crash window D) never creates a '
        'second artifact: the entry is CONFLICT, so the cycle does not '
        're-execute it, and a manual re-delivery dedupes', () async {
      await seedProduct();
      await seedSaleRow();
      final key = 'sale:client-uuid-1:CREATE:TOK-D';
await enqueueSale(
          rowId: 1, occurrenceToken: 'TOK-D', shopId: 'shop-1', key: key);

      await transportEngine().processQueue();
      // The server committed OVERSOLD; a client crash loses nothing because
      // the entry is durably CONFLICT/REVIEW_REQUIRED.
      expect(await adjustments(), hasLength(1));
      expect(await db.query('conflict_audit'), hasLength(1));
      var entry = await queueRowByKey(key);
      expect(entry['status'], 'CONFLICT');

      // Re-process: the CONFLICT sale is not re-executed (not PENDING); the
      // only work is the legitimately pending adjustment op draining. The
      // sale RPC runs exactly once, and no second artifact/audit appears.
      final result = await transportEngine().processQueue();
      expect(result.processed, 1, reason: 'only the adjustment op drains');
      expect(result.synced, 1);
      expect(fixture.calls
              .where((c) => c.function == 'create_cloud_sale_with_stock_v2')
              .length,
          1,
          reason: 'the CONFLICT sale is never re-executed');
      expect(await adjustments(), hasLength(1));
      expect(await db.query('conflict_audit'), hasLength(1));
    });
  });

  group('A3 T4/T5 — tenant isolation (fail closed)', () {
    test('T4: cross-shop queue work is never pulled or executed', () async {
      await seedProduct();
      await seedSaleRow(shopId: 'shop-2');
      enqueueSale(rowId: 1, occurrenceToken: 'TOK-X', shopId: 'shop-2');

      final result = await transportEngine().processQueue();

      expect(result.processed, 0);
      expect(fixture.calls, isEmpty,
          reason: 'cross-shop work must never reach ANY RPC');
      final entry = await queueRowByKey('sale:client-uuid-1:CREATE:TOK-X');
      expect(entry['status'], 'PENDING');
    });

    test('T5: row-level tenant mismatch fails reconciliation closed', () async {
      await seedProduct();
      await seedSaleRow(shopId: 'shop-9');
      enqueueSale(rowId: 1, occurrenceToken: 'TOK-Y', shopId: 'shop-1');

      final result = await transportEngine().processQueue();

      expect(result.synced, 0);
      expect(result.failed, 1);
      expect(logs.any((l) => l.contains('tenant guard')), isTrue,
          reason: 'the tenant guard must be the observable cause');
      expect(await adjustments(), isEmpty,
          reason: 'no Option C evidence may commit for a cross-shop row');
      expect(await db.query('conflict_audit'), isEmpty);
    });
  });

  group('A3 T6 — adjustment drain to the A4 RPC', () {
    test(
        'the enqueued stockAdjustment drains through '
        'create_cloud_stock_adjustment and adopts the governing server '
        'uuid (SYNCED), never writing fake sync fields onto the evidence '
        'table', () async {
      await seedProduct();
      await seedSaleRow();
      enqueueSale(rowId: 1, occurrenceToken: 'TOK-DRAIN', shopId: 'shop-1');

      // First cycle: oversold routing + adjustment enqueue.
      await transportEngine().processQueue();
      expect(await adjustments(), hasLength(1));

      // Second cycle: the adjustment op drains.
      final result = await transportEngine().processQueue();
      expect(result.synced, 1);

      final adjCalls = fixture.calls
          .where((c) => c.function == 'create_cloud_stock_adjustment')
          .toList();
      expect(adjCalls, hasLength(1));
      expect(adjCalls.first.params['p_product_id'], 'prod-1');
      expect(adjCalls.first.params['p_projected_current'], -989);
      expect(adjCalls.first.params['p_shortfall'], 989);
      expect(adjCalls.first.params['p_adjustment_type'], 'OVERSOLD');
      expect(adjCalls.first.params['p_sale_id'], 'sale-1');
      expect(adjCalls.first.params['p_shop_id'], 'shop-1');
      expect(adjCalls.first.params['p_idempotency_key'],
          'sale:1:ADJUST:TOK-DRAIN');

      final adj = (await adjustments()).first;
      expect(adj['cloud_uuid'], 'cloud-adj-1',
          reason: 'the governing server adjustment uuid is adopted');
      expect(adj['status'], 'SYNCED');

      final op = await queueRowByKey('sale:1:ADJUST:TOK-DRAIN');
      expect(op['status'], 'SYNCED');
    });

    test(
        'adjustment drain remains tenant-scoped and idempotent on the '
        'persisted key', () async {
      await seedProduct();
      await seedSaleRow();
      enqueueSale(rowId: 1, occurrenceToken: 'TOK-D2', shopId: 'shop-1');
      await transportEngine().processQueue();

      // Drain the adjustment once.
      await transportEngine().processQueue();

      // A second drain cycle executes nothing (the op is SYNCED).
      final result = await transportEngine().processQueue();
      expect(result.processed, 0);

      final adjCalls = fixture.calls
          .where((c) => c.function == 'create_cloud_stock_adjustment')
          .toList();
      expect(adjCalls, hasLength(1));
    });
  });

  group('A3 T7 — policy seams run post-commit, never roll back evidence', () {
    test('adjustmentSink + ownerNotifier are invoked after durable commit',
        () async {
      await seedProduct();
      await seedSaleRow();
      enqueueSale(rowId: 1, occurrenceToken: 'TOK-P1', shopId: 'shop-1');

      final artifacts = <OversellAdjustmentArtifact>[];
      final notified = <OversellAdjustmentArtifact>[];
      final reconciliation = ReconciliationService(
        adjustmentSink: (a) async => artifacts.add(a),
        ownerNotifier: (a) async => notified.add(a),
      );

      await transportEngine(reconciliation: reconciliation).processQueue();

      expect(await adjustments(), hasLength(1),
          reason: 'durable evidence exists regardless of seam invocation');
      expect(artifacts, hasLength(1));
      expect(artifacts.first.shortfall, 989);
      expect(artifacts.first.barcode, 'B-1');
      expect(artifacts.first.shopId, 'shop-1');
      expect(notified, hasLength(1));

      final adj = (await adjustments()).first;
      expect(adj['status'], 'OPEN', reason: 'evidence is not tied to seams');
    });

    test('a failing ownerNotifier never erases the durable evidence', () async {
      await seedProduct();
      await seedSaleRow();
      enqueueSale(rowId: 1, occurrenceToken: 'TOK-P2', shopId: 'shop-1');

      final reconciliation = ReconciliationService(
        adjustmentSink: (a) async {},
        ownerNotifier: (a) async => throw StateError('channel down'),
      );

      final result =
          await transportEngine(reconciliation: reconciliation).processQueue();

      expect(result.conflicts, 1);
      expect(await adjustments(), hasLength(1),
          reason: 'notification failure is not durability');
      expect(await db.query('conflict_audit'), hasLength(1));
      expect(logs.any((l) => l.contains('OWNER_NOTIFY_FAILED')), isTrue);
    });
  });

  group('A3 T8/T9 — untouched A5 paths', () {
    test('T8: a normal (non-oversold) sale still syncs SYNCED as before',
        () async {
      await db.insert('sales', {
        'date': '2026-08-20T10:00:00Z',
        'productName': 'Widget',
        'barcode': 'B-1',
        'quantity': 2,
        'salePrice': 50.0,
        'totalSaleValue': 100.0,
        'costPrice': 30.0,
        'cogs': 60.0,
        'shop_id': 'shop-1',
        'cloud_uuid': 'client-uuid-n',
        'server_version': 0,
      });
      // The fixture accepts qty 2 (available stock 10 >= 2... in the A3
      // fixture oversell only triggers when qty > stock).
      queueRepo.enqueue(
        entityType: SyncEntityType.sale.label,
        entityId: 1,
        operation: SyncQueueOperation.CREATE,
        payload: {
          'id': 1,
          'cloud_uuid': 'client-uuid-n',
          'server_version': 0,
          'date': '2026-08-20T10:00:00Z',
          'product_name': 'Widget',
          'barcode': 'B-1',
          'quantity': 2,
          'sale_price': 50.0,
          'total_sale_value': 100.0,
          'cost_price': 30.0,
          'cogs': 60.0,
        },
        idempotencyKey: 'sale:client-uuid-n:CREATE:TOK-N',
        shopId: 'shop-1',
        occurrenceToken: 'TOK-N',
      );

      final result = await transportEngine().processQueue();

      expect(result.synced, 1, reason: 'A5 success path is untouched');
      expect(result.conflicts, 0);
      expect(await adjustments(), isEmpty);
      expect(await db.query('conflict_audit'), isEmpty);
      expect(fixture.saleCount, 1);
      final row = await saleRow(1);
      expect(row['cloud_uuid'], 'sale-1');
    });

    test(
        'T9: allowOversell=false insufficient-stock rejection maps to '
        'insufficientStock at the transport boundary (A5 regression)',
        () async {
      // The engine-level fail-closed path (markFailed / never SYNCED /
      // entering PENDING with one retry) is already governed by the unchanged
      // A5 test (`idempotency_convergence_test` line 417). Here we pin the
      // transport boundary: an overselling quantity WITHOUT the oversell seam
      // is still rejected as insufficientStock, never oversold-classified.
      final transport = SyncCloudOperationsTransport(
        rpc: fixture.call,
        allowOversell: false,
      );
      await expectLater(
        transport.upsertEntity(
          adapter: SaleSyncAdapter(),
          shopId: 'shop-1',
          localId: 1,
          payload: {
            'barcode': 'B-1',
            'quantity': 999,
            'sale_price': 50.0,
            'date': '2026-08-20T10:00:00Z',
          },
          idempotencyKey: 'k-9',
        ),
        throwsA(isA<CloudDataException>().having(
            (e) => e.type, 'type', CloudDataErrorType.insufficientStock)),
      );
    });
  });

  group('A3 T10 — dormant drain', () {
    test(
        'AppConfig.syncDrainEnabled stays false and the production transport '
        'construction performs zero RPC', () async {
      expect(AppConfig.syncDrainEnabled, isFalse,
          reason: 'drain must never be on by default in this slice');
      OversoldRpcFixture builder = OversoldRpcFixture();
      SyncCloudOperationsTransport(
        rpc: builder.call,
        allowOversell: false,
      ).toOperations();
      expect(builder.calls, isEmpty,
          reason: 'constructing + exposing the transport is side-effect free');
    });
  });
}

/// RPC fixture for A3: accepts and PRESERVES oversold sales when
/// `allowOversell=true` (returning status OVERSOLD + the exact projected
/// stock), rejects with insufficientStock otherwise, and answers the A4
/// adjustment RPC with a scalar uuid. Idempotency-log aware on every key.
class OversoldRpcFixture {
  static const int openingQuantity = 10;
  int soldQuantity = 0;
  int serverVersion = 0;
  int saleCount = 0;
  int adjustmentCount = 0;
  bool failNextCallWithNetworkError = false;

  final Map<String, Map<String, dynamic>> _saleIdempotencyLog = {};
  final List<RecordedCall> calls = [];

  int get currentQuantity => openingQuantity - soldQuantity;

  dynamic _lookupSale(String? key) {
    if (key == null || key.isEmpty) return null;
    final original = _saleIdempotencyLog[key];
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
      case 'create_cloud_stock_adjustment':
        return _adjustment(params);
      default:
        throw UnimplementedError(function);
    }
  }

  Map<String, dynamic> _sale(Map<String, dynamic> p) {
    final prior = _lookupSale(p['p_idempotency_key'] as String?);
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

    final projected = currentQuantity;
    final result = <String, dynamic>{
      'status': projected < 0 ? 'OVERSOLD' : 'SYNCED',
      'id': 'sale-$saleCount',
      'current_quantity': projected,
      'server_version': serverVersion,
    };
    final key = p['p_idempotency_key'] as String?;
    if (key == null || key.isEmpty) {
      return result;
    }
    _saleIdempotencyLog[key] = result;
    return result;
  }

  dynamic _adjustment(Map<String, dynamic> p) {
    adjustmentCount += 1;
    return 'cloud-adj-$adjustmentCount';
  }
}

class RecordedCall {
  final String function;
  final Map<String, dynamic> params;

  RecordedCall(this.function, this.params);
}
