import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muaman_store/database/workbook_importer.dart';
import 'package:muaman_store/database/xlsx_reader.dart';
import 'package:muaman_store/import/workbook_source.dart';
import 'package:muaman_store/import/workbook_validation.dart';
import 'package:muaman_store/screens/settings_screen.dart';
import 'package:muaman_store/services/active_shop_context.dart';

import 'support/import_test_fixtures.dart';

class _FakeSource implements WorkbookSource {
  final WorkbookPickResult Function() onPick;
  _FakeSource(this.onPick);

  @override
  Future<WorkbookPickResult> pick() async => onPick();
}

class _FakeController implements ExcelImportController {
  final WorkbookPreparation? preparation;
  final WorkbookImportOutcome? outcome;
  final Object? prepareError;

  PickedWorkbook? preparedWith;
  bool? confirmedAllowZeroCost;

  _FakeController({this.preparation, this.outcome, this.prepareError});

  @override
  Future<WorkbookPreparation> prepare(PickedWorkbook workbook) async {
    preparedWith = workbook;
    final err = prepareError;
    if (err != null) throw err;
    return preparation!;
  }

  @override
  Future<WorkbookImportOutcome> confirm(PickedWorkbook workbook,
      {required bool allowZeroCost}) async {
    confirmedAllowZeroCost = allowZeroCost;
    return outcome!;
  }
}

Map<String, XlsxSheetData> _toSheets(Map<String, List<List<String?>>> raw) {
  return raw.map((name, rows) => MapEntry(name, XlsxSheetData(name, rows)));
}

