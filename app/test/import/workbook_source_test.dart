import 'package:flutter_test/flutter_test.dart';
import 'package:muaman_store/import/workbook_source.dart';
import 'package:muaman_store/import/workbook_validation.dart';

class _FakeWorkbookSource implements WorkbookSource {
  final WorkbookPickResult Function() onPick;
  int pickCount = 0;

  _FakeWorkbookSource(this.onPick);

  @override
  Future<WorkbookPickResult> pick() async {
    pickCount++;
    return onPick();
  }
}

void main() {
  group('N-T01 WorkbookSource abstraction', () {
    test('returns a selected handle and fake injection works', () async {
      const handle = PickedWorkbook(
        path: r'C:\fake\workbook.xlsx',
        fileName: 'workbook.xlsx',
        sizeBytes: 1234,
      );
      final source =
          _FakeWorkbookSource(() => const WorkbookPickResult.selected(handle));

      final result = await source.pick();

      expect(source.pickCount, 1);
      expect(result.isSelected, isTrue);
      expect(result.workbook, same(handle));
      expect(result.workbook!.path, r'C:\fake\workbook.xlsx');
      expect(result.workbook!.fileName, 'workbook.xlsx');
      expect(result.workbook!.sizeBytes, 1234);
    });

    test('cancel and error results carry no workbook handle', () async {
      final cancelSource =
          _FakeWorkbookSource(() => const WorkbookPickResult.cancelled());
      final cancel = await cancelSource.pick();
      expect(cancel.isSelected, isFalse);
      expect(cancel.status, WorkbookPickStatus.cancelled);
      expect(cancel.workbook, isNull);

      final errorSource = _FakeWorkbookSource(
          () => const WorkbookPickResult.error('تعذر فتح نافذة اختيار الملف'));
      final error = await errorSource.pick();
      expect(error.status, WorkbookPickStatus.error);
      expect(error.errorMessage, isNotNull);
    });
  });

  group('N-T06 extension rejection', () {
    PickedWorkbook named(String fileName) => PickedWorkbook(
        path: 'C:\\fake\\$fileName', fileName: fileName, sizeBytes: 100);

    test('rejects .xls', () {
      expect(
        () => validateWorkbookSelection(named('sheet.xls')),
        throwsA(isA<WorkbookValidationException>()
            .having((e) => e.code, 'code', WorkbookErrorCode.unsupportedFile)),
      );
    });

    test('rejects .txt', () {
      expect(
        () => validateWorkbookSelection(named('data.txt')),
        throwsA(isA<WorkbookValidationException>()
            .having((e) => e.code, 'code', WorkbookErrorCode.unsupportedFile)),
      );
    });

    test('rejects .xlsx.exe (double extension)', () {
      expect(
        () => validateWorkbookSelection(named('workbook.xlsx.exe')),
        throwsA(isA<WorkbookValidationException>()
            .having((e) => e.code, 'code', WorkbookErrorCode.unsupportedFile)),
      );
    });

    test('accepts .xlsx case-insensitively', () {
      expect(() => validateWorkbookSelection(named('SHEET.XLSX')),
          returnsNormally);
    });
  });

  group('N-T07 size cap enforcement', () {
    test('rejects 10 MiB + 1 byte by metadata before read', () {
      const oversized = PickedWorkbook(
          path: 'C:\\fake\\big.xlsx',
          fileName: 'big.xlsx',
          sizeBytes: maxWorkbookBytes + 1);
      expect(
        () => validateWorkbookSelection(oversized),
        throwsA(isA<WorkbookValidationException>()
            .having((e) => e.code, 'code', WorkbookErrorCode.oversizedFile)),
      );
    });

    test('accepts exactly 10 MiB', () {
      const atCap = PickedWorkbook(
          path: 'C:\\fake\\cap.xlsx',
          fileName: 'cap.xlsx',
          sizeBytes: maxWorkbookBytes);
      expect(() => validateWorkbookSelection(atCap), returnsNormally);
    });

    test('post-read byte recheck rejects oversized actual bytes', () {
      expect(
        () => validateWorkbookBytes(maxWorkbookBytes + 1),
        throwsA(isA<WorkbookValidationException>()
            .having((e) => e.code, 'code', WorkbookErrorCode.oversizedFile)),
      );
    });

    test('empty file rejected as access error', () {
      const empty = PickedWorkbook(
          path: 'C:\\fake\\empty.xlsx', fileName: 'empty.xlsx', sizeBytes: 0);
      expect(
        () => validateWorkbookSelection(empty),
        throwsA(isA<WorkbookValidationException>()
            .having((e) => e.code, 'code', WorkbookErrorCode.accessError)),
      );
    });
  });
}
