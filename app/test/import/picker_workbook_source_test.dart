import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muaman_store/import/picker_workbook_source.dart';
import 'package:muaman_store/import/workbook_source.dart';
import 'package:muaman_store/import/workbook_validation.dart';

/// Hand-written FilePicker fake (platform-interface subclass) that records
/// delegation arguments — no real dialog, no platform channel.
class _RecordingFilePicker extends FilePicker {
  final FilePickerResult? Function() handler;

  FileType? lastType;
  List<String>? lastAllowedExtensions;
  bool lastAllowMultiple = true;
  bool lastWithData = true;

  _RecordingFilePicker({FilePickerResult? Function()? handler})
      : handler = handler ?? (() => null);

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = true,
    int compressionQuality = 30,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
  }) async {
    lastType = type;
    lastAllowedExtensions = allowedExtensions;
    lastAllowMultiple = allowMultiple;
    lastWithData = withData;
    return handler();
  }
}

PlatformFile _windowsPickedFile() => PlatformFile(
      name: 'workbook.xlsx',
      size: 2048,
      path: 'C:\\cache\\workbook.xlsx',
    );

void main() {
  group('N-T02 Windows picker delegation', () {
    test('delegates to FilePicker with .xlsx custom filter', () async {
      final fake = _RecordingFilePicker(
          handler: () => FilePickerResult([
                _windowsPickedFile(),
              ]));
      final source = PickerWorkbookSource(picker: fake);

      final result = await source.pick();

      expect(fake.lastType, FileType.custom);
      expect(fake.lastAllowedExtensions, ['xlsx']);
      expect(fake.lastAllowMultiple, isFalse);
      expect(fake.lastWithData, isFalse);
      expect(result.isSelected, isTrue);
      expect(result.workbook!.fileName, 'workbook.xlsx');
      expect(result.workbook!.path, 'C:\\cache\\workbook.xlsx');
      expect(result.workbook!.sizeBytes, 2048);
    });
  });

  group('N-T03 Android picker delegation', () {
    test(
        'delegates identically through the same abstraction '
        '(SAF-backed plugin call; no permission API involved)', () async {
      // The Android flow uses the SAME adapter and the SAME file_picker
      // contract; SAF handling lives inside the plugin. Asserting identical
      // delegation proves no platform branch adds permission surface.
      final fake = _RecordingFilePicker(
          handler: () => FilePickerResult([
                PlatformFile(
                  name: 'شيت.xlsx',
                  size: 4096,
                  path: 'C:\\cache\\cached_copy.xlsx',
                )
              ]));
      final source = PickerWorkbookSource(picker: fake);

      final result = await source.pick();

      expect(fake.lastType, FileType.custom);
      expect(fake.lastAllowedExtensions, ['xlsx']);
      expect(fake.lastAllowMultiple, isFalse);
      expect(result.isSelected, isTrue);
      expect(result.workbook!.fileName, 'شيت.xlsx');
      expect(result.workbook!.sizeBytes, 4096);
    });
  });

  group('N-T04 picker cancel / failure', () {
    test('user cancel maps to CANCELLED with zero side effects', () async {
      final fake = _RecordingFilePicker(); // null handler → cancelled
      final source = PickerWorkbookSource(picker: fake);

      final result = await source.pick();

      expect(fake.lastType, FileType.custom);
      expect(result.status, WorkbookPickStatus.cancelled);
      expect(result.workbook, isNull);
      expect(result.errorMessage, isNull);
    });

    test('plugin exception maps to retryable SELECTION_ERROR message',
        () async {
      final failing =
          _RecordingFilePicker(handler: () => throw Exception('channel err'));

      final result = await PickerWorkbookSource(picker: failing).pick();

      expect(result.status, WorkbookPickStatus.error);
      expect(result.errorMessage, WorkbookErrorCode.selectionError.userMessage);
    });

    test('result without a local path is a selection error, not a crash',
        () async {
      final fake = _RecordingFilePicker(
          handler: () => FilePickerResult([
                PlatformFile(name: 'mystery.xlsx', size: 10),
              ]));
      final result = await PickerWorkbookSource(picker: fake).pick();
      expect(result.status, WorkbookPickStatus.error);
    });
  });
}
