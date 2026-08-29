import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:muaman_store/database/database_helper.dart';

/// Phase P (plan §F.3 / WS-2): schema v15 → v16 is DATA-ONLY.
///
/// Proves:
///   - the upgrade backfills a stable client-generated `cloud_uuid` onto
///     every pre-existing tenant row that was missing one (products, sales,
///     expenses, customers, invoices, inventory_count, ...),
///   - existing cloud_uuid values are never overwritten,
///   - the backfill is a pure backfill: it adds headroom to every table with
///     non-null UUIDs and is idempotent when replayed,
///   - fresh-create parity: onCreate at v16 == upgraded-to-v16 shape (the
///     schema columns themselves are unchanged by the data-only migration).
void main() {
  sqfliteFfiInit();

  Directory? tempDir;

  Future<Database> openUniqueDb() async {
    final path = p.join(tempDir!.path,
        'db_${DateTime.now().microsecondsSinceEpoch}_${tempDir!.listSync().length}.db');
    return databaseFactoryFfiNoIsolate.openDatabase(path);
  }

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('muaman_v16_test');
  });

  tearDownAll(() async {
    try {
      await tempDir?.delete(recursive: true);
    } catch (_) {}
  });

  final uuidShape = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$');

  Future<void> seedV15Rows(Database db) async {
    await db.insert('products', {
      'name': 'منتج قديم',
      'barcode': 'BAR-V15-1',
      'openingQuantity': 7,
      'soldQuantity': 0,
      'returnedQuantity': 0,
      'inventoryAdjustment': 0,
      'currentQuantity': 7,
      'costPrice': 3.0,
      'totalInventoryCost': 21.0,
      'shop_id': 'shop-1',
    });
    await db.insert('products', {
      'name': 'منتج بعمود موجود',
      'barcode': 'BAR-V15-2',
      'openingQuantity': 1,
      'soldQuantity': 0,
      'returnedQuantity': 0,
      'inventoryAdjustment': 0,
      'currentQuantity': 1,
      'costPrice': 9.0,
      'totalInventoryCost': 9.0,
      'shop_id': 'shop-1',
      'cloud_uuid': '11111111-2222-4333-8444-555555555555',
    });
    await db.insert('sales', {
      'date': '2026-08-20T00:00:00.000',
      'productName': 'منتج قديم',
      'barcode': 'BAR-V15-1',
      'quantity': 2,
      'salePrice': 6.0,
      'totalSaleValue': 12.0,
      'costPrice': 3.0,
      'cogs': 6.0,
      'shop_id': 'shop-1',
    });
    await db.insert('expenses', {
      'date': '2026-08-20T00:00:00.000',
      'description': 'إيجار',
      'amount': 500.0,
      'shop_id': 'shop-1',
    });
    await db.insert('customers', {
      'name': 'عميل',
      'isActive': 1,
      'isSystem': 0,
      'createdAt': '2026-08-20T00:00:00.000',
      'updatedAt': '2026-08-20T00:00:00.000',
      'shop_id': 'shop-1',
    });
    await db.insert('inventory_count', {
      'productId': 1,
      'actualQuantity': 5,
      'countDate': '2026-08-20T00:00:00.000',
      'shop_id': 'shop-1',
    });
    await db.insert('users', {
      'displayName': 'المالك',
      'username': 'owner',
      'passwordHash': 'dummy:dummy',
      'role': 'owner',
      'isActive': 1,
      'createdAt': '2026-08-20T00:00:00.000',
      'updatedAt': '2026-08-20T00:00:00.000',
      'shop_id': 'shop-1',
    });
  }

  Future<List<Map<String, Object?>>> rowsWithUuid(
      Database db, String table) async {
    return db.rawQuery('SELECT id, cloud_uuid FROM $table ORDER BY id');
  }

  group('v15 → v16 upgrade path (data-only backfill)', () {
    late Database db;

    setUp(() async {
      db = await openUniqueDb();
      // Real v15 fresh shape, then stamp it as a genuine v15 install.
      await DatabaseHelper.runFreshOnCreateForTest(db, version: 15);
      await db.rawUpdate('PRAGMA user_version = 15');
      await seedV15Rows(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('backfills cloud_uuid on every row that was missing it', () async {
      await DatabaseHelper.runUpgradeToV16ForTest(db);

      final expected = <String, int>{
        'products': 2,
        'sales': 1,
        'expenses': 1,
        'customers': 1,
        'inventory_count': 1,
        'users': 1,
      };
      for (final entry in expected.entries) {
        final rows = await db
            .rawQuery('SELECT cloud_uuid FROM ${entry.key} ORDER BY id');
        expect(rows, hasLength(entry.value), reason: '${entry.key} row count');
        for (final row in rows) {
          final uuid = row['cloud_uuid'] as String?;
          expect(uuid, isNotNull, reason: '${entry.key} uuid');
          expect(uuidShape.hasMatch(uuid!), isTrue,
              reason: '${entry.key} uuid shape: $uuid');
        }
      }
    });

    test('never overwrites an existing cloud_uuid', () async {
      await DatabaseHelper.runUpgradeToV16ForTest(db);

      final preserved = (await db.query('products',
              where: 'barcode = ?', whereArgs: ['BAR-V15-2']))
          .single;
      expect(preserved['cloud_uuid'], '11111111-2222-4333-8444-555555555555');
    });

    test('backfilled UUIDs are unique across the whole table', () async {
      await DatabaseHelper.runUpgradeToV16ForTest(db);

      final rows =
          await db.rawQuery('SELECT cloud_uuid FROM products ORDER BY id');
      final uuids = rows.map((r) => r['cloud_uuid'] as String).toSet();
      expect(uuids, hasLength(rows.length));
    });

    test('replay is idempotent (no duplicate churn, values stable)', () async {
      await DatabaseHelper.runUpgradeToV16ForTest(db);
      final first = await rowsWithUuid(db, 'products');

      await DatabaseHelper.runUpgradeToV16ForTest(db);
      final second = await rowsWithUuid(db, 'products');

      expect(second, first);
      final nulls = await db.rawQuery(
          'SELECT COUNT(*) AS c FROM products WHERE cloud_uuid IS NULL '
          "OR cloud_uuid = ''");
      expect(nulls.single['c'], 0);
    });
  });

  group('v16 fresh-create parity', () {
    test('fresh onCreate at v16 == create + upgrade-replay (data-only)',
        () async {
      final freshDb = await openUniqueDb();
      addTearDown(freshDb.close);
      await DatabaseHelper.runFreshOnCreateForTest(freshDb);

      final upgradedDb = await openUniqueDb();
      addTearDown(upgradedDb.close);
      // Create + real migration replay (historical upgrade end-state).
      await DatabaseHelper.runCreateDbForTest(upgradedDb);

      for (final table in [
        'products',
        'sales',
        'returns',
        'expenses',
        'expense_categories',
        'inventory_count',
        'invoices',
        'import_batches',
        'customers',
        'users',
        'role_permissions',
        'app_settings',
        'sync_queue',
        'conflict_audit',
        'legacy_migration_progress',
      ]) {
        Future<List<String>> shape(Database d) async {
          final info = await d.rawQuery('PRAGMA table_info($table)');
          return (info
              .map((r) => '${r['name']}:${r['type']}:${r['notnull']}')
              .toList()
            ..sort());
        }

        expect(await shape(freshDb), await shape(upgradedDb),
            reason: 'fresh v16 $table must equal upgraded $table');
      }

      final version = (await freshDb.rawQuery('PRAGMA user_version'))
          .single['user_version'];
      expect(version, DatabaseHelper.schemaVersion);
    });
  });
}
