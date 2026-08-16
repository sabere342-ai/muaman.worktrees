import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'invoice_document_data.dart';
import 'invoice_pdf_renderer.dart';

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

  /// Saves the invoice PDF through the native save dialog. Returns the chosen
  /// path, or null when the user cancels.
  Future<String?> savePdf(InvoiceDocumentData data) async {
    final bytes = await buildPdfBytes(data);
    return savePdfBytes(bytes, invoiceFileName(data));
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
