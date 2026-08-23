import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muaman_store/database/xlsx_reader.dart';
import 'package:muaman_store/import/workbook_validation.dart';

import 'support/import_test_fixtures.dart';

void main() {
  group('N-T08 corrupt / malformed workbook rejection', () {
    test('truncated ZIP rejected gracefully', () {
      final valid = buildXlsxBytes(validSyntheticWorkbook());
      final truncated = Uint8List.sublistView(valid, 0, valid.length ~/ 2);

      expect(
        () => XlsxReader.readBytes(truncated),
        throwsA(isA<WorkbookValidationException>()
            .having((e) => e.code, 'code', WorkbookErrorCode.corruptWorkbook)),
      );
    });

    test('text payload renamed to .xlsx rejected gracefully', () {
      final fake = Uint8List.fromList('هذا ملف نصي وليس Excel'.codeUnits);

      expect(
        () => XlsxReader.readBytes(fake),
        throwsA(isA<WorkbookValidationException>()
            .having((e) => e.code, 'code', WorkbookErrorCode.corruptWorkbook)),
      );
    });

    test('ZIP missing xl/workbook.xml rejected with explicit error', () {
      // Valid synthetic zip then rebuild without workbook.xml is complex;
      // instead build a minimal zip containing an unrelated entry.
      final archive = Archive();
      final content = Uint8List.fromList('hello'.codeUnits);
      archive.addFile(ArchiveFile('unrelated.txt', content.length, content));
      final bytes = Uint8List.fromList(ZipEncoder().encode(archive)!);

      expect(
        () => XlsxReader.readBytes(bytes),
        throwsA(isA<WorkbookValidationException>()
            .having((e) => e.code, 'code', WorkbookErrorCode.corruptWorkbook)
            .having((e) => e.message, 'message', contains('workbook.xml'))),
      );
    });

    test('empty bytes rejected as access error before any parsing', () {
      expect(
        () => XlsxReader.readBytes(Uint8List(0)),
        throwsA(isA<WorkbookValidationException>()
            .having((e) => e.code, 'code', WorkbookErrorCode.accessError)),
      );
    });
  });
}
