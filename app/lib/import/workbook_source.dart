/// Phase N (N-D02): platform-neutral abstraction over "the user selected a
/// workbook file". Picker mechanics (Win32 dialog / Android SAF via
/// file_picker) live behind [WorkbookSource]; importer business rules never
/// touch the platform.
library;

/// A successfully picked workbook candidate. Identity is the FILE CONTENT
/// (hashed later), never the name; [fileName] is display-only metadata.
class PickedWorkbook {
  /// Plugin-provided local path (on Android this is file_picker's cache copy
  /// of the SAF document — consumed read-once per N-D05).
  final String path;
  final String fileName;
  final int sizeBytes;

  const PickedWorkbook({
    required this.path,
    required this.fileName,
    required this.sizeBytes,
  });
}

enum WorkbookPickStatus { selected, cancelled, error }

/// Result envelope for a pick attempt. Cancellation is a normal outcome,
/// never an exception; plugin failures surface as [status] == error with a
/// retryable Arabic message (N-D16: picker failure must NOT resurrect the
/// typed-path flow).
class WorkbookPickResult {
  final WorkbookPickStatus status;
  final PickedWorkbook? workbook;

  /// Arabic, human-readable reason when [status] == error.
  final String? errorMessage;

  const WorkbookPickResult._(this.status, this.workbook, this.errorMessage);

  const WorkbookPickResult.selected(PickedWorkbook workbook)
      : this._(WorkbookPickStatus.selected, workbook, null);

  const WorkbookPickResult.cancelled()
      : this._(WorkbookPickStatus.cancelled, null, null);

  const WorkbookPickResult.error(String message)
      : this._(WorkbookPickStatus.error, null, message);

  bool get isSelected => status == WorkbookPickStatus.selected;
}

abstract class WorkbookSource {
  Future<WorkbookPickResult> pick();
}
