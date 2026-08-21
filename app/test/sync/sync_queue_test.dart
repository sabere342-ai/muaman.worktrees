import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:muaman_store/sync/sync_queue_repository.dart';
import 'package:muaman_store/sync/sync_status.dart';

void main() {
  sqfliteFfiInit();

  late Database testDb;
  late SyncQueueRepository repo;

  setUp(() async {
    testDb = await databaseFactoryFfiNoIsolate.openDatabase(inMemoryDatabasePath);
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
    repo = SyncQueueRepository(testDb);
  });

  tearDown(() async {
    await testDb.close();
  });

  group('SyncQueueRepository.enqueue', () {
    test('creates a new pending entry', () async {
      await repo.enqueue(
        entityType: 'product',
        entityId: 1,
        operation: SyncQueueOperation.CREATE,
        payload: {'name': 'Test'},
        idempotencyKey: 'key-001',
        shopId: 'shop-001',
      );

      final entries = await repo.getPendingEntries(shopId: 'shop-001');
      expect(entries, hasLength(1));
      expect(entries.first.entityType, 'product');
      expect(entries.first.entityId, 1);
      expect(entries.first.operation, SyncQueueOperation.CREATE);
      expect(entries.first.status, SyncQueueStatus.PENDING);
      expect(entries.first.idempotencyKey, 'key-001');
      expect(entries.first.shopId, 'shop-001');
      expect(entries.first.payload, {'name': 'Test'});
    });

    test('does not duplicate entries with same idempotency key', () async {
      await repo.enqueue(
        entityType: 'product',
        entityId: 1,
        operation: SyncQueueOperation.CREATE,
        idempotencyKey: 'key-dup',
        shopId: 'shop-001',
      );

      await repo.enqueue(
        entityType: 'product',
        entityId: 1,
        operation: SyncQueueOperation.UPDATE,
        idempotencyKey: 'key-dup',
        shopId: 'shop-001',
      );

      final entries = await repo.getPendingEntries(shopId: 'shop-001');
      expect(entries, hasLength(1));
    });
  });

  group('SyncQueueRepository.getPendingEntries', () {
    test('returns only PENDING entries', () async {
      await repo.enqueue(
        entityType: 'product', entityId: 1, operation: SyncQueueOperation.CREATE,
        idempotencyKey: 'k1', shopId: 's1',
      );
      await repo.enqueue(
        entityType: 'sale', entityId: 2, operation: SyncQueueOperation.CREATE,
        idempotencyKey: 'k2', shopId: 's1',
      );

      await repo.markSynced((await repo.getPendingEntries()).first.id);

      final pending = await repo.getPendingEntries(shopId: 's1');
      expect(pending, hasLength(1));
      expect(pending.first.entityType, 'sale');
    });

    test('returns entries in FIFO order', () async {
      await repo.enqueue(
        entityType: 'product', entityId: 1, operation: SyncQueueOperation.CREATE,
        idempotencyKey: 'k1',
      );
      await repo.enqueue(
        entityType: 'product', entityId: 2, operation: SyncQueueOperation.UPDATE,
        idempotencyKey: 'k2',
      );

      final entries = await repo.getPendingEntries();
      expect(entries.first.entityId, 1);
      expect(entries.last.entityId, 2);
    });

    test('filters by shop_id', () async {
      await repo.enqueue(
        entityType: 'product', entityId: 1, operation: SyncQueueOperation.CREATE,
        idempotencyKey: 'k1', shopId: 'shop-a',
      );
      await repo.enqueue(
        entityType: 'product', entityId: 2, operation: SyncQueueOperation.CREATE,
        idempotencyKey: 'k2', shopId: 'shop-b',
      );

      final shopA = await repo.getPendingEntries(shopId: 'shop-a');
      expect(shopA, hasLength(1));
      expect(shopA.first.shopId, 'shop-a');
    });
  });

  group('SyncQueueRepository status transitions', () {
    test('markSynced sets status and synced_at', () async {
      await repo.enqueue(
        entityType: 'product', entityId: 1, operation: SyncQueueOperation.CREATE,
        idempotencyKey: 'k1',
      );
      final entries = await repo.getPendingEntries();
      final entryId = entries.first.id;

      await repo.markSynced(entryId);

      final failed = await repo.getFailedEntries();
      final pending = await repo.getPendingEntries();
      expect(failed, isEmpty);
      expect(pending, isEmpty);
    });

    test('markFailed increments retry_count', () async {
      await repo.enqueue(
        entityType: 'product', entityId: 1, operation: SyncQueueOperation.CREATE,
        idempotencyKey: 'k1',
      );
      final entryId = (await repo.getPendingEntries()).first.id;

      await repo.markFailed(entryId);

      final entry = (await testDb.query('sync_queue', where: 'id = ?', whereArgs: [entryId])).first;
      expect(entry['retry_count'], 1);
      expect(entry['status'], 'PENDING');
    });

    test('markFailed sets FAILED after 5 retries', () async {
      await repo.enqueue(
        entityType: 'product', entityId: 1, operation: SyncQueueOperation.CREATE,
        idempotencyKey: 'k1',
      );
      final entryId = (await repo.getPendingEntries()).first.id;

      for (var i = 0; i < 6; i++) {
        await repo.markFailed(entryId);
      }

      final entry = (await testDb.query('sync_queue', where: 'id = ?', whereArgs: [entryId])).first;
      expect(entry['status'], 'FAILED');
    });

    test('markConflict sets CONFLICT status and data', () async {
      await repo.enqueue(
        entityType: 'product', entityId: 1, operation: SyncQueueOperation.CREATE,
        idempotencyKey: 'k1',
      );
      final entryId = (await repo.getPendingEntries()).first.id;

      await repo.markConflict(entryId, '{"server_version": 5}');

      final entry = (await testDb.query('sync_queue', where: 'id = ?', whereArgs: [entryId])).first;
      expect(entry['status'], 'CONFLICT');
      expect(entry['conflict_data'], '{"server_version": 5}');
    });

    test('retryEntry resets to PENDING with retry_count 0', () async {
      await repo.enqueue(
        entityType: 'product', entityId: 1, operation: SyncQueueOperation.CREATE,
        idempotencyKey: 'k1',
      );
      final entryId = (await repo.getPendingEntries()).first.id;

      await repo.markFailed(entryId);
      await repo.markFailed(entryId);
      await repo.retryEntry(entryId);

      final entry = (await testDb.query('sync_queue', where: 'id = ?', whereArgs: [entryId])).first;
      expect(entry['status'], 'PENDING');
      expect(entry['retry_count'], 0);
    });
  });

  group('SyncQueueRepository counts', () {
    test('getPendingCount returns correct count', () async {
      expect(await repo.getPendingCount(), 0);

      await repo.enqueue(
        entityType: 'product', entityId: 1, operation: SyncQueueOperation.CREATE,
        idempotencyKey: 'k1', shopId: 's1',
      );
      await repo.enqueue(
        entityType: 'product', entityId: 2, operation: SyncQueueOperation.CREATE,
        idempotencyKey: 'k2', shopId: 's1',
      );

      expect(await repo.getPendingCount(shopId: 's1'), 2);
    });

    test('getFailedCount returns correct count', () async {
      expect(await repo.getFailedCount(), 0);

      await repo.enqueue(
        entityType: 'product', entityId: 1, operation: SyncQueueOperation.CREATE,
        idempotencyKey: 'k1',
      );
      final entryId = (await repo.getPendingEntries()).first.id;
      for (var i = 0; i < 6; i++) {
        await repo.markFailed(entryId);
      }

      expect(await repo.getFailedCount(), 1);
    });

    test('getConflictCount returns correct count', () async {
      expect(await repo.getConflictCount(), 0);

      await repo.enqueue(
        entityType: 'product', entityId: 1, operation: SyncQueueOperation.CREATE,
        idempotencyKey: 'k1',
      );
      final entryId = (await repo.getPendingEntries()).first.id;
      await repo.markConflict(entryId, '{}');

      expect(await repo.getConflictCount(), 1);
    });
  });

  group('SyncQueueRepository.cleanupSynced', () {
    test('removes old SYNCED entries', () async {
      await repo.enqueue(
        entityType: 'product', entityId: 1, operation: SyncQueueOperation.CREATE,
        idempotencyKey: 'k1',
      );
      final entryId = (await repo.getPendingEntries()).first.id;
      await repo.markSynced(entryId);

      // Backdate deterministically: relying on wall-clock progression between
      // markSynced and cleanupSynced is flaky on coarse OS clocks where two
      // adjacent DateTime.now() calls can return the identical instant.
      final old = DateTime.now().subtract(const Duration(days: 30));
      await testDb.update(
        'sync_queue',
        {'synced_at': old.toIso8601String()},
        where: 'id = ?',
        whereArgs: [entryId],
      );

      await repo.cleanupSynced(olderThanDays: 0);

      final all = await testDb.query('sync_queue');
      expect(all, isEmpty);
    });

    test('does not remove recent SYNCED entries', () async {
      await repo.enqueue(
        entityType: 'product', entityId: 1, operation: SyncQueueOperation.CREATE,
        idempotencyKey: 'k1',
      );
      final entryId = (await repo.getPendingEntries()).first.id;
      await repo.markSynced(entryId);

      await repo.cleanupSynced(olderThanDays: 7);

      final all = await testDb.query('sync_queue');
      expect(all, hasLength(1));
    });
  });

  group('SyncQueueRepository.hasPendingForEntity', () {
    test('returns true when pending entry exists for entity', () async {
      await repo.enqueue(
        entityType: 'product', entityId: 42, operation: SyncQueueOperation.CREATE,
        idempotencyKey: 'k1',
      );

      final has = await repo.hasPendingForEntity('product', 42, SyncQueueOperation.CREATE);
      expect(has, isTrue);
    });

    test('returns false when no matching entry exists', () async {
      final has = await repo.hasPendingForEntity('product', 99, SyncQueueOperation.CREATE);
      expect(has, isFalse);
    });
  });

  group('SyncQueueEntry serialization', () {
    test('toMap and fromMap round-trip', () async {
      final entry = SyncQueueEntry(
        id: 'test-id',
        entityType: 'product',
        entityId: 42,
        operation: SyncQueueOperation.UPDATE,
        payload: {'name': 'Widget', 'price': 9.99},
        createdAt: DateTime(2026, 1, 15, 10, 30),
        syncedAt: DateTime(2026, 1, 15, 10, 31),
        retryCount: 2,
        status: SyncQueueStatus.FAILED,
        conflictData: '{"error": "conflict"}',
        idempotencyKey: 'idem-123',
        shopId: 'shop-abc',
      );

      final map = entry.toMap();
      final restored = SyncQueueEntry.fromMap(map);

      expect(restored.id, entry.id);
      expect(restored.entityType, entry.entityType);
      expect(restored.entityId, entry.entityId);
      expect(restored.operation, entry.operation);
      expect(restored.payload, entry.payload);
      expect(restored.retryCount, entry.retryCount);
      expect(restored.status, entry.status);
      expect(restored.conflictData, entry.conflictData);
      expect(restored.idempotencyKey, entry.idempotencyKey);
      expect(restored.shopId, entry.shopId);
    });

    test('copyWith creates modified copy', () {
      final entry = SyncQueueEntry(
        id: 'id',
        entityType: 'sale',
        entityId: 1,
        operation: SyncQueueOperation.CREATE,
        createdAt: DateTime.now(),
        idempotencyKey: 'k',
      );

      final updated = entry.copyWith(
        status: SyncQueueStatus.SYNCED,
        retryCount: 3,
      );

      expect(updated.status, SyncQueueStatus.SYNCED);
      expect(updated.retryCount, 3);
      expect(updated.entityType, 'sale');
    });
  });
}
