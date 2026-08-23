/// Phase N (N-D06/N-D09/N-D13 error model §20.18): workbook selection and
/// container validation constants, stable typed error taxonomy, severity
/// model, and the import result envelope contract (N-D17).
///
/// This file is intentionally free of database/reader imports so both the
/// platform picker adapters and the XlsxReader hardening can depend on it.
library;

import 'workbook_source.dart';

/// Canonical 10 MiB cap (frozen: `10 * 1024 * 1024`).
const int maxWorkbookBytes = 10 * 1024 * 1024;

/// Zip-bomb guard (N-NFR04): total inflated archive size may not exceed this
/// bound — a sane multiple of the source cap.
const int maxTotalInflatedBytes = maxWorkbookBytes * 5;

/// Upper bound on archive entry count before we treat a package as hostile.
const int maxArchiveEntries = 4096;

const String xlsxExtension = '.xlsx';

enum WorkbookSeverity { blocking, warning, info }

/// Stable machine categories (§20.18). Never render [toString] to users;
/// render [userMessage] (Arabic template) instead.
enum WorkbookErrorCode {
  selectionError,
  accessError,
  unsupportedFile,
  oversizedFile,
  corruptWorkbook,
  schemaMismatch,
  validationFailure,
  duplicateImport,
  databaseFailure,
  rollbackFailure,
  internalUnexpected,
}

extension WorkbookErrorCodeX on WorkbookErrorCode {
  String get userMessage {
    switch (this) {
      case WorkbookErrorCode.selectionError:
        return 'تعذر فتح نافذة اختيار الملف. حاول مرة أخرى.';
      case WorkbookErrorCode.accessError:
        return 'تعذر قراءة الملف. تأكد من أن الملف غير تالف وغير مفتوح في برنامج آخر.';
      case WorkbookErrorCode.unsupportedFile:
        return 'نوع الملف غير مدعوم. يُسمح فقط بملفات Excel بصيغة xlsx.';
      case WorkbookErrorCode.oversizedFile:
        return 'حجم الملف يتجاوز الحد المسموح (10 ميغابايت).';
      case WorkbookErrorCode.corruptWorkbook:
        return 'الملف تالف أو ليس ملف Excel صالحًا.';
      case WorkbookErrorCode.schemaMismatch:
        return 'بنية الملف غير مطابقة للقالب المتوقع.';
      case WorkbookErrorCode.validationFailure:
        return 'بيانات الملف تحتوي على أخطاء تمنع الاستيراد.';
      case WorkbookErrorCode.duplicateImport:
        return 'تم استيراد هذا الملف مسبقًا.';
      case WorkbookErrorCode.databaseFailure:
        return 'حدث خطأ أثناء حفظ البيانات. لم يتم استيراد أي بيانات.';
      case WorkbookErrorCode.rollbackFailure:
        return 'حدث خطأ حرج أثناء الاستيراد. يُرجى مراجعة سلامة البيانات.';
      case WorkbookErrorCode.internalUnexpected:
        return 'حدث خطأ غير متوقع. حاول مرة أخرى.';
    }
  }
}

/// Typed domain failure. Carries a machine category + Arabic user message;
/// raw OS/parser strings are NEVER embedded in [userMessage].
class WorkbookValidationException implements Exception {
  final WorkbookErrorCode code;
  final String message;

  const WorkbookValidationException(this.code, this.message);

  /// Arabic, RTL-safe user-facing message (category template). Raw [message]
  /// internals are for logs only.
  String get userMessage => code.userMessage;

  @override
  String toString() => 'WorkbookValidationException(${code.name}: $message)';
}

/// V1 file-level validation (pre-read): extension + size + non-empty.
/// Runs on metadata only; bytes are re-checked after read (N-D06).
void validateWorkbookSelection(PickedWorkbook workbook) {
  final name = workbook.fileName.toLowerCase();
  if (!name.endsWith(xlsxExtension)) {
    throw WorkbookValidationException(
      WorkbookErrorCode.unsupportedFile,
      'امتداد غير مدعوم: ${workbook.fileName}',
    );
  }
  if (workbook.sizeBytes <= 0) {
    throw const WorkbookValidationException(
      WorkbookErrorCode.accessError,
      'الملف فارغ',
    );
  }
  if (workbook.sizeBytes > maxWorkbookBytes) {
    throw WorkbookValidationException(
      WorkbookErrorCode.oversizedFile,
      'حجم الملف ${workbook.sizeBytes} بايت يتجاوز الحد $maxWorkbookBytes',
    );
  }
}

/// Re-checks actual byte length after read (N-D06 second stage).
void validateWorkbookBytes(int byteLength) {
  if (byteLength <= 0) {
    throw const WorkbookValidationException(
      WorkbookErrorCode.accessError,
      'الملف فارغ',
    );
  }
  if (byteLength > maxWorkbookBytes) {
    throw WorkbookValidationException(
      WorkbookErrorCode.oversizedFile,
      'حجم المحتوى الفعلي $byteLength بايت يتجاوز الحد $maxWorkbookBytes',
    );
  }
}

// ===================== RESULT SUMMARY CONTRACT (N-D17) =====================

enum WorkbookImportStatus {
  succeeded,
  failedRolledBack,
  duplicateDetected,
  cancelled,
  invalid,
}

extension WorkbookImportStatusX on WorkbookImportStatus {
  /// Arabic, RTL-safe status label for the result summary UI.
  String get arabicLabel {
    switch (this) {
      case WorkbookImportStatus.succeeded:
        return 'تم الاستيراد بنجاح';
      case WorkbookImportStatus.failedRolledBack:
        return 'فشل الاستيراد وتم التراجع عن كل التغييرات';
      case WorkbookImportStatus.duplicateDetected:
        return 'ملف مكرر — تم استيراده مسبقًا';
      case WorkbookImportStatus.cancelled:
        return 'تم الإلغاء';
      case WorkbookImportStatus.invalid:
        return 'الملف غير صالح للاستيراد';
    }
  }
}

class ImportCounts {
  final int products;
  final int sales;
  final int returns;
  final int expenses;
  final int adjustments;

  const ImportCounts({
    this.products = 0,
    this.sales = 0,
    this.returns = 0,
    this.expenses = 0,
    this.adjustments = 0,
  });
}

/// Terminal outcome for one import attempt over one selected file.
/// `rolledBack` is honest per N-D19: only the local SQLite transaction is
/// guaranteed atomic.
class WorkbookImportOutcome {
  final WorkbookImportStatus status;
  final int? batchId;
  final String fileSha256;
  final String fileName;
  final ImportCounts counts;
  final List<String> warnings;
  final List<String> errors;
  final bool rolledBack;

  /// Original `imported_at` when [status] == duplicateDetected.
  final DateTime? originalImportedAt;

  const WorkbookImportOutcome({
    required this.status,
    required this.fileSha256,
    required this.fileName,
    this.counts = const ImportCounts(),
    this.batchId,
    this.warnings = const [],
    this.errors = const [],
    this.rolledBack = false,
    this.originalImportedAt,
  });
}
