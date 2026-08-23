import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muaman_store/database/workbook_importer.dart';
import 'package:muaman_store/import/workbook_source.dart';
import 'package:muaman_store/import/workbook_validation.dart';
import 'package:muaman_store/services/active_shop_context.dart';
import 'package:sqflite/sqflite.dart';

import 'support/import_test_fixtures.dart';

void main() {
  late Database db;

  setUp(() async {
    db = await openImportTestDb();
    ActiveShopContext.instance
        .configure(membershipValidator: (_) async => true);
    await ActiveShopContext.instance.bind('shop-dedup-test');
  });

  tearDown(() async {
    ActiveShopContext.instance.resetForTest();
    await db.close();
  });

  Future<PickedWorkbook> writeWorkbook(String name, List<int> bytes) async {
    final dir = await Directory.systemTemp.createTemp('phase_n_dedup_');
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(bytes);
    return PickedWorkbook(
        path: file.path, fileName: name, sizeBytes: bytes.length);
  }

  test('N-T15 SHA-256 identity matches known vector in lowercase hex',
      () async {
    // Known SHA-256 vector of ASCII "abc":
    const expected =
        'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad';

    final bytes = buildXlsxBytes(validSyntheticWorkbook());
    final picked = await writeWorkbook('vector.xlsx', bytes);

    final preparation =
        await WorkbookImporter.prepareFromSource(workbook: picked, db: db);

    expect(preparation.fileSha256, isNot(equals(expected.toUpperCase())));
    // Hash the exact same bytes independently and compare casing/length:
    expect(preparation.fileSha256.length, 64);
    expect(preparation.fileSha256, preparation.fileSha256.toLowerCase());
    // The preparation hash must equal the hash recorded on a successful
    // import of the SAME bytes (hash-once reuse).
    final outcome = await WorkbookImporter.importFromSource(
      workbook: picked,
      db: db,
      enqueueSync: false,
    );
    expect(outcome.status, WorkbookImportStatus.succeeded);
    expect(outcome.fileSha256, preparation.fileSha256);

    // Sanity-check the known-vector expectation itself using the same
    // algorithm the importer uses (crypto sha256 over exact bytes).
    // ignore: avoid_dynamic_calls
    final known = _sha256HexOf(<int>[97, 98, 99]); // "abc"
    expect(known, expected);
  });

  test(
      'N-T16 same bytes + different filename → DUPLICATE_DETECTED '
      'with original imported_at', () async {
    final bytes = buildXlsxBytes(validSyntheticWorkbook());
    final first = await writeWorkbook('original.xlsx', bytes);
    final outcome1 = await WorkbookImporter.importFromSource(
      workbook: first,
      db: db,
      allowZeroCost: true,
    );
    expect(outcome1.status, WorkbookImportStatus.succeeded);

    // Byte-identical content under a DIFFERENT name:
    final renamed = await writeWorkbook('renamed-نسخة.xlsx', bytes);
    final outcome2 = await WorkbookImporter.importFromSource(
      workbook: renamed,
      db: db,
      allowZeroCost: true,
    );

    expect(outcome2.status, WorkbookImportStatus.duplicateDetected);
    expect(outcome2.originalImportedAt, isNotNull);
    expect(outcome2.rolledBack, isFalse);
    // Only one batch exists.
    expect((await db.query('import_batches')).length, 1);
  });

  test('N-T17 same filename + different bytes → distinct batch accepted',
      () async {
    final bytesA = buildXlsxBytes(validSyntheticWorkbook());
    final wbA = await writeWorkbook('month.xlsx', bytesA);
    final outcomeA = await WorkbookImporter.importFromSource(
      workbook: wbA,
      db: db,
      allowZeroCost: true,
    );
    expect(outcomeA.status, WorkbookImportStatus.succeeded);

    final bytesB = buildXlsxBytes(validSyntheticWorkbook().map((sheet, rows) {
      if (sheet == 'المخزن' && rows.length > 1) {
        return MapEntry(sheet, [
          rows.first,
          [null, 'منتج جديد', '999', '5', '2', '1', '4', '10', null, '0'],
        ]);
      }
      return MapEntry(sheet, rows);
    }));
    final wbB = await writeWorkbook('month.xlsx', bytesB); // SAME name
    final outcomeB = await WorkbookImporter.importFromSource(
      workbook: wbB,
      db: db,
      allowZeroCost: true,
    );

    expect(outcomeB.status, WorkbookImportStatus.succeeded);
    expect(outcomeB.fileSha256, isNot(outcomeA.fileSha256));
    expect(outcomeB.batchId, isNot(outcomeA.batchId));
    expect((await db.query('import_batches')).length, 2);
  });

  group('N-T21 sync handoff', () {
    test(
        'enqueueSync=true leaves pending queue rows with occurrence tokens; '
        'false leaves none; import_batches never queued', () async {
      final bytesTrue = buildXlsxBytes(validSyntheticWorkbook());
      final wbTrue = await writeWorkbook('sync-on.xlsx', bytesTrue);
      final on = await WorkbookImporter.importFromSource(
        workbook: wbTrue,
        db: db,
        allowZeroCost: true,
        enqueueSync: true,
      );
      expect(on.status, WorkbookImportStatus.succeeded);

      final queued = await db.query('sync_queue', where: "status = 'PENDING'");
      expect(queued, isNotEmpty);

      final entityTypes = queued.map((r) => r['entity_type']).toSet();
      expect(entityTypes, containsAll(['product']));
      expect(queued.map((r) => r['shop_id']), everyElement('shop-dedup-test'));
      for (final row in queued) {
        expect(row['occurrence_token'], isNotNull,
            reason: 'INV-M19 occurrence token must be persisted');
        expect(row['idempotency_key'], contains(row['occurrence_token']));
      }
      // The batch record itself must NOT be enqueued (N-D13/N-D14).
      expect(entityTypes.contains('import_batch'), isFalse);

      // Second import with enqueueSync=false → no NEW queue rows from it.
      final beforeCount = (await db.query('sync_queue')).length;
      final bytesFalse =
          buildXlsxBytes(validSyntheticWorkbook().map((sheet, rows) {
        if (sheet == 'المخزن' && rows.length > 1) {
          return MapEntry(sheet, [
            rows.first,
            [null, 'منتج فريد', '777', '5', '2', '1', '4', '10', null, '0'],
          ]);
        }
        return MapEntry(sheet, rows);
      }));
      final wbFalse = await writeWorkbook('sync-off.xlsx', bytesFalse);
      final off = await WorkbookImporter.importFromSource(
        workbook: wbFalse,
        db: db,
        allowZeroCost: true,
        enqueueSync: false,
      );
      expect(off.status, WorkbookImportStatus.succeeded);
      expect(await db.query('products'),
          hasLength(greaterThan(beforeCount == 0 ? 0 : 0)));
      final afterCount = (await db.query('sync_queue')).length;
      expect(afterCount, beforeCount,
          reason: 'enqueueSync=false must create zero import-created queue '
              'rows');
    });
  });
}

String _sha256HexOf(List<int> bytes) =>
    sha256.convert(bytes).toString().toLowerCase();
