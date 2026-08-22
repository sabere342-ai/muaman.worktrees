import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../platform/platform_capabilities.dart';
import 'invoice_document_data.dart';
import 'invoice_pdf_renderer.dart';

/// How a rendered PDF is handed to the user (Phase K D8).
enum PdfDeliveryMode {
  /// Desktop: native save dialog writing to a user-chosen path.
  nativeSaveDialog,

  /// Android: system share sheet / print service — no arbitrary
  /// filesystem writes (scoped-storage compliant).
  systemShare,
}

/// Resolves the delivery mode for the given platform truthfully.
@visibleForTesting
PdfDeliveryMode pdfDeliveryModeFor({required bool isAndroidPlatform}) {
  return isAndroidPlatform
      ? PdfDeliveryMode.systemShare
      : PdfDeliveryMode.nativeSaveDialog;
}

/// Delivery of a rendered invoice: native print dialog, native save dialog and
/// open-with-default-viewer. All operations are read-only for business data —
/// they never touch the database.
class InvoiceDelivery {
  InvoiceDelivery({InvoicePdfRenderer? renderer})
      : _renderer = renderer ?? InvoicePdfRenderer();

  final InvoicePdfRenderer _renderer;

  Future<Uint8List> buildPdfBytes(InvoiceDocumentData data) async {
    final document = await _renderer.buildDocument(data);
    return document.save();
  }

  /// Opens the native print dialog for the invoice. Returns true when the
  /// document was sent to the printer and false when the user cancels.
  Future<bool> print(InvoiceDocumentData data) {
    return Printing.layoutPdf(
      name: invoiceFileName(data),
      format: PdfPageFormat.a4,
      onLayout: (_) => buildPdfBytes(data),
    );
  }

  /// Saves the invoice PDF through the platform-appropriate route.
  ///
  /// Desktop: native save dialog, returns the chosen path or null on
  /// cancel. Android (D8): hands the PDF to the system share sheet / print
  /// service and returns null — no arbitrary filesystem access.
  Future<String?> savePdf(InvoiceDocumentData data) async {
    final bytes = await buildPdfBytes(data);
    if (pdfDeliveryModeFor(isAndroidPlatform: PlatformCapabilities.isAndroid) ==
        PdfDeliveryMode.systemShare) {
      await Printing.sharePdf(bytes: bytes, filename: invoiceFileName(data));
      return null;
    }
    return savePdfBytes(bytes, invoiceFileName(data));
  }

  /// Shares the invoice PDF through the system share sheet / print service
  /// (Android route used by callers that need the explicit share flow).
  Future<void> sharePdf(InvoiceDocumentData data) async {
    final bytes = await buildPdfBytes(data);
    await Printing.sharePdf(bytes: bytes, filename: invoiceFileName(data));
  }

  /// Saves raw PDF bytes through the native save dialog.
  Future<String?> savePdfBytes(Uint8List bytes, String fileName) async {
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'حفظ الفاتورة PDF',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (path == null) return null;
    await File(path).writeAsBytes(bytes);
    return path;
  }

  /// Opens the invoice PDF with the default viewer. On Windows this writes a
  /// temporary file and opens it with the associated application.
  Future<void> openPdf(InvoiceDocumentData data) async {
    final bytes = await buildPdfBytes(data);
    await Printing.sharePdf(bytes: bytes, filename: invoiceFileName(data));
  }
}
