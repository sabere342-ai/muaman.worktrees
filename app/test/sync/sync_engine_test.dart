import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:muaman_store/errors/cloud_data_exception.dart';
import 'package:muaman_store/sync/sync_engine.dart';
import 'package:muaman_store/sync/sync_queue_repository.dart';
import 'package:muaman_store/sync/conflict_resolver.dart';
import 'package:muaman_store/sync/adapters/entity_sync_adapter.dart';
import 'package:muaman_store/sync/adapters/product_sync_adapter.dart';
import 'package:muaman_store/sync/adapters/sale_sync_adapter.dart';
import 'package:muaman_store/sync/sync_status.dart';

void main() {
  sqfliteFfiInit();

  late Database testDb;
  late SyncQueueRepository queueRepo;
  late ConflictResolver conflictResolver;
  late SyncEngine engine;
  final logs = <String>[];

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

    queueRepo = SyncQueueRepository(testDb);

    final adapters = <SyncEntityType, EntitySyncAdapter>{
      SyncEntityType.product: ProductSyncAdapter(),
      SyncEntityType.sale: SaleSyncAdapter(),
    };
    conflictResolver = ConflictResolver(adapters);

    logs.clear();
    engine = SyncEngine(
      queueRepository: queueRepo,
      conflictResolver: conflictResolver,
      adapters: adapters,
      connectivityCheck: () async => true,
      licenseCheck: () async => true,
      shopIdProvider: () async => 'test-shop',
      logger: (type, op, {details}) async {
        logs.add('$type:$op${details != null ? ' ($details)' : ''}');
      },
    );
  });

  tearDown(() async {
    await testDb.close();
  });

  group('SyncEngine.processQueue', () {
    test('skips when offline', () async {
      engine = SyncEngine(
        queueRepository: queueRepo,
        conflictResolver: conflictResolver,
        adapters: {SyncEntityType.product: ProductSyncAdapter()},
        connectivityCheck: () async => false,
        licenseCheck: () async => true,
        shopIdProvider: () async => 'test-shop',
        logger: (type, op, {details}) async {},
      );

      final result = await engine.processQueue();
      expect(result.skippedOffline, isTrue);
      expect(result.processed, 0);
    });

    test('skips when license is expired', () async {
      engine = SyncEngine(
        queueRepository: queueRepo,
        conflictResolver: conflictResolver,
        adapters: {SyncEntityType.product: ProductSyncAdapter()},
        connectivityCheck: () async => true,
        licenseCheck: () async => false,
        shopIdProvider: () async => 'test-shop',
        logger: (type, op, {details}) async {},
      );

      final result = await engine.processQueue();
      expect(result.skippedLicenseExpired, isTrue);
      expect(result.processed, 0);
    });

    test('skips when no shop ID', () async {
      engine = SyncEngine(
        queueRepository: queueRepo,
        conflictResolver: conflictResolver,
        adapters: {SyncEntityType.product: ProductSyncAdapter()},
        connectivityCheck: () async => true,
        licenseCheck: () async => true,
        shopIdProvider: () async => null,
        logger: (type, op, {details}) async {},
      );

      final result = await engine.processQueue();
      expect(result.skippedNoShop, isTrue);
      expect(result.processed, 0);
    });

    test('processes entries and marks synced when cloud ops succeed', () async {
      engine = SyncEngine(
        queueRepository: queueRepo,
        conflictResolver: conflictResolver,
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
        idempotencyKey: 'idem-001',
        shopId: 'test-shop',
      );

      final result = await engine.processQueue();
      expect(result.processed, 1);
      expect(result.synced, 1);
      expect(result.failed, 0);

      final pending = await queueRepo.getPendingEntries();
      expect(pending, isEmpty);
    });

    test('marks entry as failed when permission denied', () async {
      engine = SyncEngine(
        queueRepository: queueRepo,
        conflictResolver: conflictResolver,
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
              throw CloudDataException(
            type: CloudDataErrorType.permissionDenied,
            message: 'No permission',
          ),
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
        idempotencyKey: 'idem-perm',
        shopId: 'test-shop',
      );

      final result = await engine.processQueue();
      expect(result.failed, 1);

      final entry = (await testDb.query('sync_queue',
              where: 'idempotency_key = ?', whereArgs: ['idem-perm']))
          .first;
      expect(entry['retry_count'], 1);
    });

    test('handles conflict and resolves via LWW', () async {
      engine = SyncEngine(
        queueRepository: queueRepo,
        conflictResolver: conflictResolver,
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
              CloudUpsertResult(
            conflict: true,
            serverData: {'name': 'Server Version'},
            localVersion: 2,
            currentServerVersion: 5,
          ),
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
        operation: SyncQueueOperation.UPDATE,
        payload: {'id': 1, 'name': 'Local Version'},
        idempotencyKey: 'idem-conflict',
        shopId: 'test-shop',
      );

      final result = await engine.processQueue();
      expect(result.synced, 1);
      expect(result.conflicts, 0);
    });

    test('marks as conflict when resolution returns null', () async {
      engine = SyncEngine(
        queueRepository: queueRepo,
        conflictResolver: conflictResolver,
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
              CloudUpsertResult(
            conflict: true,
            serverData: {},
            localVersion: 5,
            currentServerVersion: 5,
          ),
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
        operation: SyncQueueOperation.UPDATE,
        payload: {'name': 'Local'},
        idempotencyKey: 'idem-no-resolve',
        shopId: 'test-shop',
      );

      final result = await engine.processQueue();
      expect(result.conflicts, 1);
    });
  });
}
