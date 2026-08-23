import 'dart:io';

import 'package:file_picker/file_picker.dart';

import 'workbook_source.dart';
import 'workbook_validation.dart';

/// Phase N (N-D03/N-D04): single picker adapter for BOTH platforms.
///
/// Windows  → native open dialog filtered to .xlsx (file_picker).
/// Android → SAF system document picker via the same file_picker call;
/// the plugin copies the content URI into app cache and returns that path
/// (read-once consumption per N-D05). NO storage permission is requested and
/// no manifest/native surface is involved.
class PickerWorkbookSource implements WorkbookSource {
  final FilePicker _picker;

  PickerWorkbookSource({FilePicker? picker})
      : _picker = picker ?? FilePicker.platform;

  @override
  Future<WorkbookPickResult> pick() async {
    try {
      final result = await _picker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['xlsx'],
        allowMultiple: false,
        withData: false,
      );
      if (result == null || result.files.isEmpty) {
        return const WorkbookPickResult.cancelled();
      }
      final file = result.files.single;
      final path = file.path;
      if (path == null || path.isEmpty) {
        return WorkbookPickResult.error(
            WorkbookErrorCode.selectionError.userMessage);
      }
      final size = file.size > 0 ? file.size : (File(path).lengthSync());
      return WorkbookPickResult.selected(PickedWorkbook(
        path: path,
        fileName: file.name,
        sizeBytes: size,
      ));
    } on WorkbookValidationException {
      rethrow;
    } catch (_) {
      // Never leak plugin/OS internals to the UI (§20.18).
      return WorkbookPickResult.error(
          WorkbookErrorCode.selectionError.userMessage);
    }
  }
}