void main() {
  setUpAll(() {
    // sqflite ffi initialized inside openImportTestDb (used by N-T23).
  });

  group('N-T19 result summary contract', () {
    test('every terminal status has a complete envelope and Arabic label', () {
      for (final status in WorkbookImportStatus.values) {
        expect(status.arabicLabel, isNotEmpty,
            reason: '${status.name} must have an Arabic label');
      }

      const succeeded = WorkbookImportOutcome(
        status: WorkbookImportStatus.succeeded,
        fileSha256: 'abc123',
        fileName: 'f.xlsx',
        batchId: 7,
      );
      expect(succeeded.batchId, isNotNull);
      expect(succeeded.counts.products, 0);
      expect(succeeded.warnings, isEmpty);
      expect(succeeded.errors, isEmpty);
      expect(succeeded.rolledBack, isFalse);

      const failed = WorkbookImportOutcome(
        status: WorkbookImportStatus.failedRolledBack,
        fileSha256: '',
        fileName: 'f.xlsx',
        errors: ['خطأ'],
        rolledBack: true,
      );
      expect(failed.batchId, isNull);
      expect(failed.rolledBack, isTrue);

      const invalid = WorkbookImportOutcome(
        status: WorkbookImportStatus.invalid,
        fileSha256: '',
        fileName: 'f.xlsx',
        errors: ['نوع الملف غير مدعوم'],
      );
      // No raw exception / stack-trace strings surface as errors.
      expect(invalid.errors.join(), isNot(contains('Exception')));
      expect(invalid.errors.join(), isNot(contains('.dart')));
    });
  });

  group('N-T23 Android lifecycle safety', () {
    test(
        'simulated process death between pick and confirm leaves DB '
        'untouched', () async {
      final db = await openImportTestDb();
      ActiveShopContext.instance
          .configure(membershipValidator: (_) async => true);
      await ActiveShopContext.instance.bind('shop-death-test');

      final before = <String, int>{
        for (final t in [
          'products',
          'sales',
          'returns',
          'expenses',
          'inventory_count',
          'import_batches',
          'sync_queue'
        ])
          t: (await db.query(t)).length
      };

      // Pick + observational prepare succeed; then the process "dies".
      // Nothing persists the selection and no import runs.
      final workbookPath = repoWorkbookPath();
      await WorkbookImporter.prepareFromSource(
        workbook: PickedWorkbook(
          path: workbookPath,
          fileName: 'died.xlsx',
          sizeBytes: File(workbookPath).lengthSync(),
        ),
        db: db,
      );

      final after = <String, int>{
        for (final t in before.keys) t: (await db.query(t)).length
      };
      expect(after, before,
          reason: 'death-before-confirm must leave every table unchanged');

      ActiveShopContext.instance.resetForTest();
      await db.close();
    });
  });

  group('N-T24 fixed-path UX retirement', () {
    test('new Windows/Android flow never invokes legacy path helpers', () {
      final source =
          File('lib/screens/settings_screen.dart').readAsStringSync();

      expect(source.contains('_workbookPathController'), isFalse,
          reason: 'typed-path controller must be gone');
      expect(source.contains('getWorkbookPath'), isFalse);
      expect(source.contains('setWorkbookPath'), isFalse);
      expect(source.contains('getDefaultWorkbookPath'), isFalse);
      expect(source.contains('PickerWorkbookSource'), isTrue,
          reason: 'the live picker flow must be wired in');
      expect(source.contains('ExcelImportSection'), isTrue);

      final appSettings =
          File('lib/services/app_settings.dart').readAsStringSync();
      expect(appSettings.contains('getDefaultWorkbookPath'), isFalse,
          reason: 'legacy fixed-path discovery deleted (N-D16)');
      expect(appSettings.contains("keyWorkbookPath = 'workbookPath'"), isTrue,
          reason: 'settings KEY stays recognized for cloud validation');
    });
  });

  group('widget flow', () {
    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    Widget host(WorkbookSource source, {ExcelImportController? controller}) =>
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: SingleChildScrollView(
                child: ExcelImportSection(
                  workbookSource: source,
                  controller: controller,
                ),
              ),
            ),
          ),
        );

    Future<void> pumpUntil(WidgetTester tester, Finder finder) async {
      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 25));
        if (finder.evaluate().isNotEmpty) return;
      }
      fail('expected UI state never appeared: $finder');
    }

    testWidgets('N-T04 picker cancel returns to IDLE without error',
        (tester) async {
      final cancelled = _FakeSource(() => const WorkbookPickResult.cancelled());
      await tester.pumpWidget(host(cancelled));

      await tester.tap(find.byKey(const ValueKey('select-workbook-button')));
      await tester.pump();

      expect(
          find.byKey(const ValueKey('select-workbook-button')), findsOneWidget,
          reason: 'flow must return to IDLE with no error surfaced');
    });

    testWidgets(
        'full journey: pick -> preview -> ack zero-cost -> confirm '
        '-> success summary', (tester) async {
      const picked = PickedWorkbook(
          path: r'C:\fake\wb.xlsx', fileName: 'wb.xlsx', sizeBytes: 2048);
      final selectedSource =
          _FakeSource(() => const WorkbookPickResult.selected(picked));

      // Zero-cost product present in this preview -> acknowledgement gate.
      final preparation = WorkbookPreparation(
        fileSha256: 'deadbeefdeadbeef',
        fileName: 'wb.xlsx',
        preview: buildPreview(_toSheets({
          ...validSyntheticWorkbook(),
          'المخزن': [
            [null],
            [null, 'تحزية', '900', '1', '0', '0', '1', '0', null, '0'],
          ],
        })),
      );
      expect(preparation.preview.hasZeroCostProduct, isTrue);
      final successOutcome = WorkbookImportOutcome(
        status: WorkbookImportStatus.succeeded,
        fileSha256: 'deadbeefdeadbeef',
        fileName: 'wb.xlsx',
        batchId: 1,
        counts: const ImportCounts(products: 1),
      );
      final controller = _FakeController(
        preparation: preparation,
        outcome: successOutcome,
      );

      await tester.pumpWidget(host(selectedSource, controller: controller));
      await tester.tap(find.byKey(const ValueKey('select-workbook-button')));
      await pumpUntil(tester, find.textContaining('wb.xlsx'));

      final confirmFinder = find.byKey(const ValueKey('confirm-import-button'));
      expect(tester.widget<ElevatedButton>(confirmFinder).onPressed, isNull,
          reason: 'confirm disabled until zero-cost acknowledged');

      await tester.tap(find.byKey(const ValueKey('zero-cost-ack')));
      await tester.pump();
      expect(tester.widget<ElevatedButton>(confirmFinder).onPressed, isNotNull);

      await tester.tap(confirmFinder);
      await pumpUntil(tester,
          find.textContaining(WorkbookImportStatus.succeeded.arabicLabel));

      expect(controller.confirmedAllowZeroCost, isTrue);
    });

    testWidgets('N-T19 every terminal status renders its Arabic summary',
        (tester) async {
      for (final status in WorkbookImportStatus.values) {
        final outcome = WorkbookImportOutcome(
          status: status,
          fileSha256: status == WorkbookImportStatus.succeeded ? 'cafe' : '',
          fileName: 'f.xlsx',
          batchId: status == WorkbookImportStatus.succeeded ? 42 : null,
          counts: status == WorkbookImportStatus.succeeded
              ? const ImportCounts(products: 3)
              : const ImportCounts(),
          errors: status == WorkbookImportStatus.invalid
              ? const ['نوع الملف غير مدعوم']
              : [],
        );
        final source = _FakeSource(() => const WorkbookPickResult.selected(
            PickedWorkbook(
                path: 'C:\\fake\\f.xlsx', fileName: 'f.xlsx', sizeBytes: 10)));
        final controller = _FakeController(
          preparation: WorkbookPreparation(
            fileSha256: 'aa',
            fileName: 'f.xlsx',
            preview: buildPreview(_toSheets(validSyntheticWorkbook())),
          ),
          outcome: outcome,
        );

        await tester.pumpWidget(Container(
            key: UniqueKey(), child: host(source, controller: controller)));
        await tester.tap(find.byKey(const ValueKey('select-workbook-button')));
        await pumpUntil(tester, find.textContaining('الملف: f.xlsx'));

        final confirmFinder =
            find.byKey(const ValueKey('confirm-import-button'));
        await tester.ensureVisible(confirmFinder);
        await tester.tap(confirmFinder);
        await pumpUntil(tester, find.textContaining(status.arabicLabel));

        await tester.pumpWidget(Container()); // unmount between iterations
        await tester.pump();
      }
    });
  });
}
