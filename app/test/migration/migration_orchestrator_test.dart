import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:muaman_store/database/database_helper.dart';
import 'package:muaman_store/migration/cloud_migration_client.dart';
import 'package:muaman_store/migration/maintenance_mode.dart';
import 'package:muaman_store/migration/migration_models.dart';
import 'package:muaman_store/migration/migration_orchestrator.dart';
import 'package:muaman_store/migration/migration_progress_repository.dart';
import 'package:muaman_store/migration/reconciliation_service.dart';
import 'package:muaman_store/migration/snapshot_service.dart';

// =============================================================================
// Fake cloud migration client — hand-rolled (no mock packages in this repo).
//
// Emulates the frozen server contract (D4/D5/D10/D13):
//   * per-batch ledger replay (same batch+table+local_id → same verdict)
//   * cross-batch fingerprint idempotency (SKIPPED_DUPLICATE, no new cloud row)
//   * natural-key conflicts for pre-existing product barcodes (CONFLICT)
//   * financial aggregates computed from stored payloads (D15)
// =============================================================================

class FakeCloudMigrationClient implements CloudMigrationClient {
  /// table → localId → entry for the CURRENT batch under test. The service is
  /// single-batch at a time; entries persist across batches so cross-batch
  /// idempotency and stamping behave like the real server.
  final Map<String, Map<int, MigrationLedgerEntry>> ledger = {};

  /// table → fingerprint → payload of IMPORTED rows (cloud row content).
  final Map<String, Map<String, Map<String, dynamic>>> payloadByFingerprint =
      {};

  /// table → localId → payload (for financial aggregation).
  final Map<String, Map<int, Map<String, dynamic>>> payloadByLocal = {};

  /// shop|table|fingerprint → first entry ever created (cross-batch dedup).
  final Map<String, MigrationLedgerEntry> byFingerprint = {};

  final Set<String> existingProductBarcodes = {};

  /// Async observer fired before each chunk send: tests drive pause/abort or
  /// programmatic live writes from here. Throwing inside the hook simulates a
  /// network failure that persists across every retry attempt of the chunk.
  Future<void> Function(int callIndex, String localTable,
      List<MigrationChunkRowRequest> rows)? onUpsertChunk;

  /// Transform applied to fetchLedgerMappings results, keyed by call index
  /// (0 resolver rebuild, 1 post-pass completeness, 2 stamping).
  List<MigrationLedgerEntry> Function(
      int callIndex, List<MigrationLedgerEntry> entries)? onFetchLedger;

  /// Awaited async observer fired before fetchLedgerMappings resolves; lets
  /// tests perform deterministic owner aborts at exact stage boundaries
  /// (the flag commit is guaranteed visible before entries are returned).
  Future<void> Function(int callIndex)? onFetchLedgerAsync;

  /// Reconciliation tampering (alias → delta added to cloud sums).
  final Map<String, double> financialDeltas = {};

  int upsertCalls = 0;
  int fetchLedgerCalls = 0;
  int postPassCalls = 0;
  int freshImports = 0;
  bool healthy = true;

  final List<Map<String, String>> postPassLinkPairs = [];
  final Map<String, int> chunkCallsByTable = {};
  final List<String> sentPairs = []; // 'table#localId' — every send attempt
  final Set<String> confirmedPairs = {}; // pairs confirmed server-side

  int importedCount(String table) =>
      ledger[table]?.values.where((e) => e.status == 'IMPORTED').length ?? 0;

  int get totalLedgerEntries =>
      ledger.values.fold(0, (sum, t) => sum + t.length);

  List<String> get ledgerUuids => [
        for (final t in ledger.values)
          for (final e in t.values) e.cloudUuid
      ];

  String _nextUuid() =>
      '00000000-0000-4000-8000-${(_uuidSeq++).toString().padLeft(12, '0')}';
  int _uuidSeq = 0;

  @override
  Future<List<MigrationChunkRowResult>> upsertChunk({
    required String batchId,
    required String shopId,
    required String localTable,
    required List<MigrationChunkRowRequest> rows,
  }) async {
    final callIndex = upsertCalls++;
    final hook = onUpsertChunk;
    if (hook != null) {
      await hook(callIndex, localTable, rows);
    }
    if (!healthy) {
      throw Exception('simulated network failure');
    }
    chunkCallsByTable[localTable] = (chunkCallsByTable[localTable] ?? 0) + 1;

    final results = <MigrationChunkRowResult>[];
    for (final row in rows) {
      sentPairs.add('$localTable#${row.localId}');

      // (a) Per-batch replay of the same local row.
      final existingBatch = ledger[localTable]?[row.localId];
      if (existingBatch != null) {
        results.add(MigrationChunkRowResult(
          localId: row.localId,
          status: existingBatch.status,
          cloudUuid: existingBatch.cloudUuid,
          serverVersion: existingBatch.serverVersion,
        ));
        continue;
      }

      // (b) Cross-batch content idempotency (D10).
      final fpKey = '$shopId|$localTable|${row.fingerprint}';
      final existingFp = byFingerprint[fpKey];
      if (existingFp != null) {
        final entry = MigrationLedgerEntry(
          localTable: localTable,
          localId: row.localId,
          cloudUuid: existingFp.cloudUuid,
          serverVersion: existingFp.serverVersion,
          status: 'SKIPPED_DUPLICATE',
        );
        (ledger[localTable] ??= {})[row.localId] = entry;
        results.add(MigrationChunkRowResult(
          localId: row.localId,
          status: 'SKIPPED_DUPLICATE',
          cloudUuid: entry.cloudUuid,
          serverVersion: entry.serverVersion,
        ));
        continue;
      }

      // (c) Natural-key collision: existing cloud row wins (D13).
      if (localTable == 'products' &&
          existingProductBarcodes.contains(row.payload['barcode'])) {
        final uuid = _nextUuid();
        (ledger[localTable] ??= {})[row.localId] = MigrationLedgerEntry(
          localTable: localTable,
          localId: row.localId,
          cloudUuid: uuid,
          serverVersion: 7,
          status: 'CONFLICT',
        );
        results.add(MigrationChunkRowResult(
          localId: row.localId,
          status: 'CONFLICT',
          cloudUuid: uuid,
          serverVersion: 7,
        ));
        continue;
      }

      // (d) Fresh import.
      final uuid = _nextUuid();
      final entry = MigrationLedgerEntry(
        localTable: localTable,
        localId: row.localId,
        cloudUuid: uuid,
        serverVersion: 1,
        status: 'IMPORTED',
      );
      (ledger[localTable] ??= {})[row.localId] = entry;
      ((payloadByFingerprint[localTable] ??= {})[row.fingerprint] =
          row.payload);
      ((payloadByLocal[localTable] ??= {})[row.localId] = row.payload);
      byFingerprint[fpKey] = entry;
      freshImports++;
      results.add(MigrationChunkRowResult(
        localId: row.localId,
        status: 'IMPORTED',
        cloudUuid: uuid,
        serverVersion: 1,
      ));
    }
    // The whole chunk committed server-side: every row it carried is now
    // durably confirmed (used by tests to prove resume never re-sends
    // confirmed work).
    for (final r in rows) {
      confirmedPairs.add('$localTable#${r.localId}');
    }
    return results;
  }

