import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:muaman_store/database/workbook_importer.dart';
import 'package:muaman_store/import/workbook_source.dart';
import 'package:muaman_store/import/workbook_validation.dart';
import 'package:muaman_store/services/active_shop_context.dart';
import 'package:sqflite/sqflite.dart';

import 'support/import_test_fixtures.dart';

void main() {
  setUpAll(() {
    // sqflite ffi initialized inside openImportTestDb.
  });

  group('N-T05 / N-T13 / N-T20 — atomic success path', () {
    late Database db;

    setUp(() async {
      db = await openImportTestDb();
      ActiveShopContext.instance
          .configure(membershipValidator: (_) async => true);
      await ActiveShopContext.instance.bind('shop-atomic-test');
    });

    tearDown(() async {
      ActiveShopContext.instance.resetForTest();
      await db.close();
    });

    test('N-T05 preview counts == committed counts == report counts', () async {
      final workbookPath = repoWorkbookPath();
      final picked = PickedWorkbook(
        path: workbookPath,
        fileName: 'wb.xlsx',
        sizeBytes: File(workbookPath).lengthSync(),
      );

      final preparation =
          await WorkbookImporter.prepareFromSource(workbook: picked, db: db);

      final outcome = await WorkbookImporter.importFromSource(
        workbook: picked,
        db: db,
        allowZeroCost: true,
      );

      expect(outcome.status, WorkbookImportStatus.succeeded);
      expect(outcome.counts.products, preparation.preview.products);
      expect(outcome.counts.sales, preparation.preview.sales);
      expect(outcome.counts.returns, preparation.preview.returns);
      expect(outcome.counts.expenses, preparation.preview.expenses);
      expect(outcome.counts.adjustments, preparation.preview.adjustments);

      final batch = (await db.query('import_batches')).single;
      expect(batch['products_count'], outcome.counts.products);
      expect(batch['sales_count'], outcome.counts.sales);
      expect(batch['returns_count'], outcome.counts.returns);
      expect(batch['expenses_count'], outcome.counts.expenses);
      expect(batch['adjustments_count'], outcome.counts.adjustments);
      final reconciliation = jsonDecode(batch['reconciliation_json'] as String)
          as Map<String, dynamic>;
      expect(reconciliation['productsImported'], outcome.counts.products);
      expect(reconciliation['salesImported'], outcome.counts.sales);
    });

    test('N-T13 success creates business rows AND batch row in one outcome',
        () async {
      final bytes = buildXlsxBytes(validSyntheticWorkbook());
      final tmp = await _writeTemp('synthetic-ok', bytes);

      final outcome = await WorkbookImporter.importFromSource(
        workbook: PickedWorkbook(
            path: tmp, fileName: 'synthetic-ok.xlsx', sizeBytes: bytes.length),
        db: db,
        enqueueSync: false,
      );

      expect(outcome.status, WorkbookImportStatus.succeeded);
      expect(await db.query('products'), isNotEmpty);
      expect(await db.query('sales'), isNotEmpty);
      expect(await db.query('returns'), isNotEmpty);
      expect(await db.query('expenses'), isNotEmpty);
      expect(await db.query('inventory_count'), isNotEmpty);
      final batches = await db.query('import_batches');
      expect(batches.length, 1);
      expect(batches.single['id'], outcome.batchId);
    });

    test('N-T20 batch fields preserve shop_id, counts, reconciliation_json',
        () async {
      final bytes = buildXlsxBytes(validSyntheticWorkbook());
      final tmp = await _writeTemp('stamping', bytes);

      final outcome = await WorkbookImporter.importFromSource(
        workbook: PickedWorkbook(
            path: tmp, fileName: 'stamping.xlsx', sizeBytes: bytes.length),
        db: db,
        enqueueSync: false,
      );

      expect(outcome.status, WorkbookImportStatus.succeeded);
      final batch = (await db.query('import_batches')).single;
      expect(batch['shop_id'], 'shop-atomic-test');
      expect(batch['file_sha256'], outcome.fileSha256);
      expect(batch['file_name'], 'stamping.xlsx');
      expect((batch['products_count'] as int), greaterThan(0));
      expect(batch['reconciliation_json'], isNotNull);
      final json = jsonDecode(batch['reconciliation_json'] as String)
          as Map<String, dynamic>;
      expect(json.containsKey('grossProfit'), isTrue);
      expect(json.containsKey('netProfit'), isTrue);
    });
  });

  group('N-T14 / N-T18 — rollback honesty', () {
    late Database db;

    setUp(() async {
      db = await openImportTestDb();
      ActiveShopContext.instance
          .configure(membershipValidator: (_) async => true);
      await ActiveShopContext.instance.bind('shop-rollback-test');
    });

    tearDown(() async {
      ActiveShopContext.instance.resetForTest();
      await db.close();
    });

    Future<WorkbookImportOutcome> failingImport(PickedWorkbook picked) =>
        WorkbookImporter.importFromSource(
          workbook: picked,
          db: db,
          allowZeroCost: true,
          debugFailurePoint: () async =>
              throw StateError('injected late failure'),
        );

    Future<void> expectNothingPersisted() async {
      expect(await db.query('products'), isEmpty);
      expect(await db.query('sales'), isEmpty);
      expect(await db.query('returns'), isEmpty);
      expect(await db.query('expenses'), isEmpty);
      expect(await db.query('inventory_count'), isEmpty);
      expect(await db.query('sync_queue'), isEmpty,
          reason: 'queue rows from the failed attempt must roll back too');
      expect(await db.query('import_batches'), isEmpty);
    }

    test('N-T14 injected late failure rolls back EVERYTHING', () async {
      final bytes = buildXlsxBytes(validSyntheticWorkbook());
      final tmp = await _writeTemp('late-fail', bytes);
      final picked = PickedWorkbook(
          path: tmp, fileName: 'late-fail.xlsx', sizeBytes: bytes.length);

      final outcome = await failingImport(picked);

      expect(outcome.status, WorkbookImportStatus.failedRolledBack);
      expect(outcome.rolledBack, isTrue);
      await expectNothingPersisted();
    });

    test('N-T18 failed import → retry same file succeeds', () async {
      final bytes = buildXlsxBytes(validSyntheticWorkbook());
      final tmp = await _writeTemp('retry', bytes);
      final picked = PickedWorkbook(
          path: tmp, fileName: 'retry.xlsx', sizeBytes: bytes.length);

      final first = await failingImport(picked);
      expect(first.status, WorkbookImportStatus.failedRolledBack);

      // No batch row was written for the failure, so the duplicate guard
      // must NOT block the retry.
      final retry = await WorkbookImporter.importFromSource(
        workbook: picked,
        db: db,
        allowZeroCost: true,
      );
      expect(retry.status, WorkbookImportStatus.succeeded);
      expect(retry.rolledBack, isFalse);
    });
  });

  group('N-T22 tenant fail-closed', () {
    test('no active shop → INVALID outcome with preserved message', () async {
      final localDb = await openImportTestDb();
      ActiveShopContext.instance.resetForTest();

      final bytes = buildXlsxBytes(validSyntheticWorkbook());
      final tmp = await _writeTemp('noshop', bytes);

      final outcome = await WorkbookImporter.importFromSource(
        workbook: PickedWorkbook(
            path: tmp, fileName: 'noshop.xlsx', sizeBytes: bytes.length),
        db: localDb,
      );

      expect(outcome.status, WorkbookImportStatus.invalid);
      expect(outcome.errors.join(), contains('متجر نشط'));
      expect(await localDb.query('products'), isEmpty);
      expect(await localDb.query('import_batches'), isEmpty);
      await localDb.close();
    });
  });
}

Future<String> _writeTemp(String name, List<int> bytes) async {
  final dir = await Directory.systemTemp.createTemp('phase_n_');
  final file = File('${dir.path}/$name.xlsx');
  await file.writeAsBytes(bytes);
  return file.path;
}
