import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:muaman_store/sync/hydration_service.dart';
import 'package:muaman_store/sync/adapters/product_sync_adapter.dart';

void main() {
  sqfliteFfiInit();

  late Database testDb;
  final logs = <String>[];

  setUp(() async {
    testDb =
        await databaseFactoryFfiNoIsolate.openDatabase(inMemoryDatabasePath);
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
    logs.clear();
  });

  tearDown(() async {
    await testDb.close();
  });

  group('HydrationService.hydrate', () {
    test('inserts cloud data as new local records', () async {
      final cloudSource = HydrationCloudSource(
        fetchAll: ({required shopId, required adapter}) async => [
          {
            'id': 'cloud-uuid-001',
            'name': 'Cloud Widget',
            'barcode': 'CLOUD-001',
            'opening_quantity': 10,
            'sold_quantity': 2,
            'returned_quantity': 0,
            'current_quantity': 8,
            'cost_price': 25.0,
            'total_inventory_cost': 200.0,
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
        shopId: 'shop-001',
        adapters: [ProductSyncAdapter()],
      );

      expect(result.inserted, 1);
      expect(result.updated, 0);
      expect(result.skipped, 0);

      final localRows = await testDb.query('products');
      expect(localRows, hasLength(1));
      expect(localRows.first['cloud_uuid'], 'cloud-uuid-001');
      expect(localRows.first['shop_id'], 'shop-001');
      expect(localRows.first['server_version'], 3);
      expect(localRows.first['sync_status'], 'SYNCED');
      expect(localRows.first['name'], 'Cloud Widget');
    });

    test('updates existing records when server version is newer', () async {
      await testDb.insert('products', {
        'name': 'Old Widget',
        'barcode': 'LOCAL-001',
        'openingQuantity': 5,
        'soldQuantity': 0,
        'returnedQuantity': 0,
        'currentQuantity': 5,
        'costPrice': 10.0,
        'totalInventoryCost': 50.0,
        'inventoryAdjustment': 0,
        'cloud_uuid': 'cloud-uuid-001',
        'server_version': 2,
      });

      final cloudSource = HydrationCloudSource(
        fetchAll: ({required shopId, required adapter}) async => [
          {
            'id': 'cloud-uuid-001',
            'name': 'Updated Widget',
            'barcode': 'LOCAL-001',
            'opening_quantity': 10,
            'sold_quantity': 1,
            'returned_quantity': 0,
            'current_quantity': 9,
            'cost_price': 15.0,
            'total_inventory_cost': 135.0,
            'inventory_adjustment': 0,
            'server_version': 5,
          },
        ],
      );

      final service = HydrationService(
        db: testDb,
        cloudSource: cloudSource,
        logger: (msg) async {},
      );

      final result = await service.hydrate(
        shopId: 'shop-001',
        adapters: [ProductSyncAdapter()],
      );

      expect(result.updated, 1);
      expect(result.inserted, 0);

      final row = (await testDb.query('products',
              where: 'cloud_uuid = ?', whereArgs: ['cloud-uuid-001']))
          .first;
      expect(row['name'], 'Updated Widget');
      expect(row['server_version'], 5);
    });

    test('skips records when server version is not newer', () async {
      await testDb.insert('products', {
        'name': 'Current Widget',
        'barcode': 'LOCAL-002',
        'openingQuantity': 5,
        'soldQuantity': 0,
        'returnedQuantity': 0,
        'currentQuantity': 5,
        'costPrice': 10.0,
        'totalInventoryCost': 50.0,
        'inventoryAdjustment': 0,
        'cloud_uuid': 'cloud-uuid-002',
        'server_version': 5,
      });

      final cloudSource = HydrationCloudSource(
        fetchAll: ({required shopId, required adapter}) async => [
          {
            'id': 'cloud-uuid-002',
            'name': 'Current Widget',
            'barcode': 'LOCAL-002',
            'opening_quantity': 5,
            'sold_quantity': 0,
            'returned_quantity': 0,
            'current_quantity': 5,
            'cost_price': 10.0,
            'total_inventory_cost': 50.0,
            'inventory_adjustment': 0,
            'server_version': 5,
          },
        ],
      );

      final service = HydrationService(
        db: testDb,
        cloudSource: cloudSource,
        logger: (msg) async {},
      );

      final result = await service.hydrate(
        shopId: 'shop-001',
        adapters: [ProductSyncAdapter()],
      );

      expect(result.skipped, 1);
      expect(result.updated, 0);
    });

    test('deletes local record when cloud deleted_at is set', () async {
      await testDb.insert('products', {
        'name': 'Deleted Widget',
        'barcode': 'DEL-001',
        'openingQuantity': 5,
        'soldQuantity': 0,
        'returnedQuantity': 0,
        'currentQuantity': 5,
        'costPrice': 10.0,
        'totalInventoryCost': 50.0,
        'inventoryAdjustment': 0,
        'cloud_uuid': 'cloud-uuid-del',
        'server_version': 1,
      });

      final cloudSource = HydrationCloudSource(
        fetchAll: ({required shopId, required adapter}) async => [
          {
            'id': 'cloud-uuid-del',
            'name': 'Deleted Widget',
            'barcode': 'DEL-001',
            'opening_quantity': 5,
            'sold_quantity': 0,
            'returned_quantity': 0,
            'current_quantity': 5,
            'cost_price': 10.0,
            'total_inventory_cost': 50.0,
            'inventory_adjustment': 0,
            'server_version': 2,
            'deleted_at': '2026-08-20T10:00:00Z',
          },
        ],
      );

      final service = HydrationService(
        db: testDb,
        cloudSource: cloudSource,
        logger: (msg) async {},
      );

      final result = await service.hydrate(
        shopId: 'shop-001',
        adapters: [ProductSyncAdapter()],
      );

      expect(result.deleted, 1);

      final remaining = await testDb.query('products');
      expect(remaining, isEmpty);
    });

    test('returns error when no cloud source configured', () async {
      final service = HydrationService(
        db: testDb,
        cloudSource: null,
        logger: (msg) async {},
      );

      final result = await service.hydrate(
        shopId: 'shop-001',
        adapters: [ProductSyncAdapter()],
      );

      expect(result.error, isNotNull);
      expect(result.error, contains('No cloud source'));
    });

    test('skips cloud rows with null or empty id', () async {
      final cloudSource = HydrationCloudSource(
        fetchAll: ({required shopId, required adapter}) async => [
          {'id': null, 'name': 'No ID'},
          {'id': '', 'name': 'Empty ID'},
        ],
      );

      final service = HydrationService(
        db: testDb,
        cloudSource: cloudSource,
        logger: (msg) async {},
      );

      final result = await service.hydrate(
        shopId: 'shop-001',
        adapters: [ProductSyncAdapter()],
      );

      expect(result.skipped, 2);
      expect(result.inserted, 0);
    });
  });
}
