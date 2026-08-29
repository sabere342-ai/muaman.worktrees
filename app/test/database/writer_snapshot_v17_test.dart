import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:muaman_store/database/database_helper.dart';
import 'package:muaman_store/models/product.dart';
import 'package:muaman_store/models/user_role.dart';
import 'package:muaman_store/sync/sync_queue_repository.dart';

/// Phase P (plan §F.6 / WS-5): durable per-write permission/entitlement
/// snapshot (schema v17).
///
/// Proves:
///   - a fresh v17 install carries the additive `writer_snapshot` column on
///     `sync_queue` and every enqueue stamps a truthful snapshot (permission
///     granted post-guard, entitlement active, shop/entity identity, write
///     instant, rich writer identity when the session provider is registered),
///   - the v16 → v17 upgrade adds the column without disturbing pre-existing
///     queue rows (legacy rows read back with a null snapshot),
///   - without a registered writer provider the snapshot still records all
///     database-layer facts (writer identity simply omitted).
void main() {
  sqfliteFfiInit();

  late Database testDb;
  late DatabaseHelper helper;

  setUp(() async {
    testDb =
        await databaseFactoryFfiNoIsolate.openDatabase(inMemoryDatabasePath);
    await DatabaseHelper.runCreateDbForTest(testDb);
    await DatabaseHelper.setTestDatabase(testDb);
    DatabaseHelper.setSyncShopIdProvider(() async => 'shop-1');
    helper = DatabaseHelper.instance;
  });

  tearDown(() async {
    DatabaseHelper.clearWriterSnapshotProvider();
    DatabaseHelper.clearSyncShopIdProvider();
    DatabaseHelper.resetForTest();
    await testDb.close();
  });

  Future<Set<String>> queueColumns(Database db) async {
    final info = await db.rawQuery('PRAGMA table_info(sync_queue)');
    return info.map((r) => r['name'] as String).toSet();
  }

  Future<List<SyncQueueEntry>> allEntries(Database db) async {
    final maps = await db.query('sync_queue', orderBy: 'created_at ASC');
    return maps.map(SyncQueueEntry.fromMap).toList();
  }

  Product product({String? barcode}) => Product(
        name: 'منتج WS5',
        barcode: barcode ?? 'WS5-${DateTime.now().microsecondsSinceEpoch}',
        openingQuantity: 4,
        currentQuantity: 4,
        costPrice: 2.0,
      );

  group('WS-5: per-write permission snapshot (v17)', () {
    test('fresh v17 install: column exists and CREATE stamps full snapshot',
        () async {
      expect(await queueColumns(testDb), contains('writer_snapshot'));

      DatabaseHelper.setWriterSnapshotProvider(() async => {
            'role': UserRole.owner.name,
            'display_name': 'المالك',
            'cloud_user_uuid': 'cloud-user-1',
          });

      final id =
          await helper.insertProduct(product(), currentRole: UserRole.owner);

      final entry = (await allEntries(testDb)).single;
      expect(entry.entityId, id);

      final snap = entry.writerSnapshot;
      expect(snap, isNotNull);
      expect(snap!['permission_granted'], isTrue);
      expect(snap['entitlement_active'], isTrue);
      expect(snap['permission_required'], 'inventory.edit');
      expect(snap['operation'], 'CREATE');
      expect(snap['entity_type'], 'product');
      expect(snap['shop_id'], 'shop-1');
      expect(snap['entity_uuid'], isNotEmpty);
      expect((snap['written_at'] as String).isNotEmpty, isTrue,
          reason: 'write instant must be captured for revocation adjudication');

      final writer = snap['writer'] as Map<String, dynamic>;
      expect(writer['role'], UserRole.owner.name);
      expect(writer['display_name'], 'المالك');
      expect(writer['cloud_user_uuid'], 'cloud-user-1');
    });

    test('writer identity absent when provider not registered; DB facts kept',
        () async {
      final id =
          await helper.insertProduct(product(), currentRole: UserRole.owner);

      final entry = (await allEntries(testDb)).single;
      final snap = entry.writerSnapshot;
      expect(snap, isNotNull);
      expect(snap!['permission_granted'], isTrue);
      expect(snap['entitlement_active'], isTrue);
      expect(snap['shop_id'], 'shop-1');
      expect(snap['entity_uuid'], isNotEmpty);
      expect(snap.containsKey('writer'), isFalse);
      expect(entry.entityId, id);
    });

    test('v16 → v17 upgrade adds column; legacy rows read back safely',
        () async {
      // A distinct temp-file database (in-memory paths share one handle in
      // this factory) rebuilds the v16 fresh shape: no writer_snapshot column.
      final tempDir = await Directory.systemTemp.createTemp('muaman_v17_test');
      final v16Path = p.join(
          tempDir.path, 'db_${DateTime.now().microsecondsSinceEpoch}.db');
      final v16Db = await databaseFactoryFfiNoIsolate.openDatabase(v16Path);
      await DatabaseHelper.runFreshOnCreateForTest(v16Db, version: 16);
      await DatabaseHelper.setTestDatabase(v16Db);

      expect(await queueColumns(v16Db), isNot(contains('writer_snapshot')));

      DatabaseHelper.setWriterSnapshotProvider(
          () async => {'role': UserRole.owner.name, 'display_name': 'المالك'});

      final legacyId = await helper.insertProduct(
          product(barcode: 'WS5-LEGACY'),
          currentRole: UserRole.owner);

      final legacyEntries = await allEntries(v16Db);
      final legacyEntry =
          legacyEntries.singleWhere((e) => e.entityId == legacyId);
      expect(legacyEntry.writerSnapshot, isNull,
          reason: 'column absent at v16 → no snapshot persisted');

      // Upgrade to v17; column lands; fresh writes stamp the snapshot.
      await DatabaseHelper.runUpgradeToV17ForTest(v16Db);
      expect(await queueColumns(v16Db), contains('writer_snapshot'));

      final newId = await helper.insertProduct(product(barcode: 'WS5-NEW'),
          currentRole: UserRole.owner);

      final updatedEntries = await allEntries(v16Db);
      expect(updatedEntries, hasLength(2));

      final legacyStill =
          updatedEntries.singleWhere((e) => e.entityId == legacyId);
      expect(legacyStill.writerSnapshot, isNull,
          reason: 'legacy rows keep their NULL snapshot after upgrade');

      final newEntry = updatedEntries.singleWhere((e) => e.entityId == newId);
      final snap = newEntry.writerSnapshot;
      expect(snap, isNotNull);
      expect(snap!['permission_granted'], isTrue);
      expect(snap['shop_id'], 'shop-1');
      final writer = snap['writer'] as Map<String, dynamic>;
      expect(writer['role'], UserRole.owner.name);

      await v16Db.close();
      try {
        await tempDir.delete(recursive: true);
      } catch (_) {}
    });
  });
}