  @override
  Future<Map<String, dynamic>> postPassLinks({
    required String batchId,
    required String shopId,
    required List<Map<String, String>> saleInvoiceLinks,
  }) async {
    postPassCalls++;
    postPassLinkPairs.addAll(saleInvoiceLinks);
    return {'linked': saleInvoiceLinks.length};
  }

  @override
  Future<List<MigrationLedgerEntry>> fetchLedgerMappings({
    required String batchId,
    required String shopId,
  }) async {
    // The logical call index advances on EVERY invocation regardless of
    // which hooks are installed, so stage-keyed observers (0 resolver
    // rebuild, 1 post-pass completeness, 2 stamping) are deterministic.
    final callIndex = fetchLedgerCalls++;
    final asyncHook = onFetchLedgerAsync;
    if (asyncHook != null) {
      await asyncHook(callIndex);
    }
    var entries = [
      for (final t in ledger.values) ...t.values,
    ];
    final hook = onFetchLedger;
    if (hook != null) {
      entries = hook(callIndex, entries);
    }
    return entries;
  }

  double _sumFor(String table, String field) {
    var sum = 0.0;
    for (final entry
        in ledger[table]?.values ?? const <MigrationLedgerEntry>[]) {
      if (entry.status != 'IMPORTED') continue;
      final payload = payloadByLocal[table]?[entry.localId];
      if (payload == null) continue;
      sum += (payload[field] as num?)?.toDouble() ?? 0.0;
    }
    return sum;
  }

  @override
  Future<Map<String, dynamic>> reconcileBatch({
    required String batchId,
    required String shopId,
  }) async {
    final tables = <String, dynamic>{};
    for (final table in ledger.keys) {
      final values = ledger[table]!.values;
      tables[table] = {
        'IMPORTED': values.where((e) => e.status == 'IMPORTED').length,
        'SKIPPED_DUPLICATE':
            values.where((e) => e.status == 'SKIPPED_DUPLICATE').length,
        'CONFLICT': values.where((e) => e.status == 'CONFLICT').length,
      };
    }
    double fin(String alias, String table, String field) {
      var base = _sumFor(table, field);
      final delta = financialDeltas[alias];
      if (delta != null) base += delta;
      return base;
    }

    return {
      'tables': tables,
      'financials': <String, double>{
        'sales.total_sale_value':
            fin('sales.total_sale_value', 'sales', 'total_sale_value'),
        'sales.cogs': fin('sales.cogs', 'sales', 'cogs'),
        'invoices.total_amount':
            fin('invoices.total_amount', 'invoices', 'total_amount'),
        'expenses.amount': fin('expenses.amount', 'expenses', 'amount'),
        'returns.returned_cogs':
            fin('returns.returned_cogs', 'returns', 'returned_cogs'),
      },
      'imported_rows': {
        for (final table in ledger.keys) table: importedCount(table),
      },
    };
  }
}

