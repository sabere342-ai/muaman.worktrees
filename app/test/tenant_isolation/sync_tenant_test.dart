import 'package:flutter_test/flutter_test.dart';
import 'package:muaman_store/database/database_helper.dart';
import 'package:muaman_store/models/product.dart';
import 'package:muaman_store/models/user_role.dart';
import 'package:muaman_store/services/active_shop_context.dart';
import 'package:muaman_store/sync/adapters/product_sync_adapter.dart';
import 'package:muaman_store/sync/conflict_resolver.dart';
import 'package:muaman_store/sync/hydration_service.dart';
import 'package:muaman_store/sync/incremental_sync_service.dart';
import 'package:muaman_store/sync/sync_engine.dart';
import 'package:muaman_store/sync/sync_queue_repository.dart';
import 'package:muaman_store/sync/sync_status.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'fixture.dart';

/// J-WS5 sync tenant integration (plan §O):
///   - queued work executes strictly under its persisted entry shop id,
///     surviving shop switches untouched;
///   - hydration/incremental pulls reject payloads stamped with a foreign
///     shop id — never merging cross-tenant;
///   - the enqueue provider delegates to the ActiveShopContext.
void main() {
  sqfliteFfiInit();

  late Database testDb;
  final logs = <String>[];
  final helper = DatabaseHelper.instance;

  setUp(() async {
    testDb =
        await databaseFactoryFfiNoIsolate.openDatabase(inMemoryDatabasePath);
    await DatabaseHelper.runCreateDbForTest(testDb);
    await DatabaseHelper.setTestDatabase(testDb);
    await bindTestShop('shop-a');
    logs.clear();
  });

  tearDown(() async {
    DatabaseHelper.clearSyncShopIdProvider();
    resetTestContext();
    DatabaseHelper.resetForTest();
    await testDb.close();
  });

  SyncQueueRepository queueRepo() => SyncQueueRepository(testDb);

  SyncEngine engineFor(String Function() shop) => SyncEngine(
        queueRepository: queueRepo(),
        conflictResolver:
            ConflictResolver({SyncEntityType.product: ProductSyncAdapter()}),
        adapters: {SyncEntityType.product: ProductSyncAdapter()},
        connectivityCheck: () async => true,
        licenseCheck: () async => true,
        shopIdProvider: () async => shop(),
        logger: (type, op, {details}) async =>
            logs.add('$type:$op ${details ?? ''}'),
      );

  group('queue execution identity', () {
    test('J-S01: queued Shop A entry survives a switch to Shop B untouched',
        () async {
      // Provider delegates to the context, as wired in main.dart at startup.
      DatabaseHelper.setSyncShopIdProvider(
          () async => ActiveShopContext.instance.shopId);

      final id = await helper.insertProduct(
        Product(name: 'صنف أ', barcode: 'BC-Q1', costPrice: 5.0),
        currentRole: UserRole.owner,
      );
      var entries = await queueRepo().getPendingEntries();
      expect(entries.single.shopId, 'shop-a');

      // Switch the ambient tenant context to shop B and run a cycle there.
      await bindTestShop('shop-b');
      final resultB = await engineFor(() => 'shop-b').processQueue();
      expect(resultB.processed, 0,
          reason: "Shop B's cycle must never drain Shop A's entries");
      entries = await queueRepo().getPendingEntries();
      expect(entries.single.status.label, 'PENDING',
          reason: 'entry must remain pending under its originating shop');
      expect(entries.single.entityId, id);
      expect(entries.single.shopId, 'shop-a',
          reason: 'entries are never re-attributed to the newly selected shop');

      // Switch back: the same entry now executes under its own shop.
      await bindTestShop('shop-a');
      final resultA = await engineFor(() => 'shop-a').processQueue();
      expect(resultA.synced, 1);
      expect(await queueRepo().getPendingEntries(), isEmpty);
    });

    test('J-S02: enqueue stamps the CONTEXT shop after switching', () async {
      DatabaseHelper.setSyncShopIdProvider(
          () async => ActiveShopContext.instance.shopId);

      await helper.insertProduct(
        Product(name: 'صنف أ', barcode: 'BC-Q2', costPrice: 5.0),
        currentRole: UserRole.owner,
      );
      await bindTestShop('shop-c');
      await helper.insertProduct(
        Product(name: 'صنف ج', barcode: 'BC-Q3', costPrice: 6.0),
        currentRole: UserRole.owner,
      );

      final shops =
          (await queueRepo().getPendingEntries()).map((e) => e.shopId).toSet();
      expect(shops, containsAll(['shop-a', 'shop-c']));
    });
  });

  group('hydration tenant guard', () {
    test('J-S03: hydration rejects a payload stamped with a foreign shop',
        () async {
      final cloudSource = HydrationCloudSource(
        fetchAll: ({required shopId, required adapter}) async => [
          {
            'id': 'uuid-foreign',
            'name': 'غريب',
            'barcode': 'BC-FOREIGN',
            'opening_quantity': 1,
            'sold_quantity': 0,
            'returned_quantity': 0,
            'current_quantity': 1,
            'cost_price': 5.0,
            'total_inventory_cost': 5.0,
            'inventory_adjustment': 0,
            'server_version': 2,
            'shop_id': 'shop-other',
          },
          {
            'id': 'uuid-mine',
            'name': 'لي',
            'barcode': 'BC-MINE',
            'opening_quantity': 2,
            'sold_quantity': 0,
            'returned_quantity': 0,
            'current_quantity': 2,
            'cost_price': 7.0,
            'total_inventory_cost': 14.0,
            'inventory_adjustment': 0,
            'server_version': 3,
          },
        ],
      );

      final service = HydrationService(
        db: testDb,
        cloudSource: cloudSource,
        logger: (msg) async => logs.add(msg),
      );
      final result = await service.hydrate(
        shopId: 'shop-a',
        adapters: [ProductSyncAdapter()],
      );

      expect(result.inserted, 1, reason: 'only the matching-shop row applies');
      expect(result.skipped, 1);

      final barcodes =
          (await testDb.query('products')).map((r) => r['barcode']).toSet();
      expect(barcodes, isNot(contains('BC-FOREIGN')),
          reason: 'foreign payload must never merge into this tenant');
      expect(logs.join('\n'), contains('rejected'));
    });
  });

  group('incremental pull tenant guard', () {
    test('J-S04: incremental pull rejects cross-shop payloads', () async {
      final cloudSource = HydrationCloudSource(
        fetchAll: ({required shopId, required adapter}) async => [
          {
            'id': 'uuid-inc-foreign',
            'name': 'غريب تدريجي',
            'barcode': 'BC-INC-F',
            'opening_quantity': 1,
            'sold_quantity': 0,
            'returned_quantity': 0,
            'current_quantity': 1,
            'cost_price': 5.0,
            'total_inventory_cost': 5.0,
            'inventory_adjustment': 0,
            'server_version': 9,
            'shop_id': 'shop-z',
            'updated_at': DateTime.now().toIso8601String(),
          },
        ],
      );

      final service = IncrementalSyncService(
        db: testDb,
        cloudSource: cloudSource,
        logger: (msg) async => logs.add(msg),
      );
      final result = await service.pullChanges(
        shopId: 'shop-a',
        adapters: [ProductSyncAdapter()],
        since: DateTime.now().subtract(const Duration(days: 1)),
      );

      expect(result.inserted, 0);
      expect(result.skipped, 1);
      expect(await testDb.query('products'), isEmpty);
    });
  });
}
