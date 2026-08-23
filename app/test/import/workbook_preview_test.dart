import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:muaman_store/database/workbook_importer.dart';
import 'package:muaman_store/database/xlsx_reader.dart';
import 'package:muaman_store/import/workbook_source.dart';
import 'package:muaman_store/import/workbook_validation.dart';
import 'package:muaman_store/services/active_shop_context.dart';
import 'package:sqflite/sqflite.dart';

import 'support/import_test_fixtures.dart';

Map<String, XlsxSheetData> _toSheets(Map<String, List<List<String?>>> raw) {
  return raw.map((name, rows) => MapEntry(name, XlsxSheetData(name, rows)));
}

void main() {
  late Database db;

  setUpAll(() async {
    db = await openImportTestDb();
    ActiveShopContext.instance
        .configure(membershipValidator: (_) async => true);
    await ActiveShopContext.instance.bind('shop-preview-test');
  });

  tearDownAll(() async {
    ActiveShopContext.instance.resetForTest();
    await db.close();
  });

  group('N-T09 missing sheets', () {
    test('blocking errors list ALL missing Arabic worksheet names', () {
      final sheets = {
        'لوحة التحكم': _sheet(),
        'المخزن': _sheet(),
      };
      final preview = buildPreview(_toSheets(sheets));

      expect(preview.hasBlockingErrors, isTrue);
      final messages = preview.blockingErrors.map((e) => e.message);
      expect(messages, contains('الورقة المطلوبة "الجرد" غير موجودة'));
      expect(messages, contains('الورقة المطلوبة "المبيعات" غير موجودة'));
      expect(messages, contains('الورقة المطلوبة "المرتجعات" غير موجودة'));
      expect(messages, contains('الورقة المطلوبة "المصروفات" غير موجودة'));
    });
  });

  group('N-T10 skip-tally semantics', () {
    test('short rows and missing identity rows are tallied, not counted', () {
      final sheets = <String, List<List<String?>>>{
        'لوحة التحكم': [
          [null]
        ],
        'المخزن': [
          [null],
          [null, 'منتج أ', '100', '5', '2', '1', '4', '10', null, '0'],
          [null, 'ملاحظة', null, null, null, null, null, null, null, null],
          [null, 'منتج ج'], // short row (length 4) → skippedShortRows
          [null, 'منتج د', null, '1', '1', '1', '1', '5', null, '0'],
        ],
        'الجرد': [
          [null, 'الاسم', 'الباركود', null, 'فعلي'],
          [null, 'منتج أ', '100', null, '6'],
        ],
        'المبيعات': [
          [
            null,
            'التاريخ',
            'الاسم',
            'الباركود',
            'كمية',
            'السعر',
            null,
            'التكلفة',
            null
          ],
          [null, '45000', 'منتج أ', '100', '2', '15', null, '5', null],
          [null, '45000', '', '', '', '', null, '', null], // empty name
        ],
        'المرتجعات': [
          [
            null,
            'التاريخ',
            'الاسم',
            'الباركود',
            'كمية',
            'السعر',
            null,
            'التكلفة',
            null
          ],
          [null, '45000', 'منتج أ', '100', '1', '15', null, '5', null],
        ],
        'المصروفات': [
          [null, 'التاريخ', 'البيان', 'المبلغ'],
          [null, '45000', 'إيجار', '500'],
        ],
      };

      final preview = buildPreview(_toSheets(sheets));

      expect(preview.products, 1); // منتج أ only (منتج د lacks a barcode)
      expect(preview.sales, 1);
      expect(preview.returns, 1);
      expect(preview.expenses, 1);
      expect(preview.adjustments, 1);
      expect(preview.noteRows, greaterThanOrEqualTo(1));
      expect(preview.skippedShortRows, greaterThanOrEqualTo(1));
      expect(preview.skippedMissingIdentity, greaterThanOrEqualTo(1));
      expect(preview.hasBlockingErrors, isFalse);
    });
  });

  group('N-T11 row-level error sampling', () {
    test('invalid numerics produce row errors capped at 50 samples', () {
      final storeRows = <List<String?>>[
        [null],
      ];
      // 60 product rows with non-numeric cost → all tallied, only 50 kept.
      for (var i = 0; i < 60; i++) {
        storeRows.add(
            [null, 'منتج$i', 'b$i', '1', '1', '1', '1', 'سعر؟', null, '0']);
      }
      final sheets = <String, List<List<String?>>>{
        'لوحة التحكم': [
          [null]
        ],
        'المخزن': storeRows,
        'الجرد': [
          [null, 'الاسم', 'الباركود', null, 'فعلي'],
        ],
        'المبيعات': [
          [
            null,
            'التاريخ',
            'الاسم',
            'الباركود',
            'كمية',
            'السعر',
            null,
            'التكلفة',
            null
          ],
        ],
        'المرتجعات': [
          [
            null,
            'التاريخ',
            'الاسم',
            'الباركود',
            'كمية',
            'السعر',
            null,
            'التكلفة',
            null
          ],
        ],
        'المصروفات': [
          [null, 'التاريخ', 'البيان', 'المبلغ'],
        ],
      };

      final preview = buildPreview(_toSheets(sheets));

      expect(preview.totalRowErrors, 60);
      expect(preview.rowErrorSamples.length, maxPreviewRowErrorSamples);
      expect(preview.rowErrorSamples.length, lessThan(60));
    });
  });

  group('N-T12 preview performs ZERO DB mutation', () {
    test('prepareFromSource leaves the entire DB state unchanged', () async {
      // Seed with DIFFERENT content than the workbook under preparation so
      // the duplicate probe does not fire.
      final seedBytes = buildXlsxBytes(validSyntheticWorkbook());
      final seedTmp = await Directory.systemTemp.createTemp('phase_n_seed_');
      final seedFile = File('${seedTmp.path}/seed.xlsx');
      await seedFile.writeAsBytes(seedBytes);

      final seed = await WorkbookImporter.importFromSource(
        workbook: PickedWorkbook(
            path: seedFile.path,
            fileName: 'seed.xlsx',
            sizeBytes: seedBytes.length),
        db: db,
        allowZeroCost: true,
      );
      expect(seed.status, WorkbookImportStatus.succeeded);

      final before = await _dbDigest(db);

      final workbookPath = repoWorkbookPath();
      final preparation = await WorkbookImporter.prepareFromSource(
        workbook: PickedWorkbook(
          path: workbookPath,
          fileName: 'probe.xlsx',
          sizeBytes: File(workbookPath).lengthSync(),
        ),
        db: db,
      );
      expect(preparation.preview.products, greaterThan(0));

      final after = await _dbDigest(db);
      expect(after, before,
          reason: 'preview/preparation must not mutate ANY table');
    });
  });
}

/// Full-table digest: every row serialized. Catches any insert/update/delete.
Future<Map<String, String>> _dbDigest(Database db) async {
  final digest = <String, String>{};
  for (final table in [
    'products',
    'sales',
    'returns',
    'expenses',
    'inventory_count',
    'import_batches',
    'sync_queue',
  ]) {
    final rows = await db.query(table);
    digest['count:$table'] = '${rows.length}';
    for (var i = 0; i < rows.length; i++) {
      digest['row:$table:$i'] = rows[i].toString();
    }
  }
  return digest;
}

List<List<String?>> _sheet() => [
      [null],
    ];
