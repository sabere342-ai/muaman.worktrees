import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:muaman_store/sync/sync_queue_repository.dart';
import 'package:muaman_store/sync/sync_engine.dart';
import 'package:muaman_store/sync/sync_worker.dart';
import 'package:muaman_store/sync/conflict_resolver.dart';
import 'package:muaman_store/sync/hydration_service.dart';
import 'package:muaman_store/sync/adapters/product_sync_adapter.dart';
import 'package:muaman_store/sync/adapters/sale_sync_adapter.dart';
import 'package:muaman_store/sync/adapters/expense_sync_adapter.dart';
import 'package:muaman_store/sync/sync_status.dart';

void main() {
  sqfliteFfiInit();

  late Database testDb;
  late SyncQueueRepository queueRepo;

  setUp(() async {
    testDb =
        await databaseFactoryFfiNoIsolate.openDatabase(inMemoryDatabasePath);
    await testDb.execute('''
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
        shop_id TEXT
      )
    ''');

    await testDb.execute('''
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

    queueRepo = SyncQueueRepository(testDb);
  });

  tearDown(() async {
    await testDb.close();
  });

  group('Integration: Offline -> Online sync cycle', () {
    test('queue entries created offline are processed when online', () async {
      final syncedOps = <String>[];

      final engine = SyncEngine(
        queueRepository: queueRepo,
        conflictResolver: ConflictResolver({
          SyncEntityType.product: ProductSyncAdapter(),
        }),
        adapters: {SyncEntityType.product: ProductSyncAdapter()},
        connectivityCheck: () async => true,
        licenseCheck: () async => true,
        shopIdProvider: () async => 'test-shop',
        logger: (type, op, {details}) async {},
        cloudOps: SyncCloudOperations(
          upsertEntity: ({
            required adapter,
            required shopId,
            required localId,
            required payload,
            required idempotencyKey,
          }) async {
            syncedOps.add(idempotencyKey);
            return CloudUpsertResult(success: true);
          },
          deleteEntity: ({
            required adapter,
            required shopId,
            required cloudUuid,
            required entityId,
          }) async {},
        ),
      );

      // Simulate offline: enqueue operations
      await queueRepo.enqueue(
        entityType: 'product',
        entityId: 1,
        operation: SyncQueueOperation.CREATE,
        payload: {'name': 'Offline Product 1'},
        idempotencyKey: 'off-1',
        shopId: 'test-shop',
      );
      await queueRepo.enqueue(
        entityType: 'product',
        entityId: 2,
        operation: SyncQueueOperation.CREATE,
        payload: {'name': 'Offline Product 2'},
        idempotencyKey: 'off-2',
        shopId: 'test-shop',
      );
      await queueRepo.enqueue(
        entityType: 'product',
        entityId: 1,
        operation: SyncQueueOperation.UPDATE,
        payload: {'name': 'Updated Product 1'},
        idempotencyKey: 'off-3',
        shopId: 'test-shop',
      );

      // Verify all pending
      expect(await queueRepo.getPendingCount(), 3);

      // Go online: process queue
      final result = await engine.processQueue();

      expect(result.processed, 3);
      expect(result.synced, 3);
      expect(result.failed, 0);
      expect(syncedOps, hasLength(3));
      expect(await queueRepo.getPendingCount(), 0);
    });

    test('hydration pulls cloud data into local database', () async {
      final cloudSource = HydrationCloudSource(
        fetchAll: ({required shopId, required adapter}) async => [
          {
            'id': 'cloud-p1',
            'name': 'Cloud Product',
            'barcode': 'CLOUD-001',
            'opening_quantity': 20,
            'sold_quantity': 5,
            'returned_quantity': 0,
            'current_quantity': 15,
            'cost_price': 30.0,
            'total_inventory_cost': 450.0,
            'inventory_adjustment': 0,
            'server_version': 3,
          },
        ],
      );

      final hydration = HydrationService(
        db: testDb,
        cloudSource: cloudSource,
        logger: (msg) async {},
      );

      final result = await hydration.hydrate(
        shopId: 'test-shop',
        adapters: [ProductSyncAdapter()],
      );

      expect(result.inserted, 1);

      final localRows = await testDb.query('products');
      expect(localRows, hasLength(1));
      expect(localRows.first['cloud_uuid'], 'cloud-p1');
      expect(localRows.first['name'], 'Cloud Product');
    });
  });

  group('Integration: SyncWorker lifecycle', () {
    test('start/stop/syncNow lifecycle', () async {
      int syncCount = 0;

      final engine = SyncEngine(
        queueRepository: queueRepo,
        conflictResolver: ConflictResolver({
          SyncEntityType.product: ProductSyncAdapter(),
        }),
        adapters: {SyncEntityType.product: ProductSyncAdapter()},
        connectivityCheck: () async => true,
        licenseCheck: () async => true,
        shopIdProvider: () async => 'test-shop',
        logger: (type, op, {details}) async {},
        cloudOps: SyncCloudOperations(
          upsertEntity: ({
            required adapter,
            required shopId,
            required localId,
            required payload,
            required idempotencyKey,
          }) async {
            syncCount++;
            return CloudUpsertResult(success: true);
          },
          deleteEntity: ({
            required adapter,
            required shopId,
            required cloudUuid,
            required entityId,
          }) async {},
        ),
      );

      final worker = SyncWorker(
        engine: engine,
        connectivityCheck: () async => true,
        sessionCheck: () async => true,
        logger: (msg) async {},
        interval: const Duration(hours: 1),
      );

      expect(worker.state, SyncWorkerState.stopped);

      worker.start();
      expect(worker.state, SyncWorkerState.running);

      await worker.syncNow();
      expect(syncCount, 0);

      await queueRepo.enqueue(
        entityType: 'product',
        entityId: 1,
        operation: SyncQueueOperation.CREATE,
        payload: {'name': 'Test'},
        idempotencyKey: 'w-1',
        shopId: 'test-shop',
      );

      await worker.syncNow();
      expect(syncCount, 1);
      expect(await queueRepo.getPendingCount(), 0);

      worker.stop();
      expect(worker.state, SyncWorkerState.stopped);

      worker.dispose();
    });

    test('worker skips cycle when session invalid', () async {
      int syncCount = 0;

      final engine = SyncEngine(
        queueRepository: queueRepo,
        conflictResolver: ConflictResolver({
          SyncEntityType.product: ProductSyncAdapter(),
        }),
        adapters: {SyncEntityType.product: ProductSyncAdapter()},
        connectivityCheck: () async => true,
        licenseCheck: () async => true,
        shopIdProvider: () async => 'test-shop',
        logger: (type, op, {details}) async {},
        cloudOps: SyncCloudOperations(
          upsertEntity: ({
            required adapter,
            required shopId,
            required localId,
            required payload,
            required idempotencyKey,
          }) async {
            syncCount++;
            return CloudUpsertResult(success: true);
          },
          deleteEntity: ({
            required adapter,
            required shopId,
            required cloudUuid,
            required entityId,
          }) async {},
        ),
      );

      final worker = SyncWorker(
        engine: engine,
        connectivityCheck: () async => true,
        sessionCheck: () async => false,
        logger: (msg) async {},
      );

      worker.start();
      await worker.syncNow();
      expect(syncCount, 0);

      worker.dispose();
    });
  });

  group('Integration: Idempotency across full cycle', () {
    test('re-enqueue same operation after sync is idempotent', () async {
      final engine = SyncEngine(
        queueRepository: queueRepo,
        conflictResolver: ConflictResolver({
          SyncEntityType.product: ProductSyncAdapter(),
        }),
        adapters: {SyncEntityType.product: ProductSyncAdapter()},
        connectivityCheck: () async => true,
        licenseCheck: () async => true,
        shopIdProvider: () async => 'test-shop',
        logger: (type, op, {details}) async {},
        cloudOps: SyncCloudOperations(
          upsertEntity: ({
            required adapter,
            required shopId,
            required localId,
            required payload,
            required idempotencyKey,
          }) async =>
              CloudUpsertResult(success: true),
          deleteEntity: ({
            required adapter,
            required shopId,
            required cloudUuid,
            required entityId,
          }) async {},
        ),
      );

      await queueRepo.enqueue(
        entityType: 'product',
        entityId: 1,
        operation: SyncQueueOperation.CREATE,
        payload: {'name': 'Widget'},
        idempotencyKey: 'idem-cycle-1',
        shopId: 'test-shop',
      );

      await engine.processQueue();
      expect(await queueRepo.getPendingCount(), 0);

      await queueRepo.enqueue(
        entityType: 'product',
        entityId: 1,
        operation: SyncQueueOperation.CREATE,
        payload: {'name': 'Widget'},
        idempotencyKey: 'idem-cycle-1',
        shopId: 'test-shop',
      );

      expect(await queueRepo.getPendingCount(), 0);
    });
  });

  group('Integration: Multi-entity sync', () {
    test('processes mixed entity types in FIFO order', () async {
      final processedTypes = <String>[];

      final engine = SyncEngine(
        queueRepository: queueRepo,
        conflictResolver: ConflictResolver({
          SyncEntityType.product: ProductSyncAdapter(),
          SyncEntityType.sale: SaleSyncAdapter(),
          SyncEntityType.expense: ExpenseSyncAdapter(),
        }),
        adapters: {
          SyncEntityType.product: ProductSyncAdapter(),
          SyncEntityType.sale: SaleSyncAdapter(),
          SyncEntityType.expense: ExpenseSyncAdapter(),
        },
        connectivityCheck: () async => true,
        licenseCheck: () async => true,
        shopIdProvider: () async => 'test-shop',
        logger: (type, op, {details}) async {},
        cloudOps: SyncCloudOperations(
          upsertEntity: ({
            required adapter,
            required shopId,
            required localId,
            required payload,
            required idempotencyKey,
          }) async {
            processedTypes.add(adapter.entityType.label);
            return CloudUpsertResult(success: true);
          },
          deleteEntity: ({
            required adapter,
            required shopId,
            required cloudUuid,
            required entityId,
          }) async {},
        ),
      );

      await queueRepo.enqueue(
        entityType: 'expense',
        entityId: 1,
        operation: SyncQueueOperation.CREATE,
        payload: {'id': 1, 'name': 'Test Expense'},
        idempotencyKey: 'mix-1',
        shopId: 'test-shop',
      );
      await queueRepo.enqueue(
        entityType: 'product',
        entityId: 1,
        operation: SyncQueueOperation.CREATE,
        payload: {'id': 1, 'name': 'Test Product'},
        idempotencyKey: 'mix-2',
        shopId: 'test-shop',
      );
      await queueRepo.enqueue(
        entityType: 'sale',
        entityId: 1,
        operation: SyncQueueOperation.CREATE,
        payload: {'id': 1, 'productName': 'Test Sale'},
        idempotencyKey: 'mix-3',
        shopId: 'test-shop',
      );

      final result = await engine.processQueue();

      expect(result.processed, 3);
      expect(result.synced, 3);
      expect(processedTypes, ['expense', 'product', 'sale']);
    });
  });
}