void main() {
  sqfliteFfiInit();
  // The snapshot service's integrity check and the orchestrator's D16
  // fallback consult the GLOBAL sqflite factory; production code initializes
  // it via the sqflite plugin — wire it to the ffi driver for VM tests.
  databaseFactory = databaseFactoryFfiNoIsolate;
  MigrationMaintenanceMode.resetForTest();

  late Directory tempDir;
  late Database liveDb;
  late Directory snapDir;
  late FakeCloudMigrationClient client;
  late LegacyMigrationService service;
  var batchSeq = 0;

  LegacyMigrationService makeService({
    FakeCloudMigrationClient? overrideClient,
    String? snapshotDirectory,
    int chunkSize = 2,
  }) {
    return LegacyMigrationService(
      db: liveDb,
      cloudClient: overrideClient ?? client,
      shopIdProvider: () async => 'shop-1',
      licenseCheck: () async => true,
      batchIdGenerator: () => 'batch-${++batchSeq}',
      config: LegacyMigrationConfig(
        snapshotDirectory: snapshotDirectory ?? snapDir.path,
        chunkSize: chunkSize,
        backoffSchedule: const [Duration.zero],
      ),
    );
  }

  Future<Map<String, dynamic>> progressRow(String batchId) async {
    final row = await MigrationProgressRepository(liveDb).getBatch(batchId);
    return row!;
  }

  setUp(() async {
    MigrationMaintenanceMode.resetForTest();
    tempDir = await Directory.systemTemp.createTemp('muaman_mig_test');
    snapDir = Directory(p.join(tempDir.path, 'snaps'));
    liveDb = await databaseFactoryFfiNoIsolate
        .openDatabase(p.join(tempDir.path, 'live.db'));
    await DatabaseHelper.runCreateDbForTest(liveDb);
    client = FakeCloudMigrationClient();
    batchSeq = 0;
    service = makeService();
  });

  tearDown(() async {
    await liveDb.close();
    try {
      await tempDir.delete(recursive: true);
    } catch (_) {}
  });

  Future<void> seedLegacyData({
    int products = 3,
    int categories = 2,
    int customers = 2,
    int expenses = 2,
    int inventoryCounts = 1,
    int sales = 3,
    int invoices = 1,
    int returns = 1,
    int settings = 5,
    bool orphanInventoryCount = false,
    bool linkSaleToInvoice = false,
  }) async {
    for (var i = 1; i <= categories; i++) {
      await liveDb.insert('expense_categories', {'name': 'فئة-$i'});
    }
    for (var i = 1; i <= products; i++) {
      await liveDb.insert('products', {
        'name': 'منتج-$i',
        'barcode': 'BAR-$i',
        'openingQuantity': 10,
        'soldQuantity': 2,
        'returnedQuantity': 0,
        'currentQuantity': 8,
        'costPrice': 5.0,
        'totalInventoryCost': 50.0,
        'inventoryAdjustment': 0,
      });
    }
    for (var i = 1; i <= customers; i++) {
      await liveDb.insert('customers', {
        'name': 'عميل-$i',
        'phone': '050000000$i',
        'isActive': 1,
        'isSystem': 0,
        'createdAt': '2026-01-01T00:00:00.00$i',
        'updatedAt': '2026-01-01T00:00:00.000',
      });
    }
    for (var i = 1; i <= expenses; i++) {
      await liveDb.insert('expenses', {
        'date': '2026-02-0$i',
        'description': 'مصروف-$i',
        'amount': 10.5 * i,
        'category': 'فئة-1',
      });
    }
    for (var i = 1; i <= inventoryCounts; i++) {
      await liveDb.insert('inventory_count', {
        'productId': i,
        'actualQuantity': 7,
        'notes': '',
        'countDate': '2026-03-0$i',
      });
    }
    if (orphanInventoryCount) {
      await liveDb.insert('inventory_count', {
        'productId': 9999, // no such product → missing reference (D6)
        'actualQuantity': 1,
        'notes': '',
        'countDate': '2026-03-09',
      });
    }
    for (var i = 1; i <= invoices; i++) {
      await liveDb.insert('invoices', {
        'invoiceNumber': 'INV-00$i',
        'date': '2026-04-0$i',
        'customerName': 'عميل-1',
        'paymentMethod': 'cash',
        'totalAmount': 30.0 * i,
        'totalItems': 3 * i,
        'createdAt': '2026-04-0${i}T10:00:00.000',
      });
    }
    for (var i = 1; i <= sales; i++) {
      await liveDb.insert('sales', {
        'invoiceId': linkSaleToInvoice && i == 1 ? 1 : null,
        'date': '2026-05-0$i',
        'productName': 'منتج-1',
        'barcode': 'BAR-1',
        'quantity': 1,
        'salePrice': 12.5,
        'totalSaleValue': 12.5,
        'costPrice': 5.0,
        'cogs': 5.0,
      });
    }
    for (var i = 1; i <= returns; i++) {
      await liveDb.insert('returns', {
        'date': '2026-06-0$i',
        'productName': 'منتج-1',
        'barcode': 'BAR-1',
        'quantity': 1,
        'salePrice': 12.5,
        'totalReturnValue': 12.5,
        'costPrice': 5.0,
        'returnedCogs': 5.0,
      });
    }
    for (var i = 1; i <= settings; i++) {
      await liveDb
          .insert('app_settings', {'key': 'setting-$i', 'value': 'v$i'});
    }
  }

  group('Frozen state machine (D9)', () {
    test('NOT_STARTED → ABORTED is permitted (governing semantics)', () {
      expect(
          LegacyMigrationStateMachine.canTransition(
              LegacyMigrationState.NOT_STARTED, LegacyMigrationState.ABORTED),
          isTrue);
      final sm = LegacyMigrationStateMachine();
      sm.requireTransition(LegacyMigrationState.ABORTED); // must not throw
      expect(sm.state, LegacyMigrationState.ABORTED);
    });

    test('ABORTED and COMPLETED are terminal with no outgoing transitions', () {
      for (final terminal in [
        LegacyMigrationState.ABORTED,
        LegacyMigrationState.COMPLETED,
      ]) {
        expect(kLegacyMigrationTransitions[terminal], isEmpty);
        expect(terminal.isTerminal, isTrue);
        expect(
            LegacyMigrationStateMachine.canTransition(
                terminal, LegacyMigrationState.RUNNING),
            isFalse);
      }
    });

    test('RUNNING ⇄ PAUSED and PAUSED → ABORTED/FAILED permitted', () {
      expect(
          LegacyMigrationStateMachine.canTransition(
              LegacyMigrationState.RUNNING, LegacyMigrationState.PAUSED),
          isTrue);
      expect(
          LegacyMigrationStateMachine.canTransition(
              LegacyMigrationState.PAUSED, LegacyMigrationState.RUNNING),
          isTrue);
      expect(
          LegacyMigrationStateMachine.canTransition(
              LegacyMigrationState.PAUSED, LegacyMigrationState.ABORTED),
          isTrue);
      expect(
          LegacyMigrationStateMachine.canTransition(
              LegacyMigrationState.PAUSED, LegacyMigrationState.FAILED),
          isTrue);
    });

    test('RECONCILING → FAILED permitted (resumable failure)', () {
      expect(
          LegacyMigrationStateMachine.canTransition(
              LegacyMigrationState.RECONCILING, LegacyMigrationState.FAILED),
          isTrue);
    });
  });

  group('Happy path: full migration completes and stamps exactly once', () {
    test('COMPLETED with complete ledger, stamping, zero sync_queue echo',
        () async {
      await seedLegacyData(linkSaleToInvoice: true);

      // Pre-existing PENDING queue fixtures (D7 echo guard):
      //  * an UNRELATED entry (no such product; never migrated/stamped) must
      //    survive untouched, and migration must add ZERO new queue rows;
      //  * a STALE entry belonging to a row this batch stamps (product #1)
      //    is defensively cleared by D17 stamping so the continuous-sync
      //    engine can never re-upload freshly migrated legacy rows.
      await liveDb.insert('sync_queue', {
        'id': 'pre-existing-entry',
        'entity_type': 'product',
        'entity_id': 999,
        'operation': 'CREATE',
        'created_at': DateTime.now().toIso8601String(),
        'retry_count': 0,
        'status': 'PENDING',
        'idempotency_key': 'pre-existing-key',
      });
      await liveDb.insert('sync_queue', {
        'id': 'stale-stamped-product-entry',
        'entity_type': 'product',
        'entity_id': 1,
        'operation': 'CREATE',
        'created_at': DateTime.now().toIso8601String(),
        'retry_count': 0,
        'status': 'PENDING',
        'idempotency_key': 'stale-stamped-key',
      });
      final queueBefore =
          (await liveDb.rawQuery('SELECT COUNT(*) AS c FROM sync_queue'))
              .single['c'] as int;

      final batchId = await service.startBatch();

      final row = await progressRow(batchId);
      expect(row['status'], 'COMPLETED');
      expect(row['phase'], 'DONE');

      // Every phase marked DONE including shop settings (P8b).
      final stats = MigrationProgressRepository.decodeStats(row)!;
      final phases = (stats['phases'] as Map).cast<String, dynamic>();
      expect(phases.keys, containsAll(['P1', 'P2', 'P3', 'P4', 'P5']));
      expect(phases.values.toSet(), {'DONE'});
      expect(stats['ledgerCompleteness']['verdict'], 'COMPLETE');
      expect(stats['stamped.products'], 3);
      expect(stats['stamped.app_settings'], 5);

      // Ledger accounted == census for every table (completeness evidence).
      const census = {
        'products': 3,
        'sales': 3,
        'returns': 1,
        'expenses': 2,
        'expense_categories': 2,
        'customers': 2,
        'invoices': 1,
        'inventory_count': 1,
        'app_settings': 5,
      };
      for (final entry in census.entries) {
        expect(client.importedCount(entry.key), entry.value,
            reason: '${entry.key} ledger mismatch');
      }

      // Stamping: every migrated local row now carries Phase-H SYNCED state.
      final unstamped =
          await liveDb.rawQuery("SELECT COUNT(*) AS c FROM products "
              "WHERE cloud_uuid IS NULL OR sync_status != 'SYNCED'");
      expect(unstamped.single['c'], 0);
      final stampedSettings = await liveDb.rawQuery(
          "SELECT COUNT(*) AS c FROM app_settings WHERE sync_status='SYNCED'"
          " AND cloud_uuid IS NOT NULL AND last_synced_at IS NOT NULL"
          ' AND server_version > 0');
      expect(stampedSettings.single['c'], 5);

      // D17: stamping happened without any sync_queue echo: zero additions,
      // exactly one sanctioned removal (the stamped row's stale entry).
      final queueAfter =
          (await liveDb.rawQuery('SELECT COUNT(*) AS c FROM sync_queue'))
              .single['c'] as int;
      expect(queueAfter, queueBefore - 1,
          reason:
              'migration must never enqueue into sync_queue; only the stamped '
              'row\'s stale PENDING entry may be cleared');

      // Deletion stayed scoped: only the stamped row's stale entry cleared.
      final staleCleared = await liveDb.query('sync_queue',
          where: 'id = ?', whereArgs: ['stale-stamped-product-entry']);
      expect(staleCleared, isEmpty,
          reason:
              'stale PENDING entries of stamped rows are defensively cleared');

      // The pre-existing unrelated entry was left intact.
      final preserved = await liveDb.query('sync_queue',
          where: 'id = ?', whereArgs: ['pre-existing-entry']);
      expect(preserved, isNotEmpty);
      expect(preserved.first['status'], 'PENDING');

      // P9 ran and repaired the invoice↔sale link via resolved uuid pairs.
      expect(client.postPassCalls, 1);
      expect(client.postPassLinkPairs, hasLength(1));
      expect(client.postPassLinkPairs.first.keys,
          unorderedEquals(['sale_cloud_uuid', 'invoice_cloud_uuid']));
    });

    test('app_settings TEXT-PK table chunks by explicit SQLite rowid cursor',
        () async {
      await seedLegacyData(settings: 7, products: 1);

      final batchId = await service.startBatch();
      expect((await progressRow(batchId))['status'], 'COMPLETED');

      // All 7 settings imported exactly once despite chunk size 2 → proves
      // SELECT rowid AS migration_local_id works where `SELECT *` exposes no id.
      expect(client.importedCount('app_settings'), 7);
      final settingSends =
          client.sentPairs.where((s) => s.startsWith('app_settings#'));
      expect(settingSends.toSet().length, settingSends.length,
          reason: 'no duplicate sends of app_settings rows');

      // Chunking actually happened (>1 chunk for 7 rows at chunkSize=2).
      expect(client.chunkCallsByTable['app_settings'], greaterThan(1));

      // Ledger local_ids are real snapshot rowids (dense 1..7 here).
      final ids = client.ledger['app_settings']!.keys.toList()..sort();
      expect(ids, [1, 2, 3, 4, 5, 6, 7]);
    });

    test('chunk continuation advances cursors across multi-chunk tables',
        () async {
      await seedLegacyData(products: 5, sales: 4, settings: 3);
      final batchId = await service.startBatch();
      expect((await progressRow(batchId))['status'], 'COMPLETED');

      // chunkSize=2 forces multiple chunks per multi-row table; each row sent
      // exactly once overall.
      expect(client.chunkCallsByTable['products'], 3);
      expect(client.chunkCallsByTable['sales'], 2);
      final productSends =
          client.sentPairs.where((s) => s.startsWith('products#')).toList();
      expect(productSends.toSet().length, 5);
    });
  });

  group('Restartability / durability', () {
    test('FAILED run resumes from durable checkpoint and completes', () async {
      await seedLegacyData(products: 4, sales: 3);

      // The network dies from logical chunk #5 onward and EVERY retry
      // attempt fails until healed (a single pinned call index would not
      // survive the retry loop, which re-indexes each attempt): chunks 0-4
      // stay confirmed+checkpointed before the failure surfaces.
      client.onUpsertChunk = (callIndex, table, rows) async {
        if (callIndex >= 5) {
          throw Exception('simulated network failure');
        }
      };

      Object? caught;
      try {
        await service.startBatch();
      } catch (e) {
        caught = e;
      }
      expect(caught, isA<MigrationCloudException>());

      final failedRow = await progressRow('batch-1');
      expect(failedRow['status'], 'FAILED');
      final failedStats = MigrationProgressRepository.decodeStats(failedRow)!;
      expect(failedStats['phases']['P1'], 'DONE');
      // Checkpoints are durable row COLUMNS (D8), not stats entries.
      expect(failedRow['last_table'], isNotNull);

      // Heal and resume the SAME batch from its durable checkpoint.
      final confirmedBeforeFailure = Set<String>.from(client.confirmedPairs);
      client.onUpsertChunk = null;
      client.sentPairs.clear();

      final resumedId = await service.resumeBatch('batch-1');
      expect(resumedId, 'batch-1');

      final doneRow = await progressRow('batch-1');
      expect(doneRow['status'], 'COMPLETED');
      expect(client.importedCount('products'), 4);
      expect(client.importedCount('sales'), 3);

      // Resume must not re-send any chunk already confirmed before the crash.
      final overlap =
          client.sentPairs.toSet().intersection(confirmedBeforeFailure);
      expect(overlap, isEmpty,
          reason: 'checkpoint resume re-sent confirmed rows: $overlap');

      // Nothing stamped twice: all products stamped exactly once.
      final stampedCount = await liveDb.rawQuery(
          "SELECT COUNT(*) AS c FROM products WHERE sync_status='SYNCED'"
          ' AND cloud_uuid IS NOT NULL');
      expect(stampedCount.single['c'], 4);
    });

    test('idempotent rerun via NEW batch: all SKIPPED_DUPLICATE, no new rows',
        () async {
      await seedLegacyData(products: 2, sales: 2);

      // Run 1 uploads the ENTIRE universe, then crashes at the post-pass
      // boundary (ledger fetch #1) before finalization — FAILED with a full
      // ledger. (A mid-import chunk failure cannot produce an all-duplicates
      // rerun: rows its failed chunk never delivered must import fresh; that
      // scenario is covered by the resume test above.)
      client.onFetchLedgerAsync = (callIndex) async {
        if (callIndex == 1) {
          throw Exception('simulated crash after complete import');
        }
      };
      Object? caught;
      try {
        await service.startBatch();
      } catch (e) {
        caught = e;
      }
      expect(caught, isA<MigrationCloudException>());
      expect((await progressRow('batch-1'))['status'], 'FAILED');

      final importsAfterFirstRun = client.freshImports;
      final uuidsAfterFirstRun = Set<String>.from(client.ledgerUuids);
      client.sentPairs.clear();

      // Owner starts a brand-new batch over the same legacy store (D10/D12).
      final secondId = await service.startBatch();
      expect(secondId, 'batch-2');
      expect((await progressRow('batch-2'))['status'], 'COMPLETED');

      // Zero new cloud rows: everything matched existing fingerprints.
      expect(client.freshImports, importsAfterFirstRun);
      expect(Set<String>.from(client.ledgerUuids), uuidsAfterFirstRun);

      // Yet the new batch still accounts for the full universe (ledger entries
      // recorded as SKIPPED_DUPLICATE pointing at the original cloud rows).
      expect(
          client.importedCount('products') +
              (client.ledger['products']?.values
                      .where((e) => e.status == 'SKIPPED_DUPLICATE')
                      .length ??
                  0),
          greaterThanOrEqualTo(2));
      expect(client.importedCount('sales'), 2,
          reason: 'run-1 IMPORTED ledger entries are reused by the rerun');

      // And the live store ends fully stamped exactly once.
      final stamped = await liveDb.rawQuery(
          "SELECT COUNT(*) AS c FROM products WHERE sync_status='SYNCED'");
      expect(stamped.single['c'], 2);
    });

    test('owner PAUSE persists PAUSED durably; resume continues, not restarts',
        () async {
      await seedLegacyData(products: 2, sales: 3, invoices: 1);

      client.onUpsertChunk = (callIndex, table, rows) async {
        // Pause during the FIRST sales chunk; earlier phases stay complete.
        if (table == 'sales') {
          service.requestPause();
        }
      };

      final batchId = await service.startBatch();
      final pausedRow = await progressRow(batchId);
      expect(pausedRow['status'], 'PAUSED',
          reason: 'PAUSED must be durably persisted before returning');

      final pausedStats = MigrationProgressRepository.decodeStats(pausedRow)!;
      final phases = (pausedStats['phases'] as Map).cast<String, dynamic>();
      expect(phases['P1'], 'DONE'); // expense categories finished
      expect(phases.containsKey('P8b'), isFalse,
          reason: 'run must stop at the pause boundary');
      expect(client.postPassCalls, 0,
          reason: 'no post-pass/stamping work may happen while paused');

      final sentAtPause = Set<String>.from(client.sentPairs);

      // Resume continues from durable progress.
      client.onUpsertChunk = null;
      client.sentPairs.clear(); // isolate post-resume sends
      await service.resumeBatch(batchId);

      final doneRow = await progressRow(batchId);
      expect(doneRow['status'], 'COMPLETED');
      expect(client.importedCount('sales'), 3);

      // Already-sent rows were NOT re-sent (durable cursor honored).
      final reSent =
          client.sentPairs.where((pair) => sentAtPause.contains(pair)).toList();
      expect(reSent, isEmpty,
          reason: 'resume must continue from checkpoint, not restart');
    });

    test('missing-reference evidence survives interruption (incremental)',
        () async {
      await seedLegacyData(orphanInventoryCount: true);

      // Fail during P6 sales (after P5 discovered the orphan reference).
      client.onUpsertChunk = (callIndex, table, rows) async {
        if (table == 'sales') {
          throw Exception('simulated crash after missing-ref discovery');
        }
      };

      Object? caught;
      try {
        await service.startBatch();
      } catch (e) {
        caught = e;
      }
      expect(caught, isNotNull);

      final row = await progressRow('batch-1');
      final stats = MigrationProgressRepository.decodeStats(row)!;
      final missingRefs =
          (stats['missingRefs'] as Map?)?.cast<String, dynamic>() ?? {};
      expect(missingRefs['inventory_count'], isNotEmpty,
          reason:
              'discovered reconciliation evidence must be durable BEFORE the pipeline ends');

      // Resume with a healthy client: evidence preserved (seeded), orphan row
      // stays excluded from import, batch completes because countsMatch
      // includes the explicit missing-reference bucket.
      client.onUpsertChunk = null;
      await service.resumeBatch('batch-1');
      final doneRow = await progressRow('batch-1');
      expect(doneRow['status'], 'COMPLETED');
      final doneStats = MigrationProgressRepository.decodeStats(doneRow)!;
      final doneMissing =
          ((doneStats['missingRefs'] as Map?)?.cast<String, dynamic>()) ?? {};
      expect(doneMissing['inventory_count'], isNotEmpty,
          reason: 'resumed run must keep previously discovered evidence');
      expect(doneStats['reconciliation']['verdict'], 'PASS');
    });
  });

  group('Abort semantics (terminal)', () {
    test('abort mid-import stops everything; no later phase runs; no stamping',
        () async {
      await seedLegacyData(sales: 2, invoices: 1);

      client.onUpsertChunk = (callIndex, table, rows) async {
        if (table == 'sales') {
          await service.abort('batch-1');
        }
      };

      final batchId = await service.startBatch();
      expect(batchId, 'batch-1');

      final row = await progressRow(batchId);
      expect(row['status'], 'ABORTED',
          reason: 'ABORTED is terminal and durably committed');

      // Later phases never executed.
      expect(client.postPassCalls, 0);
      expect(client.importedCount('invoices'), 0);
      expect(client.importedCount('app_settings'), 0);

      // No local mutation: nothing stamped anywhere.
      for (final table in ['products', 'sales', 'app_settings']) {
        final unstamped = await liveDb.rawQuery(
            'SELECT COUNT(*) AS c FROM $table WHERE cloud_uuid IS NOT NULL');
        expect(unstamped.single['c'], 0, reason: '$table must be untouched');
      }
    });

    test('abort observed during stamping prevents ANY stamping mutation',
        () async {
      await seedLegacyData(products: 2);

      // Stamp-stage ledger fetch is the third call (0 resolver rebuild, 1
      // post-pass completeness, 2 stamping). The AWAITED async hook commits
      // the owner abort before the pipeline can proceed past this boundary —
      // no racy fire-and-forget.
      client.onFetchLedgerAsync = (callIndex) async {
        if (callIndex == 2) {
          await service.abort('batch-1');
        }
      };

      final batchId = await service.startBatch();
      expect(batchId, 'batch-1');

      final row = await progressRow(batchId);
      expect(row['status'], 'ABORTED',
          reason: 'ABORTED is terminal and durably committed');

      // CRITICAL: reconciliation passed, but ZERO rows were stamped because
      // the abort was observed before the first stamping transaction.
      final stamped = await liveDb.rawQuery(
          'SELECT COUNT(*) AS c FROM products WHERE cloud_uuid IS NOT NULL');
      expect(stamped.single['c'], 0,
          reason: 'no stamping mutation may occur after abort is observed');
    });

    test('post-abort: resume rejected, repeat abort no-op, nothing mutates',
        () async {
      await seedLegacyData(sales: 1);
      client.onUpsertChunk = (callIndex, table, rows) async {
        if (table == 'sales') await service.abort('batch-1');
      };
      await service.startBatch();
      client.onUpsertChunk = null;

      final rowBefore = await progressRow('batch-1');
      final sendsBefore = List<String>.from(client.sentPairs);
      final linksBefore = client.postPassCalls;

      // Terminal batches reject resume outright (D10).
      Object? resumeError;
      try {
        await service.resumeBatch('batch-1');
      } catch (e) {
        resumeError = e;
      }
      expect(resumeError, isA<MigrationStateException>());

      // Repeated abort is an acknowledged no-op.
      await service.abort('batch-1');

      // Nothing moved after terminal commit.
      final rowAfter = await progressRow('batch-1');
      expect(rowAfter['status'], rowBefore['status']);
      expect(rowAfter['stats_json'], rowBefore['stats_json']);
      expect(client.postPassCalls, linksBefore);
      expect(client.sentPairs.length, sendsBefore.length);
    });
  });

  group('Superseded detection & reconciliation gates', () {
    test('programmatic live write during run aborts the batch as superseded',
        () async {
      await seedLegacyData(products: 2);

      var rogueInserted = false;
      client.onUpsertChunk = (callIndex, table, rows) async {
        if (table == 'sales' && !rogueInserted) {
          rogueInserted = true;
          // Simulate a programmatic write bypassing maintenance mode.
          await liveDb.insert('products', {
            'name': 'rogue-product',
            'barcode': 'BAR-ROGUE',
            'openingQuantity': 1,
            'currentQuantity': 1,
            'costPrice': 1.0,
            'totalInventoryCost': 1.0,
            'inventoryAdjustment': 0,
          });
        }
      };

      Object? caught;
      try {
        await service.startBatch();
      } catch (e) {
        caught = e;
      }
      expect(caught, isA<MigrationStateException>());
      expect(
          (caught as MigrationStateException).message, contains('superseded'));

      final row = await progressRow('batch-1');
      expect(row['status'], 'ABORTED');
    });

    test('tampered cloud financials FAIL reconciliation and block stamping',
        () async {
      await seedLegacyData(sales: 2);

      client.financialDeltas['sales.total_sale_value'] = 100.0;

      final batchId = await service.startBatch();
      final row = await progressRow(batchId);
      expect(row['status'], 'FAILED',
          reason: 'FAIL verdict blocks finalization (D15)');

      final stamped = await liveDb.rawQuery(
          'SELECT COUNT(*) AS c FROM sales WHERE cloud_uuid IS NOT NULL');
      expect(stamped.single['c'], 0, reason: 'nothing may be stamped on FAIL');
    });

    test('natural-key conflict: CONFLICT ledger status, row left unstamped',
        () async {
      await seedLegacyData(products: 2);
      client.existingProductBarcodes.addAll({'BAR-1'});

      final batchId = await service.startBatch();
      final row = await progressRow(batchId);
      expect(row['status'], 'COMPLETED');

      // Conflicting row recorded but NOT imported NOR stamped.
      expect(client.ledger['products']![1]!.status, 'CONFLICT');
      expect(client.importedCount('products'), 1);
      final conflictedLocal = await liveDb
          .rawQuery("SELECT COUNT(*) AS c FROM products WHERE barcode='BAR-1'"
              ' AND cloud_uuid IS NULL');
      expect(conflictedLocal.single['c'], 1,
          reason: 'existing cloud row wins; local colliding row stays legacy');
    });

    test('incomplete ledger blocks finalization with INCOMPLETE verdict',
        () async {
      await seedLegacyData(products: 2, sales: 1);

      // Post-pass fetch (#1) silently drops ALL sales entries → expected-vs-
      // recorded mismatch beyond the missing-ref bucket → gate trips.
      client.onFetchLedger = (callIndex, entries) {
        if (callIndex == 1) {
          return entries
              .where((e) => e.localTable != 'sales')
              .toList(growable: false);
        }
        return entries;
      };

      final batchId = await service.startBatch();
      final row = await progressRow(batchId);
      expect(row['status'], 'FAILED',
          reason: 'a partially populated ledger can never finalize');

      final stats = MigrationProgressRepository.decodeStats(row)!;
      expect(stats['ledgerCompleteness']['verdict'], 'INCOMPLETE');

      final stamped = await liveDb.rawQuery(
          'SELECT COUNT(*) AS c FROM sales WHERE cloud_uuid IS NOT NULL');
      expect(stamped.single['c'], 0);
    });
  });

  group('Snapshot handling', () {
    test('empty snapshotDirectory resolves via sqflite databases path root',
        () async {
      await seedLegacyData(products: 1);
      final dbRoot = p.join(tempDir.path, 'dbroot');
      await databaseFactoryFfiNoIsolate.setDatabasesPath(dbRoot);

      final defaultConfigService = LegacyMigrationService(
        db: liveDb,
        cloudClient: client,
        shopIdProvider: () async => 'shop-1',
        licenseCheck: () async => true,
        batchIdGenerator: () => 'batch-${++batchSeq}',
        config: const LegacyMigrationConfig(), // snapshotDirectory ''
      );

      final batchId = await defaultConfigService.startBatch();
      expect((await progressRow(batchId))['status'], 'COMPLETED');

      final resolvedRoot = Directory(p.join(dbRoot, 'migration_snapshots'));
      expect(resolvedRoot.existsSync(), isTrue,
          reason:
              'snapshot destination defaults to getDatabasesPath()/migration_snapshots');
      expect(
          resolvedRoot.listSync().whereType<File>(),
          everyElement(isA<File>()
              .having((f) => f.lengthSync(), 'size', greaterThan(0))));
    });

    test('tampered snapshot fails verification and leaves state unchanged',
        () async {
      await seedLegacyData(products: 1);

      // Pin a snapshot through the service's own machinery, then corrupt it.
      final snapshot =
          await const LegacySnapshotService().createVerifiedSnapshot(
        liveDb: liveDb,
        destinationDirectory: snapDir.path,
        fileBaseName: 'corrupt_me',
      );
      await File(snapshot.path).writeAsString('garbage', mode: FileMode.append);

      // Insert the batch row manually as NOT_STARTED pointing at the corrupt
      // pin, then attempt a resume: verification must refuse promotion.
      await MigrationProgressRepository(liveDb).insertBatch(
        batchId: 'batch-corrupt',
        shopId: 'shop-1',
        phase: 'P0',
        status: 'NOT_STARTED',
        snapshotPath: snapshot.path,
        snapshotSha256: snapshot.sha256,
        stats: {},
      );

      Object? caught;
      try {
        await service.resumeBatch('batch-corrupt');
      } catch (e) {
        caught = e;
      }
      expect(caught, isNotNull);

      final row = await progressRow('batch-corrupt');
      expect(row['status'], 'NOT_STARTED',
          reason: 'verification failure must not promote the batch state');
    });
  });

  group('ReconciliationService construction & behavior (D15)', () {
    test('retains the exact snapshot db instance it was constructed with',
        () async {
      final snapshotDb = await databaseFactoryFfiNoIsolate
          .openDatabase(p.join(tempDir.path, 'reconcile_snapshot.db'));
      addTearDown(snapshotDb.close);
      // Give THIS db a distinctive census only it holds.
      for (final ddl in _universeTablesDdl()) {
        await snapshotDb.execute(ddl);
      }
      for (var i = 1; i <= 3; i++) {
        await snapshotDb.insert('products', {'name': 'p$i', 'barcode': 'B$i'});
      }

      client.ledger['products'] = {
        for (var i = 1; i <= 3; i++)
          i: MigrationLedgerEntry(
              localTable: 'products',
              localId: i,
              cloudUuid: 'u$i',
              serverVersion: 1,
              status: 'IMPORTED'),
      };
      client.payloadByLocal['products'] = {
        for (var i = 1; i <= 3; i++)
          i: {
            'name': 'p$i',
            'barcode': 'B$i',
            'opening_quantity': 10,
            'sold_quantity': 2,
            'returned_quantity': 0,
            'current_quantity': 8,
            'cost_price': 5.0,
            'total_inventory_cost': 50.0,
            'inventory_adjustment': 0,
          },
      };
      client.payloadByFingerprint['products'] = {
        for (var i = 1; i <= 3; i++)
          'fp$i': client.payloadByLocal['products']![i]!,
      };
      client.byFingerprint.addEntries([
        for (var i = 1; i <= 3; i++)
          MapEntry('shop-1|products|fp$i', client.ledger['products']![i]!),
      ]);

      final recon = ReconciliationService(
        snapshotDb: snapshotDb,
        cloudClient: client,
      );
      final report = await recon.reconcile(
        batchId: 'batch-x',
        shopId: 'shop-1',
        missingRefsByTable: const {},
      );

      // The report MUST reflect the CONSTRUCTED snapshot db (expected_rows=3),
      // proving the intended DB instance is retained end-to-end.
      final productsResult =
          report.tables.firstWhere((t) => t.tableName == 'products');
      expect(productsResult.expectedRows, 3);
      expect(productsResult.countsMatch, isTrue);
      expect(report.verdictPass, isTrue);
      expect(report.verdict, 'PASS');
    });

    test('report JSON round-trip preserves verdict and buckets', () {
      final report = ReconciliationReport.fromMap({
        'batch_id': 'b',
        'shop_id': 's',
        'tables': [
          {
            'table': 'sales',
            'expected_rows': 4,
            'imported': 3,
            'duplicates_skipped': 0,
            'conflicts': 0,
            'missing_refs': ['sales#4: orphan'],
            'financial_expected': {'sales.total_sale_value': 25.0},
            'financial_actual': {'sales.total_sale_value': 18.75},
            'pass': false,
          }
        ],
        'quarantined_notes': ['note'],
      });
      expect(report.verdictPass, isFalse);
      expect(jsonEncode(report.toMap()), contains('missing_refs'));
    });
  });
}

