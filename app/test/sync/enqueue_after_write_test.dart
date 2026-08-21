import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:muaman_store/database/database_helper.dart';
import 'package:muaman_store/models/product.dart';
import 'package:muaman_store/models/expense.dart';
import 'package:muaman_store/models/customer.dart';
import 'package:muaman_store/models/user_role.dart';
import 'package:muaman_store/services/permissions.dart';
import 'package:muaman_store/sync/sync_queue_repository.dart';
import 'package:muaman_store/sync/sync_status.dart';

void main() {
  sqfliteFfiInit();

  late Database testDb;
  late SyncQueueRepository queueRepo;
  late DatabaseHelper helper;

  setUp(() async {
    testDb = await databaseFactoryFfiNoIsolate.openDatabase(inMemoryDatabasePath);
    await DatabaseHelper.runCreateDbForTest(testDb);
    await DatabaseHelper.setTestDatabase(testDb);
    DatabaseHelper.setSyncShopIdProvider(() async => 'shop-1');
    queueRepo = SyncQueueRepository(testDb);
    helper = DatabaseHelper.instance;
  });

  tearDown(() async {
    DatabaseHelper.clearSyncShopIdProvider();
    DatabaseHelper.resetForTest();
    await testDb.close();
  });

  Future<List<SyncQueueEntry>> allEntries() async {
    final maps = await testDb.query('sync_queue', orderBy: 'created_at ASC');
    return maps.map(SyncQueueEntry.fromMap).toList();
  }

  Product product({String? barcode, String name = 'منتج تجريبي'}) => Product(
        name: name,
        barcode: barcode ?? 'BC-${DateTime.now().microsecondsSinceEpoch}',
        openingQuantity: 10,
        currentQuantity: 10,
        costPrice: 5.0,
      );

  group('H-I09: enqueue-after-write wiring', () {
    test('H-I09-T01: local create enqueues exactly one correct CREATE op',
        () async {
      final id = await helper.insertProduct(product(),
          currentRole: UserRole.owner);

      final entries = await allEntries();
      expect(entries, hasLength(1));

      final entry = entries.single;
      expect(entry.entityType, 'product');
      expect(entry.entityId, id);
      expect(entry.operation, SyncQueueOperation.CREATE);
      expect(entry.status, SyncQueueStatus.PENDING);
      expect(entry.shopId, 'shop-1');
      expect(entry.idempotencyKey, isNotEmpty);
    });

    test('H-I09-T02: local update enqueues correct UPDATE op', () async {
      final id = await helper.insertProduct(product(),
          currentRole: UserRole.owner);

      final updated = Product(
        id: id,
        name: 'اسم معدل',
        barcode: 'BC-UPDATE-1',
        openingQuantity: 10,
        currentQuantity: 8,
        costPrice: 7.0,
      );
      final affected =
          await helper.updateProduct(updated, currentRole: UserRole.owner);
      expect(affected, 1);

      final entries = await allEntries();
      expect(entries, hasLength(2));
      expect(entries.last.operation, SyncQueueOperation.UPDATE);
      expect(entries.last.entityType, 'product');
      expect(entries.last.entityId, id);
      expect(entries.last.payload?['name'], 'اسم معدل');
      expect(entries.last.shopId, 'shop-1');
    });

    test(
        'H-I09-T03: local delete enqueues DELETE op carrying pre-delete snapshot',
        () async {
      final id = await helper.insertProduct(product(barcode: 'BC-DEL-1'),
          currentRole: UserRole.owner);

      // Clear CREATE entry so the DELETE entry is unambiguous.
      await testDb.delete('sync_queue');

      final affected =
          await helper.deleteProduct(id, currentRole: UserRole.owner);
      expect(affected, 1);

      final entries = await allEntries();
      expect(entries, hasLength(1));
      final entry = entries.single;
      expect(entry.operation, SyncQueueOperation.DELETE);
      expect(entry.entityType, 'product');
      expect(entry.entityId, id);
      expect(entry.payload?['barcode'], 'BC-DEL-1');
      expect(entry.payload?['name'], isNotEmpty,
          reason: 'DELETE payload must carry the pre-delete row snapshot');

      final remaining = await testDb.query('products', where: 'id = ?',
          whereArgs: [id]);
      expect(remaining, isEmpty);
    });

    test('H-I09-T04: failed local write leaves no queue entry', () async {
      await helper.insertProduct(product(barcode: 'BC-DUP'),
          currentRole: UserRole.owner);
      expect(await queueRepo.getPendingCount(), 1);

      // Duplicate barcode must fail validation before any write.
      await expectLater(
        helper.insertProduct(product(barcode: ' BC-DUP '),
            currentRole: UserRole.owner),
        throwsArgumentError,
      );

      expect(await queueRepo.getPendingCount(), 1,
          reason: 'failed local write must not create a ghost queue entry');

      // Permission-denied write must not enqueue either.
      await expectLater(
        helper.insertProduct(product(barcode: 'BC-NOPE'), currentRole: null),
        throwsA(isA<PermissionDeniedException>()),
      );
      expect(await queueRepo.getPendingCount(), 1);
    });

    test(
        'H-I09-T05: cloud-applied writes through suppression gate do not re-enqueue',
        () async {
      final countBefore = await queueRepo.getPendingCount();

      // Simulates a remote-apply path that routes a business write through
      // DatabaseHelper (e.g. conflict resolution writing server data back).
      await DatabaseHelper.runWithoutSyncEnqueue(() async {
        await helper.insertProduct(product(barcode: 'BC-REMOTE'),
            currentRole: UserRole.owner);
      });

      expect(await queueRepo.getPendingCount(), countBefore,
          reason:
              'remote-originated write inside suppression scope must not enqueue');

      // The row itself IS written locally.
      final rows = await testDb
          .query('products', where: 'barcode = ?', whereArgs: ['BC-REMOTE']);
      expect(rows, hasLength(1));
    });

    test('H-I09-T06: entity_type matches adapter label for each entity',
        () async {
      final pid =
          await helper.insertProduct(product(), currentRole: UserRole.owner);
      final eid = await helper.insertExpense(
          Expense(
              date: DateTime.now(),
              description: 'إيجار',
              amount: 100),
          currentRole: UserRole.owner);
      final cid = await helper.insertCustomer(Customer(name: 'عميل'),
          currentRole: UserRole.owner);

      final entries = await allEntries();
      // Entity ids are per-table autoincrement values, so identity is the
      // (entity_type, entity_id) pair, not the bare id.
      final pairs = entries.map((e) => (e.entityType, e.entityId)).toSet();
      expect(pairs, contains(('product', pid)));
      expect(pairs, contains(('expense', eid)));
      expect(pairs, contains(('customer', cid)));
    });

    test('H-I09-T07: entity_id equals the persisted local row id', () async {
      final id = await helper.insertProduct(product(),
          currentRole: UserRole.owner);
      final entries = await allEntries();
      expect(entries.single.entityId, id);
      final row =
          (await testDb.query('products', where: 'id = ?', whereArgs: [id]))
              .single;
      expect(row['id'], entries.single.entityId);
    });

    test('H-I09-T08: payload built from persisted row via adapter contract',
        () async {
      final id = await helper.insertProduct(
          product(barcode: 'BC-PAYLOAD', name: 'منتج الدفع'),
          currentRole: UserRole.owner);

      final payload = (await allEntries()).single.payload!;
      expect(payload['id'], id);
      expect(payload['name'], 'منتج الدفع');
      expect(payload['barcode'], 'BC-PAYLOAD');
      expect(payload['server_version'], 0,
          reason: 'fresh local row starts at server_version 0');
      expect(payload.containsKey('cloud_uuid'), isTrue);
    });

    test('H-I09-T09: shop_id stamped from provider; no shop means no enqueue',
        () async {
      final id = await helper.insertProduct(product(),
          currentRole: UserRole.owner);
      expect((await allEntries()).single.shopId, 'shop-1');

      // No authorized cloud tenant context → purely local write.
      DatabaseHelper.setSyncShopIdProvider(() async => null);
      await helper.insertProduct(product(barcode: 'BC-NOSHOP'),
          currentRole: UserRole.owner);

      final entries = await allEntries();
      expect(entries, hasLength(1));
      expect(entries.single.entityId, id);
    });

    test('H-I09-T10: version metadata consistent between row and payload',
        () async {
      final id = await helper.insertProduct(product(),
          currentRole: UserRole.owner);

      final row =
          (await testDb.query('products', where: 'id = ?', whereArgs: [id]))
              .single;
      final entry = (await allEntries()).single;

      expect(row['server_version'], 0);
      expect(entry.payload?['server_version'], row['server_version']);
      expect(row['sync_status'], EntitySyncStatus.PENDING.label,
          reason: 'locally written row must be flagged PENDING for sync');
    });

    test('H-I09-T11: multiple entity types covered by write paths', () async {
      await helper.insertProduct(product(), currentRole: UserRole.owner);
      await helper.insertExpense(
          Expense(date: DateTime.now(), description: 'كهرباء', amount: 50),
          currentRole: UserRole.owner);
      await helper.insertCustomer(Customer(name: 'زائر'),
          currentRole: UserRole.owner);

      final entries = await allEntries();
      expect(entries.map((e) => e.entityType).toSet(),
          containsAll(<String>['product', 'expense', 'customer']));
      for (final e in entries) {
        expect(e.operation, SyncQueueOperation.CREATE);
        expect(e.status, SyncQueueStatus.PENDING);
      }
    });

    test('H-I09-T12: queue IDs remain unique across many writes', () async {
      for (var i = 0; i < 12; i++) {
        await helper.insertProduct(product(barcode: 'BC-U-$i'),
            currentRole: UserRole.owner);
      }
      final entries = await allEntries();
      expect(entries, hasLength(12));
      expect(entries.map((e) => e.id).toSet(), hasLength(12));
      expect(entries.map((e) => e.idempotencyKey).toSet(), hasLength(12),
          reason: 'idempotency keys must be unique per logical write');
    });

    test('H-I09-T13: one logical write does not enqueue twice', () async {
      await helper.insertProduct(product(), currentRole: UserRole.owner);
      final afterCreate = await allEntries();

      // Re-run the exact same logical write path once more and confirm the
      // queue only grows by one entry per logical write, never two.
      final id2 = await helper.insertProduct(product(barcode: 'BC-ONCE'),
          currentRole: UserRole.owner);
      final afterSecond = await allEntries();

      expect(afterCreate, hasLength(1));
      expect(afterSecond, hasLength(2));
      expect(
        afterSecond.where((e) => e.entityId == id2),
        hasLength(1),
        reason: 'a single insertProduct call must produce a single entry',
      );
    });

    test(
        'H-I09-T14: transaction rollback leaves no orphan/ghost queue row',
        () async {
      // The enqueue-after-write contract requires the queue entry to share
      // the caller's transaction executor. Prove atomicity directly: an
      // enqueue participating in a transaction that later throws must vanish.
      await expectLater(
        testDb.transaction((txn) async {
          await queueRepo.enqueue(
            entityType: 'product',
            entityId: 999,
            operation: SyncQueueOperation.CREATE,
            payload: {'name': 'ghost'},
            idempotencyKey: 'rollback-key',
            shopId: 'shop-1',
            executor: txn,
          );
          // Entry visible inside the open transaction...
          final inside = await txn.query('sync_queue',
              where: 'idempotency_key = ?', whereArgs: ['rollback-key']);
          expect(inside, hasLength(1));
          throw StateError('force rollback');
        }),
        throwsStateError,
      );

      // ...and gone after rollback.
      final orphans = await testDb
          .query('sync_queue', where: 'idempotency_key = ?', whereArgs: ['rollback-key']);
      expect(orphans, isEmpty,
          reason: 'rolled-back transaction must not leave a ghost queue row');
    });

    test('H-I09-T15: no sync echo loop from remote apply paths', () async {
      // Structural guarantee: HydrationService / IncrementalSyncService write
      // cloud rows straight to the raw SQLite handle — they never route
      // through DatabaseHelper business methods, so they can never trigger
      // _enqueueAfterWrite. Simulate exactly that write shape here.
      final countBefore = await queueRepo.getPendingCount();

      await testDb.insert('products', {
        'name': 'Cloud Row',
        'barcode': 'BC-CLOUD',
        'openingQuantity': 1,
        'currentQuantity': 1,
        'costPrice': 3.0,
        'totalInventoryCost': 3.0,
        'shop_id': 'shop-1',
        'cloud_uuid': 'uuid-cloud-1',
        'server_version': 4,
        'sync_status': EntitySyncStatus.SYNCED.label,
      });

      expect(await queueRepo.getPendingCount(), countBefore,
          reason:
              'hydration-style direct writes must not create queue entries');

      // Defense-in-depth: even if a future remote path routed through a
      // business method, the suppression gate blocks the echo.
      await DatabaseHelper.runWithoutSyncEnqueue(() async {
        await helper.updateProduct(
          Product(
              id: 1,
              name: 'Cloud Row v2',
              barcode: 'BC-CLOUD',
              costPrice: 3.0),
          currentRole: UserRole.owner,
        );
      });
      expect(await queueRepo.getPendingCount(), countBefore);
    });
  });
}
