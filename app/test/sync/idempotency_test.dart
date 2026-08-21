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

  group('Idempotency: duplicate prevention', () {
    test('same idempotency key prevents duplicate enqueue', () async {
      await repo.enqueue(
        entityType: 'product',
        entityId: 1,
        operation: SyncQueueOperation.CREATE,
        payload: {'name': 'First'},
        idempotencyKey: 'idem-001',
      );

      await repo.enqueue(
        entityType: 'product',
        entityId: 1,
        operation: SyncQueueOperation.UPDATE,
        payload: {'name': 'Second'},
        idempotencyKey: 'idem-001',
      );

      final entries = await repo.getPendingEntries();
      expect(entries, hasLength(1));
      expect(entries.first.payload!['name'], 'First');
    });

    test('different idempotency keys allow separate entries', () async {
      await repo.enqueue(
        entityType: 'product',
        entityId: 1,
        operation: SyncQueueOperation.CREATE,
        idempotencyKey: 'idem-a',
      );

      await repo.enqueue(
        entityType: 'product',
        entityId: 1,
        operation: SyncQueueOperation.UPDATE,
        idempotencyKey: 'idem-b',
      );

      final entries = await repo.getPendingEntries();
      expect(entries, hasLength(2));
    });
  });

  group('Idempotency: retry safety', () {
    test('retry after sync does not create duplicate', () async {
      await repo.enqueue(
        entityType: 'sale',
        entityId: 10,
        operation: SyncQueueOperation.CREATE,
        idempotencyKey: 'idem-sale',
      );

      final entryId = (await repo.getPendingEntries()).first.id;
      await repo.markSynced(entryId);

      await repo.enqueue(
        entityType: 'sale',
        entityId: 10,
        operation: SyncQueueOperation.CREATE,
        idempotencyKey: 'idem-sale',
      );

      final pending = await repo.getPendingEntries();
      expect(pending, isEmpty);
    });

    test('idempotency key is unique per operation', () async {
      final keys = <String>{};
      for (var i = 0; i < 100; i++) {
        await repo.enqueue(
          entityType: 'product',
          entityId: i,
          operation: SyncQueueOperation.CREATE,
          idempotencyKey: 'key-$i',
        );
        keys.add('key-$i');
      }

      expect(keys.length, 100);

      final allEntries = await testDb.query('sync_queue');
      final idemKeys = allEntries.map((r) => r['idempotency_key'] as String).toSet();
      expect(idemKeys.length, 100);
    });
  });

  group('Idempotency: concurrent operations', () {
    test('different entities with different keys coexist', () async {
      await repo.enqueue(
        entityType: 'product',
        entityId: 1,
        operation: SyncQueueOperation.CREATE,
        idempotencyKey: 'idem-p1',
      );

      await repo.enqueue(
        entityType: 'sale',
        entityId: 1,
        operation: SyncQueueOperation.CREATE,
        idempotencyKey: 'idem-s1',
      );

      await repo.enqueue(
        entityType: 'expense',
        entityId: 1,
        operation: SyncQueueOperation.CREATE,
        idempotencyKey: 'idem-e1',
      );

      final entries = await repo.getPendingEntries();
      expect(entries, hasLength(3));
    });

    test('same entity different operations with different keys', () async {
      await repo.enqueue(
        entityType: 'product',
        entityId: 1,
        operation: SyncQueueOperation.CREATE,
        idempotencyKey: 'idem-create',
      );

      await repo.enqueue(
        entityType: 'product',
        entityId: 1,
        operation: SyncQueueOperation.UPDATE,
        idempotencyKey: 'idem-update',
      );

      final entries = await repo.getPendingEntries();
      expect(entries, hasLength(2));
    });
  });
}