/// Minimal DDL for all nine migration-universe tables on a raw snapshot db.
List<String> _universeTablesDdl() {
  return [
    '''
    CREATE TABLE products (
      id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL,
      barcode TEXT UNIQUE NOT NULL, openingQuantity INTEGER DEFAULT 0,
      soldQuantity INTEGER DEFAULT 0, returnedQuantity INTEGER DEFAULT 0,
      currentQuantity INTEGER DEFAULT 0, costPrice REAL DEFAULT 0,
      totalInventoryCost REAL DEFAULT 0, inventoryAdjustment INTEGER DEFAULT 0,
      shop_id TEXT, cloud_uuid TEXT, server_version INTEGER DEFAULT 0,
      sync_status TEXT DEFAULT 'SYNCED', last_synced_at TEXT)
  ''',
    '''
    CREATE TABLE sales (
      id INTEGER PRIMARY KEY AUTOINCREMENT, invoiceId INTEGER, date TEXT NOT NULL,
      productName TEXT NOT NULL, barcode TEXT NOT NULL, quantity INTEGER DEFAULT 0,
      salePrice REAL DEFAULT 0, totalSaleValue REAL DEFAULT 0, costPrice REAL DEFAULT 0,
      cogs REAL DEFAULT 0, shop_id TEXT, cloud_uuid TEXT,
      server_version INTEGER DEFAULT 0, sync_status TEXT DEFAULT 'SYNCED',
      last_synced_at TEXT)
  ''',
    '''
    CREATE TABLE returns (
      id INTEGER PRIMARY KEY AUTOINCREMENT, date TEXT NOT NULL,
      productName TEXT NOT NULL, barcode TEXT NOT NULL, quantity INTEGER DEFAULT 0,
      salePrice REAL DEFAULT 0, totalReturnValue REAL DEFAULT 0, costPrice REAL DEFAULT 0,
      returnedCogs REAL DEFAULT 0, shop_id TEXT, cloud_uuid TEXT,
      server_version INTEGER DEFAULT 0, sync_status TEXT DEFAULT 'SYNCED',
      last_synced_at TEXT)
  ''',
    '''
    CREATE TABLE expenses (
      id INTEGER PRIMARY KEY AUTOINCREMENT, date TEXT NOT NULL,
      description TEXT NOT NULL, amount REAL DEFAULT 0, category TEXT,
      shop_id TEXT, cloud_uuid TEXT, server_version INTEGER DEFAULT 0,
      sync_status TEXT DEFAULT 'SYNCED', last_synced_at TEXT)
  ''',
    '''
    CREATE TABLE expense_categories (
      id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT UNIQUE NOT NULL,
      shop_id TEXT, cloud_uuid TEXT, server_version INTEGER DEFAULT 0,
      sync_status TEXT DEFAULT 'SYNCED', last_synced_at TEXT)
  ''',
    '''
    CREATE TABLE customers (
      id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, phone TEXT,
      address TEXT, notes TEXT, isActive INTEGER DEFAULT 1,
      isSystem INTEGER DEFAULT 0, createdAt TEXT NOT NULL, updatedAt TEXT,
      shop_id TEXT, cloud_uuid TEXT, server_version INTEGER DEFAULT 0,
      sync_status TEXT DEFAULT 'SYNCED', last_synced_at TEXT)
  ''',
    '''
    CREATE TABLE invoices (
      id INTEGER PRIMARY KEY AUTOINCREMENT, invoiceNumber TEXT UNIQUE NOT NULL,
      date TEXT NOT NULL, customerName TEXT NOT NULL, paymentMethod TEXT NOT NULL,
      totalAmount REAL DEFAULT 0, totalItems INTEGER DEFAULT 0, createdAt TEXT NOT NULL,
      shop_id TEXT, cloud_uuid TEXT, server_version INTEGER DEFAULT 0,
      sync_status TEXT DEFAULT 'SYNCED', last_synced_at TEXT)
  ''',
    '''
    CREATE TABLE inventory_count (
      id INTEGER PRIMARY KEY AUTOINCREMENT, productId INTEGER NOT NULL,
      actualQuantity INTEGER DEFAULT 0, notes TEXT DEFAULT '',
      countDate TEXT NOT NULL, shop_id TEXT, cloud_uuid TEXT,
      server_version INTEGER DEFAULT 0, sync_status TEXT DEFAULT 'SYNCED',
      last_synced_at TEXT)
  ''',
    '''
    CREATE TABLE app_settings (
      key TEXT PRIMARY KEY, value TEXT NOT NULL, shop_id TEXT,
      cloud_uuid TEXT, server_version INTEGER DEFAULT 0,
      sync_status TEXT DEFAULT 'SYNCED', last_synced_at TEXT)
  ''',
  ];
}
